return {
  -- mostly simple webdev language support
  {
    'nvim-treesitter/nvim-treesitter',
    config = function(_, opts)
      require('nvim-treesitter.configs').setup(opts)

      -- Neovim 0.12 changed query match values from TSNode to TSNode[].
      -- nvim-treesitter's master branch still assumes single TSNodes in
      -- its markdown injection predicates, which breaks render-markdown
      -- and the core highlighter on markdown files. Re-register the two
      -- directives with the new signature until upstream fixes it.
      local q = require('vim.treesitter.query')
      local aliases = { ex = 'elixir', pl = 'perl', sh = 'bash', uxn = 'uxntal', ts = 'typescript' }
      local function first(match, id)
        local v = match[id]
        return type(v) == 'table' and v[1] or v
      end
      q.add_directive('set-lang-from-info-string!', function(match, _, bufnr, pred, metadata)
        local node = first(match, pred[2])
        if not node then return end
        local alias = vim.treesitter.get_node_text(node, bufnr):lower()
        local ft = vim.filetype.match { filename = 'a.' .. alias }
        metadata['injection.language'] = ft or aliases[alias] or alias
      end, { force = true, all = true })
      q.add_directive('downcase!', function(match, _, bufnr, pred, metadata)
        local node = first(match, pred[2])
        if not node then return end
        local text = vim.treesitter.get_node_text(node, bufnr):lower()
        metadata[pred[2]] = metadata[pred[2]] or {}
        metadata[pred[2]].text = text
      end, { force = true, all = true })
    end,
    opts = {
      ensure_installed = {
        'bash',
        'c_sharp',
        'css',
        'csv',
        'dockerfile',
        'go',
        'gomod',
        'gosum',
        'gowork',
        'html',
        'javascript',
        'lua',
        'elixir',
        'vim',
        'markdown',
        'markdown_inline',
        'regex',
        'rust',
        'scss',
        'typescript',
        'vue',
        'yaml',
      },
    },
  },
}
