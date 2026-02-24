# NIXOS-LEGO-MODULE: mangowc-overlay
# PURPOSE: Override mangowc to latest release from GitHub
# CATEGORY: overlays
# ---
nixpkgs.overlays = [
  (final: prev: {
    mangowc = prev.mangowc.overrideAttrs (old: {
      version = "0.12.3";
      src = prev.fetchFromGitHub {
        owner = "DreamMaoMao";
        repo = "mangowc";
        rev = "v0.12.3";
        hash = lib.fakeHash;
      };
    });
  })
];
