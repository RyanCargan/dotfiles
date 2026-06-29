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

    # Nix/flake/dev-shell tooling.
    nix = with pkgs; [
      cachix
      nixfmt
      nixpkgs-fmt
      nixos-option
      nix-du
      nix-prefetch-git
      nix-index
      nix-ld
      nil
      nixd
    ];

    # JS/web/project tooling.
    web = with pkgs; [
      nodejs
      pnpm
      sass
      asar
      mkcert
      flyctl
    ];

    # SQLite and small local DB tooling.
    db = with pkgs; [
      sqlite
      sqlite-utils
      sqlitebrowser
      sqlitecpp
      sqldiff
    ];

    # C/C++/Zig compilers.
    cppCompilers = with pkgs; [
      clang
      gcc
      zig
      zls
    ];

    # Build/link tooling.
    cppBuildLink = with pkgs; [
      bintools-unwrapped
      cmake
      gnumake
      mold
      ninja
      pkg-config
    ];

    # LLVM runtime/toolchain pieces.
    cppLlvmRuntime = with pkgs; [
      clang-tools
      llvmPackages.compiler-rt
      llvmPackages.libcxx
      llvmPackages.lld
    ];

    # Static analysis/indexing/formatting.
    cppStaticAnalysis = with pkgs; [
      ccls
      cppcheck
      include-what-you-use
      universal-ctags
      uncrustify
    ];

    # Native debugging.
    cppDebug = with pkgs; [
      gdb
      lldb
      valgrind
    ] ++ lib.optionals isX86Linux (with pkgs; [
      rr
    ]);

    # Parser/codegen tools.
    cppParsingCodegen = with pkgs; [
      bison
      flex
    ];

    # Interactive C++.
    cppInteractive = with pkgs; [
      cling
    ];

    # WebAssembly / browser-native tooling.
    wasm = with pkgs; [
      binaryen
      wasmer
      emscripten
    ];

    # Vulkan runtime/dev tools.
    vulkanRuntimeDev = lib.optionals isLinux (with pkgs; [
      vulkan-headers
      vulkan-loader
      vulkan-tools
      vulkan-validation-layers
      vulkan-extension-layer
    ]);

    # Shader toolchain.
    shaderToolchain = lib.optionals isLinux (with pkgs; [
      shader-slang
      shaderc
      glslang
      spirv-cross
      spirv-headers
      spirv-tools
    ]);

    # GPU debugging. RenderDoc is mostly relevant on x86 Linux.
    gpuDebug = lib.optionals isX86Linux (with pkgs; [
      renderdoc
    ]);

    # CPU profiling.
    profilingCpu = with pkgs; [
      perf
      flamegraph
      hotspot
      gperftools
    ];

    # Memory profiling.
    profilingMemory = with pkgs; [
      heaptrack
      kdePackages.kcachegrind
    ];

    # Kernel/system tracing.
    tracingKernel = with pkgs; [
      bpftrace
      kernelshark
      sysprof
      trace-cmd
    ];

    # Instrumentation profiler.
    profilingInstrumentation = with pkgs; [
      tracy
    ];

    # Python project tooling.
    python = with pkgs; [
      poetry
      uv
      pythonWithTools
    ];

    # Mostly headless dev shell.
    # This is the safe portable default for Unix/WSL users.
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

    # Explicit graphics/game/native-app dev layer.
    graphics =
      vulkanRuntimeDev
      ++ shaderToolchain
      ++ gpuDebug;

    # Full local dev inventory.
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
    # Core build/runtime libraries whose dev outputs/headers/pkg-config metadata
    # are useful inside project shells.
    core = with pkgs; [
      zlib
      openssl
      libffi

      sqlite
      sqlitecpp

      cppzmq
      libgccjit
    ];

    # Graphics/windowing/input/rendering libraries.
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

  # Imported by configuration.nix.
  #
  # Policy:
  #   system config = superset / inventory owner
  #   dev flake     = subset / exposure shim
  #
  # So the system installs the whole shared dev inventory.
  systemPackages =
    tools.full
    ++ libs.full;

  # Imported by devflake/flake.nix.
  #
  # The dev shell uses these lists to expose dev outputs, headers,
  # pkg-config paths, library paths, and shell variables.
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
