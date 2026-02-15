{
  description = "NixOS LEGO Configuration - {{PRESET_NAME}}";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.{{HOST_NAME}} = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, lib, config, ... }: {
          # =============================================
          # IDENTIDADE MÍNIMA DO HOST E USUÁRIO
          # =============================================
          # Este arquivo é a placa de identificação do host.
          # Não coloque overlays, pacotes ou serviços aqui.
          # Use módulos LEGO para tudo que é encaixável.

          users.users."{{USER_NAME}}" = {
            isNormalUser = true;
            description = "{{USER_DESCRIPTION}}";
            extraGroups = [ "wheel" "networkmanager" ];
          };

          time.timeZone = "{{TIMEZONE}}";

          i18n.defaultLocale = "{{DEFAULT_LOCALE}}";
          i18n.extraLocaleSettings = {
            LC_ADDRESS = "{{LC_ADDRESS}}";
            LC_IDENTIFICATION = "{{LC_IDENTIFICATION}}";
            LC_MEASUREMENT = "{{LC_MEASUREMENT}}";
            LC_MONETARY = "{{LC_MONETARY}}";
            LC_NAME = "{{LC_NAME}}";
            LC_NUMERIC = "{{LC_NUMERIC}}";
            LC_PAPER = "{{LC_PAPER}}";
            LC_TELEPHONE = "{{LC_TELEPHONE}}";
            LC_TIME = "{{LC_TIME}}";
          };

          console = { keyMap = "{{KEYMAP}}"; };

          networking.hostName = "{{HOST_NAME}}";
          networking.networkmanager.enable = true;

          system.stateVersion = "{{STATE_VERSION}}";

          # =============================================
          # SECTION: MODULES START
          # =============================================
          {{MODULE_INJECTION_POINT}}
          # =============================================
          # SECTION: MODULES END
          # =============================================
        })
      ];
    };
  };
}
