{
  description = "Python Template";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: 
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python310;
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Python dependencies
            python
            python.pkgs.pip
            python.pkgs.virtualenv
            
            # Rust and build dependencies
            rustc
            cargo
            rust-analyzer
            rustfmt
            clippy
            
            # System dependencies
            pkg-config
            openssl
            gcc
            
            # LLVM toolchain
            clang
            lld
            llvm
          ];
          
          nativeBuildInputs = with pkgs; [
            pkg-config
            cmake
          ];

          # Environment variables
          LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
          BINDGEN_EXTRA_CLANG_ARGS = "-I${pkgs.glibc.dev}/include -I${pkgs.clang}/resource-root/include";
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.stdenv.cc.cc
            pkgs.openssl
          ];

          shellHook = ''
            # Python venv setup
            if [ ! -d ".venv" ]; then
              virtualenv .venv
            fi
            source .venv/bin/activate
            pip install --upgrade pip
            pip install -r requirements.txt

            # Rust setup
            export RUSTFLAGS="-C target-cpu=native -C link-arg=-fuse-ld=lld"
            export RUST_BACKTRACE=1
            export RUST_LOG=debug

            # Set up rust src path
            export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/library"

            # Print versions for debugging
            echo "Rust version: $(rustc --version)"
            echo "Cargo version: $(cargo --version)"
            echo "LLVM version: $(llvm-config --version)"
            echo "Rust source path: $RUST_SRC_PATH"
            # if [ ! -d "cache" ]; then
            #     echo "Running initial setup..."
            #     sh compile.sh
            #     sh install.sh
            #   fi
          '';
        };
        
        packages.default = python.pkgs.buildPythonApplication {
          pname = "template";
          version = "0.0.0";
          format = "setuptools";
          src = ./.;
          doCheck = false;
        };
      }
    );
}
