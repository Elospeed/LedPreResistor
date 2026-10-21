# Elospeed LedPreResistor 2.0 – Projektübersicht

Stand: 21.10.2026 · Autor: Elospeed

## Ziel und Hintergrund

LedPreResistor wird als freies Lazarus-Tool **Elospeed LedPreResistor 2.0** neu aufgebaut: modern, eine einzelne EXE, ohne Zusatzpakete.

- **Original:** Delphi 7, ca. 2004, veröffentlicht als Freeware von SpeedJohn Electronics. Zwei Units (`MainProgram.pas`, `About.pas`), rund 350 Zeilen Logik, Formulare im Textformat. Quellcode als Referenz unter `docs/legacy/`.
- **Abhängigkeiten der Altversion:** fast alle Bedienelemente aus JVCL/JCL, dazu eine eingebettete Info-PDF und eine Registry-Abfrage nach Acrobat Reader.
- **Entscheid:** keine automatische Konvertierung. Die Oberfläche wird in Lazarus neu gebaut, die Rechenlogik wird übernommen und korrigiert.
- **Autor:** Elospeed (Altversion: SpeedJohn / Speedy).

## Funktionsumfang

Version 2.0 rechnet live bei jeder Eingabe und zeigt das Resultat als Zahl, als Farbringe und im Schaltplan.

| Funktion | Altversion | 2.0 |
| --- | --- | --- |
| Vorwiderstand aus U, Ud, I berechnen | ja | ja, live ohne Knopf |
| LED-Farbvorgaben (Rot, Gelb, Grün, Blau, Weiss, Infrarot) | ja, alte Werte | ja, aktualisierte Werte |
| Manuelle Durchlassspannung | ja | ja |
| Nächster Normwert | nur E12 | E12, E24, E96 wählbar |
| Mehrere LEDs in Reihe | nein | ja (Anzahl n) |
| Tatsächlicher Strom, Leistung R, Leistung total | ja | ja |
| Belastbarkeit des Widerstands (⅛ / ¼ / ½ / 1 W) mit Warnung | nein | ja |
| Farbringe des Widerstands | nein | ja (4 Ringe; 5 Ringe bei E96) |
| Schematischer Schaltplan mit Werten | nein | ja |
| Leuchtende LED in gewählter Farbe | blinkende LEDs | statisch leuchtend |
| Resultat in Zwischenablage kopieren | nein | ja |
| LED-Info | PDF über Acrobat | Info-Seite im Programm oder PDF mit Standardprogramm |
| Komma und Punkt als Dezimalzeichen | nur Punkt | beides |
| Sprache | Deutsch | Deutsch und Englisch |

## Berechnung

Gerechnet wird intern immer in SI-Einheiten (V, A, Ω, W). Umgerechnet wird nur bei Ein- und Ausgabe (mA, mW).

```
U_R      = U - n * Ud
R_ber    = U_R / I
R        = nächster Normwert >= R_ber   (gewählte Reihe, alle Dekaden)
I_tat    = U_R / R
P_R      = U_R * I_tat
P_LED    = n * Ud * I_tat
P_total  = U * I_tat
Auslastung = P_R / P_Nenn
```

- **Prüfung:** U muss grösser als n × Ud sein, sonst Hinweis im Resultatfeld statt Meldungsfenster.
- **Normwert:** Der nächsthöhere Wert der gewählten Reihe (E12, E24, E96) wird über alle Dekaden gesucht. Verglichen wird mit einer kleinen Toleranz (relativ 1e-9), damit z. B. genau 330 Ω nicht fälschlich auf 390 Ω springt.
- **Belastbarkeit:** Empfohlen wird die kleinste Bauform aus ⅛, ¼, ½, 1 W, die höchstens zu 50 % ausgelastet ist. Über 50 % gibt es eine Warnung (gelb), über 100 % einen Fehler (rot).
- **Anzeige:** Spannungen mit 2 Nachkommastellen, Ströme in mA mit 1–2, Leistungen in mW, Widerstände ohne unnötige Nachkommastellen (z. B. 4,7 kΩ).

**Typische Durchlassspannungen (Vorgaben, Datenblatt hat Vorrang):**

| LED | Ud typisch (V) | Altversion (V) |
| --- | --- | --- |
| Rot | 2,0 | 1,6 |
| Gelb | 2,1 | 2,2 |
| Grün (Standard) | 2,2 | 2,1 |
| Blau | 3,2 | 2,9 |
| Weiss | 3,2 | 4,0 |
| Infrarot | 1,3 | 1,5 |

**Beispielrechnung (Referenz für Tests):** U = 12 V, 1 × weisse LED (3,2 V), I = 20 mA, E12.

