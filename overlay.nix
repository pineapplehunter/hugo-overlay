final: prev:
let
  inherit (prev) lib;
  versions = map (x: lib.removeSuffix ".json" x) (builtins.attrNames (builtins.readDir ./versions));
  files = lib.genAttrs versions (version: lib.importJSON "${./versions}/${version}.json");
  packages = lib.mapAttrs (
    version: version-info:
    lib.mapAttrs (
      kind: per-system-info:
      final.callPackage ./hugo-bin.nix {
        inherit version per-system-info kind;
      }
    ) version-info
  ) files;
  latest_version = lib.trim (lib.readFile ./versions/latest);
in
{
  hugo-bin = packages // {
    latest = final.hugo-bin.${latest_version};
  };
}
