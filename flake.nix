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
        hugo_extended = pkgs.hugo-bin.latest.extended;
        hugo_extended_withdeploy = pkgs.hugo-bin.latest.extended_withdeploy;
        default = pkgs.hugo-bin.latest.default;
      });
      checks = eachSystem (pkgs: self.packages.${pkgs.system});
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.hugo-bin.latest.default ];
        };
      });
      legacyPackages = eachSystem lib.id;
    };
}
