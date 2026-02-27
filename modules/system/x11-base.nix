# NIXOS-LEGO-MODULE: x11-base
# PURPOSE: Habilita o Servidor X.org clássico e Permissões Gráficas
# CATEGORY: system
# ---
services.xserver.enable = true;
security.polkit.enable = true;
hardware.graphics.enable = true;

users.users."{{USER_NAME}}".extraGroups = [ "video" ];
