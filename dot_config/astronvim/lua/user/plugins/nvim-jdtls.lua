return {
  'mfussenegger/nvim-jdtls',
  config = function()
    require('jdtls').start_or_attach({
      cmd = { 'jdtls' },
      root_dir = require('jdtls.setup').find_root({ '.git', 'pom.xml' }),
      on_attach = require('jdtls').on_attach,
    })
  end,
}
