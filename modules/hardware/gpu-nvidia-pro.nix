# NIXOS-LEGO-MODULE: gpu-nvidia-pro
# PURPOSE: NVIDIA proprietary driver with modesetting, Vulkan and PRIME offload
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
  dynamicBoost.enable = true;
  powerManagement = {
    enable = false;
    finegrained = lib.mkForce false;
  };
  open = false;
  nvidiaSettings = true;
  package = config.boot.kernelPackages.nvidiaPackages.stable;
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

environment.systemPackages = with pkgs; [
  zenith-nvidia
  nvidia-system-monitor-qt
  vulkan-tools
];

environment.sessionVariables = {
  MESA_GLTHREAD = "true";
};

services.lact.enable = true;
