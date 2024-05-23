# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:
with pkgs;
let
  system = "x86_64-linux";

  custom-fonts = pkgs.stdenv.mkDerivation {
    name = "custom-fonts";
    version = "1.000";
    src = /fonts;

    installPhase = ''
      mkdir -p $out/share/fonts/opentype/custom-fonts
      cp -rv $src/* $out/share/fonts/opentype/custom-fonts
    '';
  };

  RStudio-with-my-packages = rstudioWrapper.override {
    packages = with rPackages; [
      ggplot2
      dplyr
      tidyr
      xts
      lubridate
      readr
      readxl
      randomForest
      mice
      FactoMineR
      rstudioapi
      here
      gt
      kableExtra
      data_table
      mltools
      fastDummies
      gridExtra
      corrplot
      plyr
    ];
  };

in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix = {
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
    };
    permittedInsecurePackages = [
      # "openssl-1.1.1v"
      # "nodejs-16.20.2"
    ];
  };

  # Storage optimization.
  nix.settings.auto-optimise-store = true;

  # Limit CPU usage during builds
  nix.settings.cores = 4;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable NTFS-3G support
  boot.supportedFilesystems = [ "ntfs" ];

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

  # SSD
  services.fstrim.enable = true;

  # Disable automatic refresh of ClamAV signatures database (do this manually).
  services.clamav = {
    daemon.enable = false;
    updater.enable = false;
  };

  # VPN
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  # GitHub runners
  # services.github-runners = {
  #   runner1 = {
  #     enable = true;
  #     name = "sync-bot";
  #     tokenFile = "/home/ryan/Documents/pat.txt";
  #     url = "https://github.com/RyanCargan/Scratch";
  #     workDir = "/var/lib/runner-workspace";
  #     user = "ryan";
  #   };
  # };

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
  networking.networkmanager = {
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
    '';

  services.openssh.enable = true;
  services.openssh.settings.X11Forwarding = true;

  networking.firewall.allowedTCPPorts = [ 6443 ];

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

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull.override { bluetoothSupport = false; };
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;
  nixpkgs.config.pulseaudio = true;
  hardware.pulseaudio.extraConfig = ''
    load-module module-combine-sink
    unload-module module-suspend-on-idle
  '';

  # Enable Bluetooth
  hardware.bluetooth.enable = false;
  services.blueman.enable = false;

  # Paprefs fix.
  programs.dconf.enable = true; # + gnome3.dconf

  # D-Bus
  services.gnome.gnome-keyring.enable = true;

  # Database
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_14;
    settings = {
      wal_level = "logical";
    };
    extraPlugins = with pkgs.postgresql_14; [
      pgtap
      postgis
      timescaledb
    ];
    authentication = lib.mkForce ''
      # Generated file; do not edit!
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
    '';
  };

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
  };

  # Overlay configuration
  nixpkgs.overlays = [

    # Wine
    (self: super: {
      wine = super.wineWowPackages.stableFull;
    })

    # dwm
    (self: super: {
      dwm = super.dwm.overrideAttrs (oa: rec {
        patches = [
          (super.fetchpatch {
            url = "https://dwm.suckless.org/patches/systray/dwm-systray-6.3.diff";
            sha256 = "1plzfi5l8zwgr8zfjmzilpv43n248n4178j98qdbwpgb4r793mdj";
          })
          (super.fetchpatch {
            url = "https://raw.githubusercontent.com/RyanCargan/dwm/main/patches/dwm-custom-6.3.diff";
            sha256 = "116jf166rv9w1qyg1d52sva8f1hzpg3lij9m16izz5s8y0742hy7";
          })
        ];
      });
      st = super.st.overrideAttrs (oa: rec {
        patches = [
        ];
      });
    })

    # nix-direnv
    # (self: super: { nix-direnv = super.nix-direnv.override { enableFlakes = true; }; })
  ];

  fonts.packages = with pkgs; [
    source-code-pro
    liberation_ttf
    custom-fonts
  ];
  fonts.fontDir.enable = true;

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
    # electron # Insecure
    nodePackages.asar

    # Virtualization
    # (pkgs.stdenv.mkDerivation {
    #   name = "virtiofsd-link";
    #   buildCommand = ''
    #     mkdir -p $out/bin
    #     ln -s ${pkgs.qemu}/libexec/virtiofsd $out/bin/
    #   '';
    # })
    remmina

    # Flakes
    # inputs.blender.packages.x86_64-linux.default
    inputs.poetry2nix.packages.x86_64-linux.poetry2nix
    release2105.dos2unix

    # nix-direnv
    direnv
    nix-direnv

    # Educational software
    anki-bin
    d2

    # 3D art
    blender

    # 2D art
    krita

    # Audio & video comms
    (mumble.override { pulseSupport = true; })
    iproute2
    jq

    # Audio utils
    reaper
    sonic-pi
    easyeffects

    ## Language servers
    ccls
    # Go
    go-outline

    # Security
    clamav

    # Sys utils
    inxi
    samba

    # Comm utils
    gnome.cheese
    # zoom-us
    anydesk
    torsocks
    tor
    ngrok
    cloudflared
    telegram-desktop

    # Editors
    # marktext # Markdown
    # apostrophe # Markdown
    # jetbrains.idea-community # Java
    languagetool
    vale
    unstable.obsidian

    # Rec utils
    simplescreenrecorder
    peek

    # Web Dev
    deno
    flyctl
    go
    sass
    ungoogled-chromium
    # postman
    # insomnia
    mkcert
    nodejs_20
    ruby

    # Fun stuff
    duktape
    kotlin

    # Android Dev
    wmname # Java app GUI issue fix
    android-studio
    gradle
    android-tools
    watchman
    libpcap
    genymotion

    #Sys Dev
    nixos-option
    nixpkgs-fmt

    # Data analysis
    pspp

    # VPS
    mosh
    sshfs

    # VPN
    # mullvad-vpn

    # Weird stuff
    eaglemode
    lagrange

    # Project Management Tools
    ganttproject-bin

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
    xorg.xdpyinfo
    xclip

    # ML Tools
    unstable.ollama
    # (unstable.ollama.override { acceleration = "cuda"; })


    # AWS tools
    awscli2
    minio

    # Azure tools
    azure-cli
    azuredatastudio

    # IaC
    terraform
    terraform-providers.aws
    terraform-providers.cloudflare


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

    # Debian tools
    dpkg

    # Steam tools
    protontricks
    gamescope
    gamemode
    mangohud

    # Programming utils
    bintools-unwrapped # Tools for manipulating binaries (linker, assembler, etc.)
    colordiff
    cpulimit

    # SDKs
    git-lfs # Git extension for versioning large files
    gcc # GNU Compiler Collection, version 10.3.0 (wrapper script)
    libgccjit
    gnumake # A tool to control the generation of non-source files from sources
    pkg-config
    mdk # GNU MIX Development Kit (MDK)
    racket # A programmable programming language
    chicken # A portable compiler for the Scheme programming language
    release2111.renpy # Ren'Py Visual Novel Engine
    nwjs-sdk # An app runtime based on Chromium and node.js
    arrayfire
    forge

    # Stable Diffusion Deps
    gperftools

    # Source code explorer & deps
    universal-ctags
    hound # Lightning fast code searching made easy

    # SDL2 SDK
    SDL2 # SDL2_ttf SDL2_net SDL2_gfx SDL2_mixer SDL2_image smpeg2 guile-sdl2

    # Shopify
    # shopify-cli
    function-runner

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
    xfce.xfce4-screenshooter
    polkit_gnome
    pavucontrol
    dmenu
    feh
    tmux
    volctl
    okular
    konsole
    guake
    tilda
    gnome.zenity
    virtualgl
    autokey
    xautomation
    xdotool
    libnotify
    dunst
    mkvtoolnix
    poppler_utils
    ksnip
    flameshot

    # Emacs deps
    texlive.combined.scheme-full

    # Sys utils
    st
    xterm
    mlterm
    imagemagick
    libwebp
    lsix
    flex
    bison
    tree
    p7zip
    parallel
    desktop-file-utils # Command line utilities for working with .desktop files
    xdg-utils # A set of command line tools that assist applications with a variety of desktop integration tasks
    nethogs # A small 'net top' tool, grouping bandwidth by process
    file # A program that shows the type of files
    grub2_efi # Bootloader (not activated)
    exfatprogs # GParted exFAT support
    gptfdisk # Set of partitioning tools for GPT disks
    pciutils # Provides lspci
    k4dirstat # Sums up disk usage for directory trees
    aria # Download manager
    qbittorrent # Torrent manager
    transmission_4-qt
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

    # DevOps Utils
    # openssl_1_1

    # Productivity tools
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
    sqldiff
    isso # FOSS Disqus clone
    sqlitecpp
    github-to-sqlite
    sqlite-utils
    sqlitebrowser
    jmeter

    # GIS utils
    # qgis

    # KDE utils
    libsForQt5.ark # Archive manager

    # Office software
    beancount
    fava
    fontforge

    # Media players
    vlc # Video
    lightspark # Flash

    # Media fetcher
    hakuneko

    # Kernel headers
    linuxHeaders

    # Android MTP
    jmtpfs

    # R
    RStudio-with-my-packages

    # Spreadsheet conversion
    gnumeric

    # JVM
    # unstable.jdk20_headless
    # jdk17
    # oraclejdk8
    jdk21
    maven
    xorg.libXxf86vm

    # Python 3
    (
      let
        my-python-packages = python-packages: with python-packages; [
          fonttools
          pyside6
          pygame
          matplotlib
          pillow
          pytesseract
          databricks-cli
        ];
        python-with-my-packages = python311.withPackages my-python-packages;
      in
      python-with-my-packages
    )
    poetry

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
    ninja
    clang_14
    lldb_14
    valgrind
    gdb

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

    # PHP
    php81
    php81Packages.composer

    # VS Code
    unstable.vscode-fhs

    # Games
    cataclysm-dda

    # Emulation
    appimage-run
    wine
    winetricks
    playonlinux
    mednafen
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
