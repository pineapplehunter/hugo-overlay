{
  stdenv,
  lib,
  libgcc,
  autoPatchelfHook,
  fetchurl,
  versionCheckHook,
  buildPackages,
  installShellFiles,

  # custom
  version,
  kind,
  per-system-info,
}:
let
  inherit (lib) optionals;
  platform-info = per-system-info.${stdenv.hostPlatform.system} or (throw "unsupported system");
  # non default variants on linux need to link with shared library
  needsPatching = kind != "default" && stdenv.hostPlatform.isLinux;

  hugo-bin-unwrapped = stdenv.mkDerivation {
    pname = "hugo-${kind}-bin-unwrapped";
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
  };
in
stdenv.mkDerivation {
  pname = "hugo-${kind}-bin";
  inherit version;

  nativeBuildInputs = [ installShellFiles ];

  dontUnpack = true;
  dontBuild = true;

  installPhase =
    let
      emulator = stdenv.hostPlatform.emulator buildPackages;
    in
    ''
      runHook preInstall

      mkdir -p "$out/bin"
      ln -s "${hugo-bin-unwrapped}/bin/hugo" "$out/bin/hugo"

      ${emulator} "$out/bin/hugo" gen man
      installManPage man/*
      installShellCompletion --cmd hugo \
        --bash <(${emulator} "$out/bin/hugo" completion bash) \
        --fish <(${emulator} "$out/bin/hugo" completion fish) \
        --zsh  <(${emulator} "$out/bin/hugo" completion zsh)

      runHook postInstall
    '';

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
