{
  lib,
  pkgs,
  stdenvNoCC,
  fetchurl,
  jdk,
  unzip,
  writeShellScriptBin,
  writeTextFile,
}: let
  version = "2025.1.1";
  productName = "pro";
  productDesktop = "Burp Suite Professional";
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
  bundleId = "net.portswigger.burpsuitepro";
  description = "An integrated platform for performing security testing of web applications";

  jarPath = "burpsuite_pro_v${version}.jar";

  javaOpens = lib.concatStringsSep " " [
    "--add-opens=java.desktop/javax.swing=ALL-UNNAMED"
    "--add-opens=java.base/java.lang=ALL-UNNAMED"
    "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED"
    "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED"
    "--add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED"
  ];

  # ---- launcher scripts built as first-class Nix derivations, no heredocs ----
  mainLauncher = writeShellScriptBin pname ''
    exec "${jdk}/bin/java" ${javaOpens} \
      -javaagent:@out@/share/loader.jar \
      -noverify -jar @out@/share/${jarPath} "$@"
  '';

  loaderLauncher = writeShellScriptBin "loader" ''
    exec "${jdk}/bin/java" -jar @out@/share/loader.jar "$@"
  '';

  bundleExecutable = writeShellScriptBin pname ''
    exec @out@/bin/${pname} "$@"
  '';

  infoPlist = writeTextFile {
    name = "Info.plist";
    text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleName</key>
        <string>${productDesktop}</string>
        <key>CFBundleDisplayName</key>
        <string>${productDesktop}</string>
        <key>CFBundleIdentifier</key>
        <string>${bundleId}</string>
        <key>CFBundleVersion</key>
        <string>${version}</string>
        <key>CFBundleShortVersionString</key>
        <string>${version}</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>CFBundleExecutable</key>
        <string>${pname}</string>
        <key>CFBundleIconFile</key>
        <string>${pname}.icns</string>
        <key>LSMinimumSystemVersion</key>
        <string>11.0</string>
        <key>NSHighResolutionCapable</key>
        <true/>
      </dict>
      </plist>
    '';
  };
in
  stdenvNoCC.mkDerivation {
    inherit pname version;

    dontUnpack = true;
    dontBuild = true;

    nativeBuildInputs = [unzip];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share

      cp ${burpSrc} $out/share/${jarPath}
      cp ${loaderSrc}/loader.jar $out/share/loader.jar

      # substitute the @out@ placeholder now that $out is known, then install
      sed "s#@out@#$out#g" ${mainLauncher}/bin/${pname} > $out/bin/${pname}
      chmod +x $out/bin/${pname}

      sed "s#@out@#$out#g" ${loaderLauncher}/bin/loader > $out/bin/loader
      chmod +x $out/bin/loader

      # ---- macOS .app bundle ----
      APP="$out/Applications/${productDesktop}.app"
      mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

      cp ${infoPlist} "$APP/Contents/Info.plist"

      sed "s#@out@#$out#g" ${bundleExecutable}/bin/${pname} > "$APP/Contents/MacOS/${pname}"
      chmod +x "$APP/Contents/MacOS/${pname}"

      # extract icon and convert to .icns via macOS-native iconutil
      ICONSET=$(mktemp -d)/${pname}.iconset
      mkdir -p "$ICONSET"
      ${lib.getBin unzip}/bin/unzip -p ${burpSrc} resources/Media/icon64${productName}.png \
        > "$ICONSET/icon_64x64.png"
      cp "$ICONSET/icon_64x64.png" "$ICONSET/icon_32x32.png"
      cp "$ICONSET/icon_64x64.png" "$ICONSET/icon_32x32@2x.png"
      cp "$ICONSET/icon_64x64.png" "$ICONSET/icon_128x128.png"
      if [ -x /usr/bin/iconutil ]; then
        /usr/bin/iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/${pname}.icns" || true
      fi
      cp "$ICONSET/icon_64x64.png" "$APP/Contents/Resources/${pname}.png"

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
      maintainers = with maintainers; [bennofs fab];
      mainProgram = pname;
    };
  }
