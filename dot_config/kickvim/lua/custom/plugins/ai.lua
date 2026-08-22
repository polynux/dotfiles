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
        request_timeout = 5,
        throttle = 1500,
        debounce = 600,
        provider_options = {
          openai_fim_compatible = {
            api_key = 'TERM',
            name = 'Ollama Cloud',
            end_point = 'http://localhost:11434/v1/completions',
            model = 'deepseek-v4-flash:0731-cloud',
            stream = true,
            optional = {
              max_tokens = 56,
              top_p = 0.9,
            },
          },
        },
      }
    end,
  },
}