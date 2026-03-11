return {
  -- this will lint files if linting configs are found in the project folder
  {
    'mfussenegger/nvim-lint',
    event = 'FileType',
    opts = {
      events = { 'BufWritePost', 'BufReadPost', 'InsertLeave' },
      linters_by_ft = {
        go = {
          'golangcilint',
        },
        javascript = {
          'biomejs',
        },
        typescript = {
          'biomejs',
        },
        javascriptreact = {
          'biomejs',
        },
        typescriptreact = {
          'biomejs',
        },
        vue = {
          'biomejs',
        },
        css = {
          'biomejs',
        },
        json = {
          'biomejs',
        },
      },
    },
    config = function(_, opts)
      local C = {}
      local lint = require 'lint'

      lint.linters_by_ft = opts.linters_by_ft

      -- configure biome to use global config as fallback
      local biomejs = lint.linters.biomejs
      if biomejs then
        biomejs.args = {
          'lint',
          '--config-path',
          function()
            return vim.fs.root(0, { 'biome.json', 'biome.jsonc' }) or (vim.env.HOME .. '/.config/biome')
          end,
        }
      end
      function C.debounce(ms, fn)
        local timer = vim.uv.new_timer()
        return function(...)
          local argv = { ... }
          if timer then
            timer:start(ms, 0, function()
              timer:stop()
              vim.schedule_wrap(fn)(unpack(argv))
            end)
          end
        end
      end
      function C.lint()
        local names = lint._resolve_linter_by_ft(vim.bo.filetype)

        -- Create a copy of the names table to avoid modifying the original
        names = vim.list_extend({}, names)

        -- Add fallback linters
        if #names == 0 then
          vim.list_extend(names, lint.linters_by_ft['_'] or {})
        end

        -- Add global linters
        vim.list_extend(names, lint.linters_by_ft['*'] or {})

        -- Filter out linters that don't exist or don't match the filetype
        local ctx = { filename = vim.api.nvim_buf_get_name(0) }
        ctx.dirname = vim.fn.fnamemodify(ctx.filename, ':h')
        names = vim.tbl_filter(function(name)
          local linter = lint.linters[name]
          if not linter or (type(linter) == 'table' and linter.condition and not linter.condition(ctx)) then
            return false
          end
          -- Skip linters whose binary is not found on PATH
          local cmd = type(linter) == 'table' and linter.cmd
          if type(cmd) == 'function' then cmd = cmd() end
          if cmd and type(cmd) == 'string' and vim.fn.executable(cmd) == 0 then
            return false
          end
          return true
        end, names)

        -- run any linters that were found
        if #names > 0 then
          lint.try_lint(names)
        end
      end
      vim.api.nvim_create_autocmd(opts.events, {
        group = vim.api.nvim_create_augroup('nvim-lint', { clear = true }),
        callback = C.debounce(100, C.lint),
      })
    end,
  },
}
