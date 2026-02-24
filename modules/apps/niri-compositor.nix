# NIXOS-LEGO-MODULE: niri-compositor
# PURPOSE: Niri scrollable-tiling Wayland compositor from nixpkgs master
# CATEGORY: apps
# ---
programs.niri.enable = true;
programs.niri.package = pkgs-master.niri;

# XWayland for legacy X11 apps
programs.xwayland.enable = true;

# Portal for screen sharing / file dialogs
xdg.portal = {
  enable = true;
  extraPortals = with pkgs-master; [
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
  ];
};

environment.systemPackages = with pkgs-master; [
  niri
  swaylock
  fuzzel
  mako
  wl-clipboard
  brightnessctl
  grim
  slurp
  swappy
];

# Session env vars for Wayland
environment.sessionVariables = {
  NIXOS_OZONE_WL = "1";
  MOZ_ENABLE_WAYLAND = "1";
  QT_QPA_PLATFORM = "wayland";
  SDL_VIDEODRIVER = "wayland";
  XDG_SESSION_TYPE = "wayland";
};
