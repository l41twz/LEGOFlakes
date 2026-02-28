{
  pkgs,
  modulesPath,
  lib,
  config,
  ...
}:
let
  # Carrega secrets se o arquivo existir
  secrets =
    if builtins.pathExists ./secrets/gemini.nix then
      import ./secrets/gemini.nix
    else
      { gemini_api_key = "GEMINI_API_KEY_PLACEHOLDER"; };
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # Basic settings
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # ISO Customization
  isoImage.squashfsCompression = "zstd";

  # Networking
  networking.hostName = "NixBooterGEMINI";
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  # Time and Locale
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };
  console.keyMap = "br-abnt2";

  # Services
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  # No GUI
  services.xserver.enable = false;

  # Set Nushell as default shell
  users.defaultUserShell = pkgs.nushell;

  # Set Micro as default editor
  environment.variables = {
    EDITOR = "micro";
    VISUAL = "micro";
  };

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    initialPassword = lib.mkForce "nixos";
    initialHashedPassword = lib.mkForce null;
    shell = pkgs.nushell;
  };

  # Autologin scenario customization
  services.getty.autologinUser = lib.mkForce "nixos";
  services.getty.greetingLine = lib.mkForce "";
  services.getty.helpLine = lib.mkForce "";

  # Package Selection
  environment.systemPackages = with pkgs; [
    # Core & Shell
    nushell
    nushellPlugins.formats
    nushellPlugins.highlight

    # Modern CLI Tools
    dust
    eza
    fd
    ripgrep
    rustscan
    macchina
    systemctl-tui
    bottom
    bat
    delta
    amfora # Browser Gemini
    yazi # File Manager
    zellij # Multiplexer
    devenv # Development Environment Manager
    zoxide # Smart cd
    fzf # Fuzzy finder
    starship # Modern prompt
    helix # Core Editor
    git
    curl
    jq
    pciutils
    usbutils
    disko
    nil # LSP for Nix
    nixpkgs-fmt # Formatter for Nix
    go # Go Language
    gum # charmbracelet tools
    micro # text editor

    # Scripts como pacotes (Mais robusto)
    (pkgs.writeTextFile {
      name = "gemini";
      destination = "/bin/gemini";
      executable = true;
      text = ''
        #!${pkgs.nushell}/bin/nu
        def main [pergunta: string] {
          let api_key = "${secrets.gemini_api_key}"
          if ($api_key == "GEMINI_API_KEY_PLACEHOLDER") {
            print "Erro: GEMINI_API_KEY não configurada."
            return
          }

          let modelos = ["gemini-2.5-flash-lite", "gemini-2.5-flash", "gemini-3-flash"]
          let body = { contents: [{ parts: [{ text: $pergunta }] }] } | to json

          for modelo in $modelos {
            let url = $"https://generativelanguage.googleapis.com/v1beta/models/($modelo):generateContent?key=($api_key)"
            let response = (curl -s -X POST $url -H "Content-Type: application/json" -d $body | from json)
            
            if ($response | get -o error | is-not-empty) {
              let msg = ($response.error.message | str downcase)
              if ($msg =~ "quota" or $msg =~ "limit" or $msg =~ "exhausted") {
                print $"Aviso: Quota excedida para ($modelo). Tentando próximo modelo..."
                continue
              }
              print $"Erro no modelo ($modelo): ($response.error.message)"
              return
            }
            
            print ($response.candidates.0.content.parts.0.text)
            return
          }
          print "Erro: Quota esgotada em todos os modelos disponíveis (2.5 Flash Lite, 2.5 Flash e 3 Flash)."
        }
      '';
    })

    (pkgs.writeTextFile {
      name = "install-disko";
      destination = "/bin/install-disko";
      executable = true;
      text = ''
        #!${pkgs.nushell}/bin/nu
        def main [] {
          print "Iniciando instalação com Disko..."
          nix run github:nix-community/disko -- --mode disko /etc/disko.nix
        }
      '';
    })

    (pkgs.writeTextFile {
      name = "generate-config";
      destination = "/bin/generate-config";
      executable = true;
      text = ''
        #!${pkgs.nushell}/bin/nu
        def main [] {
          print "Gerando configurações iniciais em /mnt/etc/nixos..."
          mkdir /mnt/etc/nixos
          nixos-generate-config --root /mnt
        }
      '';
    })

    (pkgs.writeTextFile {
      name = "yzx";
      destination = "/bin/yzx";
      executable = true;
      text = ''
        #!${pkgs.nushell}/bin/nu
        def main [subcommand?: string] {
          if ($subcommand == "launch") {
             # Lógica para lançar o Yazelix (Zellij com layout)
             # Por enquanto lança o Zellij padrão
             zellij
          } else {
             print "Uso: yzx launch"
             print "Iniciando Zellij..."
             zellij
          }
        }
      '';
    })

    (pkgs.writeTextFile {
      name = "clonelegoflakes";
      destination = "/bin/clonelegoflakes";
      executable = true;
      text = ''
        #!${pkgs.nushell}/bin/nu
        def main [] {
          print "Clonando LEGOFlakes..."
          git clone https://github.com/l41twz/LEGOFlakes.git ($env.HOME + "/LEGOFlakes")
          cd ($env.HOME + "/LEGOFlakes")
          print "Compilando..."
          $env.CGO_ENABLED = "0"
          go build -o lego-tui ./cmd/lego-tui
          print "Pronto! Execute 'legoflakes' para iniciar."
        }
      '';
    })

    (pkgs.writeTextFile {
      name = "legoflakes";
      destination = "/bin/legoflakes";
      executable = true;
      text = ''
        #!${pkgs.nushell}/bin/nu
        def main [] {
          let lego_path = ($env.HOME + "/LEGOFlakes/lego-tui")
          if ($lego_path | path exists) {
            cd ($env.HOME + "/LEGOFlakes")
            ./lego-tui
          } else {
            print "Erro: LEGOFlakes não encontrado. Execute 'clonelegoflakes' primeiro."
          }
        }
      '';
    })
  ];

  # Pre-generate Nushell Init Scripts (Fixes 'source' parse-time error)
  environment.etc."nushell/zoxide.nu".source =
    pkgs.runCommand "zoxide-init" { nativeBuildInputs = [ pkgs.zoxide ]; }
      ''
        zoxide init nushell > $out
      '';

  environment.etc."nushell/starship.nu".source =
    pkgs.runCommand "starship-init" { nativeBuildInputs = [ pkgs.starship ]; }
      ''
        starship init nushell > $out
      '';

  # Nushell Configuration Files
  environment.etc."nushell/env.nu".text = ''
    $env.config.show_banner = false
    $env.GEMINI_API_KEY = "${secrets.gemini_api_key}"
  '';

  environment.etc."nushell/config.nu".text = ''
    # Vibrant Ink Theme for Nushell
    let vibrant_ink_theme = {
        binary: '#9933cc'
        block: '#44b4cc'
        cell-path: '#f5f5f5'
        closure: '#44b4cc'
        custom: '#e5e5e5'
        duration: '#ffcc00'
        float: '#ff0000'
        glob: '#e5e5e5'
        int: '#9933cc'
        list: '#44b4cc'
        nothing: '#ff6600'
        range: '#ffcc00'
        record: '#44b4cc'
        string: '#ccff04'
        bool: {|| if $in { '#00ffff' } else { '#ffcc00' } }
        filesize: {|e|
            if $e == 0b {
                '#f5f5f5'
            } else if $e < 1mb {
                '#44b4cc'
            } else {{ fg: '#44b4cc' }}
        }
        shape_and: { fg: '#9933cc' attr: 'b' }
        shape_binary: { fg: '#9933cc' attr: 'b' }
        shape_block: { fg: '#44b4cc' attr: 'b' }
        shape_bool: '#00ffff'
        shape_closure: { fg: '#44b4cc' attr: 'b' }
        shape_custom: '#ccff04'
        shape_datetime: { fg: '#44b4cc' attr: 'b' }
        shape_directory: '#44b4cc'
        shape_external: '#44b4cc'
        shape_external_resolved: '#00ffff'
        shape_externalarg: { fg: '#ccff04' attr: 'b' }
        shape_filepath: '#44b4cc'
        shape_flag: { fg: '#44b4cc' attr: 'b' }
        shape_float: { fg: '#ff0000' attr: 'b' }
        shape_garbage: { fg: '#FFFFFF' bg: '#FF0000' attr: 'b' }
        shape_glob_interpolation: { fg: '#44b4cc' attr: 'b' }
        shape_globpattern: { fg: '#44b4cc' attr: 'b' }
        shape_int: { fg: '#9933cc' attr: 'b' }
        shape_internalcall: { fg: '#44b4cc' attr: 'b' }
        shape_keyword: { fg: '#9933cc' attr: 'b' }
        shape_list: { fg: '#44b4cc' attr: 'b' }
        shape_literal: '#44b4cc'
        shape_match_pattern: '#ccff04'
        shape_matching_brackets: { attr: 'u' }
        shape_nothing: '#ff6600'
        shape_operator: '#ffcc00'
        shape_or: { fg: '#9933cc' attr: 'b' }
        shape_pipe: { fg: '#9933cc' attr: 'b' }
        shape_range: { fg: '#ffcc00' attr: 'b' }
        shape_raw_string: { fg: '#e5e5e5' attr: 'b' }
        shape_record: { fg: '#44b4cc' attr: 'b' }
        shape_redirection: { fg: '#9933cc' attr: 'b' }
        shape_signature: { fg: '#ccff04' attr: 'b' }
        shape_string: '#ccff04'
        shape_string_interpolation: { fg: '#44b4cc' attr: 'b' }
        shape_table: { fg: '#44b4cc' attr: 'b' }
        shape_vardecl: { fg: '#44b4cc' attr: 'u' }
        shape_variable: '#9933cc'
        empty: '#44b4cc'
        header: { fg: '#ccff04' attr: 'b' }
        hints: '#555555'
        leading_trailing_space_bg: { attr: 'n' }
        row_index: { fg: '#ccff04' attr: 'b' }
        search_result: { fg: '#ff6600' bg: '#f5f5f5' }
        separator: '#f5f5f5'
    }

    $env.config.color_config = $vibrant_ink_theme
    $env.config.show_banner = false

    # Auto-start Yazelix (Zellij) logic
    #if ($nu.is-interactive) and ($env.ZELLIJ? == null) {
    #   print "Iniciando Yazelix (IDE Mode)..."
    #   exec zellij --layout default --config /etc/zellij/config.kdl
    #}

    # Keybindings for F2 and F3
    $env.config.keybindings = [
      {
        name: tools_menu
        modifier: none
        keycode: f2
        mode: [emacs, vi_normal, vi_insert]
        event: { send: executehostcommand cmd: "tools_menu" }
      }
      {
        name: shortcuts_menu
        modifier: none
        keycode: f3
        mode: [emacs, vi_normal, vi_insert]
        event: { send: executehostcommand cmd: "shortcuts_menu" }
      }
    ]

    # --- Modular Menu System ---

    def banner [] {
      let label = "${config.system.nixos.label}"
      print $"(ansi cyan_bold)╔════════════════════════════════════════════════════════════════╗(ansi reset)"
      print $"(ansi cyan_bold)║(ansi yellow_bold) 🚀 NixBooterGEMINI ($label)  ISO Final [v9.3] 📦 (ansi cyan_bold)║(ansi reset)"
      print $"(ansi cyan_bold)╚════════════════════════════════════════════════════════════════╝(ansi reset)"
      print $"(ansi blue_italic)Ajuda: [F2] Ferramentas | [F3] Atalhos | [Ctrl+o] Sessão(ansi reset)"
      print ""
    }

    def tools_menu [] {
      banner
      print $"(ansi green)🛠️  FERRAMENTAS DO SISTEMA:(ansi reset)"
      print ""
      print $"# --- SISTEMA E EXPLORAÇÃO ---             # --- MONITORAMENTO E REDE ---"
      print $"dust            # Espaço em disco [du]    macchina         # Info do sistema/hardware"
      print $"eza             # Substituto moderno ls   systemctl-tui    # Gestão visual do systemd"
      print $"fd              # Busca rápida arquivos   bottom           # Monitor de recursos [btm]"
      print $"ripgrep         # Busca texto em arquivos rustscan         # Scanner de portas veloz"
      print $"yazi            # File manager TUI        amfora           # Browser protocolo Gemini"
      print $"zoxide          # cd inteligente"
      print ""
      print "# --- EDIÇÃO E PROMPT ---                  # --- UTILITÁRIOS E NIX ---"
      print "bat              # cat com sintaxe/git     disko            # Particionamento via Nix"
      print "delta            # Visualizador de diff    nil              # LSP para linguagem Nix"
      print "helix            # Editor modal moderno    nixpkgs-fmt      # Formatador de código Nix"
      print "starship         # Prompt customizável     devenv           # Ambientes de dev isolados"
      print "zellij           # Multiplexador terminal  fzf              # Buscador difuso [fuzzy]"
      print ""
      print "# --- CORE E HARDWARE ---                  # --- DADOS E WEB ---"
      print "git              # Controle de versão      jq               # Processador JSON via CLI"      
      print "curl             # Transferência via URL   pciutils         # Lista dispositivos PCI"
      print "usbutils         # Lista dispositivos USB"
      print ""
      print ">>> LEGOFlakes - Para instalar: [clonelegoflakes], executar: [legoflakes] <<<"
      print ""
      print "Yazelix - Para iniciar a sua 'IDE terminal' basta rodar o comando : [exec zellij]"
      
    }

    def shortcuts_menu [] {
      banner
      print $"(ansi green)⌨️  ATALHOS [Alt-Centric Mode]:(ansi reset)"
      print ""
      print $"  (ansi yellow)Alt + n(ansi reset)    -> Novo Painel"
      print $"  (ansi yellow)Alt + q(ansi reset)    -> Sair [Quit]"
      print $"  (ansi yellow)Alt + d(ansi reset)    -> Detach Session"
      print $"  (ansi yellow)Alt + h(ansi reset)    -> Mover Foco Esquerda"
      print $"  (ansi yellow)Alt + l(ansi reset)    -> Mover Foco Direita"
      print $"  (ansi yellow)Alt + j(ansi reset)    -> Mover Foco Baixo"
      print $"  (ansi yellow)Alt + k(ansi reset)    -> Mover Foco Cima"
      print $"  (ansi yellow)Alt + r(ansi reset)    -> Modo Resize"
      print $"  (ansi yellow)Alt + p(ansi reset)    -> Modo Pane"
      print $"  (ansi yellow)Alt + t(ansi reset)    -> Modo Tab"
      print $"  (ansi yellow)Alt + s(ansi reset)    -> Modo Scroll"
      print ""
      print $"  (ansi cyan)F2(ansi reset)   -> Menu Ferramentas"
      print $"  (ansi cyan)F3(ansi reset)   -> Menu Atalhos [Esta tela]"
      print ""
    }

    def welcome_screen [] {
      banner
      print $"(ansi green)Sistema pronto. Use os atalhos acima para navegar.(ansi reset)"
    }

    # Executar saudação if it's an interactive shell
    if ($nu.is-interactive) {
       welcome_screen
    }

    # Aliases
    alias ll = eza -l --icons
    alias la = eza -la --icons
    alias tree = eza --tree --icons
    alias sys = systemctl-tui
    alias top = btm
    alias yzx = yzx launch

    # Static sourcing (Generated at build time)
    source /etc/nushell/zoxide.nu
    source /etc/nushell/starship.nu
  '';

  # Remove old /etc/nushell files as we're using the module now

  # Starship Configuration (Keep in skel as fallthrough or local override)
  environment.etc."skel/.config/starship.toml".text = ''
    add_newline = false
    format = "|$username| $directory$git_branch$git_status$nix_shell$character"

    [username]
    show_always = true
    format = "[$user]($style)"
    style_user = "bold yellow"

    [directory]
    style = "bold blue"
  '';

  # Embed scripts
  environment.etc."disko.nix".source = ./disko.nix;

  # Zellij Configuration (Global F2 Binding)
  environment.etc."zellij/config.kdl".text = ''
        keybinds {
          normal clear-defaults=true {
            bind "Alt q" { Quit; }
            bind "Alt d" { Detach; }
            bind "Alt p" { SwitchToMode "pane"; }
            bind "Alt r" { SwitchToMode "resize"; }
            bind "Alt t" { SwitchToMode "tab"; }
            bind "Alt s" { SwitchToMode "scroll"; }
            bind "Alt m" { SwitchToMode "move"; }
            bind "Alt n" { NewPane; }
            bind "Alt h" { MoveFocusOrTab "Left"; }
            bind "Alt l" { MoveFocusOrTab "Right"; }
            bind "Alt j" { MoveFocus "Down"; }
            bind "Alt k" { MoveFocus "Up"; }
            bind "Alt =" { Resize "Increase"; }
            bind "Alt +" { Resize "Increase"; }
            bind "Alt -" { Resize "Decrease"; }
            bind "Ctrl 1" { WriteChars "tools_menu\r"; }
            bind "Ctrl 2" { WriteChars "shortcuts_menu\r"; }
            }
            pane clear-defaults=true {
              bind "Enter" "Esc" "Space" { SwitchToMode "normal"; }
              bind "h" "Left" { NewPane "Left"; }
              bind "l" "Right" { NewPane "Right"; }
              bind "j" "Down" { NewPane "Down"; }
              bind "k" "Up" { NewPane "Up"; }
              bind "Alt h" "Left" { MoveFocus "Left"; }
              bind "Alt l" "Right" { MoveFocus "Right"; }
              bind "Alt j" "Down" { MoveFocus "Down"; }
              bind "Alt k" "Up" { MoveFocus "Up"; }
              bind "p" { SwitchFocus; }
              bind "n" { NewPane; }
              bind "x" { CloseFocus; }
              bind "f" { ToggleFocusFullscreen; }
              bind "z" { TogglePaneFrames; }
              bind "Ctrl 1" { SwitchToMode "normal"; WriteChars "tools_menu\r"; }
              bind "Ctrl 2" { SwitchToMode "normal"; WriteChars "shortcuts_menu\r"; }
              }
              tab clear-defaults=true {
                bind "Enter" "Esc" "Space" { SwitchToMode "normal"; }
                bind "h" "Left" { GoToPreviousTab; }
                bind "l" "Right" { GoToNextTab; }
                bind "n" { NewTab; }
                bind "x" { CloseTab; }
                bind "s" { ToggleActiveSyncTab; }
                bind "Alt h" { MoveFocus "Left"; }
                bind "Alt l" { MoveFocus "Right"; }
                bind "Alt j" { MoveFocus "Down"; }
                bind "Alt k" { MoveFocus "Up"; }
                bind "1" { GoToTab 1; }
                bind "2" { GoToTab 2; }
                bind "3" { GoToTab 3; }
                bind "4" { GoToTab 4; }
                bind "5" { GoToTab 5; }
                bind "6" { GoToTab 6; }
                bind "7" { GoToTab 7; }
                bind "8" { GoToTab 8; }
                bind "9" { GoToTab 9; }
                bind "Tab" { ToggleTab; }
                bind "Ctrl 1" { SwitchToMode "normal"; WriteChars "tools_menu\r"; }
                bind "Ctrl 2" { SwitchToMode "normal"; WriteChars "shortcuts_menu\r"; }
                }
                resize clear-defaults=true {
                  bind "Enter" "Esc" "Space" { SwitchToMode "normal"; }
                  bind "h" "Left" { Resize "Left"; }
                  bind "j" "Down" { Resize "Down"; }
                  bind "k" "Up" { Resize "Up"; }
                  bind "l" "Right" { Resize "Right"; }
                  bind "Alt =" { Resize "Increase"; }
                  bind "Alt +" { Resize "Increase"; }
                  bind "Alt -" { Resize "Decrease"; }
                  bind "Alt n" { NewPane; }
                  bind "Alt h" { MoveFocus "Left"; }
                  bind "Alt l" { MoveFocus "Right"; }
                  bind "Alt j" { MoveFocus "Down"; }
                  bind "Alt k" { MoveFocus "Up"; }
                  bind "Ctrl 1" { SwitchToMode "normal"; WriteChars "tools_menu\r"; }
                  bind "Ctrl 2" { SwitchToMode "normal"; WriteChars "shortcuts_menu\r"; }
                  }
                  move clear-defaults=true {
                    bind "Enter" "Esc" "Space" { SwitchToMode "normal"; }
                    bind "h" "Left" { MovePane "Left"; }
                    bind "j" "Down" { MovePane "Down"; }
                    bind "k" "Up" { MovePane "Up"; }
                    bind "l" "Right" { MovePane "Right"; }
                    bind "Alt n" { NewPane; }
                    bind "Alt h" { MoveFocus "Left"; }
                    bind "Alt l" { MoveFocus "Right"; }
                    bind "Alt j" { MoveFocus "Down"; }
                    bind "Alt k" { MoveFocus "Up"; }
                    bind "Ctrl 1" { SwitchToMode "normal"; WriteChars "tools_menu\r"; }
                    bind "Ctrl 2" { SwitchToMode "normal"; WriteChars "shortcuts_menu\r"; }
                    }
                    scroll clear-defaults=true {
                      bind "e" { EditScrollback; SwitchToMode "normal"; }
                      bind "Enter" "Esc" { SwitchToMode "normal"; }
                      bind "Alt c" { ScrollToBottom; SwitchToMode "normal"; }
                      bind "j" "Down" { ScrollDown; }
                      bind "k" "Up" { ScrollUp; }
                      bind "Alt f" "PageDown" "Right" "l" { PageScrollDown; }
                      bind "Alt b" "PageUp" "Left" "h" { PageScrollUp; }
                      bind "d" { HalfPageScrollDown; }
                      bind "u" { HalfPageScrollUp; }
                      bind "Alt h" { MoveFocus "Left"; }
                      bind "Alt l" { MoveFocus "Right"; }
                      bind "Alt j" { MoveFocus "Down"; }
                      bind "Alt k" { MoveFocus "Up"; }
                      bind "s" { SwitchToMode "entersearch"; SearchInput 0; }
                      bind "Ctrl 1" { SwitchToMode "normal"; WriteChars "tools_menu\r"; }
                      bind "Ctrl 2" { SwitchToMode "normal"; WriteChars "shortcuts_menu\r"; }
                      }
                      search clear-defaults=true {
                        bind "Alt s" "Enter" "Esc" "Space" { SwitchToMode "normal"; }
                        bind "s" { SwitchToMode "entersearch"; SearchInput 0; }
                        bind "n" { Search "Down"; }
                        bind "p" { Search "Up"; }
                        bind "c" { SearchToggleOption "CaseSensitivity"; }
                        bind "w" { SearchToggleOption "Wrap"; }
                        bind "o" { SearchToggleOption "WholeWord"; }
                        bind "Alt h" "Alt Left" { MoveFocusOrTab "Left"; }
                        bind "Alt l" "Alt Right" { MoveFocusOrTab "Right"; }
                        bind "Alt j" "Alt Down" { MoveFocus "Down"; }
                        bind "Alt k" "Alt Up" { MoveFocus "Up"; }
                        bind "Ctrl 1" { SwitchToMode "normal"; WriteChars "tools_menu\r"; }
                        bind "Ctrl 2" { SwitchToMode "normal"; WriteChars "shortcuts_menu\r"; }
                        }
                        entersearch clear-defaults=true {
                          bind "Enter" { SwitchToMode "search"; }
                          bind "Alt c" "Esc" { SearchInput 27; SwitchToMode "scroll"; }
                          bind "Alt h" "Alt Left" { MoveFocusOrTab "Left"; }
                          bind "Alt l" "Alt Right" { MoveFocusOrTab "Right"; }
                          bind "Alt j" "Alt Down" { MoveFocus "Down"; }
                          bind "Alt k" "Alt Up" { MoveFocus "Up"; }
                          bind "Ctrl 1" { SwitchToMode "normal"; WriteChars "tools_menu\r"; }
                          bind "Ctrl 2" { SwitchToMode "normal"; WriteChars "shortcuts_menu\r"; }
                          }
        locked clear-defaults=true {}
        renamepane clear-defaults=true {}
        renametab clear-defaults=true {}
        session clear-defaults=true {
            bind "Ctrl 1" { SwitchToMode "normal"; WriteChars "tools_menu\r"; }
            bind "Ctrl 2" { SwitchToMode "normal"; WriteChars "shortcuts_menu\r"; }
            bind "Enter" "Esc" "Space" { SwitchToMode "normal"; }
            bind "d" { Detach; }
        }
        tmux clear-defaults=true {}
    }

    on_force_close "quit"
    simplified_ui false
    default_layout "default"
    pane_frames true
    mouse_mode true
    scroll_buffer_size 100000
  '';

  # Zellij layoutConfiguration
  environment.etc."zellij/layouts/default.kdl".text = ''
    layout {
        pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
        }
        pane split_direction="horizontal" size="70%" {
            pane command="yazi"
        }
        pane split_direction="horizontal" size="30%" {
            pane
        }
        pane size=2 borderless=true {
            plugin location="zellij:status-bar"
        }
    }
  '';

  # Helix Configuration
  environment.etc."skel/.config/helix/config.toml".text = ''
    theme = "base16_terminal"

      [ editor ]
      line-number = "relative"
    cursorline = true
    color-modes = true

    [editor.cursor-shape]
    insert = "bar"
    normal = "block"
    select = "underline"

    [languages.language.nix]
    formatter = { command = "nixpkgs-fmt" }
  '';

  # Activation scripts removed in favor of /etc/skel (FAILED - Reverting to Force Overwrite)
  system.activationScripts.forceNuConfig = {
    text = ''
      # AGGRESSIVE OVERWRITE
      # Nushell on LiveCD generates defaults at runtime. We must clobber them.
      mkdir -p /home/nixos/.config/nushell

      # Force copy from /etc to home, overwriting anything that exists
      cp -f /etc/nushell/config.nu /home/nixos/.config/nushell/config.nu
      cp -f /etc/nushell/env.nu /home/nixos/.config/nushell/env.nu

      # Ensure permissions
      chown -R 1000:100 /home/nixos/.config
      chmod -R 755 /home/nixos/.config
    '';
  };

  nixpkgs.config.allowUnfree = true;
}
