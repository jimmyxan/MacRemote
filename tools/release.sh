#!/bin/bash
# Builds MacRemote.app and zips it for a GitHub Release (the download site links to .../releases/latest/download/MacRemote.zip).
# Usage: tools/release.sh v1.0.0
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="${1:?usage: tools/release.sh vX.Y.Z}"
./build.sh
rm -f MacRemote.zip
ditto -c -k --keepParent MacRemote.app MacRemote.zip   # ditto keeps the code signature and permissions that plain zip drops
echo "Built MacRemote.zip. Publish it with:"
echo "  gh release create $VERSION MacRemote.zip --title \"MacRemote $VERSION\" --generate-notes"
