# NIXOS-LEGO-MODULE: kernel-hardening
# PURPOSE: Kernel sysctl tuning, module blacklist and boot params for performance
# CATEGORY: system
# ---
boot = {
  supportedFilesystems = [ "ntfs" ];
  kernelParams = [
    "pcie_aspm=off"
    "mitigations=auto"
  ];
  kernelModules = [
    "ntsync"
    "tcp_bbr"
    "sch_cake"
  ];
  blacklistedKernelModules = [
    # Unused audio/storage
    "snd_seq_dummy"
    "dm_mod"
    "lpc_ich"
    # Not used
    "ath3k"
    "fprint"
    "ide_core"
    # Obscure network protocols
    "af_802154"
    "decnet"
    "econet"
    "ipx"
    "p8022"
    "p8023"
    "psnap"
    "sctp"
    # Old/rare filesystems
    "f2fs"
    "bcachefs"
    "hfs"
    "hfsplus"
    "jfs"
    "squashfs"
    "udf"
    "ufs"
    # Unused network filesystems
    "cifs"
    "gfs2"
    "ksmbd"
    "nfs"
    "nfsv3"
    "nfsv4"
    # Thunderbolt
    "thunderbolt"
    # Testing/debug
    "vivid"
    "nvidiafb"
    "hwpoison_inject"
    "punit_atom_debug"
    "acpi_configfs"
    "slram"
    "phram"
    "floppy"
    "cpuid"
    "evbug"
  ];
};

boot.kernel.sysctl = {
  # Memory management
  "vm.swappiness" = lib.mkDefault 10;
  "vm.vfs_cache_pressure" = lib.mkDefault 50;
  "vm.overcommit_memory" = lib.mkDefault 1;
  "vm.dirty_ratio" = lib.mkDefault 10;
  "vm.dirty_background_ratio" = lib.mkDefault 5;

  # Network — BBR + CAKE
  "net.core.default_qdisc" = "cake";
  "net.core.rmem_max" = 134217728;
  "net.core.wmem_max" = 134217728;
  "net.ipv4.tcp_rmem" = "4096 87380 67108864";
  "net.ipv4.tcp_wmem" = "4096 65536 67108864";
  "net.ipv4.tcp_mtu_probing" = 1;
  "net.ipv6.conf.all.accept_ra" = 2;
  "net.ipv6.conf.default.accept_ra" = 2;
  "net.core.rmem_default" = 262144;
  "net.core.wmem_default" = 262144;
  "net.core.optmem_max" = 20480;
  "net.core.netdev_max_backlog" = 1000;
  "net.ipv4.tcp_congestion_control" = "bbr";
  "net.ipv4.tcp_fastopen" = 3;
};
