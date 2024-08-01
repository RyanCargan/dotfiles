{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # release2105.url = "github:NixOS/nixpkgs/nixos-21.05";
    release2111.url = "github:NixOS/nixpkgs/nixos-21.11";
    # nix.url = "github.com:NixOS/nix/2.5-maintenance"; # Add 'nix' to outputs along with nixpkgs if needed
    # pythonOnNix.url = "github:on-nix/python/2e735762c73651cffc027ca850b2a58d87d54b49";
    # pythonOnNix.inputs.nixpkgs.follows = "nixpkgs";
    # blender.url = "github:edolstra/nix-warez?dir=blender"; # Don't pass to outputs since it isn't used immediately
    # poetry2nix.url = "github:nix-community/poetry2nix/1.26.0";
  };
  outputs = { self, nixpkgs, ... }@inputs: {
    #     nixpkgs.config.allowUnfree = true;
    #     release2105.config.allowUnfree = true;
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      #       flake2105 = import inputs.release2105 {
      # 	    inherit system;
      # 	    config.allowUnfree = true;
      #       };
      modules =
        [ (import ./configuration.nix) ];
      specialArgs = { inherit inputs; };
    };
  };
}
