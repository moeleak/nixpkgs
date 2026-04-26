{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  makeWrapper,
  vulkan-headers,
  vulkan-loader,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "vkpeak";
  version = "20260112";

  src = fetchFromGitHub {
    owner = "nihui";
    repo = "vkpeak";
    tag = finalAttrs.version;
    fetchSubmodules = true;
    hash = "sha256-m/qv8E8KqF4lr/xp0Bf8MMLSiPV8JQdID7NBEWhFjaA=";
  };

  postPatch = ''
    echo 'install(TARGETS vkpeak RUNTIME DESTINATION bin)' >> CMakeLists.txt
  '';

  cmakeFlags = [
    (lib.cmakeBool "GLSLANG_ENABLE_INSTALL" false)
  ];

  nativeBuildInputs = [
    cmake
    makeWrapper
  ];

  buildInputs = [
    vulkan-headers
    vulkan-loader
  ];

  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    wrapProgram $out/bin/vkpeak \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ vulkan-loader ]}
  '';

  meta = {
    description = "Synthetic benchmark for measuring peak capabilities of Vulkan devices";
    homepage = "https://github.com/nihui/vkpeak";
    license = lib.licenses.mit;
    mainProgram = "vkpeak";
    platforms = lib.platforms.linux;
  };
})
