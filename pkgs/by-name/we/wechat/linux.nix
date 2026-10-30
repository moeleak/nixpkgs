{
  pname,
  version,
  src,
  meta,
  passthru ? { },
  appimageTools,
  lib,
  noto-fonts-cjk-sans-static,
  writeText,
}:

let
  appimageContents = appimageTools.extract {
    inherit pname version src;
    postExtract = ''
      patchelf --replace-needed libtiff.so.5 libtiff.so $out/opt/wechat/wechat
    '';
  };

  # WeChat's bundled Qt 5.15 renders variable Noto fonts at their default Thin
  # weight (e.g. in the message input box). Use static fonts for Latin as well
  # as CJK text, and redirect its default sans-serif families to them.
  fontsConf = writeText "wechat-fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
      <dir>${noto-fonts-cjk-sans-static}/share/fonts</dir>
      <selectfont>
        <rejectfont>
          <glob>*/NotoSansCJK-VF.otf.ttc</glob>
          <glob>*/NotoSansMonoCJK-VF.otf.ttc</glob>
          <glob>*/NotoSerifCJK-VF.otf.ttc</glob>
          <glob>*/NotoSans.ttf</glob>
          <glob>*/NotoSans-Italic.ttf</glob>
        </rejectfont>
      </selectfont>
      ${lib.concatMapStringsSep "\n"
        (family: ''
          <alias binding="strong">
            <family>${family}</family>
            <prefer><family>Noto Sans CJK SC</family></prefer>
          </alias>
        '')
        [
          "sans-serif"
          "Noto Sans"
          "Noto Sans SC"
        ]
      }
    </fontconfig>
  '';
in
appimageTools.wrapAppImage {
  inherit
    pname
    version
    meta
    passthru
    ;

  src = appimageContents;

  profile = ''
    export FONTCONFIG_FILE=${fontsConf}
  '';

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    cp ${appimageContents}/wechat.desktop $out/share/applications/
    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp ${appimageContents}/wechat.png $out/share/icons/hicolor/256x256/apps/

    substituteInPlace $out/share/applications/wechat.desktop --replace-fail AppRun wechat
  '';
}
