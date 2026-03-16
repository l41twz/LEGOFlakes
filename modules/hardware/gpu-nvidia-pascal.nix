# NIXOS-LEGO-MODULE: gpu-nvidia-pascal
# PURPOSE: Dual NVIDIA Pascal GPUs — GTX 1070 Ti display + GTX 1080 Ti compute-only
# CATEGORY: hardware
# ---
boot = {
  kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_UsePageAttributeTable=1"
    "nvidia.NVreg_RegistryDwords=RmEnableAggressiveVblank=1,RMIntrLockingMode=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    # Peer-mapping entre as duas GPUs para cenários multi-GPU CUDA
    "nvidia.NVreg_RegistryDwords=PeerMappingOverride=1"
  ];
  kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
    "i2c-dev"
    "i2c-piix4"
  ];
  blacklistedKernelModules = [
    "nouveau"
    "radeon"
  ];
};

services.xserver.videoDrivers = [ "nvidia" ];

# Restringir o Xorg/Wayland a usar SOMENTE a GTX 1070 Ti para display
# A 1080 Ti (0a:00.0) fica livre como compute-only para o Ollama
services.xserver.extraConfig = ''
  Section "Device"
    Identifier "nvidia-display"
    Driver     "nvidia"
    BusID      "PCI:9:0:0"
    Option     "AllowEmptyInitialConfiguration" "true"
  EndSection
'';

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
  #driSupport = true;
  #driSupport32Bit = true;   # essencial pra emuladores 32-bit
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
