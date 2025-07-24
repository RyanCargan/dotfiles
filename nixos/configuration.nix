# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:
with pkgs;
let
  system = "x86_64-linux";

  customFFmpeg = pkgs.ffmpeg.override {
    withJack = true;
    withCuda = true;
    withNvenc = true;
    withCuvid = true;
    ffmpegVariant = "full";
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
      reshape2
    ];
  };

in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./cachix.nix
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
    # cudaPackages = pkgs.cudaPackages;
    packageOverrides = pkgs: {
      # release2105 = import inputs.release2105 {
      #   config = config.nixpkgs.config;
      #   inherit system;
      # };
      release2111 = import inputs.release2111 {
        config = config.nixpkgs.config;
        inherit system;
      };
      unstable = import inputs.unstable {
        config = config.nixpkgs.config;
        inherit system;
      };
    };
    allowBroken = true;
    permittedInsecurePackages = [
      # "openssl-1.1.1v"
      # "nodejs-16.20.2"
    ];
  };

  # Storage optimization.
  nix.settings.auto-optimise-store = true;

  # Limit CPU usage during builds
  nix.settings.cores = 4;

  # Cache
  nix.settings.substituters = [
    "https://nix-community.cachix.org"
    "https://cuda-maintainers.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    # Compare to the key published at https://nix-community.org/cache
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="

  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable NTFS-3G support
  boot.supportedFilesystems = [ "ntfs" ];

  # Enable kernel modules
  boot.kernelModules = [ "v4l2loopback" "snd-seq" "snd-rawmidi" ];

  # Set users.
  users.users.ryan = {
    createHome = true;
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "libvirtd"
      "qemu-libvirtd"
      "audio"
      "video"
      "networkmanager"
      "vglusers"
      "lxd"
      "docker"
      "jackaudio"
    ];
    group = "users";
    home = "/home/ryan";
    uid = 1000;
  };
  users.users.rishindu = {
    createHome = true;
    isNormalUser = true;
    extraGroups = [
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

  # Flatpak
  services.flatpak.enable = true;
  xdg.portal.enable = true;

  # Teamviewer
  services.teamviewer.enable = true;

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

  # Remote cams
  services.udev.extraRules = ''
    KERNEL=="video*", SUBSYSTEM=="video4linux", MODE="0660", OWNER="ryan", GROUP="video"
  '';

  # Enable virtualization.
  virtualisation.libvirtd.enable = true;
  boot.extraModprobeConfig =
    "options kvm_amd nested=1"; # Nested virtualization (requires AMD-V).
  virtualisation.lxd.enable = false;
  virtualisation.docker = {
    enable = true;
    # enableNvidia = true; # Deprecated
  };
  # boot.kernelModules = [ "kvm-amd" "kvm-intel" ]; # Only needed if kvm-amd/intel is not set in hardware-configuration.nix AFAIK.

  # Allow proprietary packages
  # nixpkgs.config.cudaSupport = false;
  nixpkgs.config.allowUnfreePredicate = p:
    builtins.all (license:
      license.free || builtins.elem license.shortName [
        "CUDA EULA"
        "cuDNN EULA"
        "cuTENSOR EULA"
        "NVidia OptiX EULA"
        "unfreeRedistributable"
        "unfree"
        "postman"
        "bsl11"
        "bsd3"
        "issl"
      ]) (if builtins.isList p.meta.license then
        p.meta.license
      else
        [ p.meta.license ]);

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp34s0.useDHCP = true;
  networking.interfaces.wlp3s0f0u8.useDHCP = true;

  # Firewall
  services.opensnitch.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Wi-Fi
  networking.networkmanager = { enable = true; };
  programs.nm-applet.enable = true;
  # programs.light.enable = true;
  programs.steam = {
    enable = true;
    extraPackages = [
      gamescope
      steamtinkerlaunch
      # xorg.xwininfo
    ];
  };
  services.logmein-hamachi.enable = true;
  programs.haguichi.enable = true;

  # Hosts
  networking.extraHosts = "";

  services.openssh.enable = true;
  services.openssh.settings.X11Forwarding = true;

  networking.firewall.allowedTCPPorts = [ 6443 ];

  # Enable NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = false;
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ libGL ];
    enable32Bit = true;
    # setLdLibraryPath = true;
  };
  hardware.nvidia-container-toolkit.enable = true;

  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
  };
  services.displayManager.defaultSession = "xfce";

  services.gvfs = {
    enable = true;
    package = lib.mkForce pkgs.gnome.gvfs;
  };

  # Enable sound.

  # Disable PulseAudio & JACKd
  services.pulseaudio.enable = false;
  services.jack.jackd.enable = false;

  # Turn on PipeWire core + bridges
  services.pipewire = {
    enable = true;
    alsa.enable = true; # provides /dev/snd/ via PipeWire
    pulse.enable = true; # replaces PulseAudio
    jack.enable = true; # provides JACK API
    # package = pkgs.pipewire.override { wireplumberSupport = true; };
    wireplumber.enable = true;
  };

  # Enable Bluetooth
  hardware.bluetooth.enable = false;
  services.blueman.enable = false;

  # Paprefs fix.
  programs.dconf.enable = true; # + gnome3.dconf

  # D-Bus
  services.gnome.gnome-keyring.enable = true;

  # Database
  services.postgresql = {
    enable = false;
    package = pkgs.postgresql_14;
    settings = { wal_level = "logical"; };
    extensions = with pkgs.postgresql_14; [ pgtap postgis timescaledb ];
    authentication = lib.mkForce ''
      # Generated file; do not edit!
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
    '';
  };

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

  #-------------------------------------------------------------------------
  # Enable redis service
  #-------------------------------------------------------------------------
  services.redis.servers."talos".enable = true;
  services.redis.servers."talos".port = 6379;

  # Mic
  programs.droidcam.enable = true;
  services.murmur.enable = true;
  services.avahi = { enable = true; };

  # Misc
  programs.gamemode.enable = true;

  # Overlay configuration
  nixpkgs.overlays = [

    # Wine
    (self: super: { wine = super.wineWowPackages.stableFull; })

    # dwm
    (self: super: {
      dwm = super.dwm.overrideAttrs (oa: rec {
        patches = [
          (super.fetchpatch {
            url =
              "https://dwm.suckless.org/patches/systray/dwm-systray-6.3.diff";
            sha256 = "1plzfi5l8zwgr8zfjmzilpv43n248n4178j98qdbwpgb4r793mdj";
          })
          (super.fetchpatch {
            url =
              "https://raw.githubusercontent.com/RyanCargan/dwm/main/patches/dwm-custom-6.3.diff";
            sha256 = "116jf166rv9w1qyg1d52sva8f1hzpg3lij9m16izz5s8y0742hy7";
          })
        ];
      });
      st = super.st.overrideAttrs (oa: rec { patches = [ ]; });
    })

  ];

  fonts.packages = with pkgs; [
    source-code-pro
    liberation_ttf
    dejavu_fonts
    open-sans
  ];
  fonts.fontDir.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  environment.systemPackages = with pkgs; [
    vim
    wget
    firefox
    kdePackages.kate
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
    (obs-studio.override { cudaSupport = true; })
    gron
    go-org
    groff
    direnv
    elinks
    fbida
    # texmacs
    kdePackages.ghostwriter
    (mumble.override { pulseSupport = true; })

    linuxKernel.packages.linux_6_6.v4l2loopback
    paprefs
    gparted
    unetbootin
    emscripten
    wasmer
    # nvidia-docker
    pyspread
    inkscape
    neovim
    calibre
    root
    # sageWithDoc
    nyxt
    maim
    yacreader
    tigervnc
    aria
    ghostscript
    pdftk
    nix-du
    zgrviewer
    graphviz
    google-chrome
    unstable.tor-browser-bundle-bin
    busybox
    electron
    nodePackages.asar
    nixfmt-classic

    # Virtualization
    remmina

    # Flakes
    # inputs.blender.packages.x86_64-linux.default
    # inputs.poetry2nix.packages.x86_64-linux.poetry2nix
    # release2105.dos2unix

    # nix-direnv
    direnv
    nix-direnv

    # Educational software
    anki-bin
    d2
    xmind
    freeplane

    # 3D art
    (unstable.blender.override { cudaSupport = true; })

    # 2D art
    krita
    opentabletdriver

    # Audio & video comms
    (mumble.override { pulseSupport = true; })
    iproute2
    jq
    # pulseaudio
    pipewire
    wireplumber
    alsa-utils

    # Audio utils
    reaper
    sonic-pi
    easyeffects
    audacity
    lmms
    csound

    ## Language servers
    ccls
    # Go
    go-outline

    # Security
    clamav

    # Sys utils
    inxi
    samba
    evtest
    xautomation
    woeusb-ng
    bchunk
    cachix

    # Comm utils
    cheese
    # zoom-us
    unstable.anydesk
    torsocks
    tor
    ngrok
    cloudflared
    telegram-desktop
    discord
    caddy
    nginx

    # Editors
    languagetool
    vale

    # Rec utils
    simplescreenrecorder
    peek

    # Video Editing
    customFFmpeg
    (kdePackages.kdenlive.override { "ffmpeg-full" = customFFmpeg; })
    glaxnimate
    # davinci-resolve

    # Web Dev
    deno
    flyctl
    go
    sass
    ungoogled-chromium
    unstable.postman
    speedtest-cli
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
    # genymotion

    #Sys Dev
    nixos-option
    nixpkgs-fmt

    # Data analysis
    pspp

    # VPS
    mosh
    sshfs
    autossh

    # VPN
    # mullvad-vpn

    # Networking tools
    tcpdump
    wireshark
    opensnitch-ui

    # Weird stuff
    # eaglemode
    # lagrange

    # Project Management Tools
    # ganttproject-bin

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

    # AWS tools
    awscli2
    minio

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
    steamtinkerlaunch
    # --- steamtinkerlaunch deps
    xorg.xwininfo
    yad
    xorg.xrandr
    xorg.xprop

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
    release2111.renpy # Ren'Py Visual Novel Engine

    # Stable Diffusion Deps
    gperftools

    # Source code explorer & deps
    universal-ctags
    # hound # Lightning fast code searching made easy

    # SDL2 SDK
    SDL2 # SDL2_ttf SDL2_net SDL2_gfx SDL2_mixer SDL2_image smpeg2 guile-sdl2

    # Shopify
    # shopify-cli
    # function-runner

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
    alsa-tools
    # qjackctl
    qpwgraph
    helvum
    easyeffects
    # jack2
    # jack_capture
    # jackmix
    dmenu
    feh
    tmux
    volctl
    kdePackages.okular
    kdePackages.konsole
    guake
    tilda
    zenity
    virtualgl
    autokey
    # xautomation
    xdotool
    libnotify
    dunst
    mkvtoolnix
    poppler_utils
    ksnip
    flameshot
    findutils

    # Emacs deps
    # texlive.combined.scheme-full

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
    pinentry
    xfsprogs
    parted
    input-remapper
    smartmontools
    zstd

    # DevOps Utils
    # openssl_1_1

    # Productivity tools
    # gnome.pomodoro

    # Bluetooth
    # obexftp

    # Doc utils
    # xournalpp
    pandoc
    # vale
    # gephi
    abiword
    # gnum4
    zotero
    # qnotero
    ocamlPackages.cpdf
    exiftool
    djvu2pdf
    djvulibre

    # DB utils
    dbeaver-bin # Universal SQL Client for developers, DBA and analysts. Supports MySQL, PostgreSQL, MariaDB, SQLite, and more.
    sqlite
    sqldiff
    isso # FOSS Disqus clone
    sqlitecpp
    sqlite-utils
    sqlitebrowser
    postgresql_16

    # GIS utils
    qgis
    gdal
    tilemaker

    # KDE utils
    libsForQt5.ark # Archive manager

    # Office software
    libreoffice-fresh

    # Media players
    vlc # Video
    lightspark # Flash

    # Media fetcher
    hakuneko

    # Kernel headers
    linuxHeaders

    # Android MTP
    jmtpfs

    # Misc libs
    nss

    # R
    RStudio-with-my-packages

    # Spreadsheet conversion
    # gnumeric

    # JVM
    jdk21
    maven
    xorg.libXxf86vm

    # Python 3
    (let

      my-python-packages = python-packages:
        with python-packages; [
          pyside6
          pygame
          matplotlib
          evdev
          python-uinput
          vpk
        ];
      python-with-my-packages = python312.withPackages my-python-packages;
    in python-with-my-packages)
    poetry

    # Misc Tools
    scribus
    exe2hex

    # ML Tools
    fasttext

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

    # GIMP
    gimp

    # PHP
    php81
    php81Packages.composer

    # VS Code
    unstable.vscode-fhs

    # Games
    gzdoom
    unstable.quakespasm
    darkplaces
    libjpeg8

    # Emulation
    appimage-run
    wine
    winetricks
    playonlinux
    mednafen
    mame
    kega-fusion
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
