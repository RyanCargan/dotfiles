{ config, pkgs, inputs, lib, ... }:

with pkgs;

{
  imports = [ ./hardware-configuration.nix ./cachix.nix ];

  nix = {
    package = pkgs.nixVersions.stable;
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
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
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
        unstable = import inputs.unstable {
          config = config.nixpkgs.config;
          inherit (pkgs.stdenv.hostPlatform) system;
        };
      };
    };

    overlays = [
      (self: super: { wine = super.wineWow64Packages.stableFull; })
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
    kernelParams = [
      "mem_sleep_default=deep"
      "usbcore.autosuspend=-1"
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
    ];
    kernel.sysctl = {
      "kernel.perf_event_paranoid" = 1;
      "kernel.kptr_restrict" = 0;
    };
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
      extraGroups = [
        "wheel"
        "libvirtd"
        "kvm"
        "qemu-libvirtd"
        "audio"
        "video"
        "networkmanager"
        "vglusers"
        "lxd"
        "docker"
        "jackaudio"
      ];
    };

    users.rishindu = {
      createHome = true;
      isNormalUser = true;
      group = "users";
      home = "/home/rishindu";
      uid = 1001;
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

    "/run/media/ryan/nixos" = {
      device = "/mnt/nixos-storage";
      fsType = "none";
      options = [ "bind" "nofail" ];
    };

    "/run/media/ryan/ubuntu" = {
      device = "/mnt/ubuntu-storage";
      fsType = "none";
      options = [ "bind" "nofail" ];
    };

    "/run/media/ryan/swap" = {
      device = "/mnt/swap-storage";
      fsType = "none";
      options = [ "bind" "nofail" ];
    };
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

    openssh = {
      enable = true;
      settings.X11Forwarding = true;
    };

    clamav = {
      daemon.enable = false;
      updater.enable = false;
    };

    mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };

    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      desktopManager.xterm.enable = false;
    };

    displayManager = {
      defaultSession = "hyprland";
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };

    gvfs = {
      enable = true;
      package = lib.mkForce pkgs.gnome.gvfs;
    };

    pulseaudio.enable = false;
    jack.jackd.enable = false;

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    blueman.enable = false;
    gnome.gnome-keyring.enable = true;
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
    docker.enable = true;
  };

  programs = {
    virt-manager.enable = true;
    nm-applet.enable = true;
    haguichi.enable = true;

    hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    dconf.enable = true;
    droidcam.enable = true;
    gamemode.enable = true;

    nix-ld = {
      enable = true;
      libraries = [ openssl ];
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    steam = {
      enable = true;
      extraPackages = [
        gamescope
        steamtinkerlaunch
        vkbasalt
      ];
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
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

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

    opentabletdriver = {
      enable = true;
      daemon.enable = true;
    };
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
    packages = with pkgs; [
      source-code-pro
      liberation_ttf
      dejavu_fonts
      open-sans

      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji

      nerd-fonts.symbols-only
    ];

    fontDir.enable = true;

    fontconfig.defaultFonts = {
      monospace = [
        "Source Code Pro"
        "Symbols Nerd Font"
        "Noto Color Emoji"
      ];
      sansSerif = [
        "Open Sans"
        "Noto Sans"
        "Noto Color Emoji"
      ];
      serif = [
        "Liberation Serif"
        "Noto Serif"
        "Noto Color Emoji"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  environment.systemPackages = with pkgs;
    let
      # Shared dev/toolchain inventory.
      #
      # Policy:
      #   system config = superset / inventory owner
      #   dev flake     = subset / exposure shim
      devPkgs = import ./shared/dev-pkgs.nix {
        inherit pkgs lib;
      };

      gimpFull = gimp-with-plugins.override {
        plugins = with gimpPlugins; [
          gmic
          resynthesizer
        ];
      };

      # OS/rescue/shell basics that are not specifically dev-shell inventory.
      pkgsShellCore = [
        vim
        wget
        ripgrep-all
        silver-searcher
        btop
        yt-dlp
        gron
        go-org
        groff
        elinks
        fbida
        busybox
        starship
        erdtree
      ];

      pkgsFileArchiveDisk = [
        aria2
        bat
        bchunk
        colordiff
        cpulimit
        desktop-file-utils
        dpkg
        evtest
        exfatprogs
        findutils
        gparted
        gptfdisk
        grub2_efi
        httrack
        hwinfo
        ifmetric
        inxi
        qdirstat
        lshw
        lsix
        ncdu
        nethogs
        newt
        p7zip
        parallel
        parted
        pciutils
        smartmontools
        subversion
        trash-cli
        unrar
        xfsprogs
        cdrtools
        syslinux
        xorriso
      ];

      pkgsNetworkRemote = [
        autossh
        awscli2
        cloudflared
        iproute2
        libpcap
        garage_2
        mosh
        ngrok
        nmap
        opensnitch-ui
        remmina
        samba
        sshfs
        tcpdump
        tigervnc
        tor
        torsocks
        wireshark
      ];

      pkgsCommsPresence = [
        cheese
        sparrow
        telegram-desktop
      ];

      pkgsWaylandHypr = [
        grim
        hyprlock
        hyprpaper
        rofi
        slurp
        swappy
        waybar
        wl-clipboard
      ];

      pkgsDesktopCommon = [
        autokey
        conky
        dmenu
        dunst
        feh
        flameshot
        glava
        guake
        ksnip
        libnotify
        maim
        mlterm
        polkit_gnome
        st
        tilda
        tilix
        tmux
        ulauncher
        virtualgl
        volctl
        xclip
        xdotool
        xterm
        yad
        zenity
      ];

      pkgsDesktopKdeQt = [
        kdePackages.ark
        kdePackages.kalarm
      ];

      # X11 inspection/compat utilities.
      # X11 dev libraries moved to shared/dev-pkgs.nix.
      pkgsX11Tools = [
        xdpyinfo
        xev
        xhost
        xmessage
        xmodmap
        xprop
        xrandr
        xwininfo
      ];

      pkgsXfceCompat = [
        thunar
        thunar-volman
        tumbler
        xfce4-screenshooter
        xfce4-whiskermenu-plugin
      ];

      pkgsBrowsers = [
        google-chrome
        tor-browser
        ungoogled-chromium
        inputs.firefox.packages.${pkgs.stdenv.hostPlatform.system}.firefox-nightly-bin
      ];

      # Non-core web/network user tools.
      # nodejs/pnpm/sass/mkcert/flyctl/asar moved to shared/dev-pkgs.nix.
      pkgsWebUserTools = [
        filezilla
        speedtest-cli
      ];

      pkgsDocsWriting = [
        abiword
        calibre
        djvu2pdf
        djvulibre
        exiftool
        ghostscript
        graphviz
        kdePackages.ghostwriter
        kdePackages.kate
        kdePackages.okular
        languagetool
        ocamlPackages.cpdf
        pandoc
        pdftk
        poppler-utils
        vale
        yacreader
        zgrviewer
      ];

      pkgsAudioCore = [
        alsa-tools
        alsa-utils
        easyeffects
        pavucontrol
        pipewire
        qpwgraph
        wireplumber
      ];

      pkgsAudioProduction = [
        audacity
        csound
        reaper
        sox
      ];

      pkgsVideoMedia = [
        ffmpeg-full
        glaxnimate
        kdePackages.kdenlive
        mkvtoolnix
        obs-studio
        simplescreenrecorder
        vlc
      ];

      pkgsArtImage3d = [
        blender
        gimpFull
        inkscape
        openimageio
      ];

      pkgsEducationMiscGui = [
        anki-bin
        d2
        freeplane
        hakuneko
        input-remapper
        jmtpfs
        lightspark
        pspp
        xmind
      ];

      pkgsDbServices = [
        isso
      ];

      pkgsSystemHeaders = [
        linuxHeaders
        linuxKernel.packages.linux_6_6.v4l2loopback
      ];

      pkgsAndroid = [
        android-tools
        watchman
        wmname
      ];

      pkgsGameLaunchCompat = [
        appimage-run
        protontricks
        vkbasalt-cli
        wine
        winetricks
      ];

      pkgsGamesNative = [
        darkplaces
        gzdoom
        quakespasm
      ];

      pkgsEmulation = [
        kega-fusion
        libjpeg8
        mednafen
      ];

      pkgsIdeEditorsAgents = [
        vscode-fhs
        inputs.zed-fork.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.claude-fork.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    in
    lib.unique (
      pkgsShellCore
      ++ pkgsFileArchiveDisk
      ++ pkgsNetworkRemote
      ++ pkgsCommsPresence
      ++ pkgsWaylandHypr
      ++ pkgsDesktopCommon
      ++ pkgsDesktopKdeQt
      ++ pkgsX11Tools
      ++ pkgsXfceCompat
      ++ pkgsBrowsers
      ++ pkgsWebUserTools
      ++ pkgsDocsWriting
      ++ pkgsAudioCore
      ++ pkgsAudioProduction
      ++ pkgsVideoMedia
      ++ pkgsArtImage3d
      ++ pkgsEducationMiscGui
      ++ pkgsDbServices
      ++ pkgsSystemHeaders
      ++ pkgsAndroid
      ++ pkgsGameLaunchCompat
      ++ pkgsGamesNative
      ++ pkgsEmulation
      ++ pkgsIdeEditorsAgents

      # Shared system/dev package inventory.
      # This keeps the system config as the superset and lets the dev flake
      # remain only an exposure shim.
      ++ devPkgs.systemPackages
    );

  system.stateVersion = "21.11";
}
