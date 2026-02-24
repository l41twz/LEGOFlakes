# NIXOS-LEGO-MODULE: cpu-amd
# PURPOSE: AMD CPU microcode, pstate driver, zenpower and zenstates
# CATEGORY: hardware
# ---
hardware.cpu.amd.updateMicrocode = true;
hardware.cpu.x86.msr.enable = true;
boot = {
  kernelModules = [
    "amd-pstate"
    "zenpower"
  ];
  kernelParams = [
    "amd_pstate=active"
    "amd_iommu=on"
    "iommu=pt"
  ];
  extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
  blacklistedKernelModules = [
    "k10temp"
    "sp5100_tco"
  ];
};

environment.systemPackages = with pkgs; [
  zenstates
];
