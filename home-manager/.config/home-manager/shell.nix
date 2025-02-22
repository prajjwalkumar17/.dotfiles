{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    rustc
    cargo
    rust-analyzer
    rustfmt
    clippy
    
    # Build dependencies
    pkg-config
    openssl
    gcc
  ];

  RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
  RUSTFLAGS = "--cfg procmacro2_semver_exempt";
}
