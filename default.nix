{ pkgs ? import <nixpkgs> {}
}:

let
in buildRustPackage rec {
    inherit src;
    name = "servo-rust-${version}";
    postUnpack = ''
      pwd
      ls -la 
      exit 100
    '';
    sourceRoot = "servo/components/servo";

    depsSha256 = "0ca0lc8mm8kczll5m03n5fwsr0540c2xbfi4nn9ksn0s4sap50yn";

    doCheck = false;
  };

