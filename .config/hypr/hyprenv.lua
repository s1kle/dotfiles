hl.env("XCURSOR_SIZE", "26")
hl.env("HYPRCURSOR_SIZE", "26")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "hyprqt6engine")
-- GTK_THEME is intentionally NOT set: a hardcoded value overrides gsettings,
-- which is what theme-variant.sh toggles for runtime light/dark switching.
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("GBM_BACKEND", "nvidia-drm")

-- NVIDIA (RTX 5060 Ti) env vars for the future main desktop -- commented out
-- since this file is shared with the AMD-only laptop/VM and GBM_BACKEND=
-- nvidia-drm would break rendering entirely on non-NVIDIA hardware. Uncomment
-- (host-guarded, once that machine's hostname is known) when it's provisioned.
-- hl.env("__GL_GSYNC_ALLOWED", "1")   -- only if the monitor is G-Sync capable
-- hl.env("__GL_VRR_ALLOWED", "1")
-- also requires nvidia_drm.modeset=1 as a kernel param (bootloader/mkinitcpio,
-- not something this file can set).