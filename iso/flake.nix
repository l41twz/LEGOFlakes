{
  description = "LEGOFlakes: Custom ISO booter";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # Effectively 26.05 in early 2026
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      ...
    }:
    {
      nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./iso.nix
        ];
      };

      packages.x86_64-linux.iso = self.nixosConfigurations.iso.config.system.build.isoImage;
      packages.x86_64-linux.default = self.packages.x86_64-linux.iso;
    };
}
