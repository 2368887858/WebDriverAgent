#!/bin/bash

xcodebuild clean build-for-testing \
  -project WebDriverAgent.xcodeproj \
  -derivedDataPath $DERIVED_DATA_PATH \
  -scheme $SCHEME \
  -destination "$DESTINATION" \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES ARCHS=arm64

pushd $WD

# Build the IPA properly - include XCTest frameworks (needed on real devices)
# and add ad-hoc code signature
mkdir -p Payload
cp -r $SCHEME-Runner.app Payload/

# Ad-hoc sign the entire bundle so re-signing tools can work
codesign -f -s - --entitlements - Payload/$SCHEME-Runner.app <<< '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>com.apple.private.xctest</key><true/>
  <key>com.apple.security.get-task-allow</key><true/>
  <key>platform-application</key><true/>
  <key>keychain-access-groups</key><array><string>com.apple.token</string></array>
  <key>com.apple.private.skip-library-validation</key><true/>
  <key>run-unsigned-code</key><true/>
  <key>get-task-allow</key><true/>
  <key>com.apple.private.memorystatus</key><true/>
  <key>com.apple.private.testing.using-test-proxy</key><true/>
</dict></plist>'

# Also sign the xctest bundle
if [ -d "Payload/$SCHEME-Runner.app/PlugIns/WebDriverAgentRunner.xctest" ]; then
  codesign -f -s - Payload/$SCHEME-Runner.app/PlugIns/WebDriverAgentRunner.xctest
fi

# Package as IPA
zip -r $ZIP_PKG_NAME Payload

popd
mv $WD/$ZIP_PKG_NAME ./
