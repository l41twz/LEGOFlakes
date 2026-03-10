# NIXOS-LEGO-MODULE: greetd
# PURPOSE: Minimalist console-based greeter using greetd and tuigreet
# CATEGORY: apps
# ---
services.greetd = {
  enable = true;
  settings = {
    default_session = {
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd bash --remember --remember-user-session --sessions /run/current-system/sw/share/wayland-sessions --xsessions /run/current-system/sw/share/xsessions";
      user = "greeter";
    };
  };
};

environment.systemPackages = with pkgs; [
  greetd.tuigreet
];
