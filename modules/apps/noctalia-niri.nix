# NIXOS-LEGO-MODULE: noctalia-niri
# PURPOSE: Niri scrollable-tiling compositor + Noctalia shell integrated desktop pack
# CATEGORY: apps
# ---
programs.niri.enable = true;
programs.niri.package = niri-git;

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

environment.systemPackages = [
  # Noctalia shell (from flake input)
  noctalia-git
] ++ (with pkgs-master; [
  quickshell
]) ++ (with pkgs; [
  # Wayland utilities
  swaylock
  fuzzel
  mako
  wl-clipboard
  brightnessctl
  grim
  slurp
  swappy
  foot
]);

environment.sessionVariables = {
  NIXOS_OZONE_WL = "1";
  MOZ_ENABLE_WAYLAND = "1";
  QT_QPA_PLATFORM = "wayland";
  SDL_VIDEODRIVER = "wayland";
  XDG_SESSION_TYPE = "wayland";
  XDG_CURRENT_DESKTOP = "niri";
};

# Calendar events support via evolution-data-server (for Noctalia)
services.gnome.evolution-data-server.enable = true;

# Ensure the .desktop file is also available in wayland-sessions
environment.etc."wayland-sessions/niri.desktop".text = ''
  [Desktop Entry]
  Name=Niri
  Comment=Niri scrollable-tiling Wayland compositor
  Exec=${niri-git}/bin/niri-session
  Type=Application
  DesktopNames=niri
'';

