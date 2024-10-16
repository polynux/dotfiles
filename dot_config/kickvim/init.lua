-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git', '--branch=stable', -- latest stable release
    lazypath
  }
end
vim.opt.rtp:prepend(lazypath)

-- NOTE: Here is where you install your plugins.
--  You can configure plugins using the `config` key.
--
--  You can also configure plugins after the setup call,
--    as they will be available in your neovim runtime.
require('lazy').setup({
  -- NOTE: First, some plugins that don't require any configuration

  -- Git related plugins
  'tpope/vim-fugitive', 'tpope/vim-rhubarb',

  -- Detect tabstop and shiftwidth automatically
  -- 'tpope/vim-sleuth',
  'NvChad/nvim-colorizer.lua',
  { 'stevearc/dressing.nvim', opts = {} }, "nelsyeung/twig.vim",
  "blueyed/smarty.vim", "roobert/tailwindcss-colorizer-cmp.nvim",
  "imsnif/kdl.vim", "khaveesh/vim-fish-syntax",

  -- NOTE: This is where your plugins related to LSP can be installed.
  --  The configuration is done below. Search for lspconfig to find it below.
  {
    -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs to stdpath for neovim
      { 'williamboman/mason.nvim', config = true },
      'williamboman/mason-lspconfig.nvim',

      -- Useful status updates for LSP
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      {
        'j-hui/fidget.nvim',
        tag = 'legacy',
        opts = {
          progress = {
            display = {
              progress_icon = { pattern = { "dots", period = 1 } }
            }
          }
        }
      }, -- Additional lua configuration, makes nvim stuff amazing!
      'folke/neodev.nvim'
    }
  },
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_fallback = true }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = false,
      -- format_on_save = function(bufnr)
      --   -- Disable "format_on_save lsp_fallback" for languages that don't
      --   -- have a well standardized coding style. You can add additional
      --   -- languages here or re-enable it for the disabled ones.
      --   local disable_filetypes = { c = true, cpp = true }
      --   return {
      --     timeout_ms = 500,
      --     lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
      --   }
      -- end,
      formatters_by_ft = {
        lua = { 'stylua' },
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        php = { 'phpcbf', 'php-cs-fixer', stop_after_first = true },
      },
    },
  },
  {
    -- Autocompletion
    'hrsh7th/nvim-cmp',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      'L3MON4D3/LuaSnip', 'saadparwaiz1/cmp_luasnip',

      -- Adds LSP completion capabilities
      'hrsh7th/cmp-nvim-lsp', -- Adds a number of user-friendly snippets
      'rafamadriz/friendly-snippets'
    }
  }, -- Useful plugin to show you pending keybinds.
  { 'folke/which-key.nvim',   opts = {} }, {
  -- Adds git related signs to the gutter, as well as utilities for managing changes
  'lewis6991/gitsigns.nvim',
  opts = {
    -- See `:help gitsigns.txt`
    signs = {
      add = { text = '+' },
      change = { text = '~' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' }
    },
    current_line_blame = true,
    on_attach = function(bufnr)
      vim.keymap.set('n', '<leader>gp', require('gitsigns').prev_hunk,
        {
          buffer = bufnr,
          desc = '[G]o to [P]revious Hunk'
        })
      vim.keymap.set('n', '<leader>gn', require('gitsigns').next_hunk,
        { buffer = bufnr, desc = '[G]o to [N]ext Hunk' })
      vim.keymap.set('n', '<leader>ph',
        require('gitsigns').preview_hunk,
        { buffer = bufnr, desc = '[P]review [H]unk' })
    end
  }
}, -- {
  --   -- Theme inspired by Atom
  --   'navarasu/onedark.nvim',
  --   priority = 1000,
  --   config = function()
  --     vim.cmd.colorscheme 'onedark'
  --   end,
  -- },
  {
    'catppuccin/nvim',
    priority = 1000,
    name = 'catppuccin',
    config = function() vim.cmd.colorscheme "catppuccin" end
  }, {
  -- Set lualine as statusline
  'nvim-lualine/lualine.nvim',
  -- See `:help lualine.txt`
  opts = {
    options = {
      icons_enabled = true,
      theme = 'palenight',
      -- component_separators = '|',
      component_separators = '⃒'
      -- section_separators = '',
    }
  }
}, {
  -- Add indentation guides even on blank lines
  'lukas-reineke/indent-blankline.nvim',
  -- Enable `lukas-reineke/indent-blankline.nvim`
  -- See `:help indent_blankline.txt`
  main = "ibl",
  config = function()
    require("ibl").setup {
      indent = {
        char = "▏",
      }
    }
  end
},                                        -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim', opts = {} }, -- Fuzzy Finder (files, lsp, etc)
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      -- Fuzzy Finder Algorithm which requires local dependencies to be built.
      -- Only load if `make` is available. Make sure you have the system
      -- requirements installed.
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        -- NOTE: If you are having trouble with this installation,
        --       refer to the README for telescope-fzf-native for more instructions.
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end
      }
    }
  }, {
  -- Highlight, edit, and navigate code
  'nvim-treesitter/nvim-treesitter',
  dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects' },
  build = ':TSUpdate'
}, { 'folke/neodev.nvim',  opts = {} }, {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  }
}, {
  'stevearc/oil.nvim',
  opts = {},
  -- Optional dependencies
  dependencies = { "nvim-tree/nvim-web-devicons" }
}, { "sindrets/diffview.nvim" },

  -- NOTE: Next Step on Your Neovim Journey: Add/Configure additional "plugins" for kickstart
  --       These are some example plugins that I've included in the kickstart repository.
  --       Uncomment any of the lines below to enable them.
  -- require 'kickstart.plugins.autoformat',
  { import = 'kickstart.plugins.debug' },

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    You can use this folder to prevent any conflicts with this init.lua if you're interested in keeping
  --    up-to-date with whatever is in the kickstart repo.
  --    Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  --
  --    For additional information see: https://github.com/folke/lazy.nvim#-structuring-your-plugins
  { import = 'custom.plugins' }
}, {})

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!
-- @see https://neovim.io/doc/user/options.html
---@type table<vim.opt, table<string, any>>
local options = {
  o = {
    wrap = true,
    colorcolumn = '120',
    foldmethod = 'expr',
    foldexpr = "nvim_treesitter#foldexpr()",
    foldenable = false,
    showbreak = "↪ ",
    list = true,
    listchars = "tab:»·,trail:·,extends:»,precedes:«,eol:↲,nbsp:␣",
    shiftwidth = 4,
    softtabstop = 4,
    tabstop = 4,
    expandtab = true,

    -- Set highlight on search
    hlsearch = false,

    -- Make line numbers default
    number = true,
    relativenumber = true,

    mouse = 'a',

    -- Enable break indent
    breakindent = true,

    clipboard = 'unnamedplus',

    -- Save undo history
    undofile = true,

    -- Case-insensitive searching UNLESS /C or capital in search
    ignorecase = true,
    smartcase = true,

    -- Keep signcolumn on by default
    signcolumn = 'yes',

    -- Decrease update time
    updatetime = 250,
    timeoutlen = 300,

    -- Set completeopt to have a better completion experience
    completeopt = 'menuone,noselect',

    -- NOTE: You should make sure your terminal supports this
    termguicolors = true
  }
}

