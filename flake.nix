{
  description = "hugo bin versions";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs =
    { nixpkgs, self, ... }:
    let
      inherit (nixpkgs) lib;
      eachSystem =
        f:
        lib.genAttrs [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ] (
          system:
          f (
            import nixpkgs {
              inherit system;
              overlays = [ self.overlays.default ];
            }
          )
        );

    in
    {
      overlays.default = import ./default.nix;
      packages = eachSystem (pkgs: {
        hugo = pkgs.hugo-bin.latest.default;
        default = pkgs.hugo-bin.latest.default;
      });
      checks = eachSystem (pkgs: {
        hugo = pkgs.hugo-bin.latest.default;
      });
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.hugo-bin.latest.default ];
        };
      });
    };
}
