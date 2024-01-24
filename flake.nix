{
  description = "Oracle Database";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs @ { self, flake-parts, ... }: flake-parts.lib.mkFlake { inherit inputs; } {
    systems = import inputs.systems;

    imports = [
      inputs.flake-parts.flakeModules.easyOverlay
    ];

    perSystem = { config, self', inputs', pkgs, system, lib, ... }: {
      _module.args.pkgs = import self.inputs.nixpkgs {
        inherit system;
        overlays = [ ];
        config = {
          allowUnfree = true;
        };
      };

      formatter = pkgs.nixpkgs-fmt;

      packages.oracle-database = pkgs.callPackage ./packages/oracle-database.nix { };
    };

    flake = {
      nixosModules.oracle-database = import ./modules/oracle-database.nix;
    };
  };
}
