import { Plugin } from "@opencode/plugin"
import TurndownService from "turndown"

const PROXIES = [
  { name: "r.jina.ai", build: (url: string) => `https://r.jina.ai/${url}`, headers: { "X-Return-Format": "markdown" } },
]

const MAX_RESPONSE_BYTES = 5 * 1024 * 1024
const FALLBACK_TIMEOUT = 90_000

const CHALLENGE_MARKERS = [
  "just a moment",
  "enable javascript and cookies to continue",
  "attention required",
  "verifying you are human",
  "checking your browser",
  "cf-browser-verification",
  "ddos protection by",
]

function isProbablyHTML(s: string) {
  const head = s.slice(0, 2000).toLowerCase()
  return head.includes("<html") || head.includes("<!doctype html") || head.includes("<body")
}

function looksLikeChallenge(s: string) {
  const head = s.slice(0, 3000).toLowerCase()
  return CHALLENGE_MARKERS.some((m) => head.includes(m)) && s.length < 20_000
}

function isReadable(s: string) {
  // Very small pages (e.g. example.com, ~180 chars once converted) are still
  // legitimate; only treat genuinely empty output as unreadable.
  if (!s || s.length < 60) return false
  const printable = s.replace(/\s/g, "").length
  return printable / s.length > 0.3
}

function convertHTMLToMarkdown(html: string): string {
  const turndownService = new TurndownService({
    headingStyle: "atx",
    hr: "---",
    bulletListMarker: "-",
    codeBlockStyle: "fenced",
    emDelimiter: "*",
  })
  turndownService.remove(["script", "style", "meta", "link"])
  return turndownService.turndown(html)
}

