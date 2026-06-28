{ config, pkgs, inputs, lib, ... }:

with pkgs;

{
  imports = [ ./hardware-configuration.nix ./cachix.nix ];

  nix = {
    package = pkgs.nixVersions.nix_2_30;
    registry.nixpkgs.flake = inputs.nixpkgs;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';

    settings = {
      auto-optimise-store = true;
      cores = 3;
      max-jobs = 2;
      substituters = [ "https://nix-community.cachix.org" ];
      trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
      trusted-users = [ "root" "ryan" ];
      system-features = [ "kvm" ];
    };
  };

  nixpkgs = {
    config = {
      # WARNING: global allowBroken can hide broken packages during rebuilds.
      allowBroken = true;
      permittedInsecurePackages = [ ];

      allowUnfreePredicate = p:
        builtins.all
          (license: license.free || builtins.elem license.shortName [
            "unfreeRedistributable"
            "unfree"
            "postman"
            "bsl11"
            "bsd3"
            "issl"
            "obsidian"
            "claude"
          ])
          (if builtins.isList p.meta.license then p.meta.license else [ p.meta.license ]);

      packageOverrides = pkgs: {
        unstable = import inputs.unstable { config = config.nixpkgs.config; inherit (pkgs) system; };
      };
    };

    overlays = [
      (self: super: { wine = super.wineWowPackages.stableFull; })
      (self: super: {
        dwm = super.dwm.overrideAttrs (_: {
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
        st = super.st.overrideAttrs (_: { patches = [ ]; });
      })
    ];
  };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    supportedFilesystems = [ "ntfs" ];
    kernelModules = [ "v4l2loopback" "snd-seq" "snd-rawmidi" "kvm-amd" ];
    kernelParams = [ "mem_sleep_default=deep" "usbcore.autosuspend=-1" ];
    extraModprobeConfig = ''
      options kvm_amd nested=1
      options nvidia NVreg_TemporaryFilePath=/mnt/ubuntu-storage/tmp
      options nvidia_modeset vblank_sem_control=0
    '';
  };

  users = {
    users.ryan = {
      createHome = true;
      isNormalUser = true;
      group = "users";
      home = "/home/ryan";
      uid = 1000;
      extraGroups = [ "wheel" "libvirtd" "kvm" "qemu-libvirtd" "audio" "video" "networkmanager" "vglusers" "lxd" "docker" "jackaudio" ];
    };

    users.rishindu = {
      createHome = true;
      isNormalUser = true;
      group = "users";
      home = "/home/rishindu";
      uid = 1001;
      extraGroups = [ "wheel" "libvirtd" "qemu-libvirtd" "audio" "video" "networkmanager" "vglusers" "lxd" "docker" ];
    };

    groups.libvirtd.members = [ "ryan" ];
  };

  time.timeZone = "Asia/Colombo";

  fileSystems = {
    "/mnt/nixos-storage" = {
      device = "/dev/disk/by-uuid/9d21acb3-39de-4ed0-8f4f-0123ad151ef3";
      fsType = "xfs";
      options = [ "defaults" "nofail" ];
    };
    "/mnt/ubuntu-storage" = {
      device = "/dev/disk/by-uuid/8cbe52d8-cd1e-4aab-a57f-97966a9fb055";
      fsType = "ext4";
      options = [ "defaults" "nofail" ];
    };
    "/mnt/swap-storage" = {
      device = "/dev/disk/by-uuid/d4a5bffe-1f7b-4120-bc7e-dcced60866ce";
      fsType = "ext4";
      options = [ "defaults" "nofail" ];
    };

    "/run/media/ryan/nixos" = { device = "/mnt/nixos-storage"; options = [ "bind" "nofail" ]; };
    "/run/media/ryan/ubuntu" = { device = "/mnt/ubuntu-storage"; options = [ "bind" "nofail" ]; };
    "/run/media/ryan/swap" = { device = "/mnt/swap-storage"; options = [ "bind" "nofail" ]; };
  };

  systemd = {
    tmpfiles.rules = [ "d /mnt/ubuntu-storage/tmp 1777 root root -" ];

    services.nvidia-tdp = {
      description = "Set NVIDIA power limit";
      wantedBy = [ "multi-user.target" ];
      after = [ "nvidia-persistenced.service" ];
      requires = [ "nvidia-persistenced.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi -i 0 --power-limit=95";
      };
    };
  };

  security.pam = {
    loginLimits = [
      { domain = "ryan"; type = "soft"; item = "nofile"; value = "524288"; }
      { domain = "ryan"; type = "hard"; item = "nofile"; value = "524288"; }
    ];
    services.hyprlock = { };
  };

  networking = {
    useDHCP = false;
    interfaces.enp34s0.useDHCP = true;
    interfaces.wlp3s0f0u8.useDHCP = true;
    networkmanager.enable = true;
    extraHosts = "";
    firewall.allowedTCPPorts = [ 6443 ];
  };

  services = {
    fstrim.enable = true;
    flatpak.enable = true;
    teamviewer.enable = true;
    opensnitch.enable = true;
    logmein-hamachi.enable = true;
    openssh = { enable = true; settings.X11Forwarding = true; };

    clamav = { daemon.enable = false; updater.enable = false; };
    mullvad-vpn = { enable = true; package = pkgs.mullvad-vpn; };

    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      desktopManager.xterm.enable = false;
    };

    displayManager = {
      defaultSession = "hyprland";
      sddm = { enable = true; wayland.enable = true; };
    };

    gvfs = { enable = true; package = lib.mkForce pkgs.gnome.gvfs; };

    pulseaudio.enable = false;
    jack.jackd.enable = false;
    pipewire = { enable = true; alsa.enable = true; pulse.enable = true; jack.enable = true; wireplumber.enable = true; };

    blueman.enable = false;
    gnome.gnome-keyring.enable = true;

    postgresql = {
      enable = false;
      package = pkgs.postgresql_14;
      settings.wal_level = "logical";
      extensions = with pkgs.postgresql_14; [ pgtap postgis timescaledb ];
      authentication = lib.mkForce ''
        local   all   all             trust
        host    all   all 127.0.0.1/32 trust
        host    all   all ::1/128      trust
      '';
    };

    mysql = { enable = true; package = pkgs.mariadb; };
    redis.servers."talos" = { enable = true; port = 6379; };
    murmur.enable = true;
    avahi.enable = true;

    udev.extraRules = ''
      KERNEL=="video*", SUBSYSTEM=="video4linux", MODE="0660", OWNER="ryan", GROUP="video"

      # Keep internal development partitions hidden from desktop automounters.
      SUBSYSTEM=="block", ENV{ID_FS_UUID}=="9d21acb3-39de-4ed0-8f4f-0123ad151ef3", ENV{UDISKS_IGNORE}="1"
      SUBSYSTEM=="block", ENV{ID_FS_UUID}=="8cbe52d8-cd1e-4aab-a57f-97966a9fb055", ENV{UDISKS_IGNORE}="1"
      SUBSYSTEM=="block", ENV{ID_FS_UUID}=="d4a5bffe-1f7b-4120-bc7e-dcced60866ce", ENV{UDISKS_IGNORE}="1"
    '';
  };

  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;
    lxd.enable = false;
    docker.enable = true;
  };

  programs = {
    virt-manager.enable = true;
    nm-applet.enable = true;
    haguichi.enable = true;
    hyprland = { enable = true; xwayland.enable = true; };
    dconf.enable = true;
    droidcam.enable = true;
    gamemode.enable = true;
    nix-ld = { enable = true; libraries = [ openssl ]; };
    direnv = { enable = true; nix-direnv.enable = true; };

    steam = {
      enable = true;
      extraPackages = [ gamescope steamtinkerlaunch vkbasalt ];
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  hardware = {
    bluetooth.enable = false;

    nvidia = {
      open = false; # WARNING: keep false on Pascal-era NVIDIA GPUs.
      powerManagement.enable = true;
      nvidiaSettings = true;
      nvidiaPersistenced = true;
      modesetting.enable = true;
    };

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = [ libGL ];
    };

    opentabletdriver = { enable = true; daemon.enable = true; };
  };

  environment.etc."X11/xorg.conf.d/20-nvidia-coolbits.conf".text = ''
    Section "OutputClass"
      Identifier "nvidia"
      MatchDriver "nvidia-drm"
      Driver "nvidia"
      Option "Coolbits" "28"
    EndSection
  '';

  fonts = {
    packages = [ source-code-pro liberation_ttf dejavu_fonts open-sans ];
    fontDir.enable = true;
  };

  environment.systemPackages = with pkgs;
    let
      pythonWithTools = python312.withPackages (p: with p; [
        pyside6
        pygame
        matplotlib
        evdev
        python-uinput
        vpk
        pysdl2
        uv
      ]);
    in
    [
      # Core CLI / Nix
      vim
      wget
      git
      docker
      jq
      fzf
      fd
      ripgrep
      ripgrep-all
      silver-searcher
      btop
      ccache
      yt-dlp
      gron
      go-org
      groff
      elinks
      fbida
      busybox
      nixfmt-classic
      nixpkgs-fmt
      nixos-option
      nix-du
      nix-prefetch-git
      nix-index
      cachix
      nix-ld
      nil
      nixd
      starship
      erdtree

      # Files / archives / disks / terminal utilities
      aria
      bat
      bchunk
      colordiff
      cpulimit
      desktop-file-utils
      dpkg
      evtest
      exfatprogs
      file
      findutils
      gparted
      gptfdisk
      grub2_efi
      httrack
      hwinfo
      ifmetric
      inxi
      k4dirstat
      lshw
      lsix
      ncdu_2
      nethogs
      newt
      p7zip
      parallel
      parted
      pciutils
      smartmontools
      subversion
      trash-cli
      tree
      unrar
      unzip
      xfsprogs
      zip
      zstd
      cdrtools
      syslinux
      xorriso

      # Network / remote / security
      anydesk
      autossh
      awscli2
      cheese
      clamav
      cloudflared
      iproute2
      libpcap
      minio
      mosh
      ngrok
      nmap
      opensnitch-ui
      remmina
      samba
      sparrow
      sshfs
      tcpdump
      telegram-desktop
      tigervnc
      tor
      torsocks
      wireshark

      # Desktop / Wayland / X11
      autokey
      conky
      dmenu
      dunst
      feh
      flameshot
      glava
      grim
      guake
      hyprlock
      hyprpaper
      ksnip
      libnotify
      libsForQt5.ark
      libsForQt5.kalarm
      maim
      mlterm
      polkit_gnome
      rofi-wayland
      slurp
      st
      swappy
      tilda
      tilix
      tmux
      ulauncher
      virtualgl
      volctl
      waybar
      wl-clipboard
      xclip
      xdotool
      xorg.libX11
      xorg.libXext
      xorg.libXi
      xorg.libXxf86vm
      xorg.xdpyinfo
      xorg.xev
      xorg.xhost
      xorg.xmessage
      xorg.xmodmap
      xorg.xprop
      xorg.xrandr
      xorg.xwininfo
      xterm
      yad
      zenity
      xfce.thunar
      xfce.thunar-volman
      xfce.tumbler
      xfce.xfce4-screenshooter
      xfce.xfce4-whiskermenu-plugin

      # Browsers / web / comms
      google-chrome
      tor-browser-bundle-bin
      ungoogled-chromium
      inputs.firefox.packages.${pkgs.system}.firefox-nightly-bin
      filezilla
      flyctl
      mkcert
      nodejs
      nodePackages.asar
      pnpm
      sass
      speedtest-cli

      # Editors / writing / documents
      abiword
      calibre
      djvu2pdf
      djvulibre
      exiftool
      ghostscript
      kdePackages.ghostwriter
      kdePackages.kate
      kdePackages.okular
      languagetool
      ocamlPackages.cpdf
      pandoc
      pdftk
      poppler_utils
      vale
      yacreader
      zgrviewer
      graphviz

      # Media / art / audio
      alsa-tools
      alsa-utils
      audacity
      blender
      csound
      easyeffects
      ffmpeg-full
      (gimp-with-plugins.override { plugins = with gimpPlugins; [ gmic resynthesizer ]; })
      glaxnimate
      inkscape
      kdePackages.kdenlive
      mkvtoolnix
      obs-studio
      openimageio
      pavucontrol
      pipewire
      qpwgraph
      reaper
      simplescreenrecorder
      sox
      vlc
      wireplumber

      # Education / misc GUI
      anki-bin
      butler
      d2
      freeplane
      hakuneko
      input-remapper
      jmtpfs
      lightspark
      pspp
      xmind

      # Databases / local services clients
      isso
      sqlite
      sqlite-utils
      sqlitebrowser
      sqlitecpp
      sqldiff

      # C / C++ / systems / profiling
      binaryen
      bintools-unwrapped
      bison
      ccls
      clang
      cling
      cmake
      cppzmq
      flex
      flamegraph
      gcc
      gdb
      git-lfs
      gnumake
      gperftools
      kernelshark
      libgccjit
      linuxHeaders
      linuxKernel.packages.linux_6_6.v4l2loopback
      linuxPackages.perf
      lldb
      ninja
      pkg-config
      SDL2
      sysprof
      trace-cmd
      universal-ctags
      uncrustify
      valgrind
      wasmer

      # Python / Android / package ecosystems
      android-tools
      poetry
      pythonWithTools
      watchman
      wmname

      # Gaming / Windows compatibility / emulation
      appimage-run
      darkplaces
      gzdoom
      kega-fusion
      libjpeg8
      mednafen
      protontricks
      quakespasm
      vkbasalt-cli
      wine
      winetricks

      # IDEs / agents
      vscode-fhs
      inputs.zed-fork.packages.${pkgs.system}.default
      inputs.claude-fork.packages.${pkgs.system}.default
    ];

  system.stateVersion = "21.11"; # WARNING: do not change after install unless you know the migration impact.
}
