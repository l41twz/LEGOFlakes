# NIXOS-LEGO-MODULE: mangowc-compositor
# PURPOSE: MangoWC tiling Wayland compositor (dwm-like) with XWayland
# CATEGORY: apps
# ---
programs.xwayland.enable = true;

services.displayManager.sessionPackages = [ pkgs.mangowc ];

xdg.portal = {
  enable = true;
  extraPortals = with pkgs; [
    xdg-desktop-portal-wlr
    xdg-desktop-portal-gtk
  ];
};

environment.systemPackages = with pkgs; [
  mangowc
  wl-clipboard
  brightnessctl
  grim
  slurp
  fuzzel
  mako
  swaylock
];

environment.sessionVariables = {
  NIXOS_OZONE_WL = "1";
  MOZ_ENABLE_WAYLAND = "1";
  QT_QPA_PLATFORM = "wayland";
  XDG_SESSION_TYPE = "wayland";
};
