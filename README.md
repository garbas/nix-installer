nix installer in rust
======================

Prototype demonstration of how a natively compiled nixpkgs-installer could be created.

We compile it with the musl-backend to create a fully static binary,
that should run on any linux.

TODO:
- release.nix <- combines nix -I <nix>
- convert install script (in .tar.bz2)
  - clap
    ./install-nix --prefix=/nix/blah/blah
  - alternatively, dialog
    Where do you want to insatll nix?
    > /nix/
  -
- tests for debian / centos / etc

- Statically compile installer
    - https://github.com/emk/rust-musl-builder/blob/master/Dockerfile

- research: building installer for other mac os

- provide custom cargo index for rustPlatform in default.nix

