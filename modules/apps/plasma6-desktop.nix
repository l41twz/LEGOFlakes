# NIXOS-LEGO-MODULE: plasma6-desktop
# PURPOSE: KDE Plasma 6 desktop with SDDM on Wayland
# CATEGORY: apps
# ---
services.xserver.enable = true;
services.displayManager.sddm.enable = true;
services.desktopManager.plasma6.enable = true;
services.displayManager.defaultSession = "plasma";
services.displayManager.sddm.wayland.enable = true;
