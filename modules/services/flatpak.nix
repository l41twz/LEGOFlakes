# NIXOS-LEGO-MODULE: flatpak
# PURPOSE: Flatpak application framework support
# CATEGORY: services
# ---
services.flatpak.enable = true;

environment.systemPackages = with pkgs; [
  flatseal
];
