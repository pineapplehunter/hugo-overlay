{
  stdenvNoCC,
  lib,
  libgcc,
  autoPatchelfHook,
  fetchurl,
  versionCheckHook,

  # custom
  version,
  kind,
  per-system-info,
}:
let
  inherit (lib) optionals;
  platform-info = per-system-info.${stdenvNoCC.hostPlatform.system} or (throw "unsupported system");
  # non default variants on linux need to link with shared library
  needsPatching = kind != "default" && stdenvNoCC.hostPlatform.isLinux;
in
stdenvNoCC.mkDerivation {
  pname = "hugo-${kind}-bin";
  inherit version;

  src = fetchurl { inherit (platform-info) url hash; };
  sourceRoot = ".";

  nativeBuildInputs = optionals needsPatching [ autoPatchelfHook ];
  buildInputs = optionals needsPatching [ libgcc.lib ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dt $out/bin hugo
    runHook postInstall
  '';

  nativeCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "version";

  meta = {
    changelog = "https://github.com/gohugoio/hugo/releases/tag/v${version}";
    description = "Fast and modern static website engine";
    homepage = "https://gohugo.io";
    license = lib.licenses.asl20;
    mainProgram = "hugo";
    maintainers = with lib.maintainers; [ pineapplehunter ];
    platforms = lib.attrNames per-system-info;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
