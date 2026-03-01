# NIXOS-LEGO-MODULE: corsair-ckb-next
# PURPOSE: Driver open source para periféricos corsair
# CATEGORY: system
# ---
hardware.ckb-next.enable = true;

environment.systemPackages = with pkgs; [
  ckb-next
];

users.users."{{USER_NAME}}".extraGroups = [ "ckb-next" ];
