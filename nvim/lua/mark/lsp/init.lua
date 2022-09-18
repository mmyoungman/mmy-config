local status_ok, _ = pcall(require, "lspconfig")
if not status_ok then
  vim.notify("lspconfig didn't load")
	return
end

require("mark.lsp.lsp-installer")
require("mark.lsp.handlers").setup()
