{
  lib,
  mkKdeDerivation,
  sources,
  fetchFromGitHub,
  pkg-config,
  ddcutil,
  qtwayland,
}:
let
  # moeleak/powerdevil branch v6.7.5-moeleak, which is upstream v6.7.5 plus:
  # - backport fix for spurious low battery notifications (upstream 54f8a4a8, in 6.7.6)
  # - hide the "nan%" keyboard backlight slider when UPower reports a max brightness of 0
  version = "6.7.5";
in
assert lib.assertMsg (sources.powerdevil.version == version) ''
  powerdevil: Plasma is now ${sources.powerdevil.version} but the moeleak/powerdevil fork is based on ${version}.
  Rebase the fork onto v${sources.powerdevil.version} and update src, or drop the fix if upstream has it.
'';
mkKdeDerivation {
  pname = "powerdevil";
  inherit version;

  src = fetchFromGitHub {
    owner = "moeleak";
    repo = "powerdevil";
    rev = "1bc4420c99ebb2b926d559214076ace612f6b9cd";
    hash = "sha256-py7h2ViQnFH2cKDaXAezLLLdVlztkWT829l7h27Ha0E=";
  };

  extraNativeBuildInputs = [ pkg-config ];
  extraBuildInputs = [
    ddcutil
    qtwayland
  ];
}
