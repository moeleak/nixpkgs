{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  fontconfig,
  freetype,
  libxkbcommon,
  libxcb,
  libx11,
  wayland,
  vulkan-loader,
  nix-update-script,
}:

let
  # GPUI dlopen()s these at runtime instead of linking them, so they must be
  # added to the binary's RUNPATH.
  runtimeLibs = [
    vulkan-loader
    wayland
    fontconfig
    libxkbcommon
    libxcb
    libx11
  ];
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "pizarra-gpui";
  version = "0.1.0-unstable-2026-11-10";

  src = fetchFromGitHub {
    owner = "moeleak";
    repo = "pizarra-gpui";
    rev = "a5948f6e1426796dc427693c9facefb8f095dea2";
    hash = "sha256-l0t69ksJTkwh1LvFdJ5S61vrgNZnoFZCxd8J1sh1HEY=";
  };

  cargoHash = "sha256-V7/WTHwQOeUiXYH9j1uywp3BqsAcd7Vs3RBgCF8dW1o=";

  nativeBuildInputs = [
    pkg-config
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [ rustPlatform.bindgenHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux (runtimeLibs ++ [ freetype ]);

  # The Metal shader compiler only ships with Xcode, so compile the shaders
  # when the app starts instead.
  buildFeatures = lib.optionals stdenv.hostPlatform.isDarwin [ "gpui/runtime_shaders" ];

  postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
    install -Dm644 res/pizarra-gpui.desktop -t $out/share/applications
    install -Dm644 res/pizarra.svg $out/share/icons/hicolor/scalable/apps/pizarra-gpui.svg
    install -Dm644 res/pizarra128.png $out/share/icons/hicolor/128x128/apps/pizarra-gpui.png
  '';

  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    patchelf --add-rpath ${lib.makeLibraryPath runtimeLibs} $out/bin/pizarra-gpui
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };

  meta = {
    description = "Free-hand vector drawing application with an infinite canvas, with graphics tablet support";
    longDescription = ''
      A GPUI frontend for the pizarra drawing engine, ported from pizarra-gtk.
      Pen pressure modulates the stroke width and the eraser end of a stylus
      selects the eraser, on X11, Wayland and macOS.
    '';
    homepage = "https://github.com/moeleak/pizarra-gpui";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ moeleak ];
    mainProgram = "pizarra-gpui";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
