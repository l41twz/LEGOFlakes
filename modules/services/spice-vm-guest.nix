# NIXOS-LEGO-MODULE: spice-vm-guest
# PURPOSE: SPICE and QEMU guest agent for virtual machines
# CATEGORY: services
# ---
services.spice-vdagentd.enable = true;
services.qemuGuest.enable = true;

systemd.services.spice-vdagent = {
  wantedBy = [ "graphical.target" ];
};

environment.systemPackages = with pkgs; [
  spice-vdagent
  polkit
  pciutils
  usbutils
];
