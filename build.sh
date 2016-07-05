set -e

if [ ! -f nix-1.11.2-x86_64-linux.tar.bz2 ]; then
wget https://nixos.org/releases/nix/nix-1.11.2/nix-1.11.2-x86_64-linux.tar.bz2
fi

cargo build
objcopy --add-section .nixdata=nix-1.11.2-x86_64-linux.tar.bz2 \
        --set-section-flags .nixdata=noload,readonly target/debug/nixpkgs-installer test-installer
