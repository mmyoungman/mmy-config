local M = {}

-- TODO: backfill this to template
M.setup = function()
  local signs = {
    { name = "DiagnosticSignError", text = "" },
    { name = "DiagnosticSignWarn", text = "" },
    { name = "DiagnosticSignHint", text = "" },
    { name = "DiagnosticSignInfo", text = "" },
  }

  for _, sign in ipairs(signs) do
    vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
  end

  local config = {
    -- disable virtual text
    virtual_text = false,
    -- show signs
    signs = {
      active = signs,
    },
    update_in_insert = true,
    underline = true,
    severity_sort = true,
    float = {
      focusable = false,
      style = "minimal",
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
    },
  }

  vim.diagnostic.config(config)

  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = "rounded",
  })

  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
    border = "rounded",
  })
end

-- From $VIMRUNTIME/lua/vim/lsp/handlers.lua -- with an additional 'wincmd p'
--local util = require 'vim.lsp.util'
--vim.lsp.handlers['textDocument/references'] = function(_, result, ctx, config)
--  if not result or vim.tbl_isempty(result) then
--    vim.notify('No references found')
--  else
--    local client = vim.lsp.get_client_by_id(ctx.client_id)
--    config = config or {}
--    local title = 'References'
--    local items = util.locations_to_items(result, client.offset_encoding)
--
--    if config.loclist then
--      vim.fn.setloclist(0, {}, ' ', { title = title, items = items, context = ctx })
--      vim.api.nvim_command('lopen')
--    elseif config.on_list then
--      assert(type(config.on_list) == 'function', 'on_list is not a function')
--      config.on_list({ title = title, items = items, context = ctx })
--    else
--      vim.fn.setqflist({}, ' ', { title = title, items = items, context = ctx })
--      vim.api.nvim_command('botright copen')
--      vim.api.nvim_command('wincmd p') -- NOTE: this is an addition
--    end
--  end
--end

--local function lsp_highlight_document(client)
--  -- Set autocommands conditional on server_capabilities
--  if client.resolved_capabilities.document_highlight then
--    vim.api.nvim_exec(
--      [[
--      augroup lsp_document_highlight
--        autocmd! * <buffer>
--        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
--        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
--      augroup END
--    ]],
--      false
--    )
--  end
--end

local function lsp_keymaps(bufnr)
  local opts = { noremap = true, silent = true }
  local buf_set_keymap = vim.api.nvim_buf_set_keymap
  buf_set_keymap(bufnr, "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
  buf_set_keymap(bufnr, "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
  buf_set_keymap(bufnr, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
  buf_set_keymap(bufnr, "n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
  buf_set_keymap(bufnr, "n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
  buf_set_keymap(bufnr, "n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
  buf_set_keymap(bufnr, "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
  buf_set_keymap(bufnr, "n", "ga", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
  buf_set_keymap(bufnr, "n", "<leader>h", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
  buf_set_keymap(bufnr, "n", "[d", '<cmd>lua vim.diagnostic.goto_prev({ border = "rounded" })<CR>', opts)
  buf_set_keymap(
    bufnr,
    "n",
    "gl",
    '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics({ border = "rounded" })<CR>',
    opts
  )
  buf_set_keymap(bufnr, "n", "]d", '<cmd>lua vim.diagnostic.goto_next({ border = "rounded" })<CR>', opts)
  buf_set_keymap(bufnr, "n", "<leader>q", "<cmd>lua vim.diagnostic.setloclist()<CR>", opts)
  vim.cmd [[ command! Format execute 'lua vim.lsp.buf.formatting()' ]]
end

M.on_attach = function(client, bufnr)
  if client.name == "tsserver" then
    client.resolved_capabilities.document_formatting = false
  end
  lsp_keymaps(bufnr)
  --lsp_highlight_document(client)
end

local capabilities = vim.lsp.protocol.make_client_capabilities()

local status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not status_ok then
  vim.notify("Failed to load cmp_vim_lsp")
  return
end

M.capabilities = cmp_nvim_lsp.default_capabilities(capabilities)

return M
