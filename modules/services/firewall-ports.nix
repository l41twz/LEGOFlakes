# NIXOS-LEGO-MODULE: firewall-ports
# PURPOSE: Open TCP ports for SSH and VNC
# CATEGORY: services
# ---
networking.firewall.allowedTCPPorts = [ 22 5901 ];
