# NIXOS-LEGO-MODULE: pipewire-audio
# PURPOSE: PipeWire audio with WirePlumber, qpwgraph and JamesDSP
# CATEGORY: hardware
# ---
services.pulseaudio.enable = false;
security.rtkit.enable = true;
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;
  wireplumber.enable = true;
};

environment.systemPackages = with pkgs; [
  qpwgraph
  jamesdsp
];
