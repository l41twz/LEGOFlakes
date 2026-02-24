# NIXOS-LEGO-MODULE: kernel-xanmod
# PURPOSE: Use Xanmod kernel (unstable branch using pkgs-master)
# CATEGORY: system
# ---
boot.kernelPackages = pkgs-master.linuxPackages_xanmod_latest;
