-- Hyprland config, tracked in mmy-config.
--
-- Deliberately thin. Hyprland compiles in a default for every setting, so we
-- only declare things we've actually made a decision about. Anything absent
-- here follows upstream defaults and can evolve without our involvement --
-- which matters, because Hyprland changes config aggressively (the .conf
-- format is being removed outright in 0.57). Every option we pin is one more
-- thing that can be renamed or deleted under us on upgrade.
--
-- The full annotated example lives at /usr/share/hypr/hyprland.lua. It is
-- package-owned and refreshed by pacman -- read it to discover options, but
-- don't copy it wholesale.
--
-- After any Hyprland upgrade: hyprctl configerrors

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Autostart, e.g.:
-- hl.on("hyprland.start", function()
--     hl.exec_cmd("waybar")
-- end)

require("look")
require("windowrules")
require("binds")

-- Personal modules last. Ordering is load-bearing: hl.config() writes are
-- last-wins, so anything required earlier can be silently clobbered by a
-- later block setting the same key.
require("input")
require("monitors")
