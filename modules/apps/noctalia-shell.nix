# NIXOS-LEGO-MODULE: noctalia-shell
# PURPOSE: Noctalia desktop shell for Wayland from nixpkgs master
# CATEGORY: apps
# ---
environment.systemPackages = with pkgs-master; [
  noctalia-shell
  quickshell
];

# Calendar events support via evolution-data-server
services.gnome.evolution-data-server.enable = true;
