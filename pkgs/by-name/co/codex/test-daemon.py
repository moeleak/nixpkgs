import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


binary, version = sys.argv[1:]
with tempfile.TemporaryDirectory(prefix="codex-daemon-") as directory:
    codex_home = Path(directory)
    state = codex_home / "app-server-daemon"
    state.mkdir()
    # Exercise a fresh local installation without contacting the update service.
    (state / "settings.json").write_text(
        json.dumps(
            {
                "updater": {"autoUpdateEnabled": False},
                "shutdownGraceSeconds": 0,
            }
        )
    )
    environment = dict(os.environ, CODEX_HOME=str(codex_home))

    def daemon(*arguments):
        result = subprocess.run(
            [binary, "app-server", "daemon", *arguments],
            env=environment,
            text=True,
            capture_output=True,
            timeout=60,
        )
        assert result.returncode == 0, result.stdout + result.stderr
        print(result.stdout, flush=True)
        return json.loads(result.stdout)

    try:
        assert daemon("start")["status"] == "started"
        package = codex_home / "packages/app-server-daemon/current"
        manifest = json.loads((package / "codex-package.json").read_text())
        assert manifest["version"] == version
        # Run the staged entrypoint too: wrappers can work in the store while
        # pointing back to the wrong executable after the daemon copies them.
        output = subprocess.check_output(
            [str(package / "bin/codex"), "--version"],
            env=environment,
            text=True,
            timeout=10,
        )
        assert output.strip() == f"codex-cli {version}", output
        assert daemon("start")["status"] == "alreadyRunning"
        assert daemon("restart")["status"] == "restarted"
        running = daemon("version")
        assert running["status"] == "running"
        assert running["appServerVersion"] == version
    finally:
        assert daemon("stop")["status"] in ("stopped", "notRunning")