| Grösse | Wert |
| --- | --- |
| Spannung am Widerstand U_R | 8,80 V |
| Berechneter Widerstand | 440 Ω |
| Normwert E12 | 470 Ω (gelb, violett, braun, gold) |
| Tatsächlicher Strom | 18,72 mA |
| Leistung Widerstand | 164,8 mW (genau 164,77 mW) |
| Leistung total | 224,7 mW (genau 224,68 mW) |
| Auslastung ¼-W-Widerstand | 66 % → Empfehlung ½ W |

## Design

Gewählt ist Variante B «Labor» (dunkel) mit integriertem Schaltplan. Referenz: `docs/design/Entwurf-Final.html` (im Browser öffnen).

**Fenster (ca. 960 × 700 px), von links nach rechts und oben nach unten:**

1. **Linke Spalte «LED»:** gross gezeichnete LED, die in der gewählten Farbe leuchtet; darunter sechs runde Farbknöpfe (Rot, Gelb, Grün, Blau, Weiss, Infrarot), Name und Vorgabe-Ud, Knopf «Manuelle Durchlassspannung», Knopf «LED-Info».
2. **Eingabezeile:** vier Anzeigefelder im Stil eines Labornetzgeräts: Betriebsspannung (V), Durchlass Ud (V), LED-Strom (mA), LEDs in Reihe (Stück). Ziffern in Monospace, Bernstein-Farbe.
3. **Resultatkarte:** Vorwiderstand gross (z. B. 470 Ω), darunter der berechnete Wert; rechts die Farbringe und die Umschaltung E12 / E24 / E96.
4. **Schaltung:** Quelle, Widerstand mit Farbringen, LED-Symbol und Stromrichtung; Werte direkt an den Bauteilen (U, R, U_R, P_R, Ud, I). Bei n > 1 zeigt das LED-Symbol «× n».
5. **Statuszeile:** Belastbarkeits-Hinweis (grün / gelb / rot) mit Empfehlung, geschätzter Erwärmung und Gesamtleistung, Knopf «Resultat kopieren».
6. **Rechenweg (aufklappbar):** die Formeln aus «Berechnung» mit den aktuellen Zahlen eingesetzt, Schritt für Schritt.

**Farben und Schrift:**

| Element | Wert |
| --- | --- |
| Hintergrund / Karten / Rahmen | #0F1418 / #161D23 / #222A31 |
| Text / Nebentext | #E6EBF0 / #8E99A4 |
| Eingabewerte | #FFB547 (Bernstein) |
| Warnung | Text #FFCF7A auf #251C0B |
| Schaltplan-Linien | #C9D1D9 |
| Schrift | Segoe UI; Zahlen Cascadia Mono, Ersatz Consolas |

Titelleiste mit «LedPreResistor · Elospeed 2.0» und Sprachumschaltung DE | EN.

## Technische Umsetzung in Lazarus

Nur LCL-Standard, keine Zusatzpakete: Was es nicht fertig gibt, wird in eigenen kleinen Units selbst gezeichnet. Ziel ist eine einzelne Windows-EXE (64 Bit).

**Ersatz der JVCL-Komponenten:**

| Altversion | Lazarus 2.0 |
| --- | --- |
| TJvTransLED + 6 Timer (blinkende LEDs) | eigene LED-Zeichnung auf TPaintBox, leuchtend statt blinkend |
| TJvRadioButton (Farbwahl) | runde Farbknöpfe, selbst gezeichnet |
| TJvGroupBox, TJvLabel | TPanel und TLabel mit Theme-Farben |
| TJvBitBtn «Berechne» | entfällt (Live-Berechnung bei OnChange) |
| TJvScrollingLabel, TJvWaitingGradient | entfallen |
| TJvScrollText, TJvGradient (About) | schlichtes About-Fenster |
| JclFileUtils (Versionsinfo) | Lazarus-Unit `fileinfo` |
| Registry-Abfrage Acrobat + ShellExecute | `OpenDocument` aus `LCLIntf` oder Info direkt im Programm |

**Geplante Units (`src/`):**

| Unit | Aufgabe |
| --- | --- |
| `LedPreResistor.lpr` / `.lpi` | Projektdatei |
| `uMain.pas` / `.lfm` | Hauptfenster, verbindet Eingaben, Rechnung und Anzeige |
| `uCalc.pas` | reine Rechenlogik ohne GUI (U_R, R, I, Leistungen, Prüfungen) |
| `uESeries.pas` | Tabellen E12, E24, E96 und Suche nächsthöherer Normwert |
| `uColorCode.pas` | Farbringe zu einem Widerstandswert (4 und 5 Ringe) |
| `uLedView.pas` | LED-Zeichnung mit Leuchteffekt |
| `uSchematic.pas` | Schaltplan-Zeichnung mit Werten |
| `uTheme.pas` | alle Farben und Schriften an einer Stelle |
| `uAbout.pas` / `.lfm` | About-Fenster (Elospeed, Version, Lizenz, Link) |
| `lang/` | Deutsch und Englisch über `.po`-Dateien (LCLTranslator) |

