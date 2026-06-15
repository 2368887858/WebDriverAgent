#!/bin/bash

xcodebuild clean build-for-testing \
  -project WebDriverAgent.xcodeproj \
  -derivedDataPath $DERIVED_DATA_PATH \
  -scheme $SCHEME \
  -destination "$DESTINATION" \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES ARCHS=arm64

pushd $WD

# Create entitlements file
cat > /tmp/wda.entitlements << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>com.apple.private.xctest</key><true/>
  <key>com.apple.security.get-task-allow</key><true/>
  <key>platform-application</key><true/>
  <key>get-task-allow</key><true/>
  <key>run-unsigned-code</key><true/>
  <key>com.apple.private.skip-library-validation</key><true/>
  <key>com.apple.private.testing.using-test-proxy</key><true/>
</dict></plist>
EOF

# Ad-hoc sign the main app
/usr/bin/codesign -f -s - --entitlements /tmp/wda.entitlements \
  $SCHEME-Runner.app

# Sign the xctest plugin
if [ -d "$SCHEME-Runner.app/PlugIns/WebDriverAgentRunner.xctest" ]; then
  /usr/bin/codesign -f -s - \
    $SCHEME-Runner.app/PlugIns/WebDriverAgentRunner.xctest
fi

# Package as IPA
mkdir -p Payload
cp -r $SCHEME-Runner.app Payload/
zip -r $ZIP_PKG_NAME Payload

popd
mv $WD/$ZIP_PKG_NAME ./
