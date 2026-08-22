return {
  {
    'milanglacier/minuet-ai.nvim',
    event = 'InsertEnter',
    dependencies = { 'Saghen/blink.cmp' },
    config = function()
      local utils = require 'minuet.utils'

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
    end,
  },
}