# NIXOS-LEGO-MODULE: cli-utils
# PURPOSE: Command-line utilities for search, monitoring and navigation
# CATEGORY: apps
# ---
environment.systemPackages = with pkgs; [
  wget
  curl
  dust
  dutree
  eza
  fd
  ripgrep
  rustscan
  bat
  delta
  difftastic
  bottom
  macchina
  systemctl-tui
  gum
  fastfetch
];
