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
{ pkgs ? import (_pkgs.fetchFromGitHub _nixpkgs) {}
, version ? "devel"
}:

pkgs.rustPlatform.buildRustPackage {
  name = "nix-installer-${version}";
  src = builtins.filterSource
    (path: type: baseNameOf path != "default.nix"
              && baseNameOf path != "release.nix"
              && baseNameOf path != "result"
              && baseNameOf path != "target"
              )
    ./.;
  depsSha256 = "0jkzhyccv15rg8g6bnb53gjwacxh8pwp0pb0cq7j7pk21dpfa3j5";
  doCheck = false;
}
