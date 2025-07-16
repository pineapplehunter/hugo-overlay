{
  stdenvNoCC,
  lib,
  libgcc,
  autoPatchelfHook,
  fetchurl,

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

  nativeBuildInputs = lib.optionals (stdenvNoCC.hostPlatform.isLinux && kind != "default") [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals (stdenvNoCC.hostPlatform.isLinux && kind != "default") [
    libgcc.lib
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
}
