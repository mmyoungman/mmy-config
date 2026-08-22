-- Look and feel.
--
-- These three are pinned to the values the old example-derived config had, so
-- the desktop looks identical after the trim. I did NOT verify which of them
-- also happen to match Hyprland's built-in defaults -- if you want to find
-- out, comment a line, `hyprctl reload`, and check `hyprctl getoption`. If the
-- value is unchanged, the line was redundant and can go.
--
-- Everything else the upstream example spelled out -- gaps, blur, shadows,
-- opacity, the whole animation curve/spring block, master/scrolling layouts,
-- misc -- is deliberately NOT set here. That was ~250 lines restating defaults
-- we never actually chose, and every one of them was a rename waiting to break
-- on upgrade.

hl.config({
    general = {
        border_size = 2,
    },

    decoration = {
        rounding = 10,
    },

    dwindle = {
        preserve_split = true,
    },
})
