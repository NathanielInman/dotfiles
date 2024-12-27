return {
  {
    -- hotkeys:
    -- M-CR = generate options based on current line
    -- CR = accept
    -- gr = refresh
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function(_, opts)
      require('copilot').setup(opts)
    end,
  },
}
