{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "rust-shell";

  buildInputs = with pkgs; [
    rustup
    pkg-config
    openssl
    clang
    gnumake
    just
  ];

  shellHook = ''
    export CARGO_HOME=$HOME/.cargo
    export RUSTUP_HOME=$HOME/.rustup

    # Rust install check
    if ! command -v rustc >/dev/null; then
      echo "[rust-shell] Installing rust toolchain..."
      rustup install stable
      rustup default stable
      rustup component add clippy rustfmt
    fi

    # Aliases inside shell only
    alias cc='cargo check'
    alias cr='cargo run'
    alias c='clear && printf "\033c"'

    echo "[rust-shell] Aliases available: 'cr' = cargo run 'cc' = cargo check, 'c' = clear screen"
  '';
}
