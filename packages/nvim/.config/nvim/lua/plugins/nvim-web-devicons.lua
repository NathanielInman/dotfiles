return {
  -- some basic overwrites to ensure the icons work properly with
  -- PragmataPro font
  {
    'nvim-web-devicons',
    config = function()
      require('nvim-web-devicons').setup {
        override_by_extension = {
          js = {
            icon = ' ',
            color = '#cbcb41',
            name = 'js',
          },
          jsx = {
            icon = ' ',
            color = '#cbcb41',
            name = 'jsx',
          },
          log = {
            icon = ' ',
            color = '#ffffff',
            name = 'log',
          },
          lua = {
            icon = ' ',
            color = '#51a0cf',
            name = 'lua',
          },
          py = {
            icon = ' ',
            color = '#ffbc03',
            name = 'py',
          },
          styl = {
            icon = ' ',
            color = '#8dc149',
            name = 'styl',
          },
          ts = {
            icon = ' ',
            color = '#519aba',
            name = 'ts',
          },
          tsx = {
            icon = ' ',
            color = '#519aba',
            name = 'tsx',
          },
          json = {
            icon = ' ',
            color = '#cbcb41',
            name = 'json',
          },
          yml = {
            icon = ' ',
            color = '#6d8086',
            name = 'yml',
          },
          vue = {
            icon = ' ',
            color = '#8dc149',
            name = 'vue',
          },
        },
      }
    end,
  },
}
