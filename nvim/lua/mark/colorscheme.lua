local colorscheme = "darkplus"
local backupcolorscheme = "desert"

local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not status_ok then
  vim.notify("colorscheme " .. colorscheme .. " not found!")
  vim.notify("Using " .. backupcolorscheme .. " instead")
  vim.cmd("colorscheme " .. backupcolorscheme)
  return
end
