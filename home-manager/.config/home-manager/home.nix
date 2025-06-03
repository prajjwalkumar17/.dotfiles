{ config, pkgs, lib ? pkgs.lib, ... }:
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
  nixpkgs.config.allowUnfree = true;
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
    nodejs
    python3
    python3Packages.virtualenv
    python3Packages.pip
    rustup
    yarn

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
    cmake
    just
    libiconv
    lld
    llvm
    clang
    gcc-unwrapped
    gnumake
    openssl
    openssl.dev
    pkg-config
    protobuf
    zlib
    zlib.dev

    # dev utilities
    atuin
    ghostty
    git-extras
    git
    glibc
    meslo-lgs-nf
    ripgrep
    util-linux
    wl-clipboard
    wget
    stow
    starship
    unzip

    # networking
    dig

    # applications
    slack
    postman

    # shells
    (pkgs.writeShellScriptBin "rust-shell" ''
      exec nix-shell ${config.home.homeDirectory}/.dotfiles/home-manager/.config/home-manager/shells/rust-shell.nix "$@"
    '')  ];

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
    # ".config/containers/policy.json".source = ./containers/policy.json;
  };

  # Home Manager activating the configuration...
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
    RUSTUP_HOME = "${config.home.homeDirectory}/.rustup";
    CARGO_HOME = "${config.home.homeDirectory}/.cargo";
    PATH = "$PATH:${config.home.homeDirectory}/.cargo/bin";
    LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
    BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${pkgs.llvm}/lib/clang/${pkgs.llvm.version}/include";
    OPENSSL_DIR = "${pkgs.openssl.dev}";
    OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    CC = "clang";
    CXX = "clang++";

    # Add library path
    LD_LIBRARY_PATH = lib.makeLibraryPath [
      pkgs.openssl.out
      pkgs.libclang.lib
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
    ];
    # Database settings if needed globally
    DATABASE_URL = "postgres://postgres:postgres@localhost/hyperswitch"; 
  };

  home.activation = {
  rustupInit = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if ! [ -d "$HOME/.rustup" ]; then
      $DRY_RUN_CMD ${pkgs.rustup}/bin/rustup default stable
      $DRY_RUN_CMD ${pkgs.rustup}/bin/rustup component add rustfmt clippy rust-src rust-analyzer
    fi
  '';
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
      nix-direnv.enable = true;
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
  };
}
