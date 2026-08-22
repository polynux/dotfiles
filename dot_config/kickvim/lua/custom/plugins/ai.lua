return {
  {
    'milanglacier/minuet-ai.nvim',
    event = 'InsertEnter',
    dependencies = { 'Saghen/blink.cmp' },
    config = function()
      local utils = require 'minuet.utils'
      local common = require 'minuet.backends.common'

      local system_prompt = 'You are a code completion engine. '
        .. 'Complete the code at the cursor position. '
        .. 'Output ONLY the new code to insert. '
        .. 'No explanations, no markdown, no backticks, '
        .. 'no repetition of existing code.\n\n'

      require('minuet').setup {
        provider = 'openai_fim_compatible',
        n_completions = 1,
        context_window = 16000,
        request_timeout = 30,
        throttle = 0,
        debounce = 300,
        notify = 'debug',
        provider_options = {
          openai_fim_compatible = {
            api_key = 'TERM',
            name = 'Ollama Cloud',
            end_point = 'http://localhost:11434/api/generate',
            model = 'deepseek-v4-flash:0731-cloud',
            stream = false,
            optional = {
              think = false,
              options = { num_predict = 56 },
            },
            template = {
              prompt = function(context_before_cursor, _, _)
                local language = utils.add_language_comment()
                local tab = utils.add_tab_comment()
                return system_prompt .. language .. '\n' .. tab .. '\n' .. context_before_cursor
              end,
              suffix = false,
            },
            get_text_fn = {
              no_stream = function(json)
                return json.response or ''
              end,
            },
          },
        },
      }

      -- Override the blink source to skip new requests while one is pending
      -- or when in the Avante input buffer
      local blink_source = require 'minuet.blink'
      local original_get_completions = blink_source.get_completions

      blink_source.get_completions = function(self, ctx, callback)
        local not_manual = ctx.trigger.kind ~= 'manual'
        if not_manual and #common.current_jobs > 0 then
          -- A request is already in flight; don't kill it, just return
          callback()
          return
        end
        if not_manual and vim.bo.filetype == 'AvanteInput' then
          callback()
          return
        end
        return original_get_completions(self, ctx, callback)
      end
    end,
  },
}