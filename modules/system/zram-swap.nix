# NIXOS-LEGO-MODULE: zram-swap
# PURPOSE: ZRAM compressed swap with zstd algorithm
# CATEGORY: system
# ---
zramSwap = {
  enable = true;
  algorithm = "zstd";
  memoryPercent = 100;
  priority = 100;
};