for scope, option in pairs(options) do
  for key, value in pairs(option) do vim[scope][key] = value end
end

-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
-- save with <C-s>
vim.keymap.set('n', '<C-s>', ':w<CR>', { silent = true })

-- Tab indent in visual mode, and keep the selection
vim.keymap.set('v', '<', '<gv', { noremap = true })
vim.keymap.set('v', '>', '>gv', { noremap = true })
vim.keymap.set('v', '<S-Tab>', '<gv', { noremap = true })
vim.keymap.set('v', '<Tab>', '>gv', { noremap = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'",
  { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'",
  { expr = true, silent = true })

vim.keymap.set('n', '<leader>lf', function() vim.cmd('Format') end,
  { desc = 'Format current buffer with LSP' })

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight',
  { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function() vim.highlight.on_yank() end,
  group = highlight_group,
  pattern = '*'
})

-- Reload init.lua with command
vim.api.nvim_create_user_command('Reload', 'luafile $MYVIMRC', {})

-- Watch init.lua for changes and notify about them
-- vim.api.nvim_create_autocmd('ReloadVimrc', {
--   callback = function()
--     vim.notify('init.lua changed, reloading', vim.log.levels.INFO, {
--       title = 'Neovim',
--     })
--   end,
--   pattern = 'init.lua',
-- })

-- open netrw with <leader>e
vim.keymap.set('n', '<leader>e', ':Explore<CR>', { silent = true })

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup {
  defaults = { mappings = { i = { ['<C-u>'] = false, ['<C-d>'] = false } } }
}

-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')

-- See `:help telescope.builtin`
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles,
  { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers,
  { desc = '[ ] Find existing buffers' })
-- vim.keymap.set('n', '/', function()
--     -- You can pass additional configuration to telescope to change theme, layout, etc.
--     require('telescope.builtin').current_buffer_fuzzy_find(require(
--                                                                'telescope.themes').get_dropdown {
--         winblend = 10,
--         previewer = false
--     })
-- end, {desc = '[/] Fuzzily search in current buffer'})

vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files,
  { desc = 'Search [G]it [F]iles' })
-- vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files,
--   { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags,
  { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string,
  { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep,
  { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics,
  { desc = '[S]earch [D]iagnostics' })

vim.keymap.set("n", "<Leader>tf", function()
  require("telescope").extensions.frecency.frecency {}
end)

-- telescope frecency for current working directory
vim.keymap.set("n", "<Leader>sf", function()
  require("telescope").extensions.frecency.frecency {
    workspace = "CWD",
  }
end, { desc = '[S]earch [F]recency (files)' })

-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
require('nvim-treesitter.configs').setup {
  -- Add languages to be installed here that you want installed for treesitter
  ensure_installed = {
    "php", "javascript", "typescript", "html", "css", "json", "lua", "bash",
    "yaml", "toml", "regex", "python", "c", "tsx"
  },
  indent = { enable = { "php" }, disable = true },
  highlight = { enable = true, disable = {} },
  auto_install = true,
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = '<c-space>',
      node_incremental = '<c-space>',
      scope_incremental = '<c-s>',
      node_decremental = '<M-space>'
    }
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ['aa'] = '@parameter.outer',
        ['ia'] = '@parameter.inner',
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner'
      }
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        [']m'] = '@function.outer',
        [']]'] = '@class.outer'
      },
      goto_next_end = {
        [']M'] = '@function.outer',
        [']['] = '@class.outer'
      },
      goto_previous_start = {
        ['[m'] = '@function.outer',
        ['[['] = '@class.outer'
      },
      goto_previous_end = {
        ['[M'] = '@function.outer',
        ['[]'] = '@class.outer'
      }
    },
    swap = {
      enable = true,
      swap_next = { ['<leader>a'] = '@parameter.inner' },
      swap_previous = { ['<leader>A'] = '@parameter.inner' }
    }
  }
}

local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
parser_config.blade = {
  install_info = {
    url = "https://github.com/EmranMR/tree-sitter-blade",
    files = { "src/parser.c" },
    branch = "main",
  },
  filetype = "blade"
}

-- vim.filetype.add({
--   pattern = {
--     ['.*%.blade%.php'] = 'blade',
--   },
-- })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev,
  { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next,
  { desc = 'Go to next diagnostic message' })
-- vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist,
  { desc = 'Open diagnostics list' })

vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
vim.keymap.set("n", "<leader>e", require('oil').toggle_float,
  { desc = "Toggle oil float" })
vim.keymap.set("n", "<leader>bc", "<CMD>bdelete<CR>", { desc = "Close buffer" })

-- [[ Configure LSP ]]
--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
  -- NOTE: Remember that lua is a real programming language, and as such it is possible
  -- to define small helper and utility functions so you don't have to repeat yourself
  -- many times.
  --
  -- In this case, we create a function that lets us more easily define mappings specific
  -- for LSP related items. It sets the mode, buffer and description for us each time.
  local nmap = function(keys, func, desc)
    if desc then desc = 'LSP: ' .. desc end

    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
  nmap('<leader>la', vim.lsp.buf.code_action, '[C]ode [A]ction')

  nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
  nmap('gr', require('telescope.builtin').lsp_references,
    '[G]oto [R]eferences')
  nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
  nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
  nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols,
    '[D]ocument [S]ymbols')
  nmap('<leader>ws',
    require('telescope.builtin').lsp_dynamic_workspace_symbols,
    '[W]orkspace [S]ymbols')

  -- See `:help K` for why this keymap
  nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
  nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

  -- Lesser used LSP functionality
  nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
  nmap('<leader>wa', vim.lsp.buf.add_workspace_folder,
    '[W]orkspace [A]dd Folder')
  nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder,
    '[W]orkspace [R]emove Folder')
  nmap('<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, '[W]orkspace [L]ist Folders')

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, 'Format',
    function(_) vim.lsp.buf.format() end, {
      desc = 'Format current buffer with LSP'
    })
end

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--
--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config. You must look up that documentation yourself.
--
--  If you want to override the default filetypes that your language server will attach to you can
--  define the property 'filetypes' to the map in question.
local servers = {
  -- clangd = {},
  gopls = {},
  -- pyright = {},
  -- rust_analyzer = {},
  tsserver = {},
  html = { filetypes = { 'html', 'twig', 'hbs' } },

  -- intelephense = {
  --     intelephense = {
  --         environment = {phpVersion = "8.1"},
  --         files = {
  --             exclude = {
  --                 "**/.git", "**/.svn", "**/.hg", "**/CVS", "**/.DS_Store",
  --                 "**/node_modules", "**/bower_components", "**/vendor"
  --             }
  --         },
  --         stubs = {
  --             "wordpress", "apache", "bcmath", "bz2", "calendar",
  --             "com_dotnet", "Core", "ctype", "curl", "date", "dba", "dom",
  --             "enchant", "exif", "FFI", "fileinfo", "filter", "fpm", "ftp",
  --             "gd", "gettext", "gmp", "hash", "iconv", "imap", "intl", "json",
  --             "ldap", "libxml", "mbstring", "meta", "mysqli", "oci8", "odbc",
  --             "openssl", "pcntl", "pcre", "PDO", "pdo_ibm", "pdo_mysql",
  --             "pdo_pgsql", "pdo_sqlite", "pgsql", "Phar", "posix", "pspell",
  --             "random", "readline", "Reflection", "session", "shmop",
  --             "SimpleXML", "snmp", "soap", "sockets", "sodium", "SPL",
  --             "sqlite3", "standard", "superglobals", "sysvmsg", "sysvsem",
  --             "sysvshm", "tidy", "tokenizer", "xml", "xmlreader", "xmlrpc",
  --             "xmlwriter", "xsl", "Zend OPcache", "zip", "zlib"
  --         }
  --     }
  -- },
  phpactor = { settings = { phpactor = { php = { version = "7.4" } } } },

  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false }
    }
  }
}

