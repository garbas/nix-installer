{ pkgs ? import <nixpkgs> {} }:
let
  rustPlatform = pkgs.recurseIntoAttrs (pkgs.makeRustPlatform pkgs.rustStable rustPlatform);
  version = "master";

  installer = rustPlatform.buildRustPackage {
    name = "nix-installer-${version}";
    src = ./installer;
    depsSha256 = "1mph1rdnjq8dhrf3slvkb3mvv161gmyqaz0nlrn81idi9n5r2czl";
    doCheck = false;
  };

  tarball = pkgs.fetchurl {
   url = https://nixos.org/releases/nix/nix-1.11.2/nix-1.11.2-x86_64-linux.tar.bz2;
   sha256 = "0jbx85i6b0x7nc2q31g9iywj12b1fx84ivig3792pnlnsgy8q84b";
  };

  installerWithTarball = pkgs.stdenv.mkDerivation {
    name = "nix-instaler-with-tarball-${version}";
    phases = "composePhase";

    composePhase = ''
       mkdir -p $out/bin
       objcopy --add-section .nixdata=${tarball} \
         --set-section-flags .nixdata=noload,readonly ${installer}/bin/nixpkgs-installer $out/bin/nixpkgs-installer
     '';
  };

  # TODO: add more distributions + osx test (using a chroot?)
  tests.ubuntu1204x86_64 =
    with pkgs;
    let
      img = runCommand "nix-binary-tarball-test" {
        diskImage = vmTools.diskImages.ubuntu1204x86_64;
        QEMU_OPTS = "-device virtio-rng-pci";
      } script;
      script = ''
        ${coreutils}/bin/mknod /dev/hwrng c 10 183
        ${rng_tools}/bin/rngd
        ${installerWithTarball}/bin/nixpkgs-installer --help
      '';
      runCustomInImage = vmTools.override {
        rootModules = [ "virtio_rng" "virtio_pci" "virtio_blk" "virtio_balloon" "ext4" "unix" "9p" "9pnet_virtio" "rtc_cmos" ];
      };
    in
      runCustomInImage.runInLinuxImage img;
  jobs = {
    inherit installer;
    inherit tests;
  };
in jobs
