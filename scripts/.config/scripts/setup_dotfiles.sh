#!/usr/bin/env bash

set -euo pipefail

echo "📦 Starting Prajjwal's Dotfiles Setup..."

# Base directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# ----------------------------------------
# 1. Install Home Manager if not present
# ----------------------------------------
if ! command -v home-manager &> /dev/null; then
  echo "🔧 Installing Home Manager..."

  nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz home-manager
  nix-channel --update
  nix-shell '<home-manager>' -A install
  home-manager switch

  echo "✅ Home Manager installed."
else
  echo "✅ Home Manager already installed."
fi

# ----------------------------------------
# 2. Ensure stow is available
# ----------------------------------------
if ! command -v stow &> /dev/null; then
  echo "🔧 stow not found, installing via nix-shell..."
  nix-shell -p stow --run "echo ✅ stow ready"
fi

# ----------------------------------------
# 3. Run stow to symlink dotfiles
# ----------------------------------------
echo "🔗 Running stow.sh to symlink configs..."
STOW_SCRIPT="$DOTFILES_DIR/scripts/.config/scripts/stow.sh"
if [ -f "$STOW_SCRIPT" ]; then
  bash "$STOW_SCRIPT"
else
  echo "❌ stow.sh not found at $STOW_SCRIPT"
fi

# ----------------------------------------
# 4. Setup pokemon-icat if available
# ----------------------------------------
POKE_DIR="$DOTFILES_DIR/pokemon-icat/.config/pokemon-icat"
if [ -d "$POKE_DIR" ]; then
  echo "🧪 Setting up pokemon-icat..."
  cd "$POKE_DIR"

  # Skip setup if already done
  if [ -d ".venv" ] && [ -x "$(command -v .venv/bin/python)" ] && [ -f "$HOME/.cache/pokemon-icat/pokemon-icat" ]; then
    echo "✅ pokemon-icat already set up, skipping."
  else
    echo "🐍 Creating Python venv..."
    python3 -m venv .venv
    source .venv/bin/activate

    echo "📦 Installing Python dependencies..."
    pip install -r requirements.txt

    echo "🔨 Compiling and installing pokemon-icat..."
    bash compile.sh
    bash install.sh
  fi

  cd "$DOTFILES_DIR"
else
  echo "⚠️  pokemon-icat directory not found at $POKE_DIR, skipping."
fi

echo "🎉 Dotfiles setup complete. You may now restart your terminal."
