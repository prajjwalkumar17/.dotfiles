#!/usr/bin/env bash

set -e

echo "📦 Starting Prajjwal's Dotfiles Setup..."

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
cd scripts/.config/scripts/
sh stow.sh
cd ..

# ----------------------------------------
# 4. Setup pokemon-icat if available
# ----------------------------------------
if [ -d "pokemon-icat/.config/pokemon-icat" ]; then
  echo "🧪 Setting up pokemon-icat..."
  cd pokemon-icat/.config/pokemon-icat

  # Create Python venv
  echo "🐍 Creating Python venv..."
  python3 -m venv .venv
  source .venv/bin/activate

  # Install Python dependencies
  echo "📦 Installing Python dependencies..."
  pip install -r requirements.txt

  # Compile Rust binary and install assets
  echo "🔨 Compiling and installing pokemon-icat..."
  sh compile.sh
  sh install.sh

  # Optionally update PATH
  # echo 'export PATH=$PATH:$HOME/.cache/pokemon-icat' >> ~/.bashrc
  # echo 'export PATH=$PATH:$HOME/.cache/pokemon-icat' >> ~/.zshrc

  cd ../../../
  echo "✅ pokemon-icat setup complete."
else
  echo "⚠️  pokemon-icat directory not found, skipping."
fi

echo "🎉 Dotfiles setup complete. You may now restart your terminal."
