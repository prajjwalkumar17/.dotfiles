{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "rust-shell";

  buildInputs = with pkgs; [
    clang
    diesel-cli
    gnumake
    just
    llvmPackages.libclang
    mysql84
    openssl
    pkg-config
    postgresql_16
    redis
    rustup
  ];

  shellHook = ''
    export CARGO_HOME=$HOME/.cargo
  2025-06-17T10:10:19.393387Z  INFO  OpenRouter started [Server { host: "127.0.0.1", port: 8080 }] [Log { console: LogConsole { enabled: true, level: Level(Level(Debug)), log_format: Default, filtering_directive: None } }], category: "SERVER"
    at src/app.rs:208
    export RUSTUP_HOME=$HOME/.rustup
    export LIBCLANG_PATH=${pkgs.llvmPackages.libclang.lib}/lib
    export LD_LIBRARY_PATH=$LIBCLANG_PATH:$LD_LIBRARY_PATH
    export BINDGEN_EXTRA_CLANG_ARGS="-isystem ${pkgs.glibc.dev}/include -isystem ${pkgs.glibc.dev}/lib/gcc/*/*/include -isystem ${pkgs.glibc.dev}/lib/gcc/*/*/include-fixed -isystem ${pkgs.glibc.dev}/include-fixed"

    export PGDATA=$HOME/.local/pgdata
    export PGSOCKETDIR=$PGDATA/socket
    export PATH=${pkgs.postgresql_16}/bin:$PATH

    # Ensure PGDATA and socket dir exist early
    mkdir -p "$PGDATA"
    mkdir -p "$PGSOCKETDIR"
    chmod 700 "$PGSOCKETDIR"

    # Initialize DB if needed
    if [ ! -f "$PGDATA/PG_VERSION" ]; then
      echo "[rust-shell] Initializing PostgreSQL data directory at $PGDATA..."
      if [ -n "$(ls -A "$PGDATA")" ]; then
        echo "[rust-shell] Warning: PGDATA exists but is not a valid cluster. Cleaning..."
        rm -rf "$PGDATA"
        mkdir -p "$PGDATA"
      fi
      initdb -D "$PGDATA"
    fi

    # Re-ensure socket dir in case it's missing
    if [ ! -d "$PGSOCKETDIR" ]; then
      echo "[rust-shell] Re-creating missing socket dir at $PGSOCKETDIR"
      mkdir -p "$PGSOCKETDIR"
      chmod 700 "$PGSOCKETDIR"
    fi

    echo "[rust-shell] Starting PostgreSQL server using socket dir $PGSOCKETDIR..."
    pg_ctl -D "$PGDATA" -o "-k $PGSOCKETDIR" -l "$PGDATA/postgres.log" start

    for i in {1..10}; do
      if pg_isready -q -h "$PGSOCKETDIR"; then
        echo "[rust-shell] PostgreSQL started successfully."
        break
      fi
      sleep 0.5
    done

    if ! pg_isready -q -h "$PGSOCKETDIR"; then
      echo "[rust-shell ❌] PostgreSQL failed to start. Check logs with:"
      echo "  cat $PGDATA/postgres.log"
      return 1
    fi

    echo "[rust-shell] Ensuring required Postgres roles exist..."
    psql -h "$PGSOCKETDIR" -v ON_ERROR_STOP=1 postgres <<EOF
    DO \$\$
    BEGIN
       IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'db_user') THEN
          CREATE ROLE db_user WITH LOGIN PASSWORD 'db_pass' SUPERUSER CREATEDB CREATEROLE INHERIT;
       END IF;
       IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'postgres') THEN
          CREATE ROLE postgres WITH LOGIN SUPERUSER CREATEDB CREATEROLE INHERIT;
       END IF;
    END
    \$\$;
    EOF

    if ! psql -h "$PGSOCKETDIR" -U db_user -lqt | cut -d \| -f 1 | grep -qw hyperswitch_db; then
      echo "[rust-shell] Creating hyperswitch_db owned by db_user..."
      createdb -h "$PGSOCKETDIR" -U db_user -O db_user hyperswitch_db
    fi

    export PGHOST=$PGSOCKETDIR
    export PGUSER=db_user

    # Redis Setup
    export REDIS_DATA_DIR=$HOME/.local/redis
    export REDIS_LOG_FILE=$REDIS_DATA_DIR/redis.log
    export REDIS_PID_FILE=$REDIS_DATA_DIR/redis.pid
    export REDIS_PORT=6379

    mkdir -p "$REDIS_DATA_DIR"

    echo "[rust-shell] Starting Redis server on port $REDIS_PORT..."
    redis-server --daemonize yes \
                 --dir "$REDIS_DATA_DIR" \
                 --logfile "$REDIS_LOG_FILE" \
                 --pidfile "$REDIS_PID_FILE" \
                 --port "$REDIS_PORT"

    sleep 1

    trap 'echo "[rust-shell] Stopping services..."; \
          pg_ctl -D "$PGDATA" stop; \
          if [ -f "$REDIS_PID_FILE" ]; then kill -TERM "$(cat "$REDIS_PID_FILE")"; fi' EXIT

    # Rust toolchain
    if ! command -v rustc >/dev/null; then
      echo "[rust-shell] Installing rust toolchain..."
      rustup install stable
      rustup default stable
      rustup component add clippy rustfmt
    fi

    # Aliases
    alias cc='cargo check'
    alias cr='cargo run'
    alias ccc='RUSTFLAGS="-Awarnings" cargo check'
    alias ccr='RUSTFLAGS="-Awarnings" cargo run'
    alias c='clear && printf "\033c"'
    alias q='exit'

    alias nuke_pg='
      echo "[nuke_pg] Stopping PostgreSQL..."; \
      pg_ctl -D "$PGDATA" stop || true; \
      echo "[nuke_pg] Removing PGDATA and socket dir..."; \
      rm -rf "$PGDATA"; \
      echo "[nuke_pg] Done. Reopen rust-shell to reinitialize everything."
    '

    echo "[rust-shell] PostgreSQL ready → psql hyperswitch_db"
    echo "[rust-shell] Redis ready → redis-cli -p $REDIS_PORT"
    echo "[rust-shell] Aliases: q, cr, cc, ccc, ccr, c, nuke_pg"
  '';
}
