final: prev:
let
  inherit (prev) lib;
  versions = map (x: lib.removeSuffix ".json" x) (builtins.attrNames (builtins.readDir ./versions));
  files = lib.listToAttrs (
    map (version: {
      name = version;
      value = lib.importJSON "${./versions}/${version}.json";
    }) versions
  );
  hugo-generator =
    {
      version,
      kind,
      per-system-info,
    }:
    final.stdenvNoCC.mkDerivation {
      pname = if kind == "default" then "hugo-bin" else "hugo-${kind}-bin";
      inherit version;

      src = final.fetchurl {
        inherit (per-system-info.${final.stdenv.hostPlatform.system} or (throw "unsupported system"))
          url
          hash
          ;
      };
      sourceRoot = ".";

      nativeBuildInputs = lib.optionals (final.stdenv.hostPlatform.isLinux && kind != "default") [
        final.autoPatchelfHook
      ];

      buildInputs = lib.optionals (final.stdenv.hostPlatform.isLinux && kind != "default") [
        final.libgcc.lib
      ];

      dontBuild = true;

      installPhase = ''
        runHook preInstall
        install -Dt $out/bin hugo
        runHook postInstall
      '';

      doInstallCheck = true;
      installCheckPhase = ''
        runHook preInstallCheck
        # check if it can print it's version
        $out/bin/hugo version
        runHook postInstallCheck
      '';

      meta = {
        changelog = "https://github.com/gohugoio/hugo/releases/tag/v${version}";
        description = "Fast and modern static website engine";
        homepage = "https://gohugo.io";
        license = lib.licenses.asl20;
        mainProgram = "hugo";
        maintainers = with lib.maintainers; [
          pineapplehunter
        ];
        platforms = lib.attrNames per-system-info;
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      };
    };
  packages = lib.mapAttrs (
    version: version-info:
    lib.mapAttrs (
      kind: per-system-info:
      hugo-generator {
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
