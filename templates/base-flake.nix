{
  description = "NixOS LEGO Configuration - {{PRESET_NAME}}";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    {{FLAKE_INPUTS}}
  };

  outputs = { self, nixpkgs, nixpkgs-master, {{FLAKE_OUTPUT_ARGS}}... }:
    let
      system = "x86_64-linux";
      pkgs-master = import nixpkgs-master {
        inherit system;
        config = { allowUnfree = true; };
      };
    in {
    {{DEVSHELLS_INJECTION}}
    nixosConfigurations.{{HOST_NAME}} = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit pkgs-master;
        {{FLAKE_SPECIAL_ARGS}}
      };

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

        })
        # =============================================
        # LEGO MODULES
        # =============================================
        {{MODULE_INJECTION_POINT}}
      ];
    };
  };
}
