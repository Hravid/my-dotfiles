{ config, lib, pkgs, inputs, username, ... }:

{
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05"; # match system.stateVersion

  # ---------- Caelestia shell ----------
  programs.caelestia = {
    enable = true;
    cli.enable = true; # also gives you `caelestia` CLI (theming, screenshots, record)
    # systemd autostart — no compositor exec-once needed (UWSM runs graphical-session.target)
    systemd = {
      enable = true;
      target = "graphical-session.target";
    };
    # settings go here later, e.g.:
    # settings.bar.status.showBattery = false;
  };

  # Quickshell does its own freedesktop icon lookup and ignores the GTK theme,
  # so the launcher showed black/purple fallback squares. Point it at Papirus.
  systemd.user.services.caelestia.Service.Environment = [ "QS_ICON_THEME=Papirus-Dark" ];
  home.sessionVariables.QS_ICON_THEME = "Papirus-Dark";
  home.sessionVariables.EDITOR = "nvim";
  home.sessionVariables.VISUAL = "nvim";

  # WinBox ships only the xcb Qt platform plugin; launched from caelestia it
  # inherits QT_QPA_PLATFORM=wayland from quickshell's env and aborts on
  # startup. Shadow its desktop entry and force xcb (XWayland).
  xdg.desktopEntries.winbox = {
    name = "WinBox";
    comment = "GUI administration for Mikrotik RouterOS";
    icon = "winbox";
    categories = [ "Utility" ];
    exec = "env QT_QPA_PLATFORM=xcb WinBox";
  };

  # rpi-imager 2.x must run as root and its pkexec self-elevation is broken on
  # NixOS (hard-codes /usr/bin/pkexec). The `pimager` script (home.packages)
  # handles the sudo+Wayland invocation; ghostty gives sudo a password prompt.
  xdg.desktopEntries."com.raspberrypi.rpi-imager" = {
    name = "Raspberry Pi Imager";
    comment = "Tool for writing images to SD cards for Raspberry Pi";
    icon = "rpi-imager";
    categories = [ "Utility" ];
    exec = "ghostty -e pimager";
    mimeType = [ "x-scheme-handler/rpi-imager" "application/vnd.raspberrypi.imager-manifest+json" ];
  };

  # ---------- Cursor ----------
  # Bibata Modern Ice for Hyprland (hyprcursor), GTK and XWayland apps.
  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    hyprcursor.enable = true;
  };

  # ---------- GTK look (file dialogs, thunar, etc.) ----------
  # Papirus provides the folder/file icons that were showing as black/purple
  # fallback squares; Caelestia's icon warnings come from the same gap.
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
  };

  # ---------- Hyprland ----------
  # NOTE: home-manager's hyprland settings module generates BROKEN lua for
  # Hyprland 0.55 (old comma-string grammar wrapped in the new lua API).
  # So we bypass it and write hyprland.lua directly in the real 0.55 lua API.
  xdg.configFile."hypr/hyprland.lua".text = ''
    -- Hand-written Hyprland 0.55 config (lua API)

    ----------------
    -- MONITORS ----
    ----------------
    -- match by DESCRIPTION, not port name — kernel/ driver updates can renumber
    -- DP-1/DP-2/HDMI-A-* and port-based rules silently stop applying.
    -- Samsung Odyssey G80SH (4K@240) — LEFT, primary display
    hl.monitor({ output = "desc:Samsung Electric Company Odyssey G80SH", mode = "highrr", position = "0x0", scale = 1 })
    -- Xiaomi Mi Monitor (1440p@144) — RIGHT of the Samsung
    hl.monitor({ output = "desc:Xiaomi Corporation Mi Monitor", mode = "highrr", position = "auto-right", scale = 1 })

    -- Workspace pinning: 1 lands on the Samsung, 2 on the Xiaomi
    hl.workspace_rule({ workspace = "1", monitor = "desc:Samsung Electric Company Odyssey G80SH", default = true })
    hl.workspace_rule({ workspace = "2", monitor = "desc:Xiaomi Corporation Mi Monitor", default = true })

    -----------------
    -- AUTOSTART ----
    -----------------
    hl.on("hyprland.start", function()
      -- expose session env to dbus/systemd (portals etc.)
      hl.exec_cmd("dbus-update-activation-environment --systemd DISPLAY HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
      -- start the shell directly (graphical-session.target doesn't stay active in plain sessions)
      hl.exec_cmd("systemctl --user start caelestia.service")
    end)

    ---------------------
    -- LOOK AND FEEL ----
    ---------------------
    hl.config({
      general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
      },
      decoration = {
        rounding = 8, -- slight corner rounding on window tiles
      },
      input = {
        kb_layout = "us",
        follow_mouse = 1,
      },
      -- 240 Hz flicker fix (Caelestia FAQ): if you ever see flicker, add:
      -- misc = { vrr = 0 },
    })

    -------------------
    -- KEYBINDINGS ----
    -------------------
    -- every bind carries a description — run `shortcuts` in a terminal to list them
    local mod = "SUPER"

    -- must-haves
    hl.bind(mod .. " + T", hl.dsp.exec_cmd("ghostty"), { description = "Terminal (ghostty)" })
    hl.bind(mod .. " + W", hl.dsp.exec_cmd("firefox"), { description = "Browser (firefox)" })
    hl.bind(mod .. " + E", hl.dsp.exec_cmd("ghostty -e yazi"), { description = "File manager (yazi)" })
    hl.bind(mod .. " + C", hl.dsp.exec_cmd("code"), { description = "VS Code" })
    hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd("caelestia shell drawers toggle launcher"), { description = "App launcher (caelestia)" })
    hl.bind(mod .. " + D", hl.dsp.exec_cmd("caelestia shell drawers toggle launcher"), { description = "App launcher (caelestia)" })

    -- window basics
    hl.bind(mod .. " + Q", hl.dsp.window.close(), { description = "Close window" })
    hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), { description = "Maximize (fills workspace, keeps bars/gaps)" })
    hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })

    -- focus (vim keys)
    hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }), { description = "Focus window left" })
    hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }), { description = "Focus window down" })
    hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }), { description = "Focus window up" })
    hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }), { description = "Focus window right" })

    -- screenshot / screen-record picker (snip area, fullscreen, or record)
    hl.bind("Print", hl.dsp.exec_cmd("caelestia shell picker open"), { description = "Screenshot / record picker" })
    hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("caelestia shell picker open"), { description = "Screenshot / record picker" })
    -- the NuPhy screen button sends SUPER+SHIFT+4 (macOS screenshot combo) in
    -- Mac mode; the workspace-4 move bind is skipped in the loop below
    hl.bind(mod .. " + SHIFT + 4", hl.dsp.exec_cmd("caelestia shell picker open"), { description = "Screenshot / record picker (NuPhy screen key)" })

    -- move windows
    hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }), { description = "Move window left" })
    hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }), { description = "Move window down" })
    hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }), { description = "Move window up" })
    hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }), { description = "Move window right" })

    -- workspaces 1-10 (0 = 10)
    -- NOTE: SUPER+SHIFT+4 is reserved for the screenshot picker above (the NuPhy
    -- screen key sends it), so move-to-workspace-4 intentionally has no bind.
    for i = 1, 10 do
      local key = i % 10
      hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Focus workspace " .. i })
      if i ~= 4 then
        hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { description = "Move window to workspace " .. i })
      end
    end

    -- move/resize windows with mouse drag
    hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window (left mouse)" })
    hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window (right mouse)" })

    -- volume keys
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, description = "Volume up" })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true, description = "Volume down" })
    hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true, description = "Mute toggle" })
  '';

  # ---------- Shell: zsh + powerlevel10k ----------
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 50000;
      save = 50000;
      extended = true;           # timestamps in history
      share = true;              # shared across terminals
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;        # commands starting with a space stay out of history
      expireDuplicatesFirst = true;
    };

    # Powerlevel10k theme (settings live in ~/.config/zsh/p10k.zsh)
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        # Tab opens an fzf picker with candidates + previews instead of dumb cycling
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];

    shellAliases = {
      ll = "eza -l --icons";
      la = "eza -la --icons";
      lt = "eza --tree --icons";
      cat = "bat --paging=never"; # bat instead of cat (plain `command cat` still there)
      extract = "ouch decompress"; # extract <any archive>
      top = "btop";
      du = "dust";
      df = "duf";
      lg = "lazygit";
      ".." = "cd ..";
      "..." = "cd ../..";
      ports = "ss -tulpn";        # what's listening on this box
      myip = "curl -s ifconfig.me";
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#nixos";
      update = "nix flake update --flake ~/nixos-config && rebuild";
      cleanup = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
      vi = "nvim";
      vim = "nvim";
    };

    initContent = lib.mkMerge [
      # Instant prompt must run before anything that prints output
      (lib.mkBefore ''
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')
      ''
        # Powerlevel10k settings: your own `p10k configure` result (~/.p10k.zsh)
        # wins; otherwise fall back to the hand-tuned nix-managed config
        if [[ -f ~/.p10k.zsh ]]; then
          source ~/.p10k.zsh
        else
          source ~/.config/zsh/p10k.zsh
        fi

        # Case-insensitive tab completion
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

        # Classic arrow-key completion table (fallback where fzf-tab doesn't trigger)
        zstyle ':completion:*' menu select

        # fzf-tab previews: dirs list with eza, files preview with bat
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
        zstyle ':fzf-tab:complete:*:*' fzf-preview 'if [[ -d $realpath ]]; then eza -1 --color=always $realpath; elif [[ -f $realpath ]]; then bat --color=always --style=numbers --line-range=:200 -- $realpath; fi'

        # Type a prefix, press Up/Down → history search filtered by that prefix
        autoload -U up-line-or-beginning-search down-line-or-beginning-search
        zle -N up-line-or-beginning-search
        zle -N down-line-or-beginning-search
        bindkey "^[[A" up-line-or-beginning-search
        bindkey "^[[B" down-line-or-beginning-search

        # ESC ESC — toggle `sudo ` in front of the command (oh-my-zsh sudo plugin)
        sudo-command-line() {
          [[ -z $BUFFER ]] && zle up-history
          if [[ $BUFFER == sudo\ * ]]; then
            LBUFFER="''${LBUFFER#sudo }"
          else
            LBUFFER="sudo $LBUFFER"
          fi
        }
        zle -N sudo-command-line
        bindkey '\e\e' sudo-command-line

        setopt AUTO_CD              # `dir` works like `cd dir`
        setopt INTERACTIVE_COMMENTS # allow # comments on the command line
      ''
    ];
  };

  xdg.configFile."zsh/p10k.zsh".source = ./p10k.zsh;

  # ---------- Better commands (modern CLI stack) ----------
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.bat.enable = true;

  programs.fzf = {
    enable = true;
    enableZshIntegration = true; # Ctrl+R history, Ctrl+T files, Alt+C cd
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ]; # `cd` learns your frecent directories
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true; # caches nix shells per-project via .envrc
  };

  programs.tmux = {
    enable = true;
    mouse = true;
    keyMode = "vi";
    baseIndex = 1;
    newSession = true; # attach to an existing session instead of erroring
    terminal = "tmux-256color";
  };

  # ---------- Git / GitHub ----------
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "hravid";
        # TODO: use your GitHub noreply email (GitHub → Settings → Emails)
        email = "hravid@users.noreply.github.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true; # `git push` on a new branch just works
      fetch.prune = true;
      diff.colorMoved = "zebra";
      alias = {
        st = "status -sb";
        lg = "log --graph --oneline --decorate --all";
        undo = "reset --soft HEAD~1";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true; # git diffs with line numbers + syntax highlighting
    options = {
      navigate = true;
      line-numbers = true;
    };
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true; # git over HTTPS uses `gh auth token`
  };

  # ---------- Apps ----------
  # neovim is a plain package on purpose: LazyVim owns ~/.config/nvim as a
  # normal writable dir (lazy.nvim manages its own plugins). Using
  # programs.neovim would generate an init.lua that clobbers LazyVim's.

  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font"; # required for p10k glyphs
      font-size = 13;
      background-opacity = 0.85;
      mouse-hide-while-typing = true;
      # terminal compatibility: every server/tool knows xterm-256color,
      # unlike xterm-ghostty (which breaks ssh/curses apps on remote hosts)
      term = "xterm-256color";
      copy-on-select = "clipboard"; # select text = it's on the clipboard
      shell-integration = "detect"; # OSC133 prompt marks, sudo/ssh integration
      # theme is managed by `caelestia theme` once you're in
    };
  };

  programs.yazi.enable = true;

  # fuzzel kept as a fallback launcher — Super+Space now opens Caelestia's launcher
  programs.fuzzel.enable = true;

  home.packages = with pkgs; [
    firefox
    brave
    vscode
    spotify
    discord
    obsidian
    remmina    # RDP / VNC / SSH remote desktop client
    proton-vpn # official Proton VPN app
    winbox     # MikroTik router management (native Qt app)
    neovim     # plain package — LazyVim owns ~/.config/nvim (see comment above)
    btop
    fastfetch
    nodejs_24 # runtime for npm-installed CLIs (kimi code)
    gcc         # C compiler/linker: nvim-treesitter parsers + rustup cargo linking
    tree-sitter # CLI for nvim-treesitter grammar installs
    # NOTE: rust toolchain comes from rustup (~/.cargo/bin), not nixpkgs —
    # don't add rustc/cargo here or they shadow each other.

    # --- modern CLI replacements / better commands ---
    ripgrep    # rg  — much faster grep
    fd         # much friendlier find
    sd         # simpler sed
    dust       # du with a tree overview
    duf        # df that humans can read
    procs      # modern ps
    hyperfine  # benchmark commands
    tokei      # count lines of code per language
    tealdeer   # tldr — practical man pages
    jq         # JSON swiss army knife
    yq-go      # same for YAML
    xh         # friendly HTTP client (httpie-style)
    file
    unzip
    zip
    p7zip
    ouch       # one-liner extractor: `ouch d <any archive>` (zip/tar.*/7z/...)
    unrar      # rar archives (ouch can't do those)
    lazygit    # TUI for git

    # `shortcuts` — printable cheat sheet of all live Hyprland keybinds
    (pkgs.writeShellScriptBin "shortcuts" ''
      hyprctl binds -j | jq -r 'def m: (if .modmask % 128 >= 64 then ["SUPER"] else [] end) + (if .modmask % 2 == 1 then ["SHIFT"] else [] end) + (if .modmask % 8 >= 4 then ["CTRL"] else [] end) + (if .modmask % 16 >= 8 then ["ALT"] else [] end); .[] | select(.description != "") | "\((m + [.key]) | join(" + "))  →  \(.description)"' | sort
    '')

    # `pimager` — rpi-imager 2.x must run as root. sudo leaks DISPLAY=:0 into the
    # root env, which makes Qt pick xcb and abort on missing X auth — force
    # Wayland with an absolute socket path instead.
    (pkgs.writeShellScriptBin "pimager" ''
      exec sudo env QT_QPA_PLATFORM=wayland WAYLAND_DISPLAY="/run/user/$(id -u)/$WAYLAND_DISPLAY" rpi-imager "$@"
    '')

    # --- security research essentials ---
    nmap
    tcpdump
    binwalk    # firmware/binary analysis
    radare2    # reversing (r2)
    gdb        # debugger (add gef/pwndbg later if you want)
    ghidra     # NSA's decompiler GUI
    (python3.withPackages (ps: with ps; [ pwntools requests ipython pynvim ]))
    # wireshark/tshark is installed system-wide with capture permissions
  ];

  # user-level tool bins (npm global prefix, kimi installer, rustup/cargo)
  home.sessionPath = [ "$HOME/.npm-global/bin" "$HOME/.kimi-code/bin" "$HOME/.cargo/bin" ];
}
