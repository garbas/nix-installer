nixpkgs installer in rust
=========================


Prototype demonstration of how a natively compiled nixpkgs-installer could be created.

We compile it with the musl-backend to create a fully static binary, 
that should run on any linux.

TODO:

- verify SHA of data segment in the binary
- add support for building installer for other mac os
- integrate with generation of the .tar.bz

