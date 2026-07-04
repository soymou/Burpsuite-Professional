{
  description = "A nixos flake for burpsuite pro";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "aarch64-darwin";
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };
  in {
    packages.${system} = {
      burpsuitepro =
        pkgs.callPackage ./default.nix {
        };
      default = self.packages.${system}.burpsuitepro;
    };
  };
}
