# Changelog – Elospeed LedPreResistor

🇬🇧 *This file is kept in German. English readers: see the [README](README.md).*

Was erledigt ist, pro Version, neueste oben.
Die technischen Hintergründe stehen im [Entwicklungslog](docs/ENTWICKLUNGSLOG.md).

---

## 2.3 – 11. November 2026

### Blinkschaltung
- Neuer Reiter «Blinkschaltung» (Ansicht → Blinkschaltung, Strg+2; zurück mit Strg+1). Der gewählte Reiter und die Schaltung bleiben beim nächsten Start erhalten.
- NE555 astabil: aus R1, R2 und C die Zeiten t_H und t_L, Frequenz und Tastgrad; wahlweise mit Diode über R2 (dann auch Tastgrad unter 50 %). LED gegen Masse, gegen +U oder beide (Wechselblinker).
- Multivibrator mit zwei BC547: aus den Basiswiderständen und Kondensatoren die Leuchtzeit jeder LED, dazu Basisstrom und Übersteuerung.
- Rückwärts «aus Frequenz» (NE555): Wunschfrequenz und Tastgrad eingeben, das Programm schlägt Widerstände aus der E12-Reihe vor und rechnet mit diesen weiter.
- Vorwiderstand der LEDs mit der Spannung am Ausgang (NE555: U − 1,7 V, Multivibrator: U − 0,2 V), Farbringe und Schaltplan mit allen Werten.
- Die LED-Vorschau blinkt mit den berechneten Zeiten (beim Multivibrator zwei LEDs im Wechsel), oben links steht die Blinkfrequenz gross in Hz bzw. kHz. Der Takt wird aus der laufenden Zeit berechnet, dadurch blinkt die Vorschau gleichmässig. Sie blinkt bis etwa 10 Hz (An- und Aus-Zeit mindestens 50 ms); schneller kann ein Bildschirm mit 60 Hz das nicht gleichmässig zeigen, dann zeigt sie ruhiges, gedimmtes Licht mit der Helligkeit des Tastgrads.
- Rechenweg mit fünf Schritten und Statuszeile mit Prüfungen: NE555-Versorgung 4,5–16 V, R1 mindestens 1 kΩ, Ausgangsstrom bis 200 mA, Sperrspannung an der Basis über 6 V (Diode 1N4148 empfohlen), Sättigung der Transistoren, Blinken über 50 Hz (wirkt wie Dauerlicht).
- LED-Info: neues Kapitel «Blinkschaltungen» (Deutsch und Englisch).
- Hinweis rechts in der Kopfzeile «Rechenweg» (auch zugeklappt): Durchlassspannung und Strom aus dem Datenblatt der verwendeten LED nehmen, die Vorgaben sind nur Richtwerte.
- Im Reiter «Vorwiderstand» leuchtet die LED-Vorschau jetzt dauernd: «Blinken» mit fester Frequenz (und «Ansicht → LED blinken») ist entfallen, geblinkt wird mit echten Zeiten im Reiter «Blinkschaltung». Die LED-Vorschau ist dadurch etwas grösser.
- Pfeiltasten und Mausrad springen bei Widerständen durch die E12-Reihe, bei Kondensatoren durch die E6-Reihe.
- Multivibrator: «Symmetrisch 1:1» ist vorgewählt (RB2 folgt RB1). Statt «aus Frequenz» gibt es «aus Zeiten»: Leuchtdauer von LED 1 und LED 2 in Sekunden eingeben, z. B. 1 s und 0,5 s; das Programm wählt die E12-Widerstände und zeigt die tatsächlichen Zeiten.
- Eingabefelder nehmen nur Zahlen an: Buchstaben werden ignoriert, Punkt und Komma werden zum Dezimalzeichen der Sprache, nur eines pro Feld.

---

## 2.2 – 9. November 2026

