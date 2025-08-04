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

stdenvNoCC.mkDerivation {
  pname = "hugo-${kind}-bin";
  inherit version;

  src = fetchurl {
    inherit (per-system-info.${stdenvNoCC.hostPlatform.system} or (throw "unsupported system"))
      url
      hash
      ;
  };
  sourceRoot = ".";

  nativeBuildInputs = [
    versionCheckHook
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [
    libgcc.lib
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dt $out/bin hugo
    runHook postInstall
  '';

  doInstallCheck = true;
  versionCheckProgramArg = "version";

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
}
