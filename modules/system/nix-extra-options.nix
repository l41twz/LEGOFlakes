# NIXOS-LEGO-MODULE: nix-extra-options
# PURPOSE: Nix daemon options with flakes and parallel builds
# CATEGORY: system
# ---
nix.extraOptions = ''
  max-jobs = 6
  cores = 6
  experimental-features = nix-command flakes
'';
