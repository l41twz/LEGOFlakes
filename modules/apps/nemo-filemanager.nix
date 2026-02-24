# NIXOS-LEGO-MODULE: nemo-filemanager
# PURPOSE: Nemo file manager from Cinnamon desktop
# CATEGORY: apps
# ---
environment.systemPackages = with pkgs; [
  nemo
  nemo-fileroller
];
