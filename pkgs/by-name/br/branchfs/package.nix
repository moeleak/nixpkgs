{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  fuse3,
  macfuse-stubs,
  pkg-config,
  nix-update-script,
}:

let
  fuse = if stdenv.hostPlatform.isDarwin then macfuse-stubs else fuse3;
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "branchfs";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "multikernel";
    repo = "branchfs";
    tag = "v${finalAttrs.version}";
    hash = "sha256-0EWwshIwK2KgqToHzBD83GyefhQ2pSqXdKBYpeBV2Oo=";
  };

  cargoHash = "sha256-4dU4mGZCpeoCic0qgkGQz3Fp7IGz0vtDy+Hy6gpZFEA=";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ fuse ];

  # test_ioctl uses the Linux-only libc::__errno_location function.
  cargoTestFlags = lib.optionals stdenv.hostPlatform.isDarwin [
    "--lib"
    "--bins"
    "--test=test_integration"
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "FUSE filesystem with atomic branching for speculative execution";
    homepage = "https://github.com/multikernel/branchfs";
    changelog = "https://github.com/multikernel/branchfs/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ moeleak ];
    mainProgram = "branchfs";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
