{
  lib,
  runCommand,
  python3,
  codex,
}:
runCommand "codex-daemon-test"
  {
    nativeBuildInputs = [ python3 ];
    meta.platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
  }
  ''
    python ${./test-daemon.py} ${lib.getExe codex} ${lib.escapeShellArg codex.version}
    touch "$out"
  ''
