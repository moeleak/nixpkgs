{
  lib,
  stdenvNoCC,
  fetchurl,
  appimageTools,
  unzip,
  nix-update-script,
}:

let
  pname = "maltoria";
  version = "0.6.2";

  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/daydalek/Maltoria/releases/download/v${version}/Maltoria-${version}-arm64.zip";
      hash = "sha256-+LfQhkWBnaXH8uP7aX2aoaMv7jkHLtU2hw2tzK9zRdI=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/daydalek/Maltoria/releases/download/v${version}/Maltoria-${version}-x86_64.AppImage";
      hash = "sha256-9PtOoun1SafGjGJlt0S6bC/s7Dv13V8EhkgtnpreV8U=";
    };
  };

  src =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "maltoria: unsupported system ${stdenvNoCC.hostPlatform.system}");

  passthru = {
    inherit sources;
    # Each system has its own release asset, whose hash nix-update updates
    # wherever it runs, as these are fetched alike on any system; they are
    # fetchurl's, so nix-update is told which file to update them in. Older
    # tags are vn-v*.
    updateScript = nix-update-script {
      extraArgs = [
        "--version-regex=^v(\\d+\\.\\d+\\.\\d+)$"
        "--subpackage=sources.aarch64-darwin"
        "--subpackage=sources.x86_64-linux"
        "--override-filename=${toString ./package.nix}"
      ];
    };
  };

  meta = {
    description = "Whisky fork for playing visual novels on macOS and Linux";
    homepage = "https://github.com/daydalek/Maltoria";
    changelog = "https://github.com/daydalek/Maltoria/releases/tag/v${version}";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = with lib.maintainers; [ moeleak ];
    platforms = lib.attrNames sources;
    mainProgram = "maltoria";
  };
in
if stdenvNoCC.hostPlatform.isDarwin then
  stdenvNoCC.mkDerivation {
    inherit
      pname
      version
      src
      passthru
      meta
      ;

    nativeBuildInputs = [ unzip ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications
      cp -a Maltoria.app $out/Applications

      runHook postInstall
    '';

    # The app is signed ad hoc, and patching its scripts' shebangs would break
    # the signature.
    dontFixup = true;
  }
else
  let
    contents = appimageTools.extract { inherit pname version src; };
  in
  appimageTools.wrapType2 {
    inherit
      pname
      version
      src
      passthru
      meta
      ;

    extraInstallCommands = ''
      install -Dm444 ${contents}/com.daydalek.Maltoria.desktop -t $out/share/applications
      # Exec and TryExec
      substituteInPlace $out/share/applications/com.daydalek.Maltoria.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=maltoria'
      install -Dm444 ${contents}/com.daydalek.Maltoria.png -t $out/share/icons/hicolor/512x512/apps
      install -Dm444 ${contents}/usr/share/metainfo/com.daydalek.Maltoria.metainfo.xml -t $out/share/metainfo
    '';
  }
