# NIXOS-LEGO-MODULE: nix-settings
# PURPOSE: Nix daemon options with flakes and parallel builds
# CATEGORY: system
# ---
nix.extraOptions = ''
  max-jobs = 6
  cores = 6
  experimental-features = nix-command flakes
'';
