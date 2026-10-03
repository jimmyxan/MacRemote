#!/bin/bash
# Builds MacRemote.app (double-click to run; menu bar icon, no Dock icon).
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
APP=MacRemote.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/MacRemote "$APP/Contents/MacOS/MacRemote"
# Icons: AppIcon.icns for the Mac, touch-icon.png (180px, full-bleed) for the iPhone home screen.
ICONS=$(mktemp -d)
swift tools/make_icon.swift "$ICONS/1024.png"
mkdir "$ICONS/AppIcon.iconset"
for s in 16 32 128 256 512; do
  sips -z $s $s "$ICONS/1024.png" --out "$ICONS/AppIcon.iconset/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) "$ICONS/1024.png" --out "$ICONS/AppIcon.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONS/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"
swift tools/make_icon.swift "$ICONS/flat.png" flat
sips -z 180 180 "$ICONS/flat.png" --out "$APP/Contents/Resources/touch-icon.png" >/dev/null
rm -rf "$ICONS"

# Now Playing helper: loaded by /usr/bin/perl to read MediaRemote (see tools/mediaremote.m).
clang -dynamiclib -fobjc-arc -framework Foundation -o "$APP/Contents/Resources/libmediaremote.dylib" tools/mediaremote.m
codesign --force --sign - "$APP/Contents/Resources/libmediaremote.dylib"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>MacRemote</string>
<key>CFBundleIdentifier</key><string>local.macremote</string>
<key>CFBundleExecutable</key><string>MacRemote</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleShortVersionString</key><string>0.2.0</string>
<key>CFBundleVersion</key><string>2</string>
<key>LSUIElement</key><true/>
<key>NSLocalNetworkUsageDescription</key><string>Serve il telecomando web sulla rete locale.</string>
<key>NSAppleEventsUsageDescription</key><string>Mostra il brano in riproduzione di Music e Spotify sul telecomando.</string>
<key>NSBonjourServices</key><array><string>_http._tcp</string></array>
</dict></plist>
PLIST
# Fixed designated requirement: keeps the Accessibility permission valid across rebuilds
# (a plain ad-hoc signature ties it to the binary hash, so every rebuild silently revokes it).
codesign --force --sign - --identifier local.macremote -r='designated => identifier "local.macremote"' "$APP"
echo "Built $APP"
