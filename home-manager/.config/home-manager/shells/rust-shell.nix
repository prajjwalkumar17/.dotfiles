{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "rust-shell";

  buildInputs = with pkgs; [
    atuin
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
    sccache
  ];

  shellHook = ''
    export CARGO_HOME=$HOME/.cargo
    export RUSTUP_HOME=$HOME/.rustup
    export LIBCLANG_PATH=${pkgs.llvmPackages.libclang.lib}/lib
    export LD_LIBRARY_PATH=$LIBCLANG_PATH:$LD_LIBRARY_PATH
    export BINDGEN_EXTRA_CLANG_ARGS="-isystem ${pkgs.glibc.dev}/include -isystem ${pkgs.glibc.dev}/lib/gcc/*/*/include -isystem ${pkgs.glibc.dev}/lib/gcc/*/*/include-fixed -isystem ${pkgs.glibc.dev}/include-fixed"
    export RUSTC_WRAPPER=$(which sccache)
    export SCCACHE_DIR="$HOME/.cache/sccache"
    export SCCACHE_IDLE_TIMEOUT=1200
    export SCCACHE_CACHE_SIZE="5G"
    echo "[rust-shell] sccache is enabled → artifacts will be cached."

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

    # Git aliases
    alias g='git'
    alias ga='git add'
    alias gaa='git add --all'
    alias gb='git branch'
    alias gbd='git branch -d'
    alias gc='git commit'
    alias gcam='git commit -am'
    alias gco='git checkout'
    alias gcb='git checkout -b'
    alias gd='git diff'
    alias gf='git fetch'
    alias gpl='git pull'
    alias gp='git push'
    alias gpo='git push origin'
    alias gpom='git push origin main'
    alias gs='git status'
    alias gst='git stash'
    alias gstp='git stash pop'
    alias glog='git log --oneline --decorate --graph'
    alias grh='git reset --hard'
    alias grb='git rebase'
    alias grbi='git rebase -i'
    alias gm='git merge'
    alias gr='git remote'
    alias grv='git remote -v'
    alias glo='git log --oneline'

    alias nuke_pg='
      echo "[nuke_pg] Stopping PostgreSQL..."; \
      pg_ctl -D "$PGDATA" stop || true; \
      echo "[nuke_pg] Removing PGDATA and socket dir..."; \
      rm -rf "$PGDATA"; \
      echo "[nuke_pg] Done. Reopen rust-shell to reinitialize everything."
    '

    # Safe bash history setup
    if [ ! -f "$HOME/.bash_history" ]; then
      > "$HOME/.bash_history"
    fi

    export HISTFILE="$HOME/.bash_history"
    export HISTSIZE=100000
    export HISTFILESIZE=200000
    export HISTCONTROL=ignoredups:erasedups
    shopt -s histappend
    PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

    # Atuin initialization (avoid rebinding keys manually)
    if [ -z "$ATUIN_SESSION" ]; then
      export ATUIN_NOBIND=true
      eval "$(atuin init bash)"
    fi

    # Import bash history into Atuin at shell startup (NOT just at exit)
    if [ -f "$HISTFILE" ]; then
      atuin import --shell bash "$HISTFILE" --no-setup &>/dev/null
    fi

    # Atuin import again at shell exit to sync new commands
    trap '[ -f "$HISTFILE" ] && atuin import --shell bash "$HISTFILE" --no-setup &>/dev/null' EXIT

    # Save init for login shells
    if ! grep -q 'atuin init bash' "$HOME/.bashrc" 2>/dev/null; then
      echo 'eval "$(atuin init bash)"' >> "$HOME/.bashrc"
    fi

    echo "[rust-shell] PostgreSQL ready → psql hyperswitch_db"
    echo "[rust-shell] Redis ready → redis-cli -p $REDIS_PORT"
    echo "[rust-shell] Aliases: q, cr, cc, ccc, ccr, c, nuke_pg"
  '';
}
