-- Starts the Eclipse JDT language server for Java buffers (nvim-jdtls).
local ok, jdtls = pcall(require, 'jdtls')
if not ok then
  return
end

local root = vim.fs.root(0, { 'gradlew', 'mvnw', 'pom.xml', 'build.gradle', '.git' }) or vim.fn.getcwd()
local mason = vim.fn.stdpath 'data' .. '/mason'
-- one workspace dir per project so jdtls doesn't mix project state
local workspace = vim.fn.stdpath 'data' .. '/jdtls-workspace/' .. vim.fn.fnamemodify(root, ':p:h:t')

jdtls.start_or_attach {
  cmd = { mason .. '/bin/jdtls', '-data', workspace },
  root_dir = root,
  capabilities = require('configs.lsp').capabilities,
}
