# NIXOS-LEGO-MODULE: gpu-nouveau
# PURPOSE: Nouveau open-source NVIDIA driver with NVK Vulkan
# CATEGORY: hardware
# ---
boot = {
  kernelParams = [
    "nouveau.config=NvGspRm=1"
  ];
  kernelModules = [
    "nouveau"
    "nvidia-open"
    "nvidia_wmi_ec_backlight"
  ];
  blacklistedKernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
  extraModprobeConfig = ''
    options nouveau modeset=1
  '';
};

services.xserver.videoDrivers = [ "nouveau" ];

hardware.graphics = {
  enable = true;
  enable32Bit = true;
  extraPackages = with pkgs; [
    mesa
    libdrm
    vulkan-loader
    vulkan-validation-layers
    vulkan-tools
    vulkan-extension-layer
    libva-vdpau-driver
    libva-utils
    vdpauinfo
    libvdpau-va-gl
  ];
  extraPackages32 = with pkgs.driversi686Linux; [
    mesa
    libvdpau-va-gl
  ];
};

environment.sessionVariables = {
  LIBVA_DRIVER_NAME = "nouveau";
  VDPAU_DRIVER = "nouveau";
  MESA_GLTHREAD = "true";
};

services.lact.enable = true;
