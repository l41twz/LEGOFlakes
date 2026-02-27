# NIXOS-LEGO-MODULE: wayland-base
# PURPOSE: Habilita permisões Globais e Aceleração 3D para Compositores Wayland puros atrelados ao TTY
# CATEGORY: system
# ---
security.polkit.enable = true;
hardware.graphics.enable = true;

users.users."{{USER_NAME}}".extraGroups = [ "video" "input" ];
