{
  description = "Nix installer framework";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nix.url = "github:NixOS/nix/2.5-maintenance";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self
            , nixpkgs
            , nix 
            , flake-utils
            }:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      cargo = builtins.fromTOML (builtins.readFile ./Cargo.toml);

      tarball = "${nix.hydraJobs.binaryTarball.${system}}/${nix.packages.${system}.nix.name}-${system}.tar.xz";

      installer = pkgs.rustPlatform.buildRustPackage {
        pname = cargo.package.name;
        version = cargo.package.version;
        src = self;
        cargoLock = {
          lockFile = ./Cargo.lock;
        };
      };

      installerWithTarball = pkgs.stdenv.mkDerivation {
        name = "${cargo.package.name}-with-tarball-${cargo.package.version}";
        phases = "composePhase";
        composePhase = ''
           mkdir -p $out/bin
           objcopy \
             --add-section .nixdata=${tarball} \
             --set-section-flags .nixdata=noload,readonly ${installer}/bin/nix-installer $out/bin/nix-installer
         '';
      };
    in rec {
      packages = flake-utils.lib.flattenTree {
        nix-installer = installer;
        nix-installer-with-tarball = installerWithTarball;
      };
      defaultPackage = packages.nix-installer;
      devShell = pkgs.mkShell {
        inputsFrom = [ packages.nix-installer ];
      };
    }
  );
}
