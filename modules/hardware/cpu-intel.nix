# NIXOS-LEGO-MODULE: cpu-intel
# PURPOSE: Intel CPU microcode, pstate driver and thermal throttling
# CATEGORY: hardware
# ---
hardware.cpu.intel.updateMicrocode = true;
hardware.cpu.x86.msr.enable = true;
services.throttled.enable = true;
boot.kernelParams = [
  "intel_pstate=enable"
  "intel_idle.max_cstate=2"
  "intel_iommu=on"
];
