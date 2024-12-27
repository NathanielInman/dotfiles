return {
  -- sometimes we forget what the hotkeys are, this leverages telescope
  -- plugin to pop-up hotkeys if only part of it was clicked, or after
  -- mid-motion, on a timeout a dialog will help remind next possible motions
  {
    'folke/which-key.nvim',
    disable = false,
  },
}
