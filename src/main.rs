use anyhow::{Context, Result};
use clap::{crate_name, crate_version, crate_description, crate_authors};
use clap_verbosity_flag;
use simplelog::{ConfigBuilder, TermLogger, TerminalMode, LevelFilter, ColorChoice};
use structopt::StructOpt;


use std::path::PathBuf;
use nix_installer::{extract_tarball, install_nix, pause};


#[derive(Debug, StructOpt)]
#[structopt(
    name = crate_name!(),
    version = crate_version!(),
    about = crate_description!(),
    author = crate_authors!("\n"),
    )]
struct Opt {

    #[structopt(flatten)]
    verbose: clap_verbosity_flag::Verbosity,

    /// Path to binary tarball of Nix
    #[structopt(long="--tarball", parse(from_os_str))]
    tarball: Option<PathBuf>,
}


fn run() -> Result<()> {
    let options = Opt::from_args();
  
    // Setup logging
    let _ = TermLogger::init(
      options.verbose.log_level().map_or(LevelFilter::Error, |l| l.to_level_filter()),
      ConfigBuilder::new()
        .set_time_level(LevelFilter::Debug)
        .build(),
      TerminalMode::Mixed,
      ColorChoice::Auto,
    );

    // Validate options
    // TODO:
    // * tarball must exists and be a file when set

    // TODO:
    let temp_dir = extract_tarball(&options.tarball)
        .context("Could not extract the tarball")?;

    pause();

    install_nix(temp_dir)?;

    pause();

    Ok(())
}


fn main() {
    if let Err(err) = run() {
        eprintln!("Error: {:?}", err);
        std::process::exit(1);
    }
}
