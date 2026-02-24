# NIXOS-LEGO-MODULE: ghostty-terminal
# PURPOSE: Ghostty GPU-accelerated terminal emulator
# CATEGORY: apps
# ---
environment.systemPackages = with pkgs; [
  ghostty
];
