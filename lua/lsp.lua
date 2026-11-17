-- Native LSP, no plugins: install servers yourself (e.g. via brew/npm/rustup).
-- A server starts only if its binary is on PATH.
-- Neovim 0.11+: vim.lsp.config/enable + built-in autocompletion.
-- Neovim 0.8-0.10: vim.lsp.start on FileType + omni completion (<C-x><C-o>).

local servers = {
  lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { ".luarc.json", ".stylua.toml", ".git" },
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        workspace = { library = { vim.env.VIMRUNTIME }, checkThirdParty = false },
      },
    },
  },
  clangd = {
    cmd = { "clangd" },
    filetypes = { "c", "cpp", "objc", "objcpp" },
    root_markers = { "compile_commands.json", ".clangd", ".git" },
  },
  pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "setup.py", "requirements.txt", ".git" },
  },
  rust_analyzer = {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_markers = { "Cargo.toml", ".git" },
  },
}

local modern = vim.lsp.config ~= nil and vim.lsp.enable ~= nil

-- LSP needs at least Neovim 0.8 (vim.lsp.start, LspAttach)
if not modern and not vim.lsp.start then
  return
end

for name, config in pairs(servers) do
  if vim.fn.executable(config.cmd[1]) == 1 then
    if modern then
      vim.lsp.config(name, config)
      vim.lsp.enable(name)
    else
      vim.api.nvim_create_autocmd("FileType", {
        pattern = config.filetypes,
        callback = function(args)
          local path = vim.api.nvim_buf_get_name(args.buf)
          if path == "" then
            return
          end
          local marker = vim.fs.find(config.root_markers, { upward = true, path = vim.fs.dirname(path) })[1]
          vim.lsp.start({
            name = name,
            cmd = config.cmd,
            root_dir = marker and vim.fs.dirname(marker) or vim.fn.getcwd(),
            settings = config.settings,
          })
        end,
      })
    end
  end
end

vim.diagnostic.config {
  virtual_text = true,
  severity_sort = true,
  float = { border = "rounded" },
}

-- 'popup' and 'fuzzy' are only valid on newer versions
vim.o.completeopt = vim.fn.has "nvim-0.11" == 1 and "menuone,noselect,popup,fuzzy" or "menuone,noselect"

-- completion menu: Tab/S-Tab to move, Enter to accept a selected item
vim.keymap.set("i", "<Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true })
vim.keymap.set("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true })
vim.keymap.set("i", "<CR>", function()
  return (vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected ~= -1) and "<C-y>"
    or "<CR>"
end, { expr = true })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local buf = args.buf

    local function map(lhs, rhs, desc, mode)
      vim.keymap.set(mode or "n", lhs, rhs, { buffer = buf, desc = desc })
    end

    if client and vim.lsp.completion and client:supports_method "textDocument/completion" then
      vim.lsp.completion.enable(true, client.id, buf, { autotrigger = true })
    else
      -- older versions: trigger completion manually with <C-x><C-o> (or <C-Space>)
      vim.bo[buf].omnifunc = "v:lua.vim.lsp.omnifunc"
      map("<C-Space>", "<C-x><C-o>", "LSP completion", "i")
    end

    -- 0.11+ already provides these as defaults: K (hover), grn (rename),
    -- gra (code action), grr (references), gri (implementation), gO (symbols),
    -- [d / ]d (diagnostics), <C-w>d (diagnostic float), <C-s> in insert (signature)
    if vim.fn.has "nvim-0.11" == 0 then
      map("K", vim.lsp.buf.hover, "hover")
      map("grn", vim.lsp.buf.rename, "rename symbol")
      map("gra", vim.lsp.buf.code_action, "code action")
      map("grr", vim.lsp.buf.references, "references")
      map("gri", vim.lsp.buf.implementation, "implementation")
      map("gO", vim.lsp.buf.document_symbol, "document symbols")
      map("[d", vim.diagnostic.goto_prev, "previous diagnostic")
      map("]d", vim.diagnostic.goto_next, "next diagnostic")
      map("<C-w>d", vim.diagnostic.open_float, "diagnostic float")
      map("<C-s>", vim.lsp.buf.signature_help, "signature help", "i")
    end

    map("gd", vim.lsp.buf.definition, "go to definition")
    map("gD", vim.lsp.buf.declaration, "go to declaration")
    map("<leader>D", vim.lsp.buf.type_definition, "type definition")
    map("<leader>ra", vim.lsp.buf.rename, "rename symbol")
    map("<leader>fm", function() vim.lsp.buf.format { async = true } end, "format buffer")
    map("<leader>ds", vim.diagnostic.setloclist, "diagnostics to loclist")
  end,
})
