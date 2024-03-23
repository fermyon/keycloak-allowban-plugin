{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      out = system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        {
          devShells.default = (pkgs.buildFHSEnv {
            name = "s4d-env";
            targetPkgs = pkgs: (with pkgs; [
              jdk
              zlib
              freetype
              fontconfig
              maven
              protobuf
            ]);
            runScript = "zsh";
          }).env;

          packages.default = pkgs.maven.buildMavenPackage {
            pname = "keycloak-lists-plugin";
            version = "1.0";

            src = ./plugin;

            mvnHash = "sha256-UaVCt6KIjR8i3vHVp5YWqu8zzM7mftXyrv5J2jxtw6Q=";

            buildPhase = ''
              mvn --offline package;
            '';

            installPhase = ''
              mkdir -p $out/share/java
              install -Dm644 target/*.jar $out/share/java
            '';
          };
        };
    in
    flake-utils.lib.eachDefaultSystem out // {
      overlays.default = final: prev: {
      };
    };

}
