# 🛠️ Prajjwal's Dotfiles

This repository contains my personal configuration for:

- `zsh` (with Powerlevel10k or Starship)
- `neovim`
- `pokemon-icat` for terminal Pokémon sprites
- Home Manager dotfiles
- Managed with `GNU Stow` for easy symlink setup on NixOS

---

## ✅ Prerequisites

Install [Home Manager](https://nix-community.github.io/home-manager/) using Nix channels:

```sh
nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

---

## 🚀 Installation

### 1. Clone this repo

```sh
git clone git@github.com:prajjwalkumar17/.dotfiles.git
cd .dotfiles
```

### 2. Install `stow` (if not already)

```sh
nix-shell -p stow
```

### 3. Apply dotfiles using stow

```sh
cd scripts
sh stow.sh
```

This will symlink config files (like `.zshrc`, `.config/nvim`, etc.) into your `$HOME` directory.

---

## 🧪 Pokémon Terminal Viewer: `pokemon-icat`

A terminal-based Pokémon viewer written in Rust + Python.

### 📦 Requirements

- `cargo` and `python3.12+`
- Terminal that supports images (e.g., `kitty`)

### 🔧 Setup Instructions

```sh
# Clone the repo if not already
cd ~/.dotfiles/pokemon-icat/.config/pokemon-icat

# Create Python venv
python3 -m venv .venv
source .venv/bin/activate

# Install Python dependencies
pip install -r requirements.txt

# Compile Rust binary and install assets
sh compile.sh
sh install.sh
```

### 🧭 Add binary to PATH (if needed)

```sh
export PATH=$PATH:$HOME/.cache/pokemon-icat
```

Now you can run:

```sh
pokemon-icat -q
```

---

## 🌟 Optional: Use Starship Prompt

If Powerlevel10k is slow or not installed, use `starship`:

```sh
starship preset pastel-powerline -o ~/.config/starship.toml
```

Then make sure `~/.config/starship.toml` is sourced in your `.zshrc` or `.bashrc`.

---

## 📁 Project Structure

```
.dotfiles/
├── home-manager/           # Home Manager configuration (home.nix)
├── nvim/                   # Neovim configuration
├── zsh/                    # zsh + Powerlevel10k config
├── pokemon-icat/           # Pokémon terminal sprite viewer
├── starship.toml           # Optional Starship prompt config
└── scripts/
    └── stow.sh             # Stow all configs to $HOME
```

---

## 🧼 Notes

- Configs are tailored for **NixOS** and `home-manager`.
- If using flakes, you’ll need to adapt `flake.nix` (not provided here).
- Powerlevel10k may slow down large prompts; use Starship if needed.

---

## 📜 License

MIT — feel free to fork, adapt, and use.