**Bekannte Stolperstellen:**

- Windows erlaubt bei Standard-Knöpfen (TButton) keine eigene Hintergrundfarbe. Knöpfe im dunklen Design werden deshalb selbst gezeichnet.
- Der Leuchteffekt der LED braucht Transparenz. Ohne Zusatzbibliothek wird er mit Farbringen nachgebildet, die stufenweise in den Hintergrund übergehen. Das sieht etwas einfacher aus als im Entwurf.
- Die Rechenlogik in `uCalc` wird mit einem kleinen Testprojekt (FPCUnit) geprüft, Referenz ist die Beispielrechnung oben.

## Korrekturen gegenüber der Altversion

| Problem in der Altversion | Lösung in 2.0 |
| --- | --- |
| E12-Suche ohne Toleranz: 3.3 × 100 ergibt 329,99999…, genau 330 Ω springt auf 390 Ω | Vergleich mit relativer Toleranz 1e-9 |
| `FloatToStr` zeigt Werte wie 6.6000000000000005 | formatierte Ausgabe mit festen Nachkommastellen |
| Nur Punkt als Dezimalzeichen erlaubt; mit deutscher Ländereinstellung bricht die Umrechnung ab | Komma und Punkt werden akzeptiert, unabhängig von der Ländereinstellung |
| «Manuelle Eingabe» hebt die Auswahl «Rot» nicht auf (Zeile fehlt) | eine gemeinsame Auswahl-Logik für alle Farben |
| Sechs fast identische Click-Prozeduren und sechs Timer | eine Tabelle mit LED-Daten, eine Prozedur |
| Veraltete Ud-Werte (Weiss 4,0 V, Blau 2,9 V) | aktualisierte Vorgaben (siehe Berechnung) |
| Fehler nur als «Unbekannter Fehler» im Meldungsfenster | konkreter Hinweis direkt im Resultatfeld |
| Tippfehler «Standart», «Duchlassspannung» | korrigiert |
| Info-PDF nur mit installiertem Acrobat Reader | Standardprogramm des Systems oder Info im Programm |

## Projektstruktur und GitHub

Das Repo folgt der üblichen Elospeed-Struktur, Arbeitsname `Elospeed/LedPreResistor`.

- `README.md` (Englisch) und `LIESMICH.md` (Deutsch), gegenseitig verlinkt; `LICENSE` (MIT)
- `CHANGELOG.md`, `ROADMAP.md`, `TODO.md` im Root
- `docs/ENTWICKLUNGSLOG.md`, `docs/IDEEN.md`, `docs/TESTVERSIONEN.md`
- `src/` mit den Units oben, `src/lang/` für DE/EN
- `.github/workflows/build.yml`: Build mit Lazarus 3.8 auf `windows-latest`, `strip`, `SHA256SUMS.txt`, Testversionen nur als Workflow-Artefakt (keine Vor-Releases, wie bei StemMaker)
- Keine EXE im Repository; Downloads nur über Releases
- Altversion: Delphi-Quellcode als Referenz unter `docs/legacy/` (ohne EXE, DCU, RES-Binärdateien)
- Commits als Elospeed, Kommentare im Code auf Deutsch, jede Funktion dokumentiert

## Beschlüsse vom 21.10.2026

- **Belastbarkeits-Warnung:** Grenze bleibt bei 50 %. Die Statuszeile zeigt zusätzlich die geschätzte Erwärmung des Widerstands (Richtwert ca. 200–250 °C/W für ¼-W-Bauformen, als Näherung gekennzeichnet).
- **Rechenweg:** Neuer aufklappbarer Bereich «Rechenweg», der die Berechnung Schritt für Schritt mit den aktuellen Eingabewerten erklärt (Lernen am Beispiel).
- **LED-Info:** wird komplett neu geschrieben; die PDF von 2004 wird nicht übernommen.
- **Parallelschaltung:** vorerst nicht, als Idee in `docs/IDEEN.md`.

## Offene Punkte und nächste Schritte

**Zu entscheiden:**

- Programmname bleibt «LedPreResistor» oder wird auf Deutsch/Englisch angepasst? (vorerst Arbeitsname)
- LED-Info als Seite im Programm oder als neue PDF mit Standardprogramm?

**Nächste Schritte:**

- [x] Repo `Elospeed/LedPreResistor` mit Grundstruktur und Build-Workflow anlegen
- [x] `uCalc`, `uESeries`, `uColorCode` schreiben und mit Testprojekt prüfen
- [ ] Hauptfenster mit Eingaben, Resultatkarte und Theme aufbauen
- [ ] LED-Zeichnung und Schaltplan-Zeichnung umsetzen
- [ ] Rechenweg-Bereich
- [ ] About-Fenster und Sprachumschaltung DE/EN
- [ ] Erste Testversion bauen, unter Wine starten, als ZIP mit Anleitung an Speedy
