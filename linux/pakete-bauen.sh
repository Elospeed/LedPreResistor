#!/bin/bash
# Baut aus dem fertigen Linux-Programm das Linux-Paket:
#   LedPreResistor-<Version>-linux-x86_64.tar.gz  (braucht GTK2 auf dem System)
#
# Aufruf aus dem Hauptordner des Repos:
#   linux/pakete-bauen.sh <Version> <Ausgabeordner>
# Erwartet bin/LedPreResistor (lazbuild --ws=gtk2).
set -euo pipefail

VERSION="$1"
AUS="$(realpath -m "$2")"
HIER="$(cd "$(dirname "$0")" && pwd)"
REPO="$(dirname "$HIER")"
PROG="$REPO/bin/LedPreResistor"
ICON="$REPO/site/img/icon-512.png"

test -x "$PROG" || { echo "Fehlt: $PROG" >&2; exit 1; }
mkdir -p "$AUS"
ARBEIT="$(mktemp -d)"
trap 'rm -rf "$ARBEIT"' EXIT

# ---------- tar.gz: Ordner zum Entpacken und Starten ----------
NAME="LedPreResistor-$VERSION-linux-x86_64"
D="$ARBEIT/$NAME"
mkdir -p "$D"
install -m 755 "$PROG" "$D/LedPreResistor"
install -m 644 "$ICON" "$D/ledpreresistor.png"
install -m 644 "$HIER/ledpreresistor.desktop" "$D/ledpreresistor.desktop"
install -m 755 "$HIER/install.sh" "$D/install.sh"
install -m 644 "$HIER/LIESMICH-Linux.txt" "$D/LIESMICH-Linux.txt"
install -m 644 "$HIER/README-Linux.txt" "$D/README-Linux.txt"
install -m 644 "$REPO/LICENSE" "$D/LICENSE"
# feste Zeitstempel und Besitzer: gleiches Archiv bei gleichem Inhalt
tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='2026-01-01 00:00Z' \
  -C "$ARBEIT" -czf "$AUS/$NAME.tar.gz" "$NAME"

ls -l "$AUS"
