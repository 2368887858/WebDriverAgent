#!/bin/bash

xcodebuild clean build-for-testing \
  -project WebDriverAgent.xcodeproj \
  -derivedDataPath $DERIVED_DATA_PATH \
  -scheme $SCHEME \
  -destination "$DESTINATION" \
  CODE_SIGNING_ALLOWED=NO ARCHS=arm64

pushd $WD

# Install ldid for pseudo-signing
if ! command -v ldid &> /dev/null; then
  brew install ldid 2>/dev/null || true
fi
if ! command -v ldid &> /dev/null; then
  curl -L -o /usr/local/bin/ldid https://github.com/ProcursusTeam/ldid/releases/download/v2.1.5/ldid_macos_x86_64
  chmod +x /usr/local/bin/ldid
fi
LDID=$(which ldid 2>/dev/null || echo /usr/local/bin/ldid)

# Pseudo-sign all binaries
$LDID -S "$SCHEME-Runner.app/$SCHEME-Runner"
$LDID -S "$SCHEME-Runner.app/PlugIns/WebDriverAgentRunner.xctest/WebDriverAgentRunner"
for fw in "$SCHEME-Runner.app/PlugIns/WebDriverAgentRunner.xctest/Frameworks/"*.framework; do
  FW_NAME=$(basename "$fw" .framework)
  [ -f "$fw/$FW_NAME" ] && $LDID -S "$fw/$FW_NAME"
done

# Package as IPA
mkdir -p Payload
cp -r $SCHEME-Runner.app Payload/
zip -r $ZIP_PKG_NAME Payload

popd
mv $WD/$ZIP_PKG_NAME ./
