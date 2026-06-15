#!/bin/bash

xcodebuild clean build-for-testing \
  -project WebDriverAgent.xcodeproj \
  -derivedDataPath $DERIVED_DATA_PATH \
  -scheme $SCHEME \
  -destination "$DESTINATION" \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES ARCHS=arm64

pushd $WD

# Package as IPA with Payload structure (like EasyClick does)
mkdir -p Payload
cp -r $SCHEME-Runner.app Payload/
zip -r $ZIP_PKG_NAME Payload

popd
mv $WD/$ZIP_PKG_NAME ./
