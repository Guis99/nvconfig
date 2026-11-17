-- NvChad-style buffer tabline: every open (listed) buffer gets a tab.
-- Click a tab to switch to it; real tabpages show as "tab n/N" on the right.

vim.o.showtabline = 2

function _G.tabline_click(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_set_current_buf(bufnr)
  end
end

function _G.buf_tabline()
  local cur = vim.api.nvim_get_current_buf()
  local s = ""

  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted then
      local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ":t")
      if name == "" then
        name = "[No Name]"
      end
      name = name:gsub("%%", "%%%%") -- escape % for the tabline
      local mod = vim.bo[b].modified and " ●" or ""
      local hl = b == cur and "%#TabLineSel#" or "%#TabLine#"
      s = s .. hl .. "%" .. b .. "@v:lua.tabline_click@ " .. name .. mod .. " %X"
    end
  end

  s = s .. "%#TabLineFill#%="
  local ntabs = vim.fn.tabpagenr "$"
  if ntabs > 1 then
    s = s .. "%#TabLineSel# tab " .. vim.fn.tabpagenr() .. "/" .. ntabs .. " "
  end
  return s
end

vim.o.tabline = "%!v:lua.buf_tabline()"
