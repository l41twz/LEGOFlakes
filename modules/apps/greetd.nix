# NIXOS-LEGO-MODULE: greetd
# PURPOSE: Minimalist console-based greeter using greetd and tuigreet
# CATEGORY: apps
# ---
services.greetd = {
  enable = true;
  settings = {
    default_session = {
      command = ''
        ${pkgs.tuigreet}/bin/tuigreet \
          --time \
          --asterisks \
          --remember \
          --remember-user-session \
          --user-menu \
          --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions \
          --xsessions ${config.services.displayManager.sessionData.desktops}/share/xsessions
        '';
      user = "greeter";
    };
  };
};

# Necessário para o "--remember" funcionar (cache da última sessão/usuário)
systemd.tmpfiles.rules = [
  "d /var/cache/tuigreet 0755 greeter greeter -"
];

environment.systemPackages = with pkgs; [
  tuigreet
];