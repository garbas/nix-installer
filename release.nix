{ pkgs ? import <nixpkgs> {}
, tarball ? pkgs.fetchurl {
   url = https://nixos.org/releases/nix/nix-1.11.2/nix-1.11.2-x86_64-linux.tar.bz2;
   sha256 = "0jbx85i6b0x7nc2q31g9iywj12b1fx84ivig3792pnlnsgy8q84b";
  }
}:

let

  version = "0.1.0";  # TODO: read this from Cargo.toml
  installer = import ./default.nix { inherit pkgs version; };

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
    inherit installer;
    inherit tests;
  };

in jobs
