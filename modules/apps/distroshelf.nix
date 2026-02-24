# NIXOS-LEGO-MODULE: distroshelf
# PURPOSE: Shelf for managing Distrobox containers
# CATEGORY: apps
# ---
environment.systemPackages = with pkgs; [
  distrobox
  distroshelf
];
