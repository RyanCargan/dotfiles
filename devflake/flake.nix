{
  description = "Portable prototype dev shell; subset of Ryan's NixOS system dev inventory";

  # On Ryan's NixOS machine this resolves through the system registry.
  # Once flake.lock is committed, other users get the exact pinned nixpkgs.
  inputs.nixpkgs.url = "nixpkgs";

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs systems
          (system: f system nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (system: pkgs:
        let
          lib = pkgs.lib;
          isLinux = pkgs.stdenv.hostPlatform.isLinux;

          devPkgs = import ./shared/dev-pkgs.nix {
            inherit pkgs lib;
          };

          mkPath = paths: lib.makeBinPath paths;

          mkLibPath = libs: lib.makeLibraryPath libs;

          mkIncludePath = libs:
            lib.makeSearchPathOutput "dev" "include" libs;

          mkPkgConfigPath = libs:
            lib.concatStringsSep ":" [
              (lib.makeSearchPathOutput "dev" "lib/pkgconfig" libs)
              (lib.makeSearchPathOutput "dev" "share/pkgconfig" libs)
            ];

          mkDevShell =
            { name
            , tools
            , libs
            , extraHook ? ""
            }:
            pkgs.mkShell {
              inherit name;

              packages = tools;

              # This is the main point of the dev flake:
              # expose dev outputs, headers, CMake/pkg-config metadata, and libs.
              buildInputs = libs;

              shellHook = ''
                export DEV_SHELL_NAME="${name}"

                export CC=clang
                export CXX=clang++
                export CMAKE_GENERATOR=Ninja

                # Make shell-local tool paths explicit for non-Nix-aware scripts.
                export PATH="${mkPath tools}:$PATH"

                ${lib.optionalString isLinux ''
                  export LD_LIBRARY_PATH="${mkLibPath libs}:''${LD_LIBRARY_PATH:-}"
                  export LIBRARY_PATH="${mkLibPath libs}:''${LIBRARY_PATH:-}"
                  export CPATH="${mkIncludePath libs}:''${CPATH:-}"
                  export PKG_CONFIG_PATH="${mkPkgConfigPath libs}:''${PKG_CONFIG_PATH:-}"
                ''}

                ${extraHook}

                echo "dev shell: $DEV_SHELL_NAME"
                echo "system:    ${system}"
                echo "cc:        $CC"
                echo "cxx:       $CXX"
              '';
            };
        in
        rec {
          # Portable/headless default.
          # Good for WSL, servers, SSH sessions, and non-GUI Unix users.
          core = mkDevShell {
            name = "prototype-core";
            tools = devPkgs.shells.coreTools;
            libs = devPkgs.shells.coreLibs;
          };

          # Native graphics/app dev.
          # Vulkan, SDL2, Wayland/X11 libs, shader tools, RenderDoc where available.
          gfx = mkDevShell {
            name = "prototype-gfx";
            tools = devPkgs.shells.coreTools ++ devPkgs.shells.gfxTools;
            libs = devPkgs.shells.coreLibs ++ devPkgs.shells.gfxLibs;
          };

          # Browser/WebAssembly dev.
          # Emscripten, Binaryen, Wasmer.
          wasm = mkDevShell {
            name = "prototype-wasm";
            tools = devPkgs.shells.coreTools ++ devPkgs.shells.wasmTools;
            libs = devPkgs.shells.coreLibs;

            extraHook = ''
              export EMSCRIPTEN_ROOT="${pkgs.emscripten}"
            '';
          };

          # Local everything shell.
          # Use this on Ryan's workstation when doing mixed native/GFX/WASM work.
          full = mkDevShell {
            name = "prototype-full";
            tools = devPkgs.shells.fullTools;
            libs = devPkgs.shells.fullLibs;

            extraHook = ''
              export EMSCRIPTEN_ROOT="${pkgs.emscripten}"
            '';
          };

          # Default must stay headless/portable.
          default = core;
        });
    };
}
