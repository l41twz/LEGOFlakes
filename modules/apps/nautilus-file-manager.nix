# NIXOS-LEGO-MODULE: nautilus-file-manager
# PURPOSE: GNOME Nautilus file manager with Sushi preview and GVfs support
# CATEGORY: apps
# ---
environment.systemPackages = with pkgs; [
  nautilus
  gnome-text-editor
];

# Quick previewer for Nautilus
services.gnome.sushi.enable = true;

# GVfs is required for Nautilus to mount and access external/network drives
services.gvfs.enable = true;
