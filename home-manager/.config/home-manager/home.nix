{ config, pkgs, lib ? pkgs.lib, ... }:
let
  fenix = import (fetchTarball "https://github.com/nix-community/fenix/archive/main.tar.gz") { };
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "hangsai"; home.homeDirectory = "/home/hangsai";
  # Fix version mismatch warning
  home.enableNixpkgsReleaseCheck = false;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # home = {
  #   activation.setZshAsShell = config.lib.dag.entryAfter ["writeBoundary"] ''
  #     if [[ $SHELL != ${pkgs.zsh}/bin/zsh ]]; then
  #       chsh -s ${pkgs.zsh}/bin/zsh
  #     fi
  #     '';
  # };
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    direnv

    # languages
    jdk23
    python3
    python3Packages.virtualenv
    python3Packages.pip
    fenix.stable.toolchain

    # nvim
    fzf
    gnumake
    gdb
    libtool
    neovim
    pkg-config
    ripgrep
    vimPlugins.telescope-fzf-native-nvim

    # language_servers
    jdt-language-server
    lua-language-server

    # Common build dependencies
    # binutils
    cmake
    clang
    just
    lld
    llvm
    # gcc
    openssl
    openssl.dev
    pkg-config

    # dev utilities
    git-extras
    git
    glibc
    meslo-lgs-nf
    ripgrep
    util-linux
    wl-clipboard
    wget
    stow
    unzip
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;
    # ".p10k.zsh".source = ~/.config/.p10k.zsh;
    # ".zshrc".source = ~/.config/.zshrc;


    # # You can also set the file content immediately. ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

# Configure rustfmt
  # home.file.".rustfmt.toml".text = ''
  #   max_width = 100
  #   tab_spaces = 4
  #   edition = "2021"
  # '';
  #
  # Cargo configuration with correct linker settings
  # home.file.".cargo/config.toml".text = ''
  #   [target.x86_64-unknown-linux-gnu]
  #   linker = "gcc"
  #   rustflags = [
  #     "-C", "link-arg=-fuse-ld=lld",
  #     "-C", "target-feature=+crt-static"
  #   ]
  #
  #   [build]
  #   rustc-wrapper = "${pkgs.sccache}/bin/sccache"
  #
  #   [net]
  #   git-fetch-with-cli = true
  # '';
  # xdg.configFile."cargo/config.toml".text = ''
  #   [build]
  #   rustc-wrapper = "${pkgs.sccache}/bin/sccache"
  #   [target.x86_64-unknown-linux-gnu]
  #   linker = "gcc"
  #   rustflags = ["--cfg", "procmacro2_semver_exempt"]
  # '';

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/hangsai/etc/profile.d/hm-session-vars.sh

  home.sessionVariables = {
    EDITOR = "nvim";
    RUST_SRC_PATH = "${fenix.stable.rust-src}/lib/rustlib/src/rust/library";
    RUSTFLAGS = "--cfg procmacro2_semver_exempt";
    BINDGEN_EXTRA_CLANG_ARGS = "-I${pkgs.glibc.dev}/include -I${pkgs.clang.cc.lib}/lib/clang/${pkgs.clang.version}/include";
    OPENSSL_DIR = "${pkgs.openssl.dev}";
    OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
    OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
    LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
      pkgs.stdenv.cc.cc
      pkgs.openssl
    ];
    CC = "${pkgs.gcc}/bin/gcc";
    CXX = "${pkgs.gcc}/bin/g++";
  };

  # Let Home Manager install and manage itself.
  services = {
    ssh-agent.enable = true;
    conky.enable = true;
  };
  programs = {
    home-manager.enable = true;
    lazygit.enable = true;

    direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    fastfetch.enable = true;
    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "rg --files --hidden --follow";
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--preview 'cat {}'"
      ];
      historyWidgetOptions = [
        "--sort"
        "--exact"
      ];
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    # zsh = {
    #   enable = false;
    #   autosuggestion.enable = true;
    #   enableCompletion = true;
    #
    #   plugins = [
    #     {
    #       name = "vi-mode";
    #       src = pkgs.zsh-vi-mode;
    #     }
    #   ];
    #
    #   history = {
    #     path = "${config.home.homeDirectory}/.zsh_history";
    #     save = 50000;
    #     size = 50000;
    #     expireDuplicatesFirst = true;
    #     extended = true;
    #     share = true;
    #   };
    #
    #   # Aliases
    #   shellAliases = {
    #     mkdir = "mkdir -p";
    #   };
    #
    #   initExtra = ''
    #     export PATH=$PATH:/home/hangsai/.cache/pokemon-icat
    #     pokemon-icat -q
    #     source $(find /nix/store -name "powerlevel10k.zsh-theme" | head -n 1)
    #
    #     # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
    #     [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
    #
    #     nvim() {
    #         kitten @ set-spacing padding=0   # Set padding to 0
    #         command nvim "$@"                # Run Neovim with any passed arguments
    #         kitten @ set-spacing padding=25  # Restore padding to 25 after exiting Neovim
    #     }
    #     # FZF configuration for better history search
    #     export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
    #     export FZF_CTRL_R_OPTS="--sort --exact"
    #
    #     # Ensure history is saved properly
    #     setopt SHARE_HISTORY
    #     setopt EXTENDED_HISTORY
    #     setopt HIST_EXPIRE_DUPS_FIRST
    #     setopt HIST_IGNORE_DUPS
    #     setopt HIST_IGNORE_SPACE
    #     setopt HIST_VERIFY
    #     setopt NO_CLOBBER
    #
    #   '';
    #   oh-my-zsh = {
    #     enable = true;
    #     plugins = [
    #       "history"
    #       "dirhistory"
    #       "git"
    #     ];
    #   };
    # };
  };
  # home.activation.linkMyFiles = config.lib.dag.entryAfter ["writeBoundary"] ''
  #   ln -s ${toString ~/.config/.zshrc} ~/.zshrc
  # '';
}
