{
  self,
  callPackage,
  fetchFromGitHub,
  passthruFun,
  stdenv,
}:

let
  # The patch version is the timestamp of the git commit,
  # obtain via `cat $(nix-build -A luajit_2_1.src)/.relver`
  sources =
    if stdenv.hostPlatform.isRiscV64 then
      {
        version = "2.1.1770278956";

        src = fetchFromGitHub {
          owner = "plctlab";
          repo = "LuaJIT";
          rev = "e9c0b90b64df769a53fda125c4fff31557091762";
          hash = "sha256-dlC2cBQVtpM/t6LUBQTDSfKlt9TRbYHM1z2Ri4GpT7o=";
        };
      }
    else
      {
        version = "2.1.1791890110";

        src = fetchFromGitHub {
          owner = "LuaJIT";
          repo = "LuaJIT";
          rev = "634daf2453559fd5e0ec282f3b7aedaa09e9f344";
          hash = "sha256-vIT7ShP1cxxhZr9/vXcNsc0nhYzjncpzLFYXDG2Ff6I=";
        };
      };
in
callPackage ./default.nix {
  inherit (sources) version src;
  inherit self passthruFun;

  extraMeta = {
    badPlatforms = [
      "loongarch64-linux" # See https://github.com/LuaJIT/LuaJIT/issues/1278
      "s390x-linux" # See https://github.com/LuaJIT/LuaJIT/issues/43
      # `#error "No support for PPC64"`
      "powerpc64-linux"
      "powerpc64le-linux"
    ];
  };
}
