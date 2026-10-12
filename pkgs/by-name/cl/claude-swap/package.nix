{
  lib,
  python3Packages,
  fetchFromGitHub,
  versionCheckHook,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "claude-swap";
  version = "0.26.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "realiti4";
    repo = "claude-swap";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ypE/fxgMr+SSF/8blI2YVqcr9coW3YcGzC/NiogyadQ=";
  };

  # Updates are handled by Nix, don't nag about newer PyPI releases
  postPatch = ''
    substituteInPlace src/claude_swap/cli.py \
      --replace-fail "msg = check_for_update(__version__)" "msg = None"
  '';

  build-system = with python3Packages; [ hatchling ];

  dependencies = with python3Packages; [
    textual
    truststore
  ];

  nativeCheckInputs = with python3Packages; [
    pytest-asyncio
    pytest-xdist
    pytestCheckHook
  ];

  # The test suite refuses to write directly under the account's home
  # directory, which is the build directory inside the sandbox
  preCheck = ''
    export HOME=$(mktemp -d)
    export TMPDIR=$(mktemp -d)
  '';

  # The cache provider would write into the source directory, which the
  # sandbox guard above also rejects
  pytestFlags = [ "-pno:cacheprovider" ];

  pythonImportsCheck = [ "claude_swap" ];

  nativeInstallCheckInputs = [ versionCheckHook ];

  meta = {
    description = "Switch between multiple Claude Code accounts";
    longDescription = ''
      Multi-account switcher for Claude Code, with automatic rate-limit
      rotation, a usage dashboard and parallel sessions.
    '';
    homepage = "https://github.com/realiti4/claude-swap";
    changelog = "https://github.com/realiti4/claude-swap/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ moeleak ];
    mainProgram = "cswap";
  };
})
