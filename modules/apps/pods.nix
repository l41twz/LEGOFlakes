# NIXOS-LEGO-MODULE: pods
# PURPOSE: Podman desktop application
# CATEGORY: apps
# ---
users.users."{{USER_NAME}}" = {
  extraGroups = [ "podman" ];
};

environment.systemPackages = with pkgs; [
  pods
];