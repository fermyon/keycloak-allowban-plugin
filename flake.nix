{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, microvm }:
    let
      out = system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        {
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              jdk
              zlib
              maven
              nixos-rebuild
            ];
          };

          packages.default = pkgs.callPackage ./package.nix { };
          packages.run = self.nixosConfigurations.test.config.microvm.declaredRunner;
        };
    in
    flake-utils.lib.eachDefaultSystem out // {
      nixosConfigurations.test = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ ... }: {
            services.keycloak.plugins = [ self.packages.x86_64-linux.default ];
          })
          ./test-nixos.nix
          microvm.nixosModules.microvm
        ];
      };

      overlays.default = final: prev: { };
    };

}
