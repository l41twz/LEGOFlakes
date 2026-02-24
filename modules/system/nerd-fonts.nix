# NIXOS-LEGO-MODULE: nerd-fonts
# PURPOSE: Nerd Fonts collection with JetBrains Mono, Iosevka, Victor Mono and Fira Code
# CATEGORY: system
# ---
fonts.packages = with pkgs; [
  nerd-fonts.jetbrains-mono
  nerd-fonts.iosevka
  nerd-fonts.victor-mono
  nerd-fonts.fira-code
];
