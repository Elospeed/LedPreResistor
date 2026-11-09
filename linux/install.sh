#!/bin/sh
# LedPreResistor für den aktuellen Benutzer einrichten (ohne root):
# Programm nach ~/.local/bin, Eintrag im Startmenü, Symbol.
# Entfernen: ./install.sh --entfernen   (oder --uninstall)
# Installs LedPreResistor for the current user (no root needed).
set -e
HIER="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
APPS="$DATA/applications"
ICONS="$DATA/icons/hicolor/512x512/apps"

case "$1" in
  --entfernen|--uninstall)
    rm -f "$BIN/LedPreResistor" "$APPS/ledpreresistor.desktop" "$ICONS/ledpreresistor.png"
    echo "LedPreResistor entfernt / removed."
    exit 0
    ;;
esac

mkdir -p "$BIN" "$APPS" "$ICONS"
install -m 755 "$HIER/LedPreResistor" "$BIN/LedPreResistor"
install -m 644 "$HIER/ledpreresistor.png" "$ICONS/ledpreresistor.png"
# Exec mit vollem Pfad, falls ~/.local/bin nicht im PATH ist
sed "s|^Exec=.*|Exec=$BIN/LedPreResistor|" "$HIER/ledpreresistor.desktop" > "$APPS/ledpreresistor.desktop"
chmod 644 "$APPS/ledpreresistor.desktop"
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APPS" >/dev/null 2>&1 || true
fi
echo "LedPreResistor eingerichtet / installed: $BIN/LedPreResistor"
