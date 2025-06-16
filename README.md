
# 🛠️ Prajjwal's Dotfiles

This repository contains my personal configuration for:

- `zsh` (with Powerlevel10k or Starship)
- `neovim`
- `pokemon-icat` for terminal Pokémon sprites
- Home Manager dotfiles
- Managed with `GNU Stow` for easy symlink setup on NixOS
- ⚙️ Fully automated setup with `setup.sh`

---

## ✅ Prerequisites
Note: not required if using setup.sh

Install [Home Manager](https://nix-community.github.io/home-manager/) using Nix channels:

```sh
nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

---

## 🚀 Installation (One-liner)

Run the following to clone and execute the setup:

```sh
git clone https://github.com/prajjwalkumar17/.dotfiles.git ~/.dotfiles && bash ~/.dotfiles/setup.sh
```

This script automates the full setup process.

---

## ⚙️ What `setup.sh` Does

The `setup.sh` script performs the following:

1. **Home Manager**: Installs it if not already present
2. **Stow**: Installs `stow` if missing, then runs `stow.sh` to symlink configs
3. **Home Manager Switch**: Rebuilds the home-manager configuration
4. **pokemon-icat**:
   - Creates Python virtualenv
   - Installs Python dependencies
   - Compiles Rust binary
   - Installs it to `~/.cache/pokemon-icat`
5. **Screenshots**: Creates `~/Screenshots` directory
6. **Git Identity Setup**:
   - Prompts for `user.name` and `user.email` if not configured
   - Generates and adds an SSH key
   - Optionally uploads key to GitHub using a personal access token
7. **Remote Conversion**: Converts `.dotfiles` repo remote from HTTPS to SSH
8. **Neovim Setup**:
   - Clones `git@github.com:prajjwalkumar17/nvim.git` into `~/.config/nvim`
   - Checks out the `nix-os` branch

---

## 🔧 Customization

You can change the following by editing `setup.sh`:

- GitHub email & name prompts
- Neovim clone target or branch
- Whether SSH key is uploaded
- Location of Pokémon venv or cache

---

## 📁 Project Structure

```
.dotfiles/
├── home-manager/           # Home Manager configuration (home.nix)
├── nvim/                   # Neovim configuration
├── zsh/                    # zsh + Powerlevel10k config
├── pokemon-icat/           # Pokémon terminal sprite viewer
├── starship.toml           # Optional Starship prompt config
├── scripts/
│   └── stow.sh             # Stow all configs to $HOME
├── setup.sh                # 🔁 Fully automated setup script
└── .gitignore              # Clean build cache and venv ignores
```

---

## 📜 License

MIT — feel free to fork, adapt, and use.
