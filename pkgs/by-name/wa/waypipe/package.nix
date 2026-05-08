{
  lib,
  buildPackages,
  rustPlatform,
  fetchFromGitLab,
  meson,
  ninja,
  pkg-config,
  scdoc,
  libgbm,
  lz4,
  zstd,
  ffmpeg,
  cargo,
  rustc,
  vulkan-headers,
  vulkan-loader,
  shaderc,
  llvmPackages,
  autoPatchelfHook,
  wayland-scanner,
  rust-bindgen,
  nix-update-script,
}:
let
  objcopy = buildPackages.writeShellScriptBin "objcopy" ''
    exec ${buildPackages.binutils}/bin/objcopy "$@"
  '';
in
llvmPackages.stdenv.mkDerivation (finalAttrs: {
  pname = "waypipe";
  version = "0.11.0";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "mstoeckl";
    repo = "waypipe";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Tbd/yY90yb2+/ODYVL3SudHaJCGJKatZ9FuGM2uAX+8=";
  };
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname version src;
    hash = "sha256-IUvXHLxrhc2Au57wsE53Q+NL1cZzFcaRG3HDV8s3xWw=";
  };

  strictDeps = true;
  env.LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";
  env.CARGO_BUILD_TARGET = llvmPackages.stdenv.hostPlatform.rust.rustcTargetSpec;
  depsBuildBuild = [ pkg-config ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    scdoc
    cargo
    shaderc # for glslc
    rustc
    wayland-scanner
    rustPlatform.cargoSetupHook
    autoPatchelfHook
    rust-bindgen
    objcopy
  ];

  buildInputs = [
    libgbm
    lz4
    zstd
    ffmpeg
    vulkan-headers
    vulkan-loader
  ];

  runtimeDependencies = [
    libgbm
    ffmpeg.lib
    vulkan-loader
  ];

  postPatch = ''
    substituteInPlace compile_wrapper.sh \
      --replace-fail 'cargo build --frozen -v' 'cargo build --frozen -v --target "$CARGO_BUILD_TARGET"' \
      --replace-fail 'cp "$3/$1/waypipe" "$5"' 'cp "$3/$CARGO_BUILD_TARGET/$1/waypipe" "$5"'
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Network proxy for Wayland clients (applications)";
    longDescription = ''
      waypipe is a proxy for Wayland clients. It forwards Wayland messages and
      serializes changes to shared memory buffers over a single socket. This
      makes application forwarding similar to ssh -X feasible.
    '';
    homepage = "https://mstoeckl.com/notes/gsoc/blog.html";
    changelog = "https://gitlab.freedesktop.org/mstoeckl/waypipe/-/releases#v${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ mic92 ];
    mainProgram = "waypipe";
  };
})
