# NIXOS-LEGO-MODULE: gaming-sysctl
# PURPOSE: Kernel sysctl and boot params optimized for gaming workloads
# CATEGORY: system
# ---
boot.kernelParams = [
  "tsc=reliable"
  "clocksource=tsc"
  "preempt=full"
];

boot.kernel.sysctl = {
  "vm.mmap_min_addr" = 0;
  "fs.file-max" = 209752;
  "kernel.split_lock_mitigate" = 0;
  "net.ipv4.tcp_fin_timeout" = 5;
  "vm.page-cluster" = 0;
  "vm.compaction_proactiveness" = 0;
  "vm.watermark_boost_factor" = 1;
  "vm.watermark_scale_factor" = 250;
  "vm.zone_reclaim_mode" = 0;
  "kernel.sched_child_runs_first" = 0;
  "kernel.sched_autogroup_enabled" = 1;
  "vm.oom-kill" = 1;
};
