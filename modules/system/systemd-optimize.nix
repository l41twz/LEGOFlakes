# NIXOS-LEGO-MODULE: systemd-optimize
# PURPOSE: SystemD manager limits, tmpfiles, journald and boot speed tweaks
# CATEGORY: system
# ---
systemd = {
  services = {
    systemd-udev-settle.enable = false;
    NetworkManager-wait-online.wantedBy = lib.mkForce [];
  };

  settings.Manager = {
    DefaultLimitNOFILE = "2048:524288";
    DefaultLimitMEMLOCK = "infinity";
    DefaultLimitNPROC = "8192";
    DefaultTimeoutStartSec = "30s";
    DefaultTimeoutStopSec = "10s";
  };

  tmpfiles.rules = [
    "d /var/lib/systemd/coredump 0755 root root 3d"
    "w! /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise"
    "D! /nix/var/nix/profiles/per-user/root 1755 root root 1d"
  ];
};

services.journald = {
  storage = "persistent";
  rateLimitBurst = 1000;
  rateLimitInterval = "30s";
  extraConfig = ''
    SystemMaxUse=50M
  '';
};
