#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP=build/NetMonitor.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build -c release --show-bin-path)/NetMonitor" "$APP/Contents/MacOS/NetMonitor"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"

echo "Built $APP"
