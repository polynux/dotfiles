return {
  {
    'milanglacier/minuet-ai.nvim',
    event = 'InsertEnter',
    dependencies = { 'Saghen/blink.cmp' },
    config = function()
      require('minuet').setup {
        provider = 'openai_fim_compatible',
        n_completions = 1,
        context_window = 16000,
        request_timeout = 30,
        throttle = 2000,
        debounce = 800,
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
                local system = 'You are a code completion engine. '
                  .. 'Output ONLY the code that completes the given context. '
                  .. 'No explanations, no markdown, no backticks.\n\n'
                  .. 'Complete the code after the cursor:\n'
                return system .. context_before_cursor
              end,
              suffix = false,
            },
            get_text_fn = {
              no_stream = function(json)
                return json.response or ''
              end,
            },
            transform = {
              function(data)
                local log = require('minuet.utils').notify
                log('[minuet] request sent, waiting for response...', 'debug', vim.log.levels.INFO)
                return data
              end,
            },
          },
        },
      }
    end,
  },
}