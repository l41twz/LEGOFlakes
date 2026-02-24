# NIXOS-LEGO-MODULE: gpu-nvidia-pascal
# PURPOSE: NVIDIA proprietary driver for PASCAL architecture with modesetting
# CATEGORY: hardware
# ---
boot = {
  kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_UsePageAttributeTable=1"
    "nvidia.NVreg_RegistryDwords=RmEnableAggressiveVblank=1,RMIntrLockingMode=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];
  kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
  blacklistedKernelModules = [
    "nouveau"
    "radeon"
  ];
};

services.xserver.videoDrivers = [ "nvidia" ];

hardware.nvidia = {
  modesetting.enable = true;
  powerManagement.enable = true;
  open = false;
  nvidiaSettings = true;
  package = config.boot.kernelPackages.nvidiaPackages.production;
};

hardware.graphics = {
  enable = true;
  enable32Bit = true;
  extraPackages = with pkgs; [
    mesa
    libdrm
    nvidia-vaapi-driver
    vulkan-loader
    vulkan-validation-layers
    vulkan-tools
    vulkan-extension-layer
  ];
};

hardware.opengl = {
  enable = true;
  driSupport = true;
  driSupport32Bit = true;   # essencial pra emuladores 32-bit
};

environment.systemPackages = with pkgs; [
  zenith-nvidia
  nvidia-system-monitor-qt
  vulkan-tools
];

environment.sessionVariables = {
  MESA_GLTHREAD = "true";
};

services.lact.enable = true;
