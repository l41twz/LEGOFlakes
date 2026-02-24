# NIXOS-LEGO-MODULE: gpu-amd
# PURPOSE: AMD GPU with AMDGPU driver, Vulkan, OpenGL and ROCm compute
# CATEGORY: hardware
# ---
hardware.amdgpu.initrd.enable = true;

boot.kernelParams = [
  "gpu_sched.sched_policy=0"
  "radeon.cik_support=0"
  "amdgpu.cik_support=1"
  "radeon.si_support=0"
  "amdgpu.si_support=1"
  "amdgpu.sg_display=0"
];

hardware.graphics = {
  enable = true;
  enable32Bit = true;
  extraPackages = with pkgs; [
    mesa
    libdrm    vulkan-loader
    vulkan-validation-layers
    vulkan-tools
    vulkan-extension-layer
  ];
  extraPackages32 = with pkgs.driversi686Linux; [
    mesa
  ];
};

environment.systemPackages = with pkgs; [
  radeontop
  amdgpu_top
  vulkan-tools
];

environment.sessionVariables = {
  MESA_GLTHREAD = "true";
};

services.lact.enable = true;
