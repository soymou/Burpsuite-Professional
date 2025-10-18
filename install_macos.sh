git clone https://github.com/xiv3r/Burpsuite-Professional.git 
cd Burpsuite-Professional


# Download Burpsuite Professional
echo "Downloading Burp Suite Professional Latest..."
version=2025
url="https://portswigger.net/burp/releases/download?product=pro&type=Jar"
curl -L "$url" -o "burpsuite_pro_v$version.jar"

# Execute Key Generator and Burp Suite Simultaneously
echo "Starting Key loader.jar and Burp Suite Professional..."
(java -jar loader.jar) &
sleep 2  # Brief delay to ensure loader.jar starts first
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED \
     --add-opens=java.base/java.lang=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \
     -javaagent:loader.jar \
     -noverify \
     -jar burpsuite_pro_v$version.jar &


echo "Creating burpsuitepro shortcut..."
cat << 'EOF' > burp
#!/bin/bash
echo "Executing Burp Suite Professional..."
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED \
     --add-opens=java.base/java.lang=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \
     -javaagent:$(pwd)/loader.jar \
     -noverify \
     -jar $(pwd)/burpsuite_pro_v$version.jar &
EOF

#app bundle
echo "Creating burpsuitepro app bundle..."
jpackage --name "Burp Suite Professional" \
  --input $(pwd) \
  --main-jar burpsuite_pro_v$version.jar \
  --type app-image \
  --icon $(pwd)/burp_suite.icns \
  --dest ~/Applications/ \
  --java-options "--add-opens=java.desktop/javax.swing=ALL-UNNAMED" \
  --java-options "--add-opens=java.base/java.lang=ALL-UNNAMED" \
  --java-options "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED" \
  --java-options "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED" \
  --java-options "--add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED" \
  --java-options "-javaagent:$(pwd)/loader.jar" \
  --java-options "-noverify"