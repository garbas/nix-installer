let
  _pkgs = import <nixpkgs> {};
  _pkgs_json = _pkgs.lib.importJSON ./nixpkgs.json;
in
{ pkgs ? import (_pkgs.fetchFromGitHub { owner = "NixOS";
                                         repo = "nixpkgs-channels";
                                         rev = _pkgs_json.rev;
                                         sha256 = _pkgs_json.sha256;
                                       }) {}
}:

let
  crates_json = _pkgs.lib.importJSON ./crates.json;
  crates_version = "2017-02-22";
  crates_src = _pkgs.fetchFromGitHub { owner = "rust-lang";
                                       repo = "crates.io-index";
                                       rev = crates_json.rev;
                                       sha256 = crates_json.sha256;
                                     };
  rustRegistry = pkgs.runCommand "rustRegistry-${crates_version}-${builtins.substring 0 7 crates_json.rev}" { inherit crates_src; } ''
    # For some reason, cargo doesn't like fetchgit's git repositories, not even
    # if we set leaveDotGit to true, set the fetchgit branch to 'master' and clone
    # the repository (tested with registry rev
    # 965b634156cc5c6f10c7a458392bfd6f27436e7e), failing with the message:
    #
    # "Target OID for the reference doesn't exist on the repository"
    #
    # So we'll just have to create a new git repository from scratch with the
    # contents downloaded with fetchgit...

    mkdir -p $out

    cp -r ${crates_src}/* $out/

    cd $out

    git="${pkgs.git}/bin/git"

    $git init
    $git config --local user.email "example@example.com"
    $git config --local user.name "example"
    $git add .
    $git commit -m 'Rust registry commit'

    touch $out/touch . "$out/.cargo-index-lock"
  '';

  rustPlatform =
    pkgs.recurseIntoAttrs (pkgs.lib.fix (self:
      let
        callPackage = pkgs.newScope self;
        rust = pkgs.rustStable;
      in {
          inherit rust rustRegistry;
          buildRustPackage = callPackage "${pkgs.path}/pkgs/build-support/rust" {
            inherit rust;
          };
        }
    ));

in rustPlatform.buildRustPackage {
  name = "nix-installer";
  src = builtins.filterSource
    (path: type: baseNameOf path != "default.nix"
              && baseNameOf path != "release.nix"
              && baseNameOf path != "result"
              && baseNameOf path != "target"
              )
    ./.;
  depsSha256 = "194d4qdcxg7vzf6abdnif2i0hz08sw6q3z7dxnxqgqcsi1p32z2l";
  doCheck = false;
}
