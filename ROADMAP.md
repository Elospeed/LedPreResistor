# Roadmap – Elospeed LedPreResistor

🇬🇧 *This file is kept in German. English readers: see the [README](README.md).*

Grobe Reihenfolge bis Version 2.0. Was gerade läuft, steht in [TODO.md](TODO.md); Ideen ohne Termin in [docs/IDEEN.md](docs/IDEEN.md).

## 2.0 – Neuauflage

1. **Grundstruktur** – Repository, Doku, automatischer Build. ✔
2. **Rechenkern** – `uCalc`, `uESeries`, `uColorCode` mit FPCUnit-Testprojekt (Referenz: 12 V / 3,2 V / 20 mA → 470 Ω E12, 18,72 mA, 164,8 mW, ½ W). ✔
3. **Hauptfenster** – nach Entwurf A «Labor 2»: Eingaben, LED-Vorschau, Schaltplan, Resultatkarten, Statuszeile mit Belastbarkeit (Warnung ab 50 %, geschätzte Erwärmung), `uTheme`. ✔
4. **Zeichnungen** – leuchtende LED (`uLedView`), Farbringe, Schaltplan mit Werten (`uSchematic`). ✔
5. **Rechenweg** – aufklappbarer Bereich, der die Rechnung Schritt für Schritt mit den aktuellen Werten erklärt. ✔
6. **LED-Info** – neu geschriebene Seite «Die Leuchtdiode» als Ressource in der EXE (die PDF von 2004 wird nicht übernommen). ✔
6b. **Projektseite** – `site/` wie bei StemMaker (Englisch/Deutsch, Screenshots), veröffentlicht über GitHub Pages.
7. **About-Fenster und Sprachen** – Deutsch und Englisch über `.po`-Dateien (Sprachen ✔ in 2.1; About-Fenster offen).
8. **Testversion** – unter Wine und Windows testen, danach offizielles Release 2.0.

## 2.2 – Linux

1. **Linux-Build** – nativ mit Lazarus/GTK2, tar.gz mit Startmenü-Eintrag, Build und Release in GitHub Actions. ✔
2. **Test in der Linux-VM**, danach Release 2.2 mit ZIP (Windows) und tar.gz (Linux).
3. **Projektseite** – Windows- und Linux-Download nebeneinander.

## 2.3 – Blinkschaltung

1. **Rechenkern** `uBlink` – NE555 astabil (mit/ohne Diode) und Multivibrator mit 2 × BC547, vorwärts und rückwärts, mit Tests. ✔
2. **Reiter «Blinkschaltung»** – Schaltplan (`uBlinkSchematic`), Karten, Rechenweg, Prüfungen, blinkende Vorschau, Englisch. ✔
3. **LED-Info-Kapitel** «Blinkschaltungen». ✔
4. **Testversion** unter Wine (100 % und 150 %) und Windows, danach Release 2.3.

## 2.4 – Konstantstrom

1. **Rechenkern** `uKsq` – LM317 und Konstantstromquelle mit zwei Transistoren, Speisespannung als Bereich, Bauteilvorschlag, mit Tests. ✔
2. **Reiter «Konstantstrom»** – Schaltpläne (`uKsqSchematic`), Karten, Rechenweg, Prüfungen, Englisch. ✔
3. **Stränge parallel** im Reiter «Vorwiderstand». ✔
4. **LED-Info** Kapitel «Konstantstrom» neu. ✔
5. **Testversion** unter Wine (100 %, 150 %, 200 %) und Linux, danach Release 2.4.
