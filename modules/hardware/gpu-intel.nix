# NIXOS-LEGO-MODULE: gpu-intel
# PURPOSE: Intel integrated GPU with VA-API, Vulkan and media drivers
# CATEGORY: hardware
# ---
hardware.intel-gpu-tools.enable = true;

boot.kernelParams = [
  "i915.enable_guc=2"
  "i915.preempt_timeout=100"
  "i915.timeslice_duration=1"
];

hardware.graphics = {
  enable = true;
  enable32Bit = true;
  extraPackages = with pkgs; [
    mesa
    libdrm
    intel-media-driver
    intel-vaapi-driver
    intel-compute-runtime
    vulkan-loader
    vulkan-validation-layers
    vulkan-tools
    vulkan-extension-layer
  ];
  extraPackages32 = with pkgs.driversi686Linux; [
    mesa
    intel-media-driver
    intel-vaapi-driver
  ];
};

environment.systemPackages = with pkgs; [
  intel-gpu-tools
  libva-utils
  glxinfo
  vulkan-tools
];

environment.sessionVariables = {
  LIBVA_DRIVER_NAME = "iHD";
  VDPAU_DRIVER = "va_gl";
  MESA_GLTHREAD = "true";
};

services.lact.enable = true;
