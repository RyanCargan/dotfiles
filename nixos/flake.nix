{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    firefox.url = "github:nix-community/flake-firefox-nightly";
    zed-fork.url = "github:RyanCargan/zed";
    claude-fork.url = "github:RyanCargan/nix-claude-code";
  };
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
      specialArgs = { inherit inputs; };
    };
  };
}
