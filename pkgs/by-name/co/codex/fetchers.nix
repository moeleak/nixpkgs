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
      profile = "ptrcomp_sandbox_release";
      target = stdenv.hostPlatform.rust.rustcTarget;
      baseUrl = "https://github.com/openai/codex/releases/download/rusty-v8-v${args.version}";
    in
    fetchurl {
      name = "librusty_v8_${profile}_${target}.a.gz";
      url = "${baseUrl}/librusty_v8_${profile}_${target}.a.gz";
      hash = args.shas.${stdenv.hostPlatform.system};
      meta = {
        inherit (args) version;
        sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      };
    };

  fetchLibrustyV8SrcBinding =
    args:
    let
      profile = "ptrcomp_sandbox_release";
      target = stdenv.hostPlatform.rust.rustcTarget;
      baseUrl = "https://github.com/openai/codex/releases/download/rusty-v8-v${args.version}";
    in
    fetchurl {
      name = "src_binding_${profile}_${target}.rs";
      url = "${baseUrl}/src_binding_${profile}_${target}.rs";
      hash = args.shas.${stdenv.hostPlatform.system};
      meta = {
        inherit (args) version;
      };
    };
}
