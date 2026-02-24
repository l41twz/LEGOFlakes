# NIXOS-LEGO-MODULE: krfb-remote
# PURPOSE: KDE KRfb remote desktop package
# CATEGORY: apps
# ---
environment.systemPackages = with pkgs; [
  kdePackages.krfb
];
