{ isWSL, inputs, ... }:

{ config, lib, pkgs, ... }:

let
  sources = import ../../nix/sources.nix;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # For our MANPAGER env var
  # https://github.com/sharkdp/bat/issues/1145
  manpager = (pkgs.writeShellScriptBin "manpager" (if isDarwin then ''
    sh -c 'col -bx | bat -l man -p'
    '' else ''
    cat "$1" | col -bx | bat --language man --style plain
  ''));
in {
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
    pkgs._1password
    pkgs.asciinema
    pkgs.bat
    pkgs.fd
    pkgs.fzf
    pkgs.gh
    pkgs.htop
    pkgs.jq
    pkgs.ripgrep
    pkgs.sentry-cli
    pkgs.tree
    pkgs.watch

    pkgs.gopls

    pkgs.lastpass-cli
    pkgs.wireshark
    pkgs.betterbird
    pkgs.nodejs_22
    pkgs.python3
    pkgs.lua
    pkgs.luajitPackages.luarocks
    pkgs.curl
    pkgs.wget
    pkgs.gcc
    pkgs.gdb
    # For my neovim config
    pkgs.stow
    pkgs.tree-sitter
    pkgs.stylua
    pkgs.unzip
    pkgs.nerdfonts
    # Currently trying to do via oxalica
    # pkgs.rust-analyzer
    # For bpftool
    pkgs.bpftools
    # Packages to add:
    pkgs.dig
    # For telnet
    pkgs.inetutils
  ] ++ (lib.optionals isDarwin [
    # This is automatically setup on Linux
    pkgs.cachix
    pkgs.tailscale
  ]) ++ (lib.optionals (isLinux && !isWSL) [
    pkgs.chromium
    pkgs.firefox
    pkgs.rofi
    pkgs.valgrind
    pkgs.zathura
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
  };

  home.file = {
    ".gdbinit".source = ./gdbinit;
    ".inputrc".source = ./inputrc;
  } // (if isDarwin then {
    "Library/Application Support/jj/config.toml".source = ./jujutsu.toml;
  } else {});

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
    shellOptions = [];
    historyControl = [ "ignoredups" "ignorespace" ];
    # initExtra = builtins.readFile ./bashrc;

    shellAliases = {
      # ga = "git add";
      # gc = "git commit";
      # gco = "git checkout";
      # gcp = "git cherry-pick";
      # gdiff = "git diff";
      # gl = "git prettylog";
      # gp = "git push";
      # gs = "git status";
      # gt = "git tag";
    };
  };

  programs.direnv= {
    enable = true;

    config = {
      whitelist = {
        prefix= [
          "$HOME/code/go/src/github.com/gmarler"
        ];

        exact = ["$HOME/.envrc"];
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

  programs.jujutsu = {
    enable = true;

    # I don't use "settings" because the path is wrong on macOS at
    # the time of writing this.
  };

  programs.tmux = {
    enable = true;
    terminal = "xterm-256color";
    shortcut = "l";
    secureSocket = false;

    plugins = with pkgs;
      [
          tmuxPlugins.vim-tmux-navigator
          tmuxPlugins.catppuccin
          tmuxPlugins.yank
          tmuxPlugins.resurrect
          tmuxPlugins.continuum
      ];

    extraConfig = ''
      # Ensure that we start a bash shell for each tmux window, so .bashrc is invoked
      # as a side effect
      set-option -g default-command bash
      
      ###############################################################################
      # "Sensible" tmux defaults
      ###############################################################################
      # Address vim mode switching delay (http://superuser.com/a/252717/65504)
      set -s escape-time 0
      
      # Increase scrollback buffer size from 2000 to 750000 lines
      set -g history-limit 750000
      
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
      set -g mouse on
      
      # MY prefix (C-a, not C-b)
      unbind C-b
      set-option -g prefix C-a
      bind-key C-a send-prefix
      
      # Shift Alt vim keys to switch windows
      bind -n M-H previous-window
      bind -n M-L next-window

      # Start windows and panes at 1, not 0
      set -g base-index 1
      set -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on
      
      # set -g @catppuccin_flavour 'latte'
      set -g @catppuccin_flavour 'frappe'
      
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
      set-window-option -g mode-keys vi
      
      # keybindings
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      
      # Open panes in current directory using sane split commands
      bind '-' split-window -v -c "#{pane_current_path}"
      bind '|' split-window -h -c "#{pane_current_path}"
      unbind '"'
      unbind '%'
      
      # run '~/.tmux/plugins/tpm/tpm'
    '';
  };

  programs.alacritty = {
    enable = !isWSL;

    settings = {
      env.TERM = "xterm-256color";

      key_bindings = [
        { key = "K"; mods = "Command"; chars = "ClearHistory"; }
        { key = "V"; mods = "Command"; action = "Paste"; }
        { key = "C"; mods = "Command"; action = "Copy"; }
        { key = "Key0"; mods = "Command"; action = "ResetFontSize"; }
        { key = "Equals"; mods = "Command"; action = "IncreaseFontSize"; }
        { key = "Subtract"; mods = "Command"; action = "DecreaseFontSize"; }
      ];
    };
  };

  programs.kitty = {
    enable = !isWSL;
    extraConfig = builtins.readFile ./kitty;
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
    # Only if you want to use nightly
    package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
    # package = inputs.pkgs.unstable.neovim-unwrapped;
    # package = pkgs.neovim-unwrapped;

    withPython3 = true;

    plugins = with pkgs; [
      customVim.vim-cue
      customVim.vim-glsl
      customVim.vim-misc
      customVim.vim-pgsql
      customVim.vim-tla
      customVim.pigeon
      customVim.AfterColors

      customVim.vim-nord
      customVim.nvim-comment
      customVim.nvim-conform
      customVim.nvim-dressing
      customVim.nvim-gitsigns
      customVim.nvim-lualine
      customVim.nvim-lspconfig
      customVim.nvim-nui
      customVim.nvim-plenary # required for telescope
      customVim.nvim-telescope
      customVim.nvim-treesitter
      customVim.nvim-treesitter-playground
      customVim.nvim-treesitter-textobjects

      vimPlugins.vim-eunuch
      vimPlugins.vim-markdown
      vimPlugins.vim-nix
      vimPlugins.typescript-vim
      vimPlugins.nvim-treesitter-parsers.elixir
    ] ++ (lib.optionals (!isWSL) [
      # This is causing a segfaulting while building our installer
      # for WSL so just disable it for now. This is a pretty
      # unimportant plugin anyway.
      customVim.nvim-web-devicons
    ]);

    extraConfig = (import ./vim-config.nix) { inherit sources; };
  };

  services.gpg-agent = {
    enable = isLinux;
    pinentryPackage = pkgs.pinentry-tty;

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
