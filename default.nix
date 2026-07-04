{
  lib,
  pkgs,
  stdenvNoCC,
  fetchurl,
  jdk,
  makeDesktopItem,
  unzip,
  writeShellScriptBin,
}: let
  version = "2025.1.1";
  productName = "pro";
  productDesktop = "BurpSuite Professional";
  burpHash = "sha256-17COQ9deYkzmaXBbg1arD3BQY7l3WZ9FakLXzTxgmr8=";
  burpSrc = fetchurl {
    name = "burpsuite.jar";
    urls = [
      "https://portswigger.net/burp/releases/download?product=${productName}&version=${version}&type=Jar"
      "https://web.archive.org/web/https://portswigger.net/burp/releases/download?product=${productName}&version=${version}&type=Jar"
    ];
    hash = burpHash;
  };
  loaderSrc = ./.;
  pname = "burpsuitepro";
  description = "An integrated platform for performing security testing of web applications";

  javaOpens = lib.concatStringsSep " " [
    "--add-opens=java.desktop/javax.swing=ALL-UNNAMED"
    "--add-opens=java.base/java.lang=ALL-UNNAMED"
    "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED"
    "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED"
    "--add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED"
  ];

  desktopItem = makeDesktopItem {
    name = pname;
    exec = pname;
    icon = pname;
    desktopName = productDesktop;
    comment = description;
    categories = [
      "Development"
      "Security"
      "System"
    ];
  };
in
  stdenvNoCC.mkDerivation {
    inherit pname version;

    dontUnpack = true;
    dontBuild = true;

    nativeBuildInputs = [ unzip ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/pixmaps $out/share

      # extract Burp's app icon
      ${lib.getBin unzip}/bin/unzip -p ${burpSrc} resources/Media/icon64${productName}.png \
        > $out/share/pixmaps/${pname}.png

      # stash the jar + loader alongside
      cp ${burpSrc} $out/share/burpsuite_pro_v${version}.jar
      cp ${loaderSrc}/loader.jar $out/share/loader.jar

      # main launcher: plain java invocation, no FHS env needed on Darwin
      cat > $out/bin/${pname} <<EOF
      #!${stdenvNoCC.shell}
      exec "${jdk}/bin/java" ${javaOpens} \\
        -javaagent:$out/share/loader.jar \\
        -noverify -jar $out/share/burpsuite_pro_v${version}.jar "\$@"
      EOF
      chmod +x $out/bin/${pname}

      # secondary loader-only entrypoint, mirrors original derivation
      cat > $out/bin/loader <<EOF
      #!${stdenvNoCC.shell}
      exec "${jdk}/bin/java" -jar "$out/share/loader.jar" "\$@"
      EOF
      chmod +x $out/bin/loader

      mkdir -p $out/share/applications
      cp -r ${desktopItem}/share/applications/* $out/share/applications/

      runHook postInstall
    '';

    meta = with lib; {
      inherit description;
      longDescription = ''
        Burp Suite is an integrated platform for performing security testing of web applications.
        Its various tools work seamlessly together to support the entire testing process, from
        initial mapping and analysis of an application's attack surface, through to finding and
        exploiting security vulnerabilities.
      '';
      homepage = "https://github.com/sammhansen/Burpsuite-Professional.git";
      changelog =
        "https://portswigger.net/burp/releases/professional-community-"
        + replaceStrings ["."] ["-"] version;
      sourceProvenance = with sourceTypes; [binaryBytecode];
      license = licenses.unfree;
      platforms = ["aarch64-darwin" "x86_64-darwin"];
      hydraPlatforms = [];
      maintainers = with maintainers; [
        bennofs
        fab
      ];
      mainProgram = pname;
    };
  }
