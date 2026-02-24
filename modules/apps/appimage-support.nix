# NIXOS-LEGO-MODULE: appimage-support
# PURPOSE: Run and manage AppImage applications with GearLever
# CATEGORY: apps
# ---
programs.appimage = {
  enable = true;
  binfmt = true;
};

environment.systemPackages = with pkgs; [
  appimage-run
  gearlever
];
