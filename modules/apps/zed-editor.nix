# NIXOS-LEGO-MODULE: zed-editor
# PURPOSE: Zed code editor from official GitHub flake
# CATEGORY: apps
# ---
environment.systemPackages = [
  zed-editor-pkg
];

# Cachix/Garnix caches para binários pré-compilados do Zed
nix.settings.substituters = [
  "https://zed.cachix.org"
  "https://cache.garnix.io"
];
nix.settings.trusted-public-keys = [
  "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
  "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
];
