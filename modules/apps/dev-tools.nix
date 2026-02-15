# NIXOS-LEGO-MODULE: dev-tools
# PURPOSE: Common development packages
# CATEGORY: apps
# ---
environment.systemPackages = with pkgs; [
  git
  vim
  wget
  curl
  htop
  tmux
];
