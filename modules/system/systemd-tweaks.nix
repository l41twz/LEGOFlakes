# NIXOS-LEGO-MODULE: systemd-tweaks
# PURPOSE: Disable coredumps and limit journal size
# CATEGORY: system
# ---
systemd.coredump.enable = false;

services.journald.extraConfig = ''
  SystemMaxUse=200M
  MaxRetentionSec=1day
'';
