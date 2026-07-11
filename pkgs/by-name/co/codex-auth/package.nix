{
  lib,
  stdenv,
  fetchFromGitHub,
  nix-update-script,
  nodejs,
  testers,
  zig_0_15,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "codex-auth";
  version = "0.2.10";

  src = fetchFromGitHub {
    owner = "Loongphy";
    repo = "codex-auth";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ecB7/bNNqOuMPlB5C+mO3UlDWZgy27gb0TwOtq1z/7s=";
  };

  nativeBuildInputs = [ zig_0_15.hook ];

  postPatch = ''
    substituteInPlace src/chatgpt_http.zig \
      --replace-fail \
        'try allocator.dupe(u8, "node")' \
        'try allocator.dupe(u8, "${lib.getExe nodejs}")'
  '';

  doCheck = true;

  passthru = {
    tests.version = testers.testVersion {
      package = finalAttrs.finalPackage;
    };
    updateScript = nix-update-script {
      extraArgs = [ "--version-regex=^v(\\d+\\.\\d+\\.\\d+)$" ];
    };
  };

  meta = {
    description = "CLI for switching Codex accounts";
    homepage = "https://github.com/Loongphy/codex-auth";
    changelog = "https://github.com/Loongphy/codex-auth/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ moeleak ];
    mainProgram = "codex-auth";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
  };
})
