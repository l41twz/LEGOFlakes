# NIXOS-LEGO-MODULE: docker-engine
# PURPOSE: Docker container runtime with socket access
# CATEGORY: services
# ---
virtualisation.docker.enable = true;

environment.variables = {
  DOCKER_HOST = "unix:///var/run/docker.sock";
};

environment.systemPackages = with pkgs; [
  lazydocker
];
