#!/usr/bin/env bash

set -euo pipefail

echo "📦 Starting Prajjwal's Dotfiles Setup..."

# Root of the dotfiles repo (this script's directory)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ----------------------------------------
# 1. Install Home Manager if not present
# ----------------------------------------
if ! command -v home-manager &> /dev/null; then
  echo "🔧 Installing Home Manager..."

  nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz home-manager
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
else
  echo "✅ stow already installed."
fi

# ----------------------------------------
# 3. Run stow to symlink dotfiles
# ----------------------------------------
echo "🔗 Running stow.sh to symlink configs..."
STOW_SCRIPT="$DOTFILES_DIR/scripts/.config/scripts/stow.sh"
if [ -f "$STOW_SCRIPT" ]; then
  nix-shell -p stow --run "bash $STOW_SCRIPT"
else
  echo "❌ stow.sh not found at $STOW_SCRIPT"
fi

# ----------------------------------------
# 3. Rebuild home-manager
# ----------------------------------------
echo "🔧 Rebuilding home-manager..."
home-manager switch


# ----------------------------------------
# 4. Setup pokemon-icat if available
# ----------------------------------------
POKE_DIR="$DOTFILES_DIR/pokemon-icat/.config/pokemon-icat"
if [ -d "$POKE_DIR" ]; then
  echo "🧪 Setting up pokemon-icat..."
  cd "$POKE_DIR"

  if [ -d ".venv" ] && [ -x ".venv/bin/python" ]; then
    echo "✅ pokemon-icat already set up, skipping."
  else
    echo "🐍 Creating Python venv..."
    python3 -m venv .venv
    source .venv/bin/activate

    echo "📦 Installing Python dependencies..."
    if [ ! -f requirements.txt ]; then
      echo "❌ requirements.txt not found in $PWD"
      exit 1
    fi
    pip install -r requirements.txt

    echo "🔨 Compiling and installing pokemon-icat..."
    bash compile.sh
    bash install.sh
  fi

  cd "$DOTFILES_DIR"
else
  echo "⚠️  pokemon-icat directory not found at $POKE_DIR, skipping."
fi

# ----------------------------------------
# 5. Create Screenshots directory in ~
# ----------------------------------------
SCREENSHOT_DIR="$HOME/Screenshots"
if [ ! -d "$SCREENSHOT_DIR" ]; then
  echo "🖼️ Creating ~/Screenshots directory..."
  mkdir -p "$SCREENSHOT_DIR"
  echo "✅ ~/Screenshots created."
else
  echo "✅ ~/Screenshots already exists."
fi

# ----------------------------------------
# 6. Configure Git identity and SSH access
# ----------------------------------------
echo "🔧 Setting up Git identity and SSH key..."

# Prompt for git user.name if not set
if ! git config --global user.name &>/dev/null; then
  read -rp "👤 Enter your Git user.name: " GIT_NAME
  git config --global user.name "$GIT_NAME"
else
  echo "✅ Git user.name is already set to: $(git config --global user.name)"
fi

# Prompt for git user.email if not set
if ! git config --global user.email &>/dev/null; then
  read -rp "📧 Enter your Git user.email: " GIT_EMAIL
  git config --global user.email "$GIT_EMAIL"
else
  echo "✅ Git user.email is already set to: $(git config --global user.email)"
fi

echo "✅ Final Git identity:"
git config --global --get user.name
git config --global --get user.email

# Setup SSH key if not already present
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
  echo "🔐 SSH key not found. Generating..."
  mkdir -p "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$SSH_KEY" -N ""
  echo "✅ SSH key generated."
else
  echo "✅ SSH key already exists at $SSH_KEY"
fi

# Add to ssh-agent
echo "🔑 Adding SSH key to ssh-agent..."
eval "$(ssh-agent -s)" >/dev/null
ssh-add "$SSH_KEY"

# Show key for manual copy
echo ""
echo "📋 Your SSH public key (copy it to GitHub → Settings → SSH Keys):"
echo "-----------------------------------------------------------------"
cat "$SSH_KEY.pub"
echo "-----------------------------------------------------------------"
echo ""

# Optionally upload to GitHub via API
read -rp "🪪 Do you want to upload this key to GitHub automatically? (y/N): " upload_choice
if [[ "$upload_choice" =~ ^[Yy]$ ]]; then
  read -rp "🔑 Enter your GitHub personal access token (with 'admin:public_key' scope): " GITHUB_TOKEN
  read -rp "📝 Enter a title for this key (e.g., hangsai-nixos): " KEY_TITLE

  PUB_KEY_CONTENT=$(cat "$SSH_KEY.pub")

  curl -s -H "Authorization: token $GITHUB_TOKEN" \
       -H "Content-Type: application/json" \
       -d "{\"title\": \"$KEY_TITLE\", \"key\": \"$PUB_KEY_CONTENT\"}" \
       https://api.github.com/user/keys | jq '.'

  echo "✅ SSH key uploaded to GitHub."
else
  echo "🧷 Skipped GitHub key upload."
fi

# ----------------------------------------
# 7. Convert dotfiles repo remote from HTTPS to SSH
# ----------------------------------------
echo "🔄 Checking dotfiles remote URL..."

cd "$DOTFILES_DIR"

CURRENT_REMOTE=$(git remote get-url origin)

if [[ "$CURRENT_REMOTE" == https://github.com/* ]]; then
  SSH_REMOTE="${CURRENT_REMOTE/https:\/\/github.com\//git@github.com:}"

  git remote set-url origin "$SSH_REMOTE"
  echo "✅ Remote URL updated to SSH:"
  git remote -v
else
  echo "✅ Remote already uses SSH or a custom URL:"
  git remote -v
fi
# some extra github sanity commands
git config pull.rebase false

# ----------------------------------------
# 8. Clone personal Neovim config
# ----------------------------------------
NVIM_TARGET="$HOME/.config/nvim"
NVIM_REPO="git@github.com:prajjwalkumar17/nvim.git"
NVIM_BRANCH="nix-os"

echo "📦 Checking for existing Neovim config at $NVIM_TARGET..."

if [ -d "$NVIM_TARGET/.git" ]; then
  echo "✅ Neovim config already exists at $NVIM_TARGET, skipping clone."
else
  echo "⬇️ Cloning Neovim config from $NVIM_REPO into $NVIM_TARGET..."
  git clone "$NVIM_REPO" "$NVIM_TARGET"
  echo "✅ Neovim config cloned."
fi

# Check out nix-os branch
cd "$NVIM_TARGET"
if git show-ref --verify --quiet "refs/heads/$NVIM_BRANCH" || git ls-remote --exit-code --heads origin "$NVIM_BRANCH" &>/dev/null; then
  git checkout "$NVIM_BRANCH"
  echo "✅ Checked out branch '$NVIM_BRANCH'"
else
  echo "⚠️ Branch '$NVIM_BRANCH' not found in remote. Skipping checkout."
fi


echo "🎉 Dotfiles setup complete. You may now restart your terminal."