export default Plugin.define({
  id: "webfetch-fallback",
  async setup(ctx) {
    console.log("[webfetch-fallback] initialized")
    await ctx.tool.transform((editor) => {
      const description =
        "Fetches content from a URL and converts HTML pages to markdown for reading. If a page fails to load, times out, blocks the request, or returns empty/blocked content, it automatically retries through a reader proxy (r.jina.ai) which can access pages that direct fetching cannot."
      const input = {
        type: "object",
        properties: {
          url: { type: "string", description: "The URL to fetch content from" },
          format: {
            type: "string",
            enum: ["text", "markdown", "html"],
            description: "The format to return the content in (text, markdown, or html). Defaults to markdown.",
          },
          timeout: { type: "number", description: "Optional timeout in seconds (max 120)" },
          fallback: {
            type: "boolean",
            description:
              "Set false to disable the reader-proxy fallback for this call. Defaults to true (proxy retry on failure).",
          },
        },
        required: ["url"],
        additionalProperties: false,
      }

      async function execute(inputArgs: any, toolCtx: any) {
        const url = inputArgs.url as string
        if (!url.startsWith("http://") && !url.startsWith("https://")) {
          throw new Error("URL must start with http:// or https://")
        }

        try {
          await toolCtx.progress({ title: url })
        } catch {}

        const format = (inputArgs.format as string | undefined) ?? "markdown"
        const timeoutSec = Math.min((inputArgs.timeout as number | undefined) ?? 30, 120)
        const timeoutMs = timeoutSec * 1000
        const signal = toolCtx.signal as AbortSignal

        const headers = {
          "User-Agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36",
          "Accept-Language": "en-US,en;q=0.9",
        }

        type Outcome =
          | { ok: true; content: string; contentType: string; via: string }
          | { ok: false; reason: string }

        // Convert to the requested representation, then judge readability on the
        // converted text (raw HTML always "looks unreadable").
        function render(content: string, contentType: string) {
          const mime = contentType.split(";")[0]?.trim().toLowerCase() ?? ""
          if (format === "html") return content
          if (mime.includes("html") || isProbablyHTML(content)) {
            const md = convertHTMLToMarkdown(content)
            return format === "text" ? md.replace(/<[^>]+>/g, " ") : md
          }
          return content
        }

        function judge(outcome: Extract<Outcome, { ok: true }>, useMarkers: boolean): Outcome {
          const rendered = render(outcome.content, outcome.contentType)
          if (looksLikeChallenge(outcome.content) && useMarkers) {
            return { ok: false, reason: "bot-challenge page (Cloudflare/captcha)" }
          }
          if (!isReadable(rendered)) {
            return { ok: false, reason: `content empty or not readable (format ${format})` }
          }
          return { ...outcome, content: rendered }
        }

        async function fetchDirect(): Promise<Outcome> {
          let res: Response
          try {
            res = await fetch(url, {
              headers: { ...headers, Accept: "*/*" },
              signal: AbortSignal.any([signal, AbortSignal.timeout(timeoutMs)]),
              redirect: "follow",
            })
          } catch (e) {
            return { ok: false, reason: `network error: ${e instanceof Error ? e.message : String(e)}` }
          }
          if (!res.ok) return { ok: false, reason: `HTTP ${res.status} ${res.statusText}` }
          const contentType = res.headers.get("content-type") ?? ""
          try {
            const buf = await res.arrayBuffer()
            if (buf.byteLength > MAX_RESPONSE_BYTES) return { ok: false, reason: "response exceeds 5MB" }
            return judge(
              { ok: true, content: new TextDecoder().decode(buf), contentType, via: "direct" },
              true,
            )
          } catch (e) {
            return { ok: false, reason: `read error: ${e instanceof Error ? e.message : String(e)}` }
          }
        }

        async function fetchViaProxy(proxy: (typeof PROXIES)[number]): Promise<Outcome> {
          const proxyUrl = proxy.build(url)
          try {
            const res = await fetch(proxyUrl, {
              headers: { ...proxy.headers, Accept: "text/plain, text/markdown, */*" },
              signal: AbortSignal.any([signal, AbortSignal.timeout(FALLBACK_TIMEOUT)]),
            })
            if (!res.ok) return { ok: false, reason: `proxy HTTP ${res.status}` }
            const buf = await res.arrayBuffer()
            if (buf.byteLength > MAX_RESPONSE_BYTES) return { ok: false, reason: "proxy response exceeds 5MB" }
            const contentType = res.headers.get("content-type") ?? "text/markdown"
            // Proxy output is already markdown with a Title/URL-Source header block.
            const content = new TextDecoder().decode(buf)
            if (format === "text") return { ok: true, content, contentType, via: proxy.name }
            return judge(
              { ok: true, content, contentType, via: proxy.name },
              false,
            )
          } catch (e) {
            return { ok: false, reason: `proxy error: ${e instanceof Error ? e.message : String(e)}` }
          }
        }

        let outcome = await fetchDirect()

        if (outcome.ok === false && (inputArgs.fallback as boolean | undefined) !== false) {
          try {
            await toolCtx.progress({ title: `${url} (retrying via ${PROXIES[0].name})` })
          } catch {}
          for (const proxy of PROXIES) {
            const proxied = await fetchViaProxy(proxy)
            if (proxied.ok) {
              outcome = proxied
              break
            }
          }
        }

        if (!outcome.ok) {
          throw new Error(
            `Failed to fetch ${url}: ${outcome.reason}. ` +
              ((inputArgs.fallback as boolean | undefined) === false
                ? "Retry with fallback enabled (omit the fallback parameter) or try a different URL."
                : "The reader proxy also failed. The page may require JavaScript execution, a login, or may not exist."),
          )
        }

        const mime = outcome.contentType.split(";")[0]?.trim().toLowerCase() ?? ""

        if (mime.startsWith("image/") && outcome.via === "direct") {
          const base64 = Buffer.from(outcome.content, "utf8").toString("base64")
          return {
            content: [
              { type: "text" as const, text: "Image fetched successfully" },
              { type: "file" as const, uri: `data:${mime};base64,${base64}`, mime },
            ],
            metadata: { via: outcome.via },
          }
        }

        return { content: outcome.content, metadata: { via: outcome.via } }
      }

      const definition = { name: "webfetch", description, input, execute }
      if (editor.get("webfetch")) {
        editor.update("webfetch", (t) => {
          t.description = definition.description
          t.input = definition.input
          t.execute = definition.execute
        })
      } else {
        editor.add(definition)
      }
    })
  },
})
