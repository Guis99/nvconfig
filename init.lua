-- Minimal, plugin-free config inspired by NvChad
-- Best on Neovim 0.11+; also loads on 0.8+ with fallbacks (comments, LSP)

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- set to false to disable all LSP setup
local use_lsp = true

require "options"
require "keymaps"
require "tabline"

if use_lsp then
  require "lsp"
end
