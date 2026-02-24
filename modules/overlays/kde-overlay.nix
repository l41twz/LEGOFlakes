# NIXOS-LEGO-MODULE: kde-overlay
# PURPOSE: KDE Plasma components from nixpkgs master
# CATEGORY: overlays
# ---
nixpkgs.overlays = [
  (final: prev: {
    kdePackages = pkgs-master.kdePackages;
    sddm = pkgs-master.sddm;
  })
];
