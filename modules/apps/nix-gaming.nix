# NIXOS-LEGO-MODULE: nix-gaming
# PURPOSE: Gaming packages and optimizations from fufexan/nix-gaming
# CATEGORY: apps
# ---
environment.systemPackages = [
  nix-gaming-pkgs.wine-ge
  nix-gaming-pkgs.proton-ge
  nix-gaming-pkgs.osu-lazer-bin
];

nix.settings = {
  substituters = [ "https://nix-gaming.cachix.org" ];
  trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
};
