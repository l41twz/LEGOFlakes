# NIXOS-LEGO-MODULE: nix-extra-options
# PURPOSE: Nix daemon options with flakes and parallel builds
# CATEGORY: system
# ---
nix.extraOptions = ''
  max-jobs = auto
  cores = 0
  experimental-features = nix-command flakes
'';