-- Setup neovim lua configuration
require('neodev').setup()

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Ensure the servers above are installed
local mason_lspconfig = require 'mason-lspconfig'

mason_lspconfig.setup { ensure_installed = vim.tbl_keys(servers) }

mason_lspconfig.setup_handlers {
  function(server_name)
    require('lspconfig')[server_name].setup {
      capabilities = capabilities,
      on_attach = on_attach,
      settings = servers[server_name],
      filetypes = (servers[server_name] or {}).filetypes
    }
  end
}

-- [[ Configure nvim-cmp ]]
-- See `:help cmp`
local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {}

local copilot_suggestion = require('copilot.suggestion')

cmp.setup {
  snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
  mapping = cmp.mapping.preset.insert {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete {},
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if copilot_suggestion.is_visible() then
        copilot_suggestion.accept()
      else
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_locally_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' })
  },
  sources = {
    { name = 'nvim_lsp' }, { name = 'luasnip' },
    { name = 'buffer' }, { name = 'path' },
    -- Copilot Source
    -- { name = "copilot", group_index = 2 },
  }
}

cmp.setup.filetype({ "sql" }, {
  sources = {
    { name = "vim-dadbod-completion" },
    { name = "buffer" },
  },
})

-- if filetype is php, set tabstop to 4
vim.api.nvim_create_autocmd("FileType", {
  pattern = "php",
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
    vim.bo.softtabstop = 4
  end
})

vim.filetype.add({ extension = { blade = 'blade.php' } })
vim.filetype.add({ extension = { smarty = 'tpl' } })

local lspconfig = require('lspconfig')
local configs = require('lspconfig.configs')

if not configs.smarty then
  configs.smarty = {
    default_config = {
      cmd = { 'smarty-language-server', '--stdio' },
      filetypes = { 'smarty' },
      root_dir = lspconfig.util.root_pattern('composer.json', '.git')
    }
  }
end

if vim.fn.executable('smarty-language-server') ~= 1 then
  require('notify')('smarty-language-server not found', 'error')
  vim.fn.jobstart('npm install -g vscode-smarty-langserver-extracted', {
    on_exit = function(_, code)
      if code == 0 then
        require('notify')('smarty-language-server installed', 'info')
      else
        require('notify')('smarty-language-server installation failed', 'error')
      end
    end,
    on_stderr = function(_, data)
      require('notify')(data, 'error')
    end,
    on_stdout = function(_, data)
      require('notify')(data, 'info')
    end
  })
end

lspconfig.smarty.setup({
  on_attach = on_attach,
  settings = {
    smarty = {
      validate = true,
      completion = true,
      format = true,
      lint = true
    }
  },
  filetypes = { 'smarty' }
})

require('possession').setup {
  commands = {
    save = 'SSave',
    load = 'SLoad',
    delete = 'SDelete',
    list = 'SList'
  },
  autosave = { current = true }
}

vim.keymap.set('n', '<leader>Ss', function()
  vim.cmd('SSave' .. ' ' .. vim.fn.input('Session name: '))
end, { desc = 'Save session' })
vim.keymap.set('n', '<leader>Sl', function() vim.cmd('SLoad') end,
  { desc = 'Load session' })
vim.keymap.set('n', '<leader>Sd', function() vim.cmd('SDelete') end,
  { desc = 'Delete session' })
vim.keymap.set('n', '<leader>Sf',
  function() vim.cmd('Telescope possession list') end,
  { desc = 'List sessions' })

-- use copilot.lua api object to display animation using nvim-notify when fetching suggestions
local api = require('copilot.api')
api.register_status_notification_handler(function(status)
  -- require('notify')({ 'Copilot', status }, 'info', { timeout = 1000, title = 'Copilot' })
  if status == 'InProgress' then
    require('notify')('Fetching suggestions...', 'info',
      { timeout = 1000, title = 'Copilot' })
  end
end)

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
