{ pkgs, lib ? pkgs.lib }:

let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isX86Linux = pkgs.stdenv.hostPlatform.system == "x86_64-linux";

  pythonWithTools = pkgs.python3.withPackages (p: with p; [
    pyside6 # Qt/Python GUI bindings for small native tools and experiments.
    pygame # Python SDL/game-loop experiments and simple media prototypes.
    matplotlib # Plotting and quick numerical/data visualizations.
    evdev # Python Linux input-device access for tablet/input tooling.
    python-uinput # Python uinput bindings for virtual input-device experiments.
    vpk # Valve Pak archive tooling for Source-engine/game asset work.
    pysdl2 # Python SDL2 bindings for lightweight graphics/input prototypes.
    uv # Fast Python package/environment tool.
  ]);
in
rec {
  tools = rec {
    # Small CLI/dev-shell basics.
    shellCore = with pkgs; [
      git
      jq
      fzf
      fd
      ripgrep
      tree
      file
      unzip
      zip
      zstd
      ccache

      shellcheck
      shfmt
    ];

    nix = with pkgs; [
      cachix
      nixfmt
      nixpkgs-fmt
      nixos-option
      nix-du
      nix-prefetch-git
      nix-index
      nil
      nixd
    ];

    web = with pkgs; [
      nodejs
      pnpm
      sass
    ];

    db = with pkgs; [
      sqlite
      sqlite-utils
      sqlitebrowser
      sqlitecpp
      sqldiff
    ];

    cppCompilers = with pkgs; [
      clang
      gcc
      zig
      zls
    ];

    cppBuildLink = with pkgs; [
      bintools-unwrapped
      cmake
      gnumake
      mold
      ninja
      pkg-config
    ];

    cppLlvmRuntime = with pkgs; [
      clang-tools
      llvmPackages.compiler-rt
      llvmPackages.libcxx
      llvmPackages.lld
    ];

    cppStaticAnalysis = with pkgs; [
      ccls
      cppcheck
      include-what-you-use
      universal-ctags
      uncrustify
    ];

    cppDebug = with pkgs; [
      gdb
      lldb
      valgrind
    ] ++ lib.optionals isX86Linux [
      pkgs.rr
    ];

    cppParsingCodegen = with pkgs; [
      bison
      flex
    ];

    cppInteractive = with pkgs; [
      cling
    ];

    wasm = with pkgs; [
      binaryen
      wasmer
      emscripten
    ];

    vulkanRuntimeDev = lib.optionals isLinux (with pkgs; [
      vulkan-headers
      vulkan-loader
      vulkan-tools
      vulkan-validation-layers
      vulkan-extension-layer
    ]);

    shaderToolchain = lib.optionals isLinux (with pkgs; [
      shader-slang
      shaderc
      glslang
      spirv-cross
      spirv-headers
      spirv-tools
    ]);

    gpuDebug = lib.optionals isX86Linux (with pkgs; [
      renderdoc
    ]);

    profilingCpu = with pkgs; [
      perf
      flamegraph
      hotspot
      gperftools
    ];

    profilingMemory = with pkgs; [
      heaptrack
      kdePackages.kcachegrind
    ];

    tracingKernel = with pkgs; [
      bpftrace
      kernelshark
      sysprof
      trace-cmd
    ];

    profilingInstrumentation = with pkgs; [
      tracy
    ];

    python = with pkgs; [
      poetry
      pythonWithTools
      uv
    ];

    headless =
      shellCore
      ++ nix
      ++ web
      ++ db
      ++ cppCompilers
      ++ cppBuildLink
      ++ cppLlvmRuntime
      ++ cppStaticAnalysis
      ++ cppDebug
      ++ cppParsingCodegen
      ++ cppInteractive
      ++ python;

    graphics =
      vulkanRuntimeDev
      ++ shaderToolchain
      ++ gpuDebug;

    full =
      headless
      ++ wasm
      ++ graphics
      ++ profilingCpu
      ++ profilingMemory
      ++ tracingKernel
      ++ profilingInstrumentation;
  };

  libs = rec {
    core = with pkgs; [
      zlib
      openssl
      libffi

      sqlite
      sqlitecpp

      cppzmq
      libgccjit
    ];

    graphics = lib.optionals isLinux (with pkgs; [
      SDL2

      libGL
      libxkbcommon

      wayland
      wayland-protocols

      libx11
      libxext
      libxi
      libxxf86vm

      vulkan-headers
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer
    ]);

    full = core ++ graphics;
  };

  # System config imports this to preserve:
  #   system config = superset / inventory owner
  systemPackages =
    tools.full
    ++ libs.full;

  # Dev flake imports this as an exposure shim:
  #   dev shell = subset of system + dev-output/header/pkg-config/libpath exposure
  shells = {
    coreTools = tools.headless;
    coreLibs = libs.core;

    gfxTools = tools.graphics;
    gfxLibs = libs.graphics;

    wasmTools = tools.wasm;

    fullTools = tools.full;
    fullLibs = libs.full;
  };
}
