# NIXOS-LEGO-MODULE: cosmic-nix
# PURPOSE: COSMIC Desktop Environment with binary cache setup
# CATEGORY: apps
# ---

# Habilita o XServer (necessário para a maiorias dos Display Managers)
services.xserver.enable = true;

# Habilita o desktop environment COSMIC e seu greeter
services.desktopManager.cosmic.enable = true;
services.displayManager.cosmic-greeter.enable = true;

# Adiciona o cache binário no Cachix para compilar/baixar o COSMIC mais rápido
nix.settings.substituters = [
  "https://9lore.cachix.org"
];

nix.settings.trusted-public-keys = [
  "9lore.cachix.org-1:H2/a1Wlm7VJRfJNNvFbxtLQPYswP3KzXwSI5ROgzGII="
];
