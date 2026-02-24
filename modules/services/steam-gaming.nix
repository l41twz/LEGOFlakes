# NIXOS-LEGO-MODULE: steam-gaming
# PURPOSE: Steam client with Proton, protontricks and gaming packages
# CATEGORY: services
# ---
programs.steam = {
  enable = true;
  remotePlay.openFirewall = true;
  dedicatedServer.openFirewall = false;
  extest.enable = false;
  protontricks.enable = true;
};

hardware.steam-hardware.enable = true;

environment.systemPackages = with pkgs; [
  steam-run
  protontricks
  protonplus
];
