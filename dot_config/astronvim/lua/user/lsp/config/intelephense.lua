local lspconfig = require("lspconfig")

return {
  cmd = { "intelephense", "--stdio" },
  filetypes = { "php" },
  root_dir = function(fname)
    return lspconfig.util.root_pattern("composer.json", ".git")(fname) or
        lspconfig.util.path.dirname(fname)
  end,
  settings = {
    intelephense = {
      environment = { phpVersion = "8.1" },
      files = {
        exclude = {
          "**/.git", "**/.svn", "**/.hg", "**/CVS", "**/.DS_Store",
          "**/node_modules", "**/bower_components", "**/vendor"
        }
      },
      stubs = {
        "wordpress", "apache", "bcmath", "bz2", "calendar",
        "com_dotnet", "Core", "ctype", "curl", "date", "dba", "dom",
        "enchant", "exif", "FFI", "fileinfo", "filter", "fpm", "ftp",
        "gd", "gettext", "gmp", "hash", "iconv", "imap", "intl", "json",
        "ldap", "libxml", "mbstring", "meta", "mysqli", "oci8", "odbc",
        "openssl", "pcntl", "pcre", "PDO", "pdo_ibm", "pdo_mysql",
        "pdo_pgsql", "pdo_sqlite", "pgsql", "Phar", "posix", "pspell",
        "random", "readline", "Reflection", "session", "shmop",
        "SimpleXML", "snmp", "soap", "sockets", "sodium", "SPL",
        "sqlite3", "standard", "superglobals", "sysvmsg", "sysvsem",
        "sysvshm", "tidy", "tokenizer", "xml", "xmlreader", "xmlrpc",
        "xmlwriter", "xsl", "Zend OPcache", "zip", "zlib"
      }
    }
  }
}
