# NIXOS-LEGO-MODULE: fish-shell
# PURPOSE: Smart and user-friendly command line shell
# CATEGORY: apps
# ---
programs.fish.enable = true;
users.defaultUserShell = pkgs.fish;
#users.users."{{USER_NAME}}".shell = pkgs.fish;