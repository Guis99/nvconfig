local o = vim.o
local opt = vim.opt
local g = vim.g

-- UI
o.number = true
o.relativenumber = true
o.numberwidth = 2
o.ruler = false
o.cursorline = true
o.cursorlineopt = "number"
o.signcolumn = "yes"
o.laststatus = 3 -- single global statusline
o.showmode = false
if vim.fn.has "nvim-0.9" == 1 then
  o.splitkeep = "screen"
end
o.splitbelow = true
o.splitright = true
opt.fillchars = { eob = " " }
opt.shortmess:append "sI" -- no intro screen

-- habamax isn't bundled with every Neovim build; fall back to a stock scheme
if not pcall(vim.cmd, "colorscheme habamax") then
  pcall(vim.cmd, "colorscheme desert")
end

-- simple statusline: mode | file | flags ...... filetype | line:col | percent
local modes = {
  n = "NORMAL", i = "INSERT", v = "VISUAL", V = "V-LINE", ["\22"] = "V-BLOCK",
  c = "COMMAND", R = "REPLACE", t = "TERMINAL", s = "SELECT", S = "S-LINE",
}
function _G.statusline_mode()
  return modes[vim.api.nvim_get_mode().mode:sub(1, 1)] or "?"
end
o.statusline = " %{v:lua.statusline_mode()}  %f %m%r%=%y  %l:%c  %p%% "

-- Editing
o.clipboard = "unnamedplus"
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 2
o.smartindent = true
o.ignorecase = true
o.smartcase = true
o.mouse = "a"
o.undofile = true
o.timeoutlen = 400
o.updatetime = 250
opt.whichwrap:append "<>[]hl" -- h/l wrap to prev/next line

-- disable unused remote-plugin providers (faster startup)
g.loaded_node_provider = 0
g.loaded_python3_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0

-- File explorer: netrw as a left sidebar tree
g.netrw_banner = 0 -- hide the help banner (press I to show it)
g.netrw_liststyle = 3 -- tree view
g.netrw_browse_split = 4 -- open files in the previous (main) window
g.netrw_altv = 1 -- keep the sidebar on the left
g.netrw_winsize = 20 -- sidebar width, % of screen

-- netrw grabs <C-l> for "refresh" unless the refresh action already has a
-- mapping somewhere; give it <leader>R so <C-l> stays a window move
vim.keymap.set("n", "<leader>R", "<Plug>NetrwRefresh", { desc = "netrw refresh" })
