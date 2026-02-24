# NIXOS-LEGO-MODULE: ssh-server
# PURPOSE: OpenSSH server with password auth enabled
# CATEGORY: services
# ---
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = true;
    PermitRootLogin = "yes";
  };
};
