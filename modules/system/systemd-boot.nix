# NIXOS-LEGO-MODULE: systemd-boot
# PURPOSE: Habilita o Systemd-boot (UEFI) como bootloader padrao
# CATEGORY: system
# ---
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
