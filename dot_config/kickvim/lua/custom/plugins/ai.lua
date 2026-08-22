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
        request_timeout = 10,
        throttle = 1500,
        debounce = 600,
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
                local utils = require 'minuet.utils'
                local language = utils.add_language_comment()
                local tab = utils.add_tab_comment()
                context_before_cursor = language .. '\n' .. tab .. '\n' .. context_before_cursor
                return context_before_cursor
              end,
              suffix = false,
            },
            get_text_fn = {
              no_stream = function(json)
                return json.response
              end,
            },
          },
        },
      }
    end,
  },
}