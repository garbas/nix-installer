use anyhow::{Context, Result, anyhow};
use log::{info, debug};
use std::fs::File;
use std::fs::create_dir_all;
use std::io::Read;
use std::path::PathBuf;
use std::process::{Command, exit};
use tar::Archive;
use tempdir::TempDir;
use xz2::read::{XzDecoder};


pub fn extract_tarball(tarball: &Option<PathBuf>) -> Result<TempDir> {
    let temp_dir = TempDir::new("nix-installer")
        .context("Could not create temporary directory")?;

    info!("Created temporary directory: {}", temp_dir.path().display());

    let data = match tarball {

        Some(tarball_path) => {
            let mut tarball_file = File::open(tarball_path)
                .context("Could not open the tarball")?;

            info!("Opened the tarball: {}", tarball_path.display());

            let ref mut content = Vec::new();
            tarball_file.read_to_end(content)
                .context("Could not read the tarball")?;

            info!("Read the tarball: {}", tarball_path.display());

            content.clone()
        },

        None => {
            let current_exe: PathBuf = std::env::current_exe()
                .context("Could not get the current executable")?;

            let elf_file: elf::File = elf::File::open_path(&current_exe)
                .or(Err(anyhow!("Could not open the current executable")))?;

            let ref section = elf_file.get_section(".nixdata")
                .context("Corrupt file; does not contain .tar.xz section")?;

            section.data.clone()
        },
    };

    info!("Decoded the binary tarball");

    let mut archive = Archive::new(XzDecoder::new(data.as_slice()));

    for entry in archive.entries()? {
        let mut file = entry.context("Failed to iterate over archive")?;

        let file_with_root = file
            .path()?
            .as_ref()
            .to_owned();

        debug!("file_with_root > {:?}", file_with_root);

        let file_without_root: PathBuf = file_with_root
            .components()
            .enumerate()
            .filter(|&(i, _)| i != 0)
            .map(|(_, p)| p)
            .collect();

        debug!("file_without_root > {:?}", file_without_root);

        let file_dst = temp_dir.path().join(file_without_root);

        debug!("file_dst > {:?}", file_dst);

        let file_dst_parent = file_dst.parent().ok_or(anyhow!("No parent folder"))?;

        debug!("file_dst_parent > {:?}", file_dst_parent);

        create_dir_all(file_dst_parent)?;

        debug!("create_dir_all > Created directories");

        file.unpack(file_dst)?;

        debug!("unpack > File unpacked");

        debug!(">");
    }

    info!("The binary tarball was succesfully unpacked to: {}", temp_dir.path().display());

    Ok(temp_dir)
}


pub fn install_nix(temp_dir: TempDir) -> Result<()> {
    let installer_dir = temp_dir.path();

    let mut installer = Command::new("./install");
    installer.current_dir(installer_dir.to_path_buf());

    let mut child = installer.spawn()?;
    let status = child.wait()?;
    exit(status.code().ok_or(anyhow!("Install failed"))?);
}