### Linux
- Eigene Linux-Version (x86_64), nativ mit Lazarus/GTK2 gebaut, kein Wine nötig: `LedPreResistor-2.2-linux-x86_64.tar.gz` entpacken und `./LedPreResistor` starten.
- `install.sh` im Paket nimmt das Programm ohne root ins Startmenü auf (`~/.local`), `install.sh --entfernen` entfernt es wieder.
- Unter Linux steht die Sprachwahl in `~/.config/LedPreResistor/LedPreResistor.ini` (Programmordner sind dort oft schreibgeschützt). Unter Windows bleibt sie neben der EXE.
- Startsprache unter Linux nach `LANG` (de… → Deutsch, sonst Englisch).
- Eingabefelder unter Linux in den Farben des System-Themes: Ubuntu (Yaru) zeichnet die Felder weiss und übergeht die dunkle Farbe, die Werte waren weiss auf weiss unsichtbar (gefunden beim Test unter Ubuntu 24.04).
- Behoben für Linux: Absturz beim Start («Failed to create handles»), weil die LED-Vorschau ein Pixelformat nutzte, das GTK2 nicht annimmt. Schriften: unter Linux die Standardschriften des Systems statt Segoe UI / Consolas.
- Jeder Build baut und prüft jetzt auch die Linux-Version (startet sie unter Xvfb), das Release enthält ZIP (Windows) und tar.gz (Linux).

### Projektseite
- Download für Windows und Linux nebeneinander, Frage «Gibt es eine Linux-Version?», Linux in Titel und Beschreibung.

### Sonstiges
- Versionsinfo der EXE: Unterversion stand seit 2.1 auf 0 (zeigte 2.0.1), jetzt richtig 2.2.

---

## 2.1 – 8. November 2026

### Englisch
- Das Programm gibt es jetzt auf Deutsch und Englisch: Menüs, Beschriftungen, Auswahllisten, Schaltplan, Resultatkarten, Rechenweg, Statuszeile, Fehlermeldungen, Info und die Zusammenfassung beim Kopieren.
- Sprachwahl wie bei StemMaker: Deutsch bei deutschem Windows, sonst Englisch. Unter Ansicht → Sprache lässt sich jederzeit umschalten, ohne Neustart; die Wahl steht in `LedPreResistor.ini` neben der EXE.
- Englisch zeigt Zahlen mit Dezimalpunkt (18.72 mA) und Prozent ohne Leerschlag (66%). Eingeben lässt sich weiterhin Komma oder Punkt.
- LED-Info auf Englisch («The LED», `src/info/led-info-en.html`), F1 öffnet die Seite in der gewählten Sprache.
- Übersetzung in `src/lang/en.po` (gettext, mit Poedit bearbeitbar), steckt als Ressource in der EXE: weiterhin eine einzige EXE ohne Zusatzdateien.
- Neue Unit `uLang` mit Tests; der Build prüft, dass englische LED-Info und Übersetzung in der EXE stecken.

### Projektseite
- Englische Seite mit englischen Screenshots, Hinweis «German only» entfernt; deutsche Seite mit Frage zur englischen Version.

---

## 2.0.1 – 30. Oktober 2026

### Anzeigeskalierung (125 / 150 / 200 %)
- Das Hauptfenster war bei 150 und 200 % höher als ein Full-HD-Bildschirm: Statuszeile und Ko-fi-Knopf lagen unter dem Bildschirmrand, bei 200 % passte nicht einmal die Mindestgrösse. Es wird jetzt auf den freien Bildschirm begrenzt, die Mindestgrösse bleibt kleiner als die Startgrösse (neue Unit `uSkalierung`, gleich wie bei StemMaker).
- Die LED-Vorschau wächst und schrumpft mit dem Fenster, «Blinken» bleibt immer sichtbar.
- Ist das Fenster beim Start zu niedrig für Vorschau und Rechenweg, ist der Rechenweg zugeklappt (Ansicht → Rechenweg klappt ihn auf).
- Ko-fi-Knopf: Rand bei 150 % nicht mehr doppelt skaliert.
- Resultatkarten im schmalen Fenster: Widerstand und Farbnamen ragten in die Nachbarkarte. Der Widerstand wird kleiner, die Farbnamen brechen auf zwei Zeilen um, nichts zeichnet mehr über den Kartenrand.
- Rechenweg wieder aufklappen: Er rutschte unter die Statuszeile (auch bei 100 %). Jetzt wächst er nach oben, die Fenstergrösse bleibt gleich.
- Reicht die Höhe bei 200 % nicht, rollt die linke Spalte (Eingaben und LED-Vorschau), statt «Blinken» abzuschneiden.
- Fenster lag bei 150–200 % ein paar Pixel unter der Taskleiste: Rahmen und Titelleiste werden jetzt gemessen statt geschätzt.

---

## 2.0 – 29. Oktober 2026

### Projektseite
- `site/` mit englischer und deutscher Seite, Screenshots, Vorschaubildern für Links und Sitemap; Veröffentlichung über GitHub Pages (`.github/workflows/pages.yml`), Aufbau wie bei StemMaker.
- README und LIESMICH mit Screenshot, Link zur Seite und Kurzanleitung.

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
