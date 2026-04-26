#!/usr/bin/env bash
# Downloads Orbitron and Rajdhani from Google Fonts
set -e
DEST="assets/fonts"
mkdir -p "$DEST"

BASE="https://fonts.gstatic.com/s"
echo "Downloading Orbitron..."
curl -L "$BASE/orbitron/v31/yMJMMIlzdpvBhQQL_SC3X9yhF25-T1nyKS6xpmIyXjU.woff2" -o "$DEST/tmp.woff2"
# Note: convert woff2 → ttf using fonttools or use Google Fonts direct TTF download

echo "⚠  Please download TTF versions from:"
echo "   https://fonts.google.com/specimen/Orbitron"
echo "   https://fonts.google.com/specimen/Rajdhani"
echo "   Place them in assets/fonts/"
