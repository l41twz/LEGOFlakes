# NIXOS-LEGO-MODULE: spectacle-ocr
# PURPOSE: Spectacle screen capture from nixpkgs master with OCR support
# CATEGORY: overlays
# ---
environment.sessionVariables = {
  TESSDATA_PREFIX = "${pkgs-master.tesseract}/share";
};

nixpkgs.overlays = [
  (final: prev: {
    kdePackages = prev.kdePackages // {
      spectacle = pkgs-master.kdePackages.spectacle.overrideAttrs (old: {
        buildInputs = (old.buildInputs or []) ++ [
          pkgs-master.tesseract
          pkgs-master.leptonica
        ];
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [
          pkgs-master.pkg-config
          pkgs.makeWrapper
        ];
        postFixup = (old.postFixup or "") + ''
          wrapProgram $out/bin/spectacle \
            --prefix LD_LIBRARY_PATH : "${pkgs-master.tesseract}/lib:${pkgs-master.leptonica}/lib" \
            --set TESSDATA_PREFIX "${pkgs-master.tesseract}/share"
        '';
      });
    };
  })
];
