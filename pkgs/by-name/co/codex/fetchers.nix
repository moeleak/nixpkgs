# not a stable interface, do not reference outside the codex package but make a copy if you need
{
  lib,
  stdenv,
  fetchurl,
}:

{
  fetchLibrustyV8 =
    args:
    let
      # Codex does not publish RISC-V archives; keep using the upstream release for that target.
      isRiscV = stdenv.hostPlatform.system == "riscv64-linux";
      profile = if isRiscV then "release" else "ptrcomp_sandbox_release";
      target = stdenv.hostPlatform.rust.rustcTarget;
      baseUrl =
        if isRiscV then
          "https://github.com/denoland/rusty_v8/releases/download/v${args.version}"
        else
          "https://github.com/openai/codex/releases/download/rusty-v8-v${args.version}";
    in
    fetchurl {
      name = "librusty_v8_${profile}_${target}.a.gz";
      url = "${baseUrl}/librusty_v8_${profile}_${target}.a.gz";
      sha256 = args.shas.${stdenv.hostPlatform.system};
      meta = {
        inherit (args) version;
        sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      };
    };

  fetchLibrustyV8SrcBinding =
    args:
    let
      isRiscV = stdenv.hostPlatform.system == "riscv64-linux";
      profile = if isRiscV then "release" else "ptrcomp_sandbox_release";
      target = stdenv.hostPlatform.rust.rustcTarget;
      baseUrl =
        if isRiscV then
          "https://github.com/denoland/rusty_v8/releases/download/v${args.version}"
        else
          "https://github.com/openai/codex/releases/download/rusty-v8-v${args.version}";
    in
    fetchurl {
      name = "src_binding_${profile}_${target}.rs";
      url = "${baseUrl}/src_binding_${profile}_${target}.rs";
      sha256 = args.shas.${stdenv.hostPlatform.system};
      meta = {
        inherit (args) version;
      };
    };
}
