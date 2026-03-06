# NIXOS-LEGO-MODULE: dev-tools
# PURPOSE: Development packages installed as environment variables
# CATEGORY: apps
# ---
environment.systemPackages = with pkgs; [
  git
  wget
  curl
  tmux
  vscode
  pkgs-master.antigravity
  pkgs-master.mcp-nixos
  nil
  nixpkgs-fmt
  nixfmt
  python3
  nodejs
  nodePackages.npm
  go
  gcc
  micro
  lapce
  gum
];
# Ativa o direnv e as integrações de shell
programs.direnv = {
  enable = true;
  enableBashIntegration = true; # Opcional, pois geralmente é true por padrão
  enableFishIntegration = true;
};
