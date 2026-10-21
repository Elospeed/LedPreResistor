# Changelog – Elospeed LedPreResistor

🇬🇧 *This file is kept in German. English readers: see the [README](README.md).*

Was erledigt ist, pro Version, neueste oben.
Die technischen Hintergründe stehen im [Entwicklungslog](docs/ENTWICKLUNGSLOG.md).

---

## Unveröffentlicht

### Grundstruktur
- Repository nach der Elospeed-Struktur angelegt: README/LIESMICH, Lizenz (MIT), Changelog, Roadmap, TODO, Entwicklungslog, Ideenliste, Testversionen.
- Spezifikation `docs/PROJEKTUEBERSICHT.md` mit den Beschlüssen vom 21.10.2026.
- Quellcode der Altversion (Delphi 7, 2004) als Referenz in `docs/legacy/`, von Windows-1252 nach UTF-8 umgewandelt.
- Leeres Lazarus-Projekt `src/LedPreResistor.lpi` (Hauptfenster im dunklen Design, noch ohne Funktion), damit der automatische Build von Anfang an läuft.
- Automatischer Build mit GitHub Actions: Win64-EXE, verkleinert mit `strip`, Prüfsummen in `SHA256SUMS.txt`, Testversionen als Vor-Release.
