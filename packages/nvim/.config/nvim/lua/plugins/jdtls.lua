return {
  -- Java: nvim-jdtls drives the Eclipse JDT language server. The actual client
  -- is started per-buffer in after/ftplugin/java.lua. Needs a JDK (>=17) on the
  -- system and the `jdtls` package installed via mason.
  {
    'mfussenegger/nvim-jdtls',
    ft = { 'java' },
  },
}
