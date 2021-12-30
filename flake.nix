{
  description = "Nix installer framework";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nix.url = "github:NixOS/nix/2.5-maintenance";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.fenix = {
    url = "github:nix-community/fenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.naersk = {
    url = "github:nmattia/naersk";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self
            , nixpkgs
            , nix 
            , flake-utils
            , fenix
            , naersk
            }:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      cargo = builtins.fromTOML (builtins.readFile ./Cargo.toml);

      tarball = "${nix.hydraJobs.binaryTarball.${system}}/${nix.packages.${system}.nix.name}-${system}.tar.xz";

      target = "x86_64-unknown-linux-musl";
      toolchain = with fenix.packages.${system};
        combine [
          minimal.rustc
          minimal.cargo
          targets.${target}.latest.rust-std
        ];
      rustPlatform = naersk.lib.${system}.override {
        cargo = toolchain;
        rustc = toolchain;
      };

      installer = rustPlatform.buildPackage {
        src = self;
        CARGO_BUILD_TARGET = target;
        CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER =
          "${pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc}/bin/${target}-gcc";
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
