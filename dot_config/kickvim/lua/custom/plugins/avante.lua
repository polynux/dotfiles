return {
  {
    'yetone/avante.nvim',
    event = 'VeryLazy',
    version = false,
    build = 'make',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'nvim-tree/nvim-web-devicons',
      'nvim-telescope/telescope.nvim',
    },
    opts = {
      provider = 'ollama',
      providers = {
        ollama = {
          model = 'glm-5.2:cloud',
          endpoint = 'http://localhost:11434',
          timeout = 60000,
          is_env_set = function()
            return true
          end,
          extra_request_body = {
            options = {
              think = false,
            },
          },
        },
      },
      behaviour = {
        auto_suggestions = false,
        auto_apply_diff_after_generation = false,
        support_paste_from_clipboard = true,
        minimize_diff = true,
      },
      windows = {
        position = 'right',
        width = 40,
        sidebar_header = {
          enabled = true,
          align = 'center',
          rounded = true,
        },
        input = {
          height = 8,
        },
      },
      mappings = {
        diff = {
          ours = 'co',
          theirs = 'ct',
          all_theirs = 'ca',
          both = 'cb',
          cursor = 'cc',
          next = ']x',
          prev = '[x',
        },
        jump = {
          next = ']]',
          prev = '[[',
        },
        submit = {
          normal = '<CR>',
          insert = '<C-s>',
        },
        sidebar = {
          apply_all = 'A',
          apply_cursor = 'a',
          retry_user_request = 'r',
          edit_user_request = 'e',
          switch_windows = '<Tab>',
          reverse_switch_windows = '<S-Tab>',
          remove_file = 'd',
          add_file = '@',
          close = { '<Esc>', 'q' },
        },
      },
    },
  },
}