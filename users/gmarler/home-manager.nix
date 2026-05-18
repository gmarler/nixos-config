{ isWSL, inputs, ... }:

{
  config,
  lib,
  pkgs,
  ...
}:

let
  # sources = import ../../nix/sources.nix;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # For our MANPAGER env var
  # https://github.com/sharkdp/bat/issues/1145
  manpager = (
    pkgs.writeShellScriptBin "manpager" (
      if isDarwin then
        ''
          sh -c 'col -bx | bat -l man -p'
        ''
      else
        ''
          cat "$1" | col -bx | bat --language man --style plain
        ''
    )
  );
in
{
  # Home-manager 22.11 requires this be set. We never set it so we have
  # to use the old state version.
  home.stateVersion = "18.09";

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages I always want installed. Most packages I install using
  # per-project flakes sourced with direnv and nix-shell, so this is
  # not a huge list.
  home.packages = [
    # pkgs._1password
    pkgs.asciinema
    pkgs.bat
    pkgs.bc
    pkgs.fd
    pkgs.fzf
    pkgs.gh
    pkgs.htop
    pkgs.jq
    pkgs.ripgrep
    pkgs.rpm
    pkgs.sentry-cli
    pkgs.tree
    pkgs.watch

    pkgs.gopls

    # Want one for DashLane
    # pkgs.lastpass-cli
    pkgs.wireshark
    # pkgs.betterbird
    # NodeJS Dev Environment
    #pkgs.nodejs_22
    pkgs.nodePackages_latest.nodejs
    #pkgs.nodePackages_latest.npm
    pkgs.nodePackages_latest.gulp
    pkgs.nodePackages_latest.node2nix
    pkgs.nodePackages_latest.jsonlint

    pkgs.python3
    pkgs.lua
    pkgs.luajitPackages.luarocks
    pkgs.curl
    pkgs.wget
    pkgs.gcc
    pkgs.gdb
    # For my neovim config
    pkgs.stow
    # pkgs.tree-sitter
    pkgs.stylua
    pkgs.unzip
    pkgs.nerd-fonts.fira-mono
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.caskaydia-cove
    pkgs.nerd-fonts.blex-mono
    pkgs.nerd-fonts.commit-mono
    pkgs.rust-analyzer
    pkgs.ruff
    # NOTE: These packages should be installed via the nixvim flake, not here
    pkgs.statix
    pkgs.eslint_d
    # END OF PKGS specific to nixvim flake ####################################
    # Currently trying to do via oxalica
    # pkgs.rust-analyzer
    # For bpftool
    pkgs.bpftools
    # Packages to add:
    pkgs.dig
    # For telnet
    pkgs.inetutils
    # For Clickhouse development
    # pkgs.clickhouse
    # Love me some Infocom
    pkgs.frotz
  ]
  ++ (lib.optionals isDarwin [
    # This is automatically setup on Linux
    pkgs.cachix
    # pkgs.tailscale
  ])
  ++ (lib.optionals (isLinux && !isWSL) [
    pkgs.chromium
    # Markdown Preview Browser
    pkgs.floorp
    pkgs.firefox
    pkgs.rofi
    pkgs.valgrind
    pkgs.zathura # PDF viewer
    pkgs.xfce.xfce4-terminal
  ]);

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    MANPAGER = "${manpager}/bin/manpager";
    NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
    GIT_SSL_CAINFO = "/etc/ssl/certs/ca-bundle.crt";
  };

  home.file = {
    ".gdbinit".source = ./gdbinit;
    ".inputrc".source = ./inputrc;
  };

  ### xdg.configFile = {
  ###   "i3/config".text = builtins.readFile ./i3;
  ###   "rofi/config.rasi".text = builtins.readFile ./rofi;

  ###   # tree-sitter parsers
  ###   "nvim/parser/proto.so".source = "${pkgs.tree-sitter-proto}/parser";
  ###   "nvim/queries/proto/folds.scm".source =
  ###     "${sources.tree-sitter-proto}/queries/folds.scm";
  ###   "nvim/queries/proto/highlights.scm".source =
  ###     "${sources.tree-sitter-proto}/queries/highlights.scm";
  ### } // (if isDarwin then {
  ###   # Rectangle.app. This has to be imported manually using the app.
  ###   "rectangle/RectangleConfig.json".text = builtins.readFile ./RectangleConfig.json;
  ### } else {}) // (if isLinux then {
  ###   "ghostty/config".text = builtins.readFile ./ghostty.linux;
  ###   "jj/config.toml".source = ./jujutsu.toml;
  ### } else {});

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs.gpg.enable = !isDarwin;

  programs.bash = {
    enable = true;
    shellOptions = [ ];
    historyControl = [
      "ignoredups"
      "ignorespace"
    ];
    initExtra = builtins.readFile ./bashrc;

    shellAliases = {
      ga = "git add";
      gc = "git commit";
      gco = "git checkout";
      gcp = "git cherry-pick";
      gdiff = "git diff";
      gl = "git prettylog";
      glo = "git log --oneline --graph --pretty=format:'%h %ad %s [%an]' --date=local";
      gp = "git push";
      gs = "git status";
      gt = "git tag";
    };
  };

  programs.direnv = {
    enable = true;

    config = {
      whitelist = {
        prefix = [
          "$HOME/code/go/src/github.com/gmarler"
        ];

        exact = [ "$HOME/.envrc" ];
      };
    };
  };

  programs.git = {
    enable = true;
    userName = "Gordon Marler";
    userEmail = "gmarler@bloomberg.net";
    # signing = {
    #   key = "523D5DC389D273BC";
    #   signByDefault = true;
    # };
    aliases = {
      ci = "commit";
      co = "checkout";
      cleanup = "!git branch --merged | grep  -v '\\*\\|master\\|develop' | xargs -n 1 -r git branch -d";
      prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      root = "rev-parse --show-toplevel";
    };
    extraConfig = {
      # branch.autosetuprebase = "always";
      color.ui = true;
      core.askPass = ""; # needs to be empty to use terminal for ask pass
      credential.helper = "store"; # want to make this more secure
      github.user = "gmarler";
      push.default = "tracking";
      init.defaultBranch = "main";
    };
  };

  # See for interesting details:
  # https://haseebmajid.dev/posts/2023-07-10-setting-up-tmux-with-nix-home-manager/
  programs.tmux = {
    enable = true;
    shell = "${pkgs.bash}/bin/bash";
    terminal = "xterm-256color";
    shortcut = "a";
    secureSocket = false;
    # Start windows and panes at 1, not 0
    baseIndex = 1;
    # Address vim mode switching delay (http://superuser.com/a/252717/65504)
    escapeTime = 0;
    # Increase scrollback buffer size from 2000 to 750000 lines
    historyLimit = 750000;
    keyMode = "vi";
    mouse = true;

    plugins = with pkgs; [
      tmuxPlugins.vim-tmux-navigator
      {
        plugin = tmuxPlugins.catppuccin;
        # Following fixes issue with catppuccin setting the window names to
        # the hostname
        extraConfig = ''
          set -g  @catpuccin_flavour "frappe"
          set -gq @catppuccin_window_text " #W"
          set -gq @catppuccin_window_current_text " #W"
        '';
      }
      tmuxPlugins.yank
      # tmuxPlugins.resurrect
      # tmuxPlugins.continuum
    ];

    extraConfig = ''
      # Ensure that we start a bash shell for each tmux window, so .bashrc is invoked
      # as a side effect
      set-option -g default-command bash

      set-option -g automatic-rename on
      set-option -g automatic-rename-format '#{b:pane_current_path}'

      ###############################################################################
      # "Sensible" tmux defaults
      ###############################################################################
      # Address vim mode switching delay (http://superuser.com/a/252717/65504)
      # EscapeTime above
      # set -s escape-time 0

      # Increase scrollback buffer size from 2000 to 750000 lines
      # historyLimit above
      # set -g history-limit 750000

      # Increase tmux messages display duration from 750ms to 4s
      set -g display-time 4000

      # Refresh 'status-left' and 'status-right' more often, from every 15s to 5s
      set -g status-interval 5

      # Upgrade $TERM
      set -g default-terminal "screen-256color"

      # Focus events enabled for terminals that support them
      set -g focus-events on

      # Super useful when using "grouped sessions" and multi-monitor setup
      setw -g aggressive-resize on

      ###############################################################################

      ###############################################################################
      # Conveniences
      ###############################################################################
      # Allow moving windows left or right easily
      bind-key -n C-S-Left swap-window -t -1\; select-window -t -1
      bind-key -n C-S-Right swap-window -t +1\; select-window -t +1
      ###############################################################################

      set-option -sa terminal-overrides ",xterm*:Tc"
      # mouse above
      # set -g mouse on

      # MY prefix (C-a, not C-b)
      # shortcut above
      # unbind C-b
      # set-option -g prefix C-a
      # bind-key C-a send-prefix

      # Shift Alt vim keys to switch windows
      bind -n M-H previous-window
      bind -n M-L next-window

      # Start windows and panes at 1, not 0
      # baseIndex above
      # set -g base-index 1
      set -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on

      # set -g @catppuccin_flavour 'latte'
      # set -g @catppuccin_flavour 'frappe'

      # set -g @plugin 'tmux-plugins/tpm'
      # We set these separately above
      # set -g @plugin 'tmux-plugins/tmux-sensible'
      # set -g @plugin 'christoomey/vim-tmux-navigator'
      # set -g @plugin 'catppuccin/tmux'
      # Copy text to the system clipboard when using tmux
      # set -g @plugin 'tmux-plugins/tmux-yank'
      # Persist tmux environment across system restarts
      # set -g @plugin 'tmux-plugins/tmux-resurrect'
      # Depends on tmux-resurrect, and automatically/continuously saves tmux
      # environment, as well as automatically restoring it upon tmux startup
      # set -g @plugin 'tmux-plugins/tmux-continuum'

      # set vi-mode
      # keyMode above ???
      # set-window-option -g mode-keys vi

      # keybindings
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -sel clip -i"

      # Open panes in current directory using sane split commands
      # Which means change splits to match nvim and easier to remember
      # Open new split at cwd of current split
      bind '-' split-window -v -c "#{pane_current_path}"
      bind '|' split-window -h -c "#{pane_current_path}"
      unbind '"'
      unbind '%'
    '';
  };

  programs.i3status = {
    enable = isLinux && !isWSL;

    general = {
      colors = true;
      color_good = "#8C9440";
      color_bad = "#A54242";
      color_degraded = "#DE935F";
    };

    modules = {
      ipv6.enable = false;
      "wireless _first_".enable = false;
      "battery all".enable = false;
    };
  };

  programs.neovim = {
    enable = true;

    withPython3 = true;
  };

  services.gpg-agent = {
    enable = isLinux;
    pinentry.package = pkgs.pinentry-tty;

    # cache the keys forever so we don't get asked for a password
    defaultCacheTtl = 31536000;
    maxCacheTtl = 31536000;
  };

  xresources.extraConfig = builtins.readFile ./Xresources;

  # Make cursor not tiny on HiDPI screens
  home.pointerCursor = lib.mkIf (isLinux && !isWSL) {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
    x11.enable = true;
  };
}
