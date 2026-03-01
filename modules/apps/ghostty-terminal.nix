# NIXOS-LEGO-MODULE: ghostty-terminal
# PURPOSE: Ghostty GPU-accelerated terminal emulator
# CATEGORY: apps
# ---
environment.systemPackages = with pkgs; [
  ghostty
];

environment.etc."xdg/ghostty/config".text = ''
  font-family = "FiraCode Nerd Font"
'';
