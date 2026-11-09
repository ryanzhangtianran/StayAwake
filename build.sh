#!/bin/sh
# Builds StayAwake.app with Go + Command Line Tools only (no Xcode needed).
set -eu
cd "$(dirname "$0")"

APP=StayAwake.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

export CGO_ENABLED=1 MACOSX_DEPLOYMENT_TARGET=13.0
export CGO_CFLAGS=-mmacosx-version-min=13.0 CGO_LDFLAGS=-mmacosx-version-min=13.0
for arch in arm64 amd64; do
	GOARCH=$arch go build -ldflags="-s -w" -o "build/StayAwake-$arch" .
done
lipo -create build/StayAwake-arm64 build/StayAwake-amd64 -output "$APP/Contents/MacOS/StayAwake"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key><string>StayAwake</string>
	<key>CFBundleIdentifier</key><string>com.ryanzhangtianran.StayAwake</string>
	<key>CFBundleExecutable</key><string>StayAwake</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>1.0.0</string>
	<key>CFBundleVersion</key><string>1</string>
	<key>LSMinimumSystemVersion</key><string>13.0</string>
	<key>LSUIElement</key><true/>
</dict>
</plist>
EOF

codesign --force --sign - "$APP"
echo "Built $APP"
