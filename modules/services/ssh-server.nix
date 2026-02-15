# NIXOS-LEGO-MODULE: ssh-server
# PURPOSE: OpenSSH server configuration
# CATEGORY: services
# ---
services.openssh.enable = true;
services.openssh.settings.PermitRootLogin = "no";
services.openssh.settings.PasswordAuthentication = false;
