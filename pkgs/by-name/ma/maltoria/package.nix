{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  fetchFromGitHub,
  rustPlatform,
  appimageTools,
  runCommand,
  unzip,
  rcodesign,
  maltoria-libraries,
  libGL,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
  libxkbcommon,
  vulkan-loader,
  wayland,
  nix-update-script,
}:

let
  pname = "maltoria";
  version = "0.6.2";

  # The release ships the Swift helper, LunaHook and the other resources the
  # interface runs with.
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

  # The Material 3 interface of the moeleak fork, which replaces the release's
  # GPUI one: built from source, and run in the release's bundle in its place.
  interface = rustPlatform.buildRustPackage {
    pname = "maltoria-interface";
    version = "0-unstable-2026-11-23";

    src = fetchFromGitHub {
      owner = "moeleak";
      repo = "Maltoria";
      rev = "75ecd126024f169b945ebddbdc231d176ec1f93f";
      hash = "sha256-3/bkYZtDUl0so875A73ZzW7mgV0j8rGhM6nPiJPfgX4=";
    };

    # A standalone package beside the core it depends on by path.
    cargoRoot = "apps/maltoria";
    buildAndTestSubdir = "apps/maltoria";
    cargoHash = "sha256-aiszyvuVV9g6z8bpvR8AMCWOYq+fBdn4zgNkjTtGKr4=";

    # On macOS, the Wine runtime built for macOS 15, which the interface
    # installs where the helper runs it.
    env = lib.optionalAttrs stdenv.hostPlatform.isDarwin {
      MALTORIA_WINE_RUNTIME = "${maltoria-libraries}/Libraries";
    };

    # winit and wgpu load the windowing and graphics libraries at runtime.
    postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
      patchelf --add-rpath ${
        lib.makeLibraryPath [
          libGL
          libx11
          libxcursor
          libxi
          libxrandr
          libxkbcommon
          vulkan-loader
          wayland
        ]
      } $out/bin/maltoria
    '';

    meta.mainProgram = "maltoria";
  };

  passthru = {
    inherit sources interface;
    # Each system has its own release asset, whose hash nix-update updates
    # wherever it runs, as these are fetched alike on any system; they are
    # fetchurl's, so nix-update is told which file to update them in. Older
    # tags are vn-v*. The interface's revision is updated by hand.
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
    description = "Whisky fork for playing visual novels on macOS and Linux, with a Material 3 interface";
    homepage = "https://github.com/moeleak/Maltoria";
    changelog = "https://github.com/daydalek/Maltoria/releases/tag/v${version}";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryNativeCode
    ];
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

    nativeBuildInputs = [
      unzip
      rcodesign
    ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications
      cp -a Maltoria.app $out/Applications
      chmod -R u+w $out/Applications/Maltoria.app

      # The bundle launches whisky-gpui, and its helper is in Resources.
      install -m755 ${lib.getExe interface} \
        $out/Applications/Maltoria.app/Contents/MacOS/whisky-gpui

      # The release's icon fills its square, which macOS no longer rounds.
      install -m644 ${interface.src}/apps/maltoria/resources/AppIcon.icns \
        $out/Applications/Maltoria.app/Contents/Resources/AppIcon.icns

      # Sealed again, ad hoc as the release is.
      rcodesign sign $out/Applications/Maltoria.app

      runHook postInstall
    '';

    # Patching the scripts' shebangs would break the signature.
    dontFixup = true;
  }
else
  let
    extracted = appimageTools.extract { inherit pname version src; };

    # AppRun runs whisky-gpui, beside its helper.
    contents = runCommand "${pname}-${version}-contents" { } ''
      cp -a ${extracted} $out
      chmod -R u+w $out
      install -m755 ${lib.getExe interface} $out/usr/lib/whisky/bin/whisky-gpui
      install -m644 ${interface.src}/apps/maltoria/resources/com.daydalek.Maltoria.png \
        $out/com.daydalek.Maltoria.png
    '';
  in
  appimageTools.wrapAppImage {
    inherit
      pname
      version
      passthru
      meta
      ;
    src = contents;

    extraInstallCommands = ''
      install -Dm444 ${contents}/com.daydalek.Maltoria.desktop -t $out/share/applications
      # Exec and TryExec
      substituteInPlace $out/share/applications/com.daydalek.Maltoria.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=maltoria'
      install -Dm444 ${contents}/com.daydalek.Maltoria.png -t $out/share/icons/hicolor/512x512/apps
      install -Dm444 ${contents}/usr/share/metainfo/com.daydalek.Maltoria.metainfo.xml -t $out/share/metainfo
    '';
  }
