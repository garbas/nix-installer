extern crate elf;
extern crate bzip2;
extern crate tar;
extern crate tempdir;

use std::io::prelude::*;
use std::process::Command;

use bzip2::read::{BzDecoder};
use tar::Archive;
use tempdir::TempDir;

static version: &'static str = "nix-1.11.2-x86_64-linux";

fn main() {
    let current_exe = std::env::current_exe().unwrap_or_else(|e| panic!("Could fetch the current executable path: {}", e));
    let elf_file = elf::File::open_path(&current_exe).unwrap_or_else(|e| panic!("Could not open the current executable: {:?}", e));

    let ref bzip2_data = elf_file.get_section(".nixdata").unwrap_or_else(|| panic!("Corrupt file; does not contain .tar.bz2 section")).data;
    println!("Extracting archive");
    let mut decompressor = BzDecoder::new(bzip2_data.as_slice());
    let temp_dir = TempDir::new("nix-installer").unwrap_or_else(|e| panic!("Could not create temporary directory"));

    let mut ar = Archive::new(decompressor);
    ar.unpack(temp_dir.path());

    let mut installer_dir = temp_dir.path().to_path_buf();
    installer_dir.push(version);

    let mut installer = Command::new("./install");
    installer.current_dir(installer_dir);
    let mut child = installer.spawn().unwrap();
    let status = child.wait().unwrap();
    std::process::exit(status.code().unwrap());
}
