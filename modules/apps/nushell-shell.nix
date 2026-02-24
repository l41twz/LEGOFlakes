# NIXOS-LEGO-MODULE: nushell-shell
# PURPOSE: Nushell as system shell with format and highlight plugins
# CATEGORY: apps
# ---
environment.shells = with pkgs; [ nushell ];
environment.systemPackages = with pkgs; [
  nushell
  nushellPlugins.formats
  nushellPlugins.highlight
];
