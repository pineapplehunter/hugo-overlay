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
      overlays.default = import ./overlay.nix;
      packages = eachSystem (
        pkgs:
        let
          all-versions = lib.attrNames pkgs.hugo-bin;
          all-hugo-versions = lib.listToAttrs (
            map (v: {
              name = "hugo_${lib.replaceString "." "_" (lib.toLower v)}";
              value = pkgs.hugo-bin.${v}.default;
            }) all-versions
          );
        in
        {
          hugo = pkgs.hugo-bin.latest.default;
          hugo_extended = pkgs.hugo-bin.latest.extended;
          hugo_extended_withdeploy = pkgs.hugo-bin.latest.extended_withdeploy;
          default = pkgs.hugo-bin.latest.extended_withdeploy;
        }
        // all-hugo-versions
      );
      checks = eachSystem (pkgs: {
        hugo = pkgs.hugo-bin.latest.default;
        hugo_extended = pkgs.hugo-bin.latest.extended;
        hugo_extended_withdeploy = pkgs.hugo-bin.latest.extended_withdeploy;
        default = pkgs.hugo-bin.latest.extended_withdeploy;
      });
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.hugo-bin.latest.default ];
        };
      });
      legacyPackages = eachSystem lib.id;
    };
}
