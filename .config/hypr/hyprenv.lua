hl.env("XCURSOR_SIZE", "26")
hl.env("HYPRCURSOR_SIZE", "26")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "hyprqt6engine")
-- GTK_THEME is intentionally NOT set: a hardcoded value overrides gsettings,
-- which is what theme-variant.sh toggles for runtime light/dark switching.
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")