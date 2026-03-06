# NIXOS-LEGO-MODULE: git-config
# PURPOSE: Git configuration
# CATEGORY: apps
# ---
programs.git = {
  enable = true;
  config = {
    user = {
    name = "l41twz";
    email = "253585242+l41twz@users.noreply.github.com";
    };
    # Optional: Safe directory global configuration
    safe = {
      directory = "*";
      };
    };
  };