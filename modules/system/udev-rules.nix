# NIXOS-LEGO-MODULE: udev-rules
# PURPOSE: Custom udev rules for SSD optimization and serial device access
# CATEGORY: system
# ---
services.udev = {
  enable = true;
  extraRules = ''
    # Serial devices for ESP32/Arduino boards
    KERNEL=="ttyACM[0-9]*", MODE="0660", GROUP="dialout"
    KERNEL=="ttyUSB[0-9]*", MODE="0660", GROUP="dialout"

    # SATA SSD optimizations
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", \
      ATTR{queue/scheduler}="none", \
      ATTR{queue/read_ahead_kb}="128", \
      ATTR{queue/nr_requests}="256", \
      ATTR{queue/rq_affinity}="2", \
      ATTR{queue/max_sectors_kb}="1024"

    # NVMe SSD optimizations
    ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", \
      ATTR{queue/scheduler}="none", \
      ATTR{queue/io_poll}="1", \
      ATTR{queue/io_poll_delay}="0", \
      ATTR{queue/read_ahead_kb}="128", \
      ATTR{queue/nr_requests}="1024", \
      ATTR{queue/rq_affinity}="2"
  '';
};
