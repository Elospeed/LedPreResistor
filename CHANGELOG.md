# Changelog – Elospeed LedPreResistor

🇬🇧 *This file is kept in German. English readers: see the [README](README.md).*

Was erledigt ist, pro Version, neueste oben.
Die technischen Hintergründe stehen im [Entwicklungslog](docs/ENTWICKLUNGSLOG.md).

---

## Unveröffentlicht

### Rechenkern
- `uESeries`: Normreihen E12, E24 und E96, nächsthöherer Normwert über alle Dekaden. Genau 330 Ω bleibt 330 Ω (Fehler der Altversion behoben).
- `uColorCode`: Farbringe, 4 Ringe bei E12/E24 (Toleranz gold), 5 Ringe bei E96 (Toleranz braun).
- `uCalc`: Spannung am Widerstand, Normwert, tatsächlicher Strom, Leistungen, Auslastung mit Warnung ab 50 %, empfohlene Bauform und geschätzte Erwärmung. Eingaben mit Komma oder Punkt.
- Testprogramm `tests/` (FPCUnit) mit der Beispielrechnung; läuft bei jedem Build mit, ein Fehler macht den Build rot.

### Grundstruktur
- Repository nach der Elospeed-Struktur angelegt: README/LIESMICH, Lizenz (MIT), Changelog, Roadmap, TODO, Entwicklungslog, Ideenliste, Testversionen.
- Spezifikation `docs/PROJEKTUEBERSICHT.md` mit den Beschlüssen vom 21.10.2026.
- Quellcode der Altversion (Delphi 7, 2004) als Referenz in `docs/legacy/`, von Windows-1252 nach UTF-8 umgewandelt.
- Leeres Lazarus-Projekt `src/LedPreResistor.lpi` (Hauptfenster im dunklen Design, noch ohne Funktion), damit der automatische Build von Anfang an läuft.
- Automatischer Build mit GitHub Actions: Win64-EXE, verkleinert mit `strip`, Prüfsummen in `SHA256SUMS.txt`. Testversionen nur als Workflow-Artefakt (wie bei StemMaker), keine öffentlichen Vor-Releases.
