{ pkgs ? import <nixpkgs> {}
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
  depsSha256 = "032328aa0s1ddkrsnddw4pxckpa8z5szfkgqq9dn9w3ai5iykrgs";
  doCheck = false;
}
