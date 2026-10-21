# Roadmap – Elospeed LedPreResistor

🇬🇧 *This file is kept in German. English readers: see the [README](README.md).*

Grobe Reihenfolge bis Version 2.0. Was gerade läuft, steht in [TODO.md](TODO.md); Ideen ohne Termin in [docs/IDEEN.md](docs/IDEEN.md).

## 2.0 – Neuauflage

1. **Grundstruktur** – Repository, Doku, automatischer Build. ✔
2. **Rechenkern** – `uCalc`, `uESeries`, `uColorCode` mit FPCUnit-Testprojekt (Referenz: 12 V / 3,2 V / 20 mA → 470 Ω E12, 18,72 mA, 164,7 mW, ½ W).
3. **Hauptfenster** – Eingaben im Labornetzgerät-Stil, Resultatkarte, Statuszeile mit Belastbarkeit (Warnung ab 50 %, geschätzte Erwärmung), `uTheme`.
4. **Zeichnungen** – leuchtende LED (`uLedView`), Farbringe, Schaltplan mit Werten (`uSchematic`).
5. **Rechenweg** – aufklappbarer Bereich, der die Rechnung Schritt für Schritt mit den aktuellen Werten erklärt.
6. **LED-Info** – neu geschriebener Text (die PDF von 2004 wird nicht übernommen).
7. **About-Fenster und Sprachen** – Deutsch und Englisch über `.po`-Dateien.
8. **Testversion** – unter Wine und Windows testen, danach offizielles Release 2.0.
