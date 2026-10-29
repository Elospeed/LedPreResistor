# Changelog – Elospeed LedPreResistor

🇬🇧 *This file is kept in German. English readers: see the [README](README.md).*

Was erledigt ist, pro Version, neueste oben.
Die technischen Hintergründe stehen im [Entwicklungslog](docs/ENTWICKLUNGSLOG.md).

---

## Unveröffentlicht

### LED-Info
- Neue Seite «Die Leuchtdiode» (`src/info/led-info.html`): Aufbau, Farben und Durchlassspannungen, Vorwiderstand mit kleinem Rechner, Leistung und Erwärmung.
- Steckt als Ressource in der EXE und öffnet sich über Hilfe → LED-Info (F1) im Standard-Browser. Keine Zusatzdatei, kein Acrobat Reader mehr.

### Hauptfenster (Entwurf A «Labor 2»)
- Eingaben links: Speisespannung, LED-Farbe (mit Farbpunkt), Durchlassspannung, LED-Strom, E-Reihe, Anzahl LEDs in Reihe. Pfeiltasten und Mausrad ändern die Werte schrittweise (mit Umschalt ×10).
- LED-Vorschau: realistische 5-mm-LED in der gewählten Farbe mit Leuchtschein, Anode/Kathode und flacher Seite beschriftet; blinkt auf Wunsch (0,5 / 1 / 2 / 5 Hz).
- Schaltplan mit allen Werten an den Bauteilen und Farbringen im Widerstand.
- Vier Resultatkarten: Normwert mit Farbringen, tatsächlicher Strom, Verlustleistung, empfohlene Bauform mit Auslastungsbalken.
- Aufklappbarer Rechenweg in fünf Schritten mit den aktuellen Zahlen, inklusive geschätzter Erwärmung.
- Statuszeile grün/gelb/rot mit Erwärmung, Empfehlung und Gesamtleistung.
- Menü: Resultat kopieren (Strg+Umschalt+C), Eingaben zurücksetzen, Rechenweg ein/aus, LED blinken, Info.
- `uFormat`: Anzeige ohne überflüssige Nachkommastellen (4,7 kΩ, 18,72 mA, 164,8 mW), mit Tests.

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