# Default niri config — written to /etc/niri/config.kdl as a system default,
# then symlinked to each real user's ~/.config/niri/config.kdl on activation.
environment.etc."niri/config.kdl".text = ''
  // Input
  input {
      keyboard {
          xkb {
              layout "br"
          }
          numlock
      }
      touchpad {
          tap
          natural-scroll
          dwt
      }
      mouse {}
  }

  // Layout
  layout {
      gaps 12
      center-focused-column "never"

      preset-column-widths {
          proportion 0.33333
          proportion 0.5
          proportion 0.66667
      }

      default-column-width { proportion 0.5; }

      focus-ring {
          width 3
          active-color "#c9b890"
          inactive-color "#444444"
      }

      border {
          off
      }

      shadow {
          on
          softness 30
          spread 5
          offset x=0 y=5
          color "#0007"
      }

      struts {}
  }

  // Autostart — Noctalia shell and utilities
  spawn-at-startup "noctalia-shell"
  spawn-at-startup "mako"

  // Hotkey overlay (shows keybinds on first launch)
  hotkey-overlay {}

  // Prefer server-side decorations
  prefer-no-csd

  screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

  animations {}

  // Window rules
  window-rule {
      match app-id=r#"firefox$"# title="^Picture-in-Picture$"
      open-floating true
  }

  // Key Bindings
  binds {
      // Terminal and launcher
      Mod+Return { spawn "foot"; }
      Mod+Space { spawn "fuzzel"; }

      // Window management
      Mod+Q { close-window; }
      Mod+Shift+E { quit; }

      // Focus
      Mod+Left  { focus-column-left; }
      Mod+Down  { focus-window-down; }
      Mod+Up    { focus-window-up; }
      Mod+Right { focus-column-right; }
      Mod+H     { focus-column-left; }
      Mod+J     { focus-window-down; }
      Mod+K     { focus-window-up; }
      Mod+L     { focus-column-right; }

      // Move windows
      Mod+Ctrl+Left  { move-column-left; }
      Mod+Ctrl+Down  { move-window-down; }
      Mod+Ctrl+Up    { move-window-up; }
      Mod+Ctrl+Right { move-column-right; }
      Mod+Ctrl+H     { move-column-left; }
      Mod+Ctrl+J     { move-window-down; }
      Mod+Ctrl+K     { move-window-up; }
      Mod+Ctrl+L     { move-column-right; }

      // Monitor focus
      Mod+Shift+Left  { focus-monitor-left; }
      Mod+Shift+Down  { focus-monitor-down; }
      Mod+Shift+Up    { focus-monitor-up; }
      Mod+Shift+Right { focus-monitor-right; }

      // Move to monitor
      Mod+Shift+Ctrl+Left  { move-column-to-monitor-left; }
      Mod+Shift+Ctrl+Down  { move-column-to-monitor-down; }
      Mod+Shift+Ctrl+Up    { move-column-to-monitor-up; }
      Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }

      // Workspaces
      Mod+Page_Down      { focus-workspace-down; }
      Mod+Page_Up        { focus-workspace-up; }
      Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
      Mod+Ctrl+Page_Up   { move-column-to-workspace-up; }
      Mod+Shift+Page_Down { move-workspace-down; }
      Mod+Shift+Page_Up   { move-workspace-up; }

      Mod+WheelScrollDown      cooldown-ms=150 { focus-workspace-down; }
      Mod+WheelScrollUp        cooldown-ms=150 { focus-workspace-up; }
      Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
      Mod+Ctrl+WheelScrollUp   cooldown-ms=150 { move-column-to-workspace-up; }

      // Workspace by index
      Mod+1 { focus-workspace 1; }
      Mod+2 { focus-workspace 2; }
      Mod+3 { focus-workspace 3; }
      Mod+4 { focus-workspace 4; }
      Mod+5 { focus-workspace 5; }
      Mod+6 { focus-workspace 6; }
      Mod+7 { focus-workspace 7; }
      Mod+8 { focus-workspace 8; }
      Mod+9 { focus-workspace 9; }
      Mod+Ctrl+1 { move-column-to-workspace 1; }
      Mod+Ctrl+2 { move-column-to-workspace 2; }
      Mod+Ctrl+3 { move-column-to-workspace 3; }
      Mod+Ctrl+4 { move-column-to-workspace 4; }
      Mod+Ctrl+5 { move-column-to-workspace 5; }
      Mod+Ctrl+6 { move-column-to-workspace 6; }
      Mod+Ctrl+7 { move-column-to-workspace 7; }
      Mod+Ctrl+8 { move-column-to-workspace 8; }
      Mod+Ctrl+9 { move-column-to-workspace 9; }

      // Column sizing
      Mod+R { switch-preset-column-width; }
      Mod+F { maximize-column; }
      Mod+Shift+F { fullscreen-window; }
      Mod+Minus { set-column-width "-10%"; }
      Mod+Equal { set-column-width "+10%"; }
      Mod+Shift+Minus { set-window-height "-10%"; }
      Mod+Shift+Equal { set-window-height "+10%"; }

      // Floating
      Mod+V { toggle-window-floating; }

      // Screenshots
      Print { screenshot; }
      Ctrl+Print { screenshot-screen; }
      Alt+Print { screenshot-window; }

      // Lock screen
      Mod+Escape { spawn "swaylock"; }

      // Volume (if pipewire/pulseaudio)
      XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05+"; }
      XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05-"; }
      XF86AudioMute        allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
      XF86AudioMicMute     allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }

      // Brightness
      XF86MonBrightnessUp   { spawn "brightnessctl" "set" "+5%"; }
      XF86MonBrightnessDown { spawn "brightnessctl" "set" "5%-"; }
  }
'';

# Symlink system niri config to each normal user's ~/.config/niri/config.kdl
# Only creates if the user doesn't already have a custom config
system.activationScripts.niri-user-config = ''
  for DIR in /home/*/; do
    USER_NAME=$(basename "$DIR")
    # Skip if not a real user (uid >= 1000)
    USER_ID=$(id -u "$USER_NAME" 2>/dev/null) || continue
    [ "$USER_ID" -lt 1000 ] && continue

    NIRI_DIR="$DIR.config/niri"
    CONFIG="$NIRI_DIR/config.kdl"
    if [ ! -e "$CONFIG" ]; then
      mkdir -p "$NIRI_DIR"
      ln -sf /etc/niri/config.kdl "$CONFIG"
      chown -R "$USER_NAME":"$(id -gn "$USER_NAME")" "$NIRI_DIR"
    fi
  done
'';
