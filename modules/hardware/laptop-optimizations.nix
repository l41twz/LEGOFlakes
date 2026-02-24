# NIXOS-LEGO-MODULE: laptop-optimizations
# PURPOSE: ASUS laptop support with battery control, lid actions and power management
# CATEGORY: hardware
# ---
# ASUS hardware support
boot.kernelModules = [ "asus-wmi" ];
services.asusd = {
  enable = true;
  enableUserService = true;
};

# Battery charge threshold (default 100%)
systemd.services.battery-charge-threshold = {
  wantedBy = [
    "local-fs.target"
    "suspend.target"
    "suspend-then-hibernate.target"
    "hibernate.target"
  ];
  after = [
    "local-fs.target"
    "suspend.target"
    "suspend-then-hibernate.target"
    "hibernate.target"
  ];
  description = "Set the battery charge threshold";
  startLimitBurst = 5;
  startLimitIntervalSec = 1;
  serviceConfig = {
    Type = "oneshot";
    Restart = "on-failure";
    ExecStart = "${pkgs.runtimeShell} -c 'echo 100 > /sys/class/power_supply/BAT?/charge_control_end_threshold'";
  };
};

# Lid switch behavior
services.logind.settings.Login = {
  HandleLidSwitch = "suspend";
  HandleLidSwitchExternalPower = "lock";
  HandleLidSwitchDocked = "ignore";
};

# Power management
services.upower.enable = true;
services.power-profiles-daemon.enable = lib.mkDefault true;
