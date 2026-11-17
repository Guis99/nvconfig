local map = vim.keymap.set

-- NvChad-style basics
map("n", ";", ":", { desc = "command mode" })
map("i", "jk", "<Esc>")
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "clear search highlight" })
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR>", { desc = "save file" })

-- window navigation
map("n", "<C-h>", "<C-w>h", { desc = "window left" })
map("n", "<C-j>", "<C-w>j", { desc = "window down" })
map("n", "<C-k>", "<C-w>k", { desc = "window up" })
map("n", "<C-l>", "<C-w>l", { desc = "window right" })

-- buffers (shown as tabs in the tabline)
map("n", "<Tab>", "<cmd>bnext<CR>", { desc = "next buffer" })
map("n", "<S-Tab>", "<cmd>bprevious<CR>", { desc = "previous buffer" })
map("n", "<leader>b", "<cmd>enew<CR>", { desc = "new buffer" })
map("n", "<leader>x", function()
  -- close the buffer but keep the window (so the file tree doesn't take over)
  local buf = vim.api.nvim_get_current_buf()
  local listed = #vim.fn.getbufinfo { buflisted = 1 }
  if vim.bo[buf].modified then
    vim.notify("buffer has unsaved changes", vim.log.levels.WARN)
    return
  end
  vim.cmd(listed > 1 and "bprevious" or "enew")
  if vim.api.nvim_buf_is_valid(buf) then
    vim.cmd("bdelete " .. buf)
  end
end, { desc = "close buffer" })

-- real tabpages (separate window layouts); gt / gT switch between them
map("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "new tabpage" })
map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "close tabpage" })

-- line numbers
map("n", "<leader>n", "<cmd>set number!<CR>", { desc = "toggle line numbers" })
map("n", "<leader>rn", "<cmd>set relativenumber!<CR>", { desc = "toggle relative numbers" })

-- comments: built-in gc / gcc on 0.10+, a small fallback before that
if vim.fn.has "nvim-0.10" == 1 then
  map("n", "<leader>/", "gcc", { remap = true, desc = "toggle comment" })
  map("v", "<leader>/", "gc", { remap = true, desc = "toggle comment" })
else
  -- toggle comments on lines l1..l2 using 'commentstring'
  local function toggle_comment(l1, l2)
    local cs = vim.bo.commentstring
    if not cs:find "%%s" then
      vim.notify("no 'commentstring' for this filetype", vim.log.levels.WARN)
      return
    end
    local left, right = cs:match "^(.-)%s*%%s%s*(.-)$"
    left, right = vim.trim(left), vim.trim(right)

    local lines = vim.api.nvim_buf_get_lines(0, l1 - 1, l2, false)
    local function is_commented(line)
      local body = vim.trim(line)
      return body:sub(1, #left) == left and (right == "" or body:sub(-#right) == right)
    end

    -- uncomment only if every non-blank line is already commented
    local uncomment, indent = true, nil
    for _, l in ipairs(lines) do
      if l:match "%S" then
        uncomment = uncomment and is_commented(l)
        local ind = l:match "^%s*"
        if not indent or #ind < #indent then
          indent = ind
        end
      end
    end
    indent = indent or ""

    for i, l in ipairs(lines) do
      if l:match "%S" then
        if uncomment then
          local ind, body = l:match "^(%s*)(.-)%s*$"
          body = body:sub(#left + 1)
          if right ~= "" then
            body = body:sub(1, -#right - 1)
          end
          body = (body:gsub("^ ", ""):gsub(" $", ""))
          lines[i] = ind .. body
        else
          lines[i] = indent .. left .. " " .. l:sub(#indent + 1) .. (right ~= "" and " " .. right or "")
        end
      end
    end
    vim.api.nvim_buf_set_lines(0, l1 - 1, l2, false, lines)
  end

  local function toggle_lines()
    local l = vim.fn.line "."
    toggle_comment(l, l + vim.v.count1 - 1)
  end
  local function toggle_visual()
    local a, b = vim.fn.line "v", vim.fn.line "."
    if a > b then
      a, b = b, a
    end
    toggle_comment(a, b)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  end

  map("n", "gcc", toggle_lines, { desc = "toggle comment" })
  map("x", "gc", toggle_visual, { desc = "toggle comment" })
  map("n", "<leader>/", toggle_lines, { desc = "toggle comment" })
  map("x", "<leader>/", toggle_visual, { desc = "toggle comment" })
end

-- file explorer sidebar (netrw)
map("n", "<C-n>", "<cmd>Lexplore<CR>", { desc = "toggle file tree" })
map("n", "<leader>e", function()
  -- open the sidebar at the current file's directory
  local dir = vim.fn.expand "%:p:h"
  vim.cmd("Lexplore " .. vim.fn.fnameescape(dir ~= "" and dir or vim.fn.getcwd()))
end, { desc = "file tree at current file" })
