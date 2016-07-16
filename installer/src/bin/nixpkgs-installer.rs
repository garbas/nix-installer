extern crate elf;
extern crate bzip2;
extern crate tar;
extern crate tempdir;
extern crate clap;

use std::io::prelude::*;
use std::process::Command;
use std::path::PathBuf;
use std::fs::File;

use bzip2::read::{BzDecoder};
use tar::Archive;
use tempdir::TempDir;
use clap::{App,Arg};

static NIX_VERSION: &'static str = "nix-1.11.2-x86_64-linux";

#[derive(Debug)]
struct InstallOptions {
    tarball: Option<PathBuf>,
    prefix: Option<PathBuf>
}

//impl std::fmt::Display for InstallOptions {
//    fn fmt(&self, x: &mut std::fmt::Formatter) -> Result<(),std::fmt::Error> {
//        try!(write!(x, "hi there, tarball: {:?}, prefix: {:?}", self.tarball, self.prefix));
//        try!(write!(x, "hi there, tarball: {:?}, prefix: {:?}", self.tarball, self.prefix));
//
//        Ok(())
//    }
//}

fn main() {
  let matches = App::new("Nix installer")
                  .version("0.1.0")
                  .author("Rok Garbas <rok@garbas.si>")
                  .author("Maarten Hoogendoorn <maarten@moretea.nl>")
                  .arg(Arg::with_name("tarball")
                    .long("tarball")
                    .value_name("FILE")
                    .help("path to custom nix tarball")
                    .takes_value(true))
                  .arg(Arg::with_name("prefix")
                    .long("prefix")
                    .value_name("DIR")
                    .help("path to location where to install nix (default: `/nix`)")
                    .takes_value(true))
                  .arg(Arg::with_name("v")
                      .short("v")
                      .multiple(true))
                  .get_matches();

  let install_options = InstallOptions {
      tarball: matches.value_of("tarball").map(|v| PathBuf::from(v) ),
      prefix: matches.value_of("prefix").map(|v| PathBuf::from(v) )
  };

//  println!("{:?}", install_options);

// let install_options = dialog(install_option)

  install_nix(install_options);

//  let nix_prefix = matches.value_of("nix-prefix").unwrap_or("/nix");
//  let nix_store = format!("{}/store", nix_prefix)
}

fn install_nix(options: InstallOptions) {
    println!("Extracting archive");
    let temp_dir = extract_archive(&options);

    let mut installer_dir = temp_dir.path().to_path_buf();
    installer_dir.push(NIX_VERSION);

    let mut installer = Command::new("./install");
    installer.current_dir(installer_dir);
    let mut child = installer.spawn().unwrap();
    let status = child.wait().unwrap();
    std::process::exit(status.code().unwrap());
}

fn extract_archive(options: &InstallOptions) -> TempDir {
    fn do_extract_archive(decoder: BzDecoder<&[u8]>) -> TempDir {
        println!("Extracting archive");

        let temp_dir = TempDir::new("nix-installer").unwrap_or_else(|e| panic!("Could not create temporary directory"));

        let mut ar = Archive::new(decoder);
        ar.unpack(temp_dir.path());

        temp_dir
    }

    match &options.tarball {
        &Some(ref path) => {
            let mut tarball_file = File::open(path).unwrap();
            let mut content = Vec::new();
            tarball_file.read_to_end(&mut content).unwrap();

            let mut decoder = BzDecoder::new(content.as_slice());
            do_extract_archive(decoder)
        },
        &None => {
            let current_exe = std::env::current_exe().unwrap_or_else(|e| panic!("Could fetch the current executable path: {}", e));
            let elf_file = elf::File::open_path(&current_exe).unwrap_or_else(|e| panic!("Could not open the current executable: {:?}", e));

            let ref bzip2_data = elf_file.get_section(".nixdata").unwrap_or_else(|| panic!("Corrupt file; does not contain .tar.bz2 section")).data;
            let mut decoder = BzDecoder::new(bzip2_data.as_slice());
            do_extract_archive(decoder)
        }
    }
}

