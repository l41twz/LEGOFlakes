# NIXOS-LEGO-MODULE: git-config-gnome
# PURPOSE: Git configuration for GNOME/Niri environments
# CATEGORY: apps
# NOTE: Use this INSTEAD of git-config for GNOME-based desktops.
#        Includes credential helper via GNOME Keyring (libsecret).
# ---
programs.git = {
  enable = true;
  config = {
    user = {
      name = "l41twz";
      email = "253585242+l41twz@users.noreply.github.com";
    };
    safe = {
      directory = "*";
    };
    credential = {
      helper = "/run/current-system/sw/bin/git-credential-libsecret";
    };
  };
};
