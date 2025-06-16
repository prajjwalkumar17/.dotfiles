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
    postgresql_16
  ];

  shellHook = ''
    export CARGO_HOME=$HOME/.cargo
    export RUSTUP_HOME=$HOME/.rustup
    export LIBCLANG_PATH=${pkgs.llvmPackages.libclang.lib}/lib
    export LD_LIBRARY_PATH=$LIBCLANG_PATH:$LD_LIBRARY_PATH
    export BINDGEN_EXTRA_CLANG_ARGS="-isystem ${pkgs.glibc.dev}/include -isystem ${pkgs.glibc.dev}/lib/gcc/*/*/include -isystem ${pkgs.glibc.dev}/lib/gcc/*/*/include-fixed -isystem ${pkgs.glibc.dev}/include-fixed"

    export PGDATA=$HOME/.local/pgdata
    export PGSOCKETDIR=$PGDATA/socket
    export PATH=${pkgs.postgresql_16}/bin:$PATH

    # 🔒 Ensure both PGDATA and socket dir exist and are secure
    if [ ! -d "$PGDATA" ]; then
      mkdir -p "$PGDATA"
    fi

    if [ ! -d "$PGSOCKETDIR" ]; then
      echo "[rust-shell] Creating PGSOCKETDIR: $PGSOCKETDIR"
      mkdir -p "$PGSOCKETDIR"
      chmod 700 "$PGSOCKETDIR"
    fi

    if [ ! -f "$PGDATA/PG_VERSION" ]; then
      echo "[rust-shell] Initializing PostgreSQL data directory at $PGDATA..."

      # If PGDATA exists but is not a valid cluster, clear it
      if [ -d "$PGDATA" ] && [ -n "$(ls -A "$PGDATA")" ]; then
        echo "[rust-shell] Warning: PGDATA exists but is not a valid cluster. Cleaning it..."
        rm -rf "$PGDATA"
        mkdir -p "$PGDATA"
      fi

      initdb -D "$PGDATA"
    fi

    echo "[rust-shell] Starting PostgreSQL server using socket dir $PGSOCKETDIR..."
    pg_ctl -D "$PGDATA" -o "-k $PGSOCKETDIR" -l "$PGDATA/postgres.log" start

    # Wait until server is ready
    until pg_isready -q -h "$PGSOCKETDIR"; do sleep 0.5; done

    echo "[rust-shell] Ensuring user and database exist..."
    psql -h "$PGSOCKETDIR" -v ON_ERROR_STOP=1 postgres <<EOF
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'db_user') THEN
      CREATE USER db_user WITH PASSWORD 'db_pass' CREATEDB CREATEROLE;
   END IF;
END
\$\$;
EOF

    if ! psql -h "$PGSOCKETDIR" -U db_user -lqt | cut -d \| -f 1 | grep -qw hyperswitch_db; then
      createdb -h "$PGSOCKETDIR" -U db_user hyperswitch_db
    fi

    # Default connection settings for ease of use
    export PGHOST=$PGSOCKETDIR
    export PGUSER=db_user

    trap 'echo "[rust-shell] Stopping PostgreSQL server..."; pg_ctl -D "$PGDATA" stop' EXIT

    if ! command -v rustc >/dev/null; then
      echo "[rust-shell] Installing rust toolchain..."
      rustup install stable
      rustup default stable
      rustup component add clippy rustfmt
    fi

    alias cc='cargo check'
    alias cr='cargo run'
    alias ccc='RUSTFLAGS="-Awarnings" cargo check'
    alias ccr='RUSTFLAGS="-Awarnings" cargo run'
    alias c='clear && printf "\033c"'

    echo "[rust-shell] PostgreSQL ready. Connect using:"
    echo "  psql hyperswitch_db"
    echo "[rust-shell] Aliases: cr, cc, ccc, ccr, c"
  '';
}
