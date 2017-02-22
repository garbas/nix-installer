let
  _pkgs = import <nixpkgs> {};
  # run the following command to generate rev and sha256
  #   nix-prefetch-git https://github.com/NixOS/nixpkgs-channels > nixpkgs.json
  _nixpkgs_json = _pkgs.lib.importJSON ./nixpkgs.json;
  _nixpkgs = {
    owner = "NixOS";
    repo = "nixpkgs-channels";
    rev = _nixpkgs_json.rev;
    sha256 = _nixpkgs_json.sha256;
  };
in
{ pkgs ? import <nixpkgs> {}
, tarball ? pkgs.fetchurl {
   url = "https://nixos.org/releases/nix/nix-1.11.6/nix-1.11.6-x86_64-linux.tar.bz2";
   sha256 = "0s8rkb8qbgjh3pc4v1m3na766ddx4s6778nw8hwicf8d5jgv0gnk";
  }
}:

let

  version = "0.1.0";  # TODO: read this from Cargo.toml
  installer = import ./default.nix { inherit pkgs; };

  installerWithTarball = pkgs.stdenv.mkDerivation {
    name = "nix-instaler-with-tarball-${version}";
    phases = "composePhase";

    composePhase = ''
       mkdir -p $out/bin
       objcopy \
         --add-section .nixdata=${tarball} \
         --set-section-flags .nixdata=noload,readonly ${installer}/bin/nix-installer $out/bin/nix-installer
     '';
  };

  # TODO: add more distributions + osx test (using a chroot?)
  tests = {
    ubuntu1204x86_64 =
      let
        img = pkgs.runCommand "nix-binary-tarball-test" {
          memSize = 1024;
          diskImage = pkgs.vmTools.diskImages.ubuntu1204x86_64;
        } script;
        script = ''
          ${installerWithTarball}/bin/nix-installer --help
          ${installerWithTarball}/bin/nix-installer 
        '';
      in
        pkgs.vmTools.runInLinuxImage img;
  };

  jobs = {
    inherit
      installer
      installerWithTarball
      tests;
  };

in jobs
