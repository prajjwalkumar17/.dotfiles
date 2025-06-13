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
    llvmPackages.libclang
    mysql84
  ];

  shellHook = ''
    export CARGO_HOME=$HOME/.cargo
    export RUSTUP_HOME=$HOME/.rustup

    export LIBCLANG_PATH=${pkgs.llvmPackages.libclang.lib}/lib
    export LD_LIBRARY_PATH=$LIBCLANG_PATH:$LD_LIBRARY_PATH

    # Point bindgen to system headers explicitly
    export BINDGEN_EXTRA_CLANG_ARGS="-isystem ${pkgs.glibc.dev}/include -isystem ${pkgs.glibc.dev}/lib/gcc/*/*/include -isystem ${pkgs.glibc.dev}/lib/gcc/*/*/include-fixed -isystem ${pkgs.glibc.dev}/include-fixed"

    if ! command -v rustc >/dev/null; then
      echo "[rust-shell] Installing rust toolchain..."
      rustup install stable
      rustup default stable
      rustup component add clippy rustfmt
    fi

    alias cc='cargo check'
    alias cr='cargo run'
    alias c='clear && printf "\033c"'

    echo "[rust-shell] Aliases available: 'cr' = cargo run, 'cc' = cargo check, 'c' = clear screen"
  '';
}
