# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:
with pkgs;
let
  system = "x86_64-linux";
  # R-with-my-packages = rWrapper.override{ packages = with rPackages; [ ggplot2 dplyr xts ]; };
  # RStudio-with-my-packages = rstudioWrapper.override{ packages = with rPackages; [ ggplot2 dplyr xts ]; };
in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix = {
    # package = pkgs.nix_2_4; # Potential attributes are nix_2_x nixFlakes nixUnstable
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  nixpkgs.config = {
    packageOverrides = pkgs: {
      release2105 = import inputs.release2105 {
        config = config.nixpkgs.config;
        inherit system;
      };
      release2111 = import inputs.release2111 {
        config = config.nixpkgs.config;
        inherit system;
      };
      unstable = import inputs.unstable {
        config = config.nixpkgs.config;
        inherit system;
      };
      # unstable = import <nixos-unstable> {
      #   config = config.nixpkgs.config;
      # };
      # steam = pkgs.steam.override {
      #   nativeOnly = true;
      # };
    };
  };

  # Storage optimization.
  nix.settings.auto-optimise-store = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable NTFS-3G support
  boot.supportedFilesystems = [ "ntfs" ];

  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set users.
  users.users.ryan = {
    createHome = true;
    isNormalUser = true;
    extraGroups =
      [
        "wheel"
        "libvirtd"
        "qemu-libvirtd"
        "audio"
        "video"
        "networkmanager"
        "vglusers"
        "lxd"
        "docker"
      ];
    group = "users";
    home = "/home/ryan";
    uid = 1000;
  };
  users.users.rishindu = {
    createHome = true;
    isNormalUser = true;
    extraGroups =
      [
        "wheel"
        "libvirtd"
        "qemu-libvirtd"
        "audio"
        "video"
        "networkmanager"
        "vglusers"
        "lxd"
        "docker"
      ];
    group = "users";
    home = "/home/rishindu";
    uid = 1001;
  };

  # Set your time zone.
  time.timeZone = "Asia/Colombo";

  # Disable automatic refresh of ClamAV signatures database (do this manually).
  services.clamav = {
    daemon.enable = false;
    updater.enable = false;
  };

  # Comm utils
  # services.teamviewer.enable = false;

  # Enable virtualization.
  virtualisation.libvirtd.enable = true;
  boot.extraModprobeConfig = "options kvm_amd nested=1"; # Nested virtualization (requires AMD-V).
  virtualisation.lxd.enable = false;
  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
  };
  # boot.kernelModules = [ "kvm-amd" "kvm-intel" ]; # Only needed if kvm-amd/intel is not set in hardware-configuration.nix AFAIK.

  # Allow proprietary packages
  nixpkgs.config.allowUnfree = true; # Had to export bash env var for flakes since this didn't work
  nixpkgs.config.allowUnfreePredicate = (pkg: true);
  #   inputs.release2105.config.allowUnfree = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp34s0.useDHCP = true;
  networking.interfaces.wlp3s0f0u8.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Wi-Fi
  # networking.wireless.iwd.enable = true;
  networking.networkmanager = {
    # wifi.backend = "iwd";
    enable = true;
  };
  programs.nm-applet.enable = true;
  # programs.light.enable = true;
  programs.steam.enable = true;
  services.logmein-hamachi.enable = true;
  programs.haguichi.enable = true;

  # Hosts
  networking.extraHosts =
    ''
      127.0.0.1 codinghermit.net
    '';

  # programs.volctl.enable = true; # Invalid
  # networking.networkmanager.wifi.backend = "iwd";
  # networking.networkmanager.enable = true;

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Enable X11 forwarding.
  # Enable the OpenSSH daemon.
  # programs.ssh.setXAuthLocation = true;
  services.openssh.enable = true;
  services.openssh.settings.X11Forwarding = true;
  # services.openssh.startWhenNeeded = true;
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ 631 5901 80 443 ];

  # Enable K3s
  networking.firewall.allowedTCPPorts = [ 6443 ];
  # services.k3s.enable = false;
  # services.k3s.role = "server";
  # services.k3s.role = "agent";
  # services.k3s.extraFlags = toString [
  # "--kubelet-arg=v=4" # Optionally add additional args to k3s
  # "--no-deploy traefik --write-kubeconfig-mode 644 --node-name k3s-master-01"
  # ];

  # Enable NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      libGL
    ];
    setLdLibraryPath = true;
  };
  hardware.opengl.driSupport32Bit = true;
  # hardware.opengl.setLdLibraryPath = true;

  # Enable the Plasma 5 Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;
  # Enable dwm
  # services.xserver.windowManager.dwm.enable = true;

  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
    displayManager.defaultSession = "xfce";
  };

  services.gvfs = {
    enable = true;
    package = lib.mkForce pkgs.gnome3.gvfs;
  };

  # Misc services
  # services = {
  # fstrim.enable = true; # SSD only
  # openssh.enable = true; # Redundant
  # xserver.enable = true; # Redundant
  # compton.enable = true; # Consider picom instead
  # compton.shadow = true;
  # compton.inactiveOpacity = "0.8";
  # printing.enable = true; # Not needed
  # };

  # Enabke Iorri nix-shell extension daemon,
  # services.lorri.enable = true; # Make sure to run 'systemctl --user daemon-reload' or 'reboot' after this!

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull.override { bluetoothSupport = false; };
  # hardware.pulseaudio.package = pkgs.pulseaudioFull;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;
  nixpkgs.config.pulseaudio = true;
  hardware.pulseaudio.extraConfig = ''
    load-module module-combine-sink
    unload-module module-suspend-on-idle
  '';

  # security.rtkit.enable = true;
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  #   # If you want to use JACK applications, uncomment this
  #   jack.enable = true;

  #   config.pipewire = {
  #     "context.properties" = {
  #       "link.max-buffers" = 16;
  #       "log.level" = 2;
  #       "default.clock.rate" = 48000;
  #       "default.clock.quantum" = 128;
  #       "default.clock.min-quantum" = 128;
  #       "default.clock.max-quantum" = 128;
  #       "core.daemon" = true;
  #       "core.name" = "pipewire-0";
  #       "session.suspend-timeout-seconds" = 0;
  #     };
  #     "context.modules" = [
  #       {
  #         name = "libpipewire-module-rtkit";
  #         args = {
  #           "nice.level" = -15;
  #           "rt.prio" = 88;
  #           "rt.time.soft" = 200000;
  #           "rt.time.hard" = 200000;
  #         };
  #         flags = [ "ifexists" "nofail" ];
  #       }
  #       { name = "libpipewire-module-protocol-native"; }
  #       { name = "libpipewire-module-profiler"; }
  #       { name = "libpipewire-module-metadata"; }
  #       { name = "libpipewire-module-spa-device-factory"; }
  #       { name = "libpipewire-module-spa-node-factory"; }
  #       { name = "libpipewire-module-client-node"; }
  #       { name = "libpipewire-module-client-device"; }
  #       {
  #         name = "libpipewire-module-portal";
  #         flags = [ "ifexists" "nofail" ];
  #       }
  #       {
  #         name = "libpipewire-module-access";
  #         args = {};
  #       }
  #       { name = "libpipewire-module-adapter"; }
  #       { name = "libpipewire-module-link-factory"; }
  #       { name = "libpipewire-module-session-manager"; }
  #     ];
  #   };
  # };

  # Remove sound.enable or turn it off if you had it set previously, it seems to cause conflicts with pipewire
  #sound.enable = false;
  # rtkit is optional but recommended
  #security.rtkit.enable = true;
  #services.pipewire = {
  #  enable = true;
  #  alsa.enable = true;
  #  alsa.support32Bit = true;
  #  pulse.enable = true;
  # If you want to use JACK applications, uncomment this
  #jack.enable = true;
  #};

  # Enable Bluetooth
  hardware.bluetooth.enable = false;
  services.blueman.enable = false;

  # Paprefs fix.
  programs.dconf.enable = true; # + gnome3.dconf

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.jane = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  # };

  # Overlay setup
  # services.emacs.package = with pkgs; ((emacsPackagesFor emacsGcc).emacsWithPackages (epkgs: [
  # epkgs.emacspeak
  # ]));
  # services.emacs.enable = true; # Optional emacs daemon/server mode.

  # D-Bus
  # services.dbus.packages = with pkgs; [ gnome-keyring ];
  services.gnome.gnome-keyring.enable = true;

  # Database
  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql_14;
  services.postgresql.extraPlugins = with pkgs.postgresql_14.pkgs; [
    pgtap
    postgis
    timescaledb
    # age
  ];
  services.postgresql.authentication = lib.mkForce ''
    # Generated file; do not edit!
    # TYPE  DATABASE        USER            ADDRESS                 METHOD
    local   all             all                                     trust
    host    all             all             127.0.0.1/32            trust
    host    all             all             ::1/128                 trust
  '';

  #-------------------------------------------------------------------------
  # Enable redis service
  #-------------------------------------------------------------------------
  services.redis.servers."talos".enable = true;
  services.redis.servers."talos".port = 6379;

  # Mic
  programs.droidcam.enable = true;
  services.murmur.enable = true;
  services.avahi = {
    enable = true;
    #publish = {
    #  enable = true;
    #  address = true;
    #  workstation = true;
    #};
  };

  # Overlay configuration
  nixpkgs.overlays = [
    # (import (builtins.fetchGit {
    #   url = "https://github.com/nix-community/emacs-overlay.git";
    #   ref = "master";
    #   rev = "13bd8f5d68519898e403d3cab231281b1fbd0d71"; # change the revision as needed
    # }))

    # Wine
    (self: super: {
      wine = super.wineWowPackages.stableFull;
    })
    #(self: super: {
    #  winetricks = super.wine.wineWowPackages.stableFull;
    #})

    # dwm
    (self: super: {
      dwm = super.dwm.overrideAttrs (oa: rec {
        patches = [
          # (builtins.fetchurl https://example.com/patch2.patch)
          # ./path/to/my-dwm-patch.patch
          (super.fetchpatch {
            # url = "https://dwm.suckless.org/patches/systray/dwm-systray-6.3.diff";
            # sha256 = "1plzfi5l8zwgr8zfjmzilpv43n248n4178j98qdbwpgb4r793mdj";
            # url = "https://dwm.suckless.org/patches/systray/dwm-systray-6.0.diff";
            # sha256 = "1k95j0c9gzz15k0v307zlvkk3fbayb9kid68i27idawg2salrz54";
            url = "https://dwm.suckless.org/patches/systray/dwm-systray-6.3.diff";
            sha256 = "1plzfi5l8zwgr8zfjmzilpv43n248n4178j98qdbwpgb4r793mdj";
          })
          #(super.fetchpatch {
          # url = "https://dwm.suckless.org/patches/swaptags/dwm-swaptags-6.2.diff";
          # sha256 = "11f9c582a3xm6c7z4k7zmflisljmqbcihnzfkiz9r65m4089kv0g";
          #})
          (super.fetchpatch {
            url = "https://raw.githubusercontent.com/RyanCargan/dwm/main/patches/dwm-custom-6.3.diff";
            sha256 = "116jf166rv9w1qyg1d52sva8f1hzpg3lij9m16izz5s8y0742hy7";
          })
        ];
        # configFile = super.writeText "config.h" (builtins.readFile ./dwm-config.h);
        # postPatch = oa.postPatch or "" + "\necho 'Using own config file...'\n cp ${configFile} config.def.h";
      });
      st = super.st.overrideAttrs (oa: rec {
        # ligatures dependency
        # buildInputs = oa.buildInputs ++ [ harfbuzz ];
        patches = [
          # ./path/to/my-dwm-patch.patch
          # ligatures patch
          # (fetchpatch {
          #   url = "https://st.suckless.org/patches/ligatures/0.8.3/st-ligatures-20200430-0.8.3.diff";
          #   sha256 = "67b668c77677bfcaff42031e2656ce9cf173275e1dfd6f72587e8e8726298f09";
          # })
        ];
        # configFile = super.writeText "config.h" (builtins.readFile ./st-config.h);
        # postPatch = "${oa.postPatch}\ncp ${configFile} config.def.h\n";
      });
    })

    # nix-direnv
    (self: super: { nix-direnv = super.nix-direnv.override { enableFlakes = true; }; })

    # pulseaudio
    #(self: super: {
    #  pulseaudio = super.pulseaudio.overrideattrs (
    #    _: { nativebuildinputs = [ pkg-config meson ninja makewrapper perlpackages.perl perlpackages.xmlparser m4 ]
    #                            ++ lib.optionals stdenv.islinux [ glib ]
    #                            ++ lib.optional (bluetoothsupport && advancedbluetoothcodecs);}
    #  );
    #})
    #pulseaudio.overrideAttrs (prev: {
    #  nativeBuildInputs = utils.removePackagesByName prev.nativeBuildInputs [ wrapGAppsHook ];
    #})
  ];

  fonts.fonts = with pkgs; [
    source-code-pro
    liberation_ttf
  ];
  fonts.fontDir.enable = true;

  # environment.pathsToLink = [
  #  "/share/nix-direnv"
  # ];

  # environment.variables = {
  #  JAVA_HOME = "/nix/store/5j8rfb9qhiwlg73gskbndfwbr42dbk8j-adoptopenjdk-hotspot-bin-16.0.2"; # nix-store -q --outputs $(which java)
  # };

  #security.wrappers = {
  #  nethogs = {
  #    # setuid = true;
  #    owner = "root";
  #    group = "root";
  #    capabilities = "cap_net_admin+cap_net_raw";
  #    source = "${pkgs.nethogs}/bin/nethogs";
  #  };
  #};

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  environment.systemPackages = with pkgs; [
    vim
    wget
    firefox
    kate
    httrack
    silver-searcher
    btop
    ccache
    fzf
    fd
    ripgrep
    ripgrep-all
    git
    docker
    yt-dlp
    obs-studio
    gron
    go-org
    groff
    direnv
    elinks
    fbida
    texmacs
    ghostwriter
    ffmpeg
    paprefs
    gparted
    unetbootin
    audacity
    emscripten
    wasmer
    nvidia-docker
    pyspread
    inkscape
    neovim
    calibre
    root
    sageWithDoc
    nyxt
    nomacs
    maim
    yacreader
    tigervnc
    aria
    ghostscript
    nix-du
    zgrviewer
    graphviz
    google-chrome
    tor-browser-bundle-bin
    busybox

    # Virtualization
    (pkgs.stdenv.mkDerivation {
      name = "virtiofsd-link";
      buildCommand = ''
        mkdir -p $out/bin
        ln -s ${pkgs.qemu}/libexec/virtiofsd $out/bin/
      '';
    })
    remmina

    # Package packs
    # RStudio-with-my-packages

    # Flakes
    inputs.blender.packages.x86_64-linux.default
    inputs.poetry2nix.packages.x86_64-linux.poetry2nix
    release2105.dos2unix
    # release2105.google-chrome

    # nix-direnv
    direnv
    nix-direnv

    # Educational software
    anki-bin
    d2

    # Audio & video comms
    # droidcam
    (mumble.override { pulseSupport = true; })
    # murmur
    iproute2
    jq

    # Audio utils
    reaper
    sonic-pi
    easyeffects

    # Haskell
    # stack

    ## Language servers
    # C/C++
    ccls
    # JavaScript/TypeScript
    #nodePackages.typescript
    #nodePackages.typescript-language-server
    # Go
    #gopls
    go-outline
    # Kotlin
    # TODO
    # SQL
    #sqls
    # Nix
    #rnix-lsp
    # Bash
    #nodePackages.bash-language-server
    # CMake
    #cmake-language-server
    # CSS/SCSS
    #nodePackages.vscode-css-languageserver-bin

    # Security
    clamav

    # Sys utils
    inxi

    # Comm utils
    gnome.cheese
    teams
    # zoom-us
    anydesk
    torsocks
    tor

    # Editors
    marktext # Markdown
    apostrophe # Markdown
    jetbrains.idea-community # Java
    languagetool
    vale
    obsidian

    # Rec utils
    simplescreenrecorder
    peek

    # Web Dev
    unstable.deno
    unstable.flyctl
    go
    sass
    ungoogled-chromium
    # postman
    insomnia
    mkcert

    # Fun stuff
    duktape
    kotlin

    # Android Dev
    # android-studio
    wmname # Java app GUI issue fix
    android-studio
    android-tools
    watchman

    #Sys Dev
    nixos-option
    nixpkgs-fmt

    # Data analysis
    pspp

    # VPS
    mosh
    sshfs
    # k3s

    # Weird stuff
    eaglemode
    lagrange

    # Compiler tooling
    smlnj

    # Spellcheck
    aspell
    hunspell
    hunspellDicts.en_US

    # Virtualisation
    libguestfs
    virt-manager
    virtiofsd
    vagrant
    # unstable.lxd
    # x11docker
    xorg.xdpyinfo
    xclip

    # AWS tools
    awscli2

    # Xorg tools
    xorg.xmessage
    xorg.xev
    xorg.xmodmap
    xorg.xhost

    # Xorg gpu.js deps
    xorg.libX11
    xorg.libXi
    xorg.libXext

    # NixOS tools
    nix-index

    # Steam tools
    protontricks
    gamescope
    gamemode
    mangohud
    # logmein-hamachi
    # haguichi

    # Programming utils
    bintools-unwrapped # Tools for manipulating binaries (linker, assembler, etc.)
    colordiff
    cpulimit

    # SDKs
    #cudatoolkit_11_2
    # cudaPackages_11_6.cudatoolkit
    #cudnn_cudatoolkit_11_2
    # cudaPackages_11_6.cudnn
    #cudnn_cudatoolkit_11_2 # NVIDIA CUDA Deep Neural Network library (CUDA 11.2 + cuDNN 8.1.1 for TensorFlow 2.7.0 compat)
    git-lfs # Git extension for versioning large files
    gcc # GNU Compiler Collection, version 10.3.0 (wrapper script)
    libgccjit
    gnumake # A tool to control the generation of non-source files from sources
    pkg-config
    mdk # GNU MIX Development Kit (MDK)
    racket # A programmable programming language
    # mozart2 # An open source implementation of Oz 3
    chicken # A portable compiler for the Scheme programming language
    release2111.renpy # Ren'Py Visual Novel Engine
    nwjs-sdk # An app runtime based on Chromium and node.js
    arrayfire
    forge

    # Stable Diffusion Deps
    gperftools
    # cudaPackages.cudatoolkit # 11.7
    # cudaPackages.cudnn_8_5_0

    # Source code explorer & deps
    # tomcat10 opengrok
    universal-ctags
    hound # Lightning fast code searching made easy

    # SDL2 SDK
    SDL2 # SDL2_ttf SDL2_net SDL2_gfx SDL2_mixer SDL2_image smpeg2 guile-sdl2

    # Games
    # vkquake

    # XFCE
    xfce.xfce4-whiskermenu-plugin
    ulauncher
    picom
    glava
    conky

    # Desktop environment utils
    xfce.thunar
    xfce.thunar-volman
    xfce.tumbler
    polkit_gnome
    pavucontrol
    # plasma-pa
    dmenu
    feh
    tmux
    volctl
    okular
    konsole
    guake
    tilda
    # picom
    gnome.zenity
    # xpra # Buggy
    virtualgl
    autokey
    xautomation
    xdotool
    libnotify
    dunst
    mkvtoolnix
    poppler_utils
    # xpdf # Insecure
    ksnip
    flameshot

    # Emacs deps
    # espeak-classic
    # speechd
    # tcl
    # tclx
    # libtool
    # libvterm-neovim
    texlive.combined.scheme-full
    # mpg321
    # mpg123
    # mplayer

    # Sys utils
    # teams
    st
    xterm
    # yaft # Buggy
    mlterm
    imagemagick
    lsix
    flex
    bison
    tree
    p7zip
    parallel
    desktop-file-utils # Command line utilities for working with .desktop files
    xdg-utils # A set of command line tools that assist applications with a variety of desktop integration tasks
    nethogs # A small 'net top' tool, grouping bandwidth by process
    # iftop
    file # A program that shows the type of files
    grub2_efi # Bootloader (not activated)
    exfatprogs # GParted exFAT support
    gptfdisk # Set of partitioning tools for GPT disks
    pciutils # Provides lspci
    k4dirstat # Sums up disk usage for directory trees
    aria # Download manager
    qbittorrent # Torrent manager
    xorriso # ISO file editor (reasons for using this over cdrkit/cdrtools: https://wiki.osdev.org/Mkisofs)
    cdrtools # Provides mkisofs
    syslinux # Provides isohybrid which should NOT be used with ISOs that have been pre-treated with it like the Ubuntu ISOs
    libsForQt5.kalarm # KDE alarm
    ifmetric # Networking
    lshw # Hardware config intro
    hwinfo # Hardware detection tool from openSUSE
    bat # A cat(1) clone with syntax highlighting and Git integration
    zip # Compressor/archiver for creating and modifying zipfiles
    unrar
    ncdu_2
    subversion
    trash-cli
    nmap
    unzip
    newt
    gnupg
    xfsprogs
    parted
    input-remapper

    # Productivity tools
    # pomotroid # Electron dep seems broken
    gnome.pomodoro

    # Bluetooth
    # obexftp

    # Doc utils
    xournalpp
    pandoc
    vale
    gephi
    abiword
    gnum4
    zotero
    qnotero

    # Terminals
    hyper

    # DB utils
    dbeaver # Universal SQL Client for developers, DBA and analysts. Supports MySQL, PostgreSQL, MariaDB, SQLite, and more.
    sqlite
    sqlitecpp
    github-to-sqlite
    sqlite-utils
    sqlitebrowser
    # redis-desktop-manager
    jmeter

    # GIS utils
    # qgis

    # KDE utils
    libsForQt5.ark # Archive manager
    # calligra # Office stuff

    # Office software
    beancount
    fava
    fontforge

    # Media players
    vlc # Video
    lightspark # Flash

    # Media fetcher
    hakuneko

    # Misc file utils & other deps for a certain game.
    # unzip xdelta cabextract
    # mangohud vkBasalt gamemode
    # switcheroo-control # Only needed for dual GPU setups.

    # Kernel headers
    linuxHeaders

    # Android MTP
    jmtpfs

    # JVM
    unstable.jdk20_headless
    # adoptopenjdk-bin
    # adoptopenjdk-hotspot-bin-16
    # (sbt.override { jre = pkgs.adoptopenjdk-hotspot-bin-16; })
    # jbang

    # Python 3
    #python311
    #python311.withPackages (p: with p; [
    #fonttools
    #])
    (
      let
        my-python-packages = python-packages: with python-packages; [
          fonttools
          # conda
          # requests
          # psycopg2
          # tensorflowWithCuda
          # flask flask_wtf flask_mail flask_login flask_assets flask-sslify flask-silk flask-restx flask-openid flask-cors flask-common flask-bcrypt flask-babel flask-api flask-admin flask_sqlalchemy flask_migrate
          # fire
          # typer
          # pytest
          # poetry
          # poetry2conda
          # nixpkgs-pytools
          # rope
          # inkex
          # pyzmq
          # Sci-Comp Tools
          # jupyterlab
          # (pytorch.override {cudaSupport = true; cudaPackages = cudaPackages_11_6;})
          # scikit-learn jax objax optax flax transformers tokenizers fasttext numpy scipy sympy matplotlib pandas scikitimage statsmodels scikits-odes traittypes xarray
          # unstable.python39Packages.optuna
          # jaxlib
          # (jaxlib.override {cudaSupport = true;}) # Same as jaxlibWithCuda
          # (jaxlib.override {cudaSupport = true; cudaPackages = cudaPackages_11_6;})
          # (numba.override {cudaSupport = true; cudaPackages = cudaPackages_11_6;})
          # (cupy.override {cudaPackages = cudaPackages_11_6;})
          # (tensorflow.override {cudaSupport = true; cudaPackages = cudaPackages_11_6;})
          # spacy
          # pytesseract
          # duckdb
          # duckdb-engine
          # jaxlibWithCuda
          # numbaWithCuda
          # Scraping Tools
          # selenium
          # beautifulsoup4
          # folium
          # lxml
          # yarl
          # networkx
          # faker
          # Misc
          # pip
          # pyside2
          # pyside2-tools
          # shiboken2
          # virtualenv
          # virtualenvwrapper
          # pillow
          # virtual-display
          # EasyProcess
          # pdftotext
          # Web-Dev Tools
          # fastapi sqlalchemy sqlalchemy-utils sqlalchemy-migrate sqlalchemy-jsonfield sqlalchemy-i18n sqlalchemy-citext alembic ColanderAlchemy
          # Game Dev Tools
          # pybullet pygame pyglet
          # General tools
          # pipx
          # sh
          # Testing tools
          # pytest
          # pytest-benchmark
          # loguru
        ];
        python-with-my-packages = python310.withPackages my-python-packages;
      in
      python-with-my-packages
    )

    # (let 
    #   my-python2-packages = python2-packages: with python2-packages; [ 
    #     requests
    #     pygame_sdl2
    #   ];
    #   python2-with-my-packages = python27.withPackages my-python2-packages;
    # in
    # python2-with-my-packages)

    # Haskell
    #(let
    #  my-haskell-packages = haskellPackages: with haskellPackages; [
    #                  # libraries
    #                  arrows async criterion
    #                  # tools
    #                  stack haskintex cabal-install hlint
    #                ];
    #                 haskell-with-my-packages = unstable.haskell.packages.ghc941.ghcWithPackages my-haskell-packages;
    #                 haskell-with-my-packages = haskell.packages.ghc902.ghcWithHoogle my-haskell-packages; # unstable.haskell also works
    #in
    #haskell-with-my-packages)

    # Containers
    kube3d
    kubectl
    kubernetes-helm

    # Misc Tools
    # graalvm-ce
    scribus

    # ML Tools
    fasttext
    libtorch-bin

    # Conda
    conda

    # Rust
    rustup
    cargo-generate
    watchexec
    cargo-watch
    crate2nix
    wasm-pack

    # C++
    cling
    cppzmq
    uncrustify
    cmake
    # cmakeWithGui
    ninja
    # conan
    # Clang
    clang_14
    lldb_14
    # llvmPackages_14.libcxx
    valgrind
    gdb

    # VS Code fixes
    #gnome.gnome-keyring
    #libgnome-keyring
    #libsecret
    #gnome.seahorse

    # Vulkan
    # vulkan-tools
    # glslang
    # glm
    # vulkan-tools-lunarg
    # vulkan-loader
    # vulkan-headers
    # vulkan-validation-layers
    # spirv-tools
    # spirv-cross
    # spirv-headers
    # spirv-llvm-translator
    # mangohud

    # Coq
    coq
    coqPackages.mathcomp

    # TLA+
    tlaplusToolbox

    # GIMP
    gimp
    gimpPlugins.gap

    # Octave
    (
      let
        my-octave-packages = octave-packages: with octave-packages; [
          general
          symbolic
        ];
        octave-with-my-packages = octave.withPackages my-octave-packages;
      in
      octave-with-my-packages
    )

    # Node
    # nodejs
    # nodejs-16_x
    # nodePackages.pnpm
    # nodePackages.yarn
    # nodePackages.node-gyp
    # nodePackages.node-gyp-build

    # PHP
    php81
    php81Packages.composer

    # VS Code
    unstable.vscode-fhs

    # (vscode-with-extensions.override {
    #   # When the extension is already available in the default extensions set.
    #   vscodeExtensions = with vscode-extensions; [
    #     vscodevim.vim
    #     chenglou92.rescript-vscode
    #     ms-vscode.cpptools
    #     ms-python.python
    #     vscode-extensions.jnoortheen.nix-ide
    #     vscode-extensions.arrterian.nix-env-selector
    #     vscode-extensions.asvetliakov.vscode-neovim
    #   ]
    #   # Concise version from the vscode market place when not available in the default set.
    #   ++ vscode-utils.extensionsFromVscodeMarketplace [
    #     {
    #       name = "typescript-notebook";
    #       publisher = "donjayamanne";
    #       version = "2.0.6";
    #       #rev = "d3c419b635ba2c88179cef3ebf0ecf58563f2410"; # The usual way to get this seems to be putting a random string here ("0000000000000000000000000000000000000000000000000000") and let nix complain about it, and it will tell you the actual computed value.
    #       sha256 = "0zmm5im77mr6qj1qkp60jr7nxwbjkd9g6xf3xa41jsi5gmf8a1cz";
    #     }
    #   ];
    # })

    # Games
    cataclysm-dda

    # TBI
    # pgadmin # openssl issue here (good chance to test sed & awk).
    # discord / betterdiscordctl
    # element-desktop
    # kaldi

    # Same trick as Python for these packages (anything that has a 'Full' version should work similarly)!
    # vscode-with-extensions

    # Overlays
    #((emacsPackagesFor emacsGcc).emacsWithPackages (epkgs: [
    # epkgs.emacspeak
    # epkgs.sonic-pi
    # epkgs.languagetool
    #]))
    wine
    winetricks
    playonlinux
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
