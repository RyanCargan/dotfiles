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
        unstable = import inputs.unstable { config = config.nixpkgs.config; inherit (pkgs.stdenv.hostPlatform) system; };
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
    kernelParams = [ "mem_sleep_default=deep" "usbcore.autosuspend=-1" ];
    kernel.sysctl = { "kernel.perf_event_paranoid" = 1; "kernel.kptr_restrict" = 0; };
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
      pythonWithTools = python3.withPackages (p: with p; [
        pyside6 # Qt/Python GUI bindings for small native tools and experiments.
        pygame # Python SDL/game-loop experiments and simple media prototypes.
        matplotlib # Plotting and quick numerical/data visualizations.
        evdev # Python Linux input-device access for tablet/input tooling.
        python-uinput # Python uinput bindings for virtual input-device experiments.
        vpk # Valve Pak archive tooling for Source-engine/game asset work.
        pysdl2 # Python SDL2 bindings for lightweight graphics/input prototypes.
        uv # Fast Python package/environment tool.
      ]);

      gimpFull = gimp-with-plugins.override {
        plugins = with gimpPlugins; [
          gmic # GIMP image-processing/filter suite.
          resynthesizer # GIMP content-aware fill / texture synthesis plugin.
        ];
      };

      pkgsShellCore = [
        vim # Always-available terminal editor for config recovery.
        wget # Basic HTTP/file downloader.
        git # Version control baseline.
        jq # JSON query/filter tool for scripts and APIs.
        fzf # Fuzzy finder for shell navigation and pickers.
        fd # Fast ergonomic find replacement.
        ripgrep # Fast source/text search.
        ripgrep-all # ripgrep wrapper for PDFs, archives, docs, and rich files.
        silver-searcher # Older ag search tool; useful for muscle-memory/scripts.
        btop # Interactive process/resource monitor.
        ccache # Compiler cache for faster C/C++ rebuilds.
        yt-dlp # Media downloader/archiver.
        gron # Flatten JSON into greppable assignments.
        go-org # Org-mode parser/exporter utility.
        groff # Classic roff/manpage/document formatter.
        elinks # Text-mode browser for terminal/debug use.
        fbida # Framebuffer image/PDF viewers.
        busybox # Compact Unix tool collection for rescue/minimal scripts.
        starship # Cross-shell prompt.
        erdtree # Modern tree/disk-structure viewer.
      ];

      pkgsNixTooling = [
        cachix # Cachix binary-cache CLI.
        nixfmt # Classic Nix formatter.
        nixpkgs-fmt # Alternative Nix formatter used by older nixpkgs style.
        nixos-option # Query resolved NixOS option values.
        nix-du # Analyze Nix store/disk usage.
        nix-prefetch-git # Prefetch Git sources and hashes for Nix expressions.
        nix-index # Build/query command-not-found package index.
        nix-ld # Dynamic linker compatibility helper for foreign binaries.
        nil # Nix language server.
        nixd # Alternative Nix language server.
      ];

      pkgsFileArchiveDisk = [
        aria2 # aria2 download manager frontend/package.
        bat # Syntax-highlighted cat replacement.
        bchunk # Convert BIN/CUE CD images.
        colordiff # Colored diff output.
        cpulimit # Limit CPU usage of a process.
        desktop-file-utils # Validate/update .desktop launcher metadata.
        dpkg # Debian package inspection/extraction tools.
        evtest # Inspect Linux input events.
        exfatprogs # exFAT filesystem utilities.
        file # Identify file types by magic bytes.
        findutils # GNU find/xargs utilities.
        gparted # GUI partition editor.
        gptfdisk # GPT partitioning tools like gdisk/sgdisk.
        grub2_efi # GRUB EFI tooling; not the active bootloader here.
        httrack # Website mirroring/offline archive tool.
        hwinfo # Hardware probing utility.
        ifmetric # Adjust network interface route metrics.
        inxi # Human-readable system information summary.
        qdirstat # GUI disk-usage visualizer.
        lshw # Hardware inventory tool.
        lsix # Terminal image thumbnail helper.
        ncdu # Terminal disk-usage explorer.
        nethogs # Per-process network bandwidth monitor.
        newt # Dialog/whiptail-style TUI library/tools.
        p7zip # 7z archive support.
        parallel # GNU parallel job runner.
        parted # Partition manipulation CLI.
        pciutils # lspci and PCI inspection tools.
        smartmontools # SMART disk health tools.
        subversion # SVN client for legacy repos/assets.
        trash-cli # Freedesktop trash operations from CLI.
        tree # Directory tree printer.
        unrar # RAR archive extractor.
        unzip # ZIP extractor.
        xfsprogs # XFS filesystem tools.
        zip # ZIP archive creator/updater.
        zstd # Zstandard compression tools.
        cdrtools # ISO/CD tooling including mkisofs-style utilities.
        syslinux # Syslinux/isohybrid boot media tooling.
        xorriso # ISO authoring/editing tool.
      ];

      pkgsNetworkRemote = [
        autossh # Persistent/restarting SSH tunnels.
        awscli2 # AWS command-line tooling.
        cloudflared # Cloudflare tunnel client.
        iproute2 # ip/ss/tc networking tools.
        libpcap # Packet capture library/tools dependency.
        garage_2 # S3-compatible object store for small self-hosted geo-distributed deployments
        mosh # Roaming/latency-tolerant SSH alternative.
        ngrok # Public tunnels to local services.
        nmap # Network scanning and service discovery.
        opensnitch-ui # GUI for OpenSnitch firewall prompts/logs.
        remmina # Remote desktop client for RDP/VNC/SPICE/etc.
        samba # SMB/CIFS sharing/client tooling.
        sshfs # Mount remote filesystems over SSH.
        tcpdump # Packet capture CLI.
        tigervnc # VNC client/server tooling.
        tor # Tor daemon/client tooling.
        torsocks # Route individual CLI apps through Tor.
        wireshark # GUI packet analyzer.
      ];

      pkgsCommsPresence = [
        cheese # Webcam test/capture utility.
        sparrow # Wallet/security app currently kept from prior config.
        telegram-desktop # Telegram desktop client.
      ];

      pkgsWaylandHypr = [
        grim # Wayland screenshot capture.
        hyprlock # Hyprland lock screen.
        hyprpaper # Hyprland wallpaper daemon.
        rofi # Wayland app launcher/menu.
        slurp # Wayland region selector for screenshots.
        swappy # Screenshot annotation/editor.
        waybar # Wayland status bar.
        wl-clipboard # Wayland clipboard CLI tools.
      ];

      pkgsDesktopCommon = [
        autokey # Desktop automation/hotkey scripting.
        conky # Desktop/system monitor overlay.
        dmenu # Minimal X11 menu/launcher.
        dunst # Lightweight notification daemon.
        feh # Lightweight image viewer/wallpaper setter.
        flameshot # Screenshot UI.
        glava # Audio visualizer overlay.
        guake # Drop-down terminal.
        ksnip # Screenshot capture/annotation tool.
        libnotify # notify-send and notification helpers.
        maim # X11 screenshot utility.
        mlterm # Multilingual terminal emulator.
        polkit_gnome # Polkit authentication agent.
        st # suckless simple terminal.
        tilda # Drop-down terminal.
        tilix # Tiling terminal emulator.
        tmux # Terminal multiplexer.
        ulauncher # Desktop app launcher.
        virtualgl # Run GL apps through alternate GPU/display paths.
        volctl # Volume tray/control utility.
        xclip # X11 clipboard CLI.
        xdotool # X11 automation tool.
        xterm # Baseline X terminal.
        yad # GUI dialogs from shell scripts.
        zenity # GNOME-style GUI dialogs from shell scripts.
      ];

      pkgsDesktopKdeQt = [
        kdePackages.ark # KDE archive manager.
        kdePackages.kalarm # KDE alarm/reminder tool.
      ];

      pkgsX11DevCompat = [
        libX11 # X11 client library, useful for native builds.
        libXext # X11 extension library for native builds.
        libXi # XInput library for input-heavy native apps.
        libXxf86vm # XF86VidMode library for old GL/game deps.
        xdpyinfo # Inspect X display capabilities.
        xev # Inspect X events/input.
        xhost # Manage X server access control.
        xmessage # Tiny X11 message dialog utility.
        xmodmap # Inspect/edit X keymaps.
        xprop # Inspect X window properties.
        xrandr # X display layout/monitor control.
        xwininfo # Inspect X window geometry/properties.
      ];

      pkgsXfceCompat = [
        thunar # Lightweight file manager.
        thunar-volman # Thunar removable-volume integration.
        tumbler # Thumbnail service for Thunar/desktop apps.
        xfce4-screenshooter # XFCE screenshot utility kept for compatibility.
        xfce4-whiskermenu-plugin # XFCE menu plugin kept for legacy session pieces.
      ];

      pkgsBrowsers = [
        google-chrome # Proprietary Chrome for compatibility/testing.
        tor-browser # Tor Browser bundle.
        ungoogled-chromium # Chromium variant without Google integration.
        inputs.firefox.packages.${pkgs.stdenv.hostPlatform.system}.firefox-nightly-bin # Firefox Nightly from flake input.
      ];

      pkgsWebDev = [
        filezilla # FTP/SFTP GUI client.
        flyctl # Fly.io deployment CLI.
        mkcert # Local trusted dev certificates.
        nodejs # Default Node.js from current nixpkgs.
        asar # Electron asar archive pack/unpack tool.
        pnpm # JS package manager.
        sass # Sass/SCSS compiler.
        speedtest-cli # Network speed testing from CLI.
      ];

      pkgsDocsWriting = [
        abiword # Lightweight word processor.
        calibre # Ebook manager/converter.
        djvu2pdf # Convert DjVu documents to PDF.
        djvulibre # DjVu tools and libraries.
        exiftool # Metadata reader/writer for media/doc files.
        ghostscript # PostScript/PDF interpreter and converter.
        graphviz # Dot graph rendering.
        kdePackages.ghostwriter # Markdown editor.
        kdePackages.kate # KDE text/code editor.
        kdePackages.okular # PDF/document viewer.
        languagetool # Grammar/style checker.
        ocamlPackages.cpdf # Command-line PDF manipulation tool.
        pandoc # Universal document converter.
        pdftk # PDF toolkit for splitting/merging/forms.
        poppler-utils # PDF utilities like pdftotext/pdfinfo.
        vale # Prose/style linter.
        yacreader # Comic/manga reader.
        zgrviewer # Graphviz/DOT graph viewer.
      ];

      pkgsAudioCore = [
        alsa-tools # ALSA diagnostic and control tools.
        alsa-utils # aplay/arecord/amixer and ALSA basics.
        easyeffects # PipeWire audio effects processor.
        pavucontrol # PulseAudio/PipeWire volume control GUI.
        pipewire # PipeWire user tools.
        qpwgraph # PipeWire/JACK patchbay graph UI.
        wireplumber # PipeWire session manager tools.
      ];

      pkgsAudioProduction = [
        audacity # Audio editor/recorder.
        csound # Sound synthesis/audio programming system.
        reaper # DAW for audio production.
        sox # Swiss-army audio conversion/processing CLI.
      ];

      pkgsVideoMedia = [
        ffmpeg-full # Full FFmpeg build with broad codec/filter support.
        glaxnimate # 2D vector animation tool, useful with Kdenlive.
        kdePackages.kdenlive # Video editor.
        mkvtoolnix # Matroska/MKV inspection and muxing tools.
        obs-studio # Recording/streaming studio.
        simplescreenrecorder # Simple X11 screen recorder fallback.
        vlc # General media player.
      ];

      pkgsArtImage3d = [
        blender # 3D modeling/rendering/animation suite.
        gimpFull # GIMP plus selected plugins.
        inkscape # Vector graphics editor.
        openimageio # Image IO/conversion tools for VFX/render pipelines.
      ];

      pkgsEducationMiscGui = [
        anki-bin # Spaced-repetition flashcards.
        d2 # Text-to-diagram renderer.
        freeplane # Mind-mapping/outlining tool.
        hakuneko # Manga/comic downloader.
        input-remapper # GUI input remapping utility.
        jmtpfs # Android MTP FUSE filesystem.
        lightspark # Flash player implementation.
        pspp # SPSS-like statistics tool.
        xmind # Mind-mapping app.
      ];

      pkgsDbSqlite = [
        sqlite # SQLite CLI/library.
        sqlite-utils # Ergonomic SQLite import/query utility.
        sqlitebrowser # GUI SQLite database browser.
        sqlitecpp # C++ SQLite wrapper library.
        sqldiff # SQLite database diff tool.
      ];

      pkgsDbServices = [
        isso # Lightweight self-hosted comment server.
      ];

      pkgsCppCompilers = [
        clang # LLVM C/C++ compiler; current nixpkgs default.
        gcc # GNU C/C++ compiler; useful for compatibility comparisons.
        zig # Zig compiler/build system; useful as build.zig orchestrator and C toolchain wrapper.
        zls # Zig language server.
      ];

      pkgsCppBuildLink = [
        bintools-unwrapped # Raw binutils tools for linker/assembler/object work.
        cmake # Cross-platform build-system generator.
        gnumake # Make build tool.
        mold # Fast modern linker.
        ninja # Fast low-overhead build executor.
        pkg-config # Discover compiler/linker flags for libraries.
      ];

      pkgsCppLlvmRuntime = [
        clang-tools # clangd/clang-tidy/clang-format and related LLVM tools.
        llvmPackages.compiler-rt # LLVM runtime libs including sanitizer runtimes.
        llvmPackages.libcxx # LLVM C++ standard library for libc++ testing.
        llvmPackages.lld # LLVM linker.
      ];

      pkgsCppStaticAnalysis = [
        ccls # C/C++ language server alternative to clangd.
        cppcheck # Static analyzer for C/C++ bugs and style issues.
        include-what-you-use # Header include hygiene analyzer.
        universal-ctags # Source symbol index generator.
        uncrustify # C/C++/C-like source formatter.
      ];

      pkgsCppDebug = [
        gdb # GNU debugger; also used with rr replay.
        lldb # LLVM debugger.
        rr # Record/replay debugger for deterministic reverse debugging.
        valgrind # Dynamic analysis suite; includes Memcheck, Cachegrind, Callgrind, Massif, etc.
      ];

      pkgsCppLibraries = [
        cppzmq # Header-only C++ bindings for ZeroMQ.
        libgccjit # GCC JIT library, useful for compiler/runtime experiments.
        SDL2 # SDL2 game/input/window/audio development library.
      ];

      pkgsCppParsingCodegen = [
        bison # Parser generator.
        flex # Lexer generator.
      ];

      pkgsCppInteractive = [
        cling # Interactive C++ interpreter/repl.
      ];

      pkgsCppSystemHeaders = [
        linuxHeaders # Linux kernel headers for low-level/system builds.
        linuxKernel.packages.linux_6_6.v4l2loopback # v4l2loopback package matching linux_6_6.
      ];

      pkgsWasm = [
        binaryen # WebAssembly optimizer/tool suite; provides wasm-opt.
        wasmer # WebAssembly runtime for running WASM modules.
        emscripten # LLVM-to-JavaScript Compiler
      ];

      pkgsVulkanRuntimeDev = [
        vulkan-headers # Vulkan C headers for builds.
        vulkan-loader # Vulkan ICD loader library.
        vulkan-tools # vulkaninfo and other Vulkan diagnostics.
        vulkan-validation-layers # Khronos validation layers for debugging Vulkan API use.
        vulkan-extension-layer # Extra Vulkan extension emulation/layer support.
      ];

      pkgsShaderToolchain = [
        shader-slang # Slang shader language/compiler for modular shader codebases.
        shaderc # GLSL/HLSL to SPIR-V compiler library/tools.
        glslang # Khronos GLSL/HLSL front-end and validator.
        spirv-cross # SPIR-V reflection and cross-compilation tool.
        spirv-headers # SPIR-V registry headers.
        spirv-tools # SPIR-V assembler/disassembler/validator/optimizer tools.
      ];

      pkgsGpuDebug = [
        renderdoc # GPU frame capture/debugger for graphics APIs.
      ];

      pkgsProfilingCpu = [
        perf # Linux perf profiler matching kernel package set.
        flamegraph # Generate flame graphs from profiling stacks.
        hotspot # GUI for perf.data analysis.
        gperftools # Google performance tools: tcmalloc, CPU/heap profiler.
      ];

      pkgsProfilingMemory = [
        heaptrack # Heap allocation profiler.
        kdePackages.kcachegrind # GUI to profilers such as Valgrind
      ];

      pkgsTracingKernel = [
        bpftrace # High-level eBPF tracing language/tool.
        kernelshark # GUI trace visualizer for ftrace/trace-cmd data.
        sysprof # System-wide profiler with GUI integration.
        trace-cmd # ftrace command-line recorder/report tool.
      ];

      pkgsProfilingInstrumentation = [
        tracy # Real-time instrumentation profiler.
      ];

      pkgsPython = [
        poetry # Python dependency/project manager.
        pythonWithTools # Custom Python 3.12 environment defined above.
      ];

      pkgsAndroid = [
        android-tools # adb/fastboot Android device tools.
        watchman # File-watching service used by some mobile/dev workflows.
        wmname # Set WM name to placate some Java GUI apps.
      ];

      pkgsGameLaunchCompat = [
        appimage-run # Run AppImage binaries on NixOS.
        protontricks # Winetricks-like helper for Proton prefixes.
        vkbasalt-cli # vkBasalt Vulkan post-processing control CLI.
        wine # Windows compatibility layer.
        winetricks # Helper for Wine DLL/runtime setup.
      ];

      pkgsGamesNative = [
        darkplaces # Quake engine port.
        gzdoom # Doom engine source port.
        quakespasm # Quake engine source port.
      ];

      pkgsEmulation = [
        kega-fusion # Sega emulator.
        libjpeg8 # Legacy JPEG library kept for old binary/game compatibility.
        mednafen # Multi-system emulator.
      ];

      pkgsIdeEditorsAgents = [
        vscode-fhs # VS Code in FHS environment for extension/binary compatibility.
        inputs.zed-fork.packages.${pkgs.stdenv.hostPlatform.system}.default # Zed editor from flake input.
        inputs.claude-fork.packages.${pkgs.stdenv.hostPlatform.system}.default # Claude Code package from flake input.
      ];
    in
    pkgsShellCore
    ++ pkgsNixTooling
    ++ pkgsFileArchiveDisk
    ++ pkgsNetworkRemote
    ++ pkgsCommsPresence
    ++ pkgsWaylandHypr
    ++ pkgsDesktopCommon
    ++ pkgsDesktopKdeQt
    ++ pkgsX11DevCompat
    ++ pkgsXfceCompat
    ++ pkgsBrowsers
    ++ pkgsWebDev
    ++ pkgsDocsWriting
    ++ pkgsAudioCore
    ++ pkgsAudioProduction
    ++ pkgsVideoMedia
    ++ pkgsArtImage3d
    ++ pkgsEducationMiscGui
    ++ pkgsDbSqlite
    ++ pkgsDbServices
    ++ pkgsCppCompilers
    ++ pkgsCppBuildLink
    ++ pkgsCppLlvmRuntime
    ++ pkgsCppStaticAnalysis
    ++ pkgsCppDebug
    ++ pkgsCppLibraries
    ++ pkgsCppParsingCodegen
    ++ pkgsCppInteractive
    ++ pkgsCppSystemHeaders
    ++ pkgsWasm
    ++ pkgsVulkanRuntimeDev
    ++ pkgsShaderToolchain
    ++ pkgsGpuDebug
    ++ pkgsProfilingCpu
    ++ pkgsProfilingMemory
    ++ pkgsTracingKernel
    ++ pkgsProfilingInstrumentation
    ++ pkgsPython
    ++ pkgsAndroid
    ++ pkgsGameLaunchCompat
    ++ pkgsGamesNative
    ++ pkgsEmulation
    ++ pkgsIdeEditorsAgents;

  system.stateVersion = "21.11"; # WARNING: do not change after install unless you know the migration impact.
}
