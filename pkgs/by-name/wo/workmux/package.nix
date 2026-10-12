{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  git,
  installShellFiles,
  versionCheckHook,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "workmux";
  version = "0.1.273";

  src = fetchFromGitHub {
    owner = "raine";
    repo = "workmux";
    tag = "v${finalAttrs.version}";
    hash = "sha256-oGuzVbHMwAMrtPt47Y5q6GZrwBfgJkXvLK/X48r5jYQ=";
  };

  cargoHash = "sha256-saGuH0HzWkCfl6Rj9BQf6g18EJhDoX0OIhppWY3XxLg=";

  patches = [
    # The config watcher test waits on real filesystem events. On macOS those
    # come from fseventsd, which lags for tens of seconds while the rest of the
    # test suite churns files, so the test times out.
    ./deterministic-config-watcher-test.patch
  ];

  nativeBuildInputs = [ installShellFiles ];

  nativeCheckInputs = [ git ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    export HOME=$(mktemp -d)
    installShellCompletion --cmd workmux \
      --bash <($out/bin/workmux completions bash) \
      --fish <($out/bin/workmux completions fish) \
      --zsh <($out/bin/workmux completions zsh)
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  # workmux creates its log directory under $HOME (set in postInstall) on startup.
  versionCheckKeepEnvironment = [ "HOME" ];
  doInstallCheck = true;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Parallel development in tmux with git worktrees";
    homepage = "https://github.com/raine/workmux";
    changelog = "https://github.com/raine/workmux/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ moeleak ];
    mainProgram = "workmux";
    platforms = lib.platforms.unix;
  };
})
