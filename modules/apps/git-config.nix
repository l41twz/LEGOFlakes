# NIXOS-LEGO-MODULE: git-config
# PURPOSE: Git configuration
# CATEGORY: apps
# ---
programs.git = {
  enable = true;
  config = {
    user = {
    name = "git-username";
    email = "git-email";
    };
    # Optional: Safe directory global configuration
    safe = {
      directory = "*";
      };
    };