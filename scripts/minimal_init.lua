vim.pack.add({
  "https://github.com/nvim-lua/plenary.nvim",
})

-- Add plugin source to rtp
vim.opt.rtp:prepend(vim.fn.getcwd())
