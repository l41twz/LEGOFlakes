# NIXOS-LEGO-MODULE: grub-bootloader
# PURPOSE: GRUB bootloader for MBR/BIOS with OS prober
# CATEGORY: system
# ---
boot.loader.grub.enable = true;
boot.loader.grub.device = "/dev/vda";
boot.loader.grub.useOSProber = true;
