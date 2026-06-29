{
  description = "Portable all-purpose dev shell for prototype work";

  # On your NixOS machine this resolves through the system registry.
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
          isX86Linux = system == "x86_64-linux";

          coreTools = with pkgs; [
            bashInteractive
            git
            gnumake
            cmake
            ninja
            pkg-config
            ccache

            clang
            clang-tools
            gcc
            lldb

            jq
            fd
            ripgrep
            fzf
            tree
            file
            unzip
            zip
            zstd

            shellcheck
            shfmt

            nodejs
            pnpm

            python313
            uv

            nil
            nixd
          ] ++ lib.optionals isLinux (with pkgs; [
            mold
            gdb
            valgrind
          ]);

          cppLibs = with pkgs; [
            zlib
            openssl
            libffi
            sqlite
            SDL2
          ];

          linuxGraphicsLibs = lib.optionals isLinux (with pkgs; [
            libGL
            libxkbcommon
            wayland
            wayland-protocols

            vulkan-headers
            vulkan-loader
            vulkan-validation-layers

            shaderc
            glslang
            spirv-tools
            spirv-cross
          ]);

          linuxX11Libs = lib.optionals isLinux (with pkgs; [
            libx11
            libxext
            libxi
            libxxf86vm
          ]);

          graphicsTools = lib.optionals isLinux (with pkgs; [
            vulkan-tools
            renderdoc
            shader-slang
          ]);

          wasmTools = with pkgs; [
            emscripten
            binaryen
            wasmer
          ];

          debugTools = lib.optionals isX86Linux (with pkgs; [
            rr
          ]);

          runtimeLibs =
            cppLibs
            ++ linuxGraphicsLibs
            ++ linuxX11Libs;

          mkDevShell = extraTools:
            pkgs.mkShell {
              packages = coreTools ++ extraTools;

              # buildInputs expose headers, pkg-config files, and dev outputs.
              buildInputs = runtimeLibs;

              shellHook = ''
                export DEV_SHELL_NAME=prototype
                export CC=clang
                export CXX=clang++
                export CMAKE_GENERATOR=Ninja

                ${lib.optionalString isLinux ''
                  export LD_LIBRARY_PATH="${lib.makeLibraryPath runtimeLibs}:''${LD_LIBRARY_PATH:-}"
                ''}

                echo "dev shell: $DEV_SHELL_NAME (${system})"
                echo "cc:  $CC"
                echo "cxx: $CXX"
              '';
            };
        in
        rec {
          core = mkDevShell [ ];
          graphics = mkDevShell graphicsTools;
          wasm = mkDevShell wasmTools;
          full = mkDevShell (graphicsTools ++ wasmTools ++ debugTools);

          default = full;
        });
    };
}
