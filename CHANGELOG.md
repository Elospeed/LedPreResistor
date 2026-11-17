# Changelog – Elospeed LedPreResistor

🇬🇧 *This file is kept in German. English readers: see the [README](README.md).*

Was erledigt ist, pro Version, neueste oben.
Die technischen Hintergründe stehen im [Entwicklungslog](docs/ENTWICKLUNGSLOG.md).

---

## 2.5.2 – unveröffentlicht

### Schaltplan
- Stränge parallel: Der zweite Strang ist genau wie der erste gezeichnet: eigener Widerstand mit Farbringen und gleich viele LEDs (ab 4 LEDs mit Punkten dazwischen). Über den Säulen steht «Strang 1» und «Strang 2» bzw. «… Strang k». Vorher war er nur grau mit einer LED angedeutet, und «× k» daneben liess sich als zusätzliche Stränge lesen.
- Stränge parallel: Der Strompfeil unten liegt auf der gemeinsamen Rückleitung und zeigt den Gesamtstrom aller Stränge («I = 35,12 mA gesamt (2 × 17,56 mA)»); der Strom je Strang steht unter «k Stränge parallel».
- Konstantstrom: bis 3 LEDs einzeln, ab 4 LEDs mit Punkten dazwischen (wie beim Vorwiderstand). Vorher waren es ab 2 LEDs immer zwei Symbole.
- Multivibrator: Kreuzungen ohne Verbindung mit kleiner Brücke. Wird die Basis zu stark gesperrt, sind die empfohlenen Dioden 1N4148 vor den Basen grau eingezeichnet.
- Blinkschaltungen: Bei Elkos steht die nötige Spannungsfestigkeit dabei («22 µF/16 V»).

### Grenzen der Bauteile
- Zu grosse Werte ergeben kein Resultat mehr, sondern eine Meldung mit der Grenze: NE555 höchstens 16 V und 200 mA, Multivibrator (BC547) höchstens 45 V und 100 mA, LM317 höchstens 40 V (sonst LM317HV), zwei Transistoren höchstens 45 V. Bei LM317 und T1 zählt die ganze Speisespannung, weil sie beim Einschalten oder bei kurzgeschlossenen LEDs anliegt.
- NE555 unter 4,5 V: Hinweis auf die CMOS-Version (TLC555, ICM7555).

### Anzeige
- Empfohlene Bauform: Auslastung, Farbe, Statuszeile und Erwärmung beziehen sich immer auf die empfohlene Bauform («½ W zu 33 % belastet», grün). Vorher stand bei der Empfehlung ½ W eine gelbe «Auslastung 66 %» für ¼ W in der Statuszeile. Wie stark ¼ W belastet wäre, steht im Nebensatz der Statuszeile und als Begründung im Rechenweg.
- Multivibrator: Sperrspannung der Basis über 6 V (Datenblatt BC547) ergibt nur einen ruhigen Tipp in Grün mit den grau gezeichneten 1N4148 als Schutz, denn die Schaltung läuft in der Praxis auch ohne. Gelb gewarnt wird erst über 12 V. Gerechnet wird ohne Dioden.
- LM317-Grenze: «höchstens 40 V zwischen IN und OUT» statt «am Eingang».
- Rechenweg: «genau ein E12-Wert: 120 Ω», wenn der ideale Wert schon ein Normwert ist; Herkunft der 1,3 V beim Basiswiderstand und «Ausgang Low ≈ 0,1 V» beim Wechselblinker genannt.
- Multivibrator: Elko-Beschriftung zweizeilig («C2 = 22 µF», darunter «16 V»), damit sie T2 nicht berührt; «10 nF» beim NE555 mit Abstand.
- Karten: kein Umbruch direkt vor oder nach «→» und «=».
- Karten: Untertexte kürzer, damit sie auf echtem Windows bei 100 % in zwei Zeilen passen und nichts abgeschnitten ist (z. B. «Soll 20,0 mA; gleich von 14,4 V bis 40 V», «18,64 / 17,27 mA · bis 98,5 mW → ¼ W»). «ausgelastet» statt «belastet», wie in Statuszeile und Rechenweg.
- Konstantstrom bei 150-200 %: Erscheint links eine Bildlaufleiste, wird die Spalte breiter, damit die Auswahllisten nicht angeschnitten sind.
- Kopieren: Kopfzeile «Blinkschaltung: Multivibrator (2 Transistoren)» statt doppelter Klammern.
- NE555 über 16 V: Im Schaltplan steht «U_OUT = –» statt einer Ausgangsspannung.
- Kartentexte brechen nicht mehr zwischen Bruch und Einheit um («⅛ W»).
- Konstantstrom: «2 Transistoren (T1 je nach Strom)» statt «(T1 nach Strom)».
- Karte «Tatsächlicher Strom» und «LED-Strom»: «100 Ω statt ideal 90 Ω (Soll 20,0 mA)» statt «berechnet 90 Ω → 20,0 mA», das wie der tatsächliche Strom aussah.
- Spannung zu klein: Die Meldung nennt die Abhilfe («Abhilfe: höchstens 3 LEDs in Reihe oder mehr Spannung»).
- Wechselblinker: Karte «Vorwiderstand» mit «LED 1 18,21 mA / LED 2 18,51 mA».
- Multivibrator: Karte «Basisstrom» gelb, solange die Basis-Warnung gilt.
- Multivibrator: Bei zu kleinem Basisstrom heisst es «zu wenig: nur 0,7-fach des Nötigen» statt «0,7-fach übersteuert».
- Konstantstrom: «Messwiderstand» statt «Fühlerwiderstand».
- Eingaben: Lange Beschriftungen wie «Durchlassspannung» werden bei 100 % nicht mehr abgeschnitten.

### Kopieren
- Stränge parallel: Strom «je Strang» und die Leistung getrennt nach je Widerstand, alle Widerstände, alle LEDs und gesamt. Vorher stand die Leistung eines Widerstands neben der Summe aller LEDs.
- Farbname klein wie im Schaltplan («LED weiss»), «Sollstrom» statt «Strom» für den eingegebenen Wert.

### Blinkschaltung
- Wechselblinker (NE555, beide LEDs) und Multivibrator: Karten, Vorschau, Rechenweg und Kopiertext nennen die Zeiten und den Tastgrad je LED («LED 1 / LED 2 an», «Tastgrad (LED 1 an)»).

### Tests
- Neue Verbindungstests für alle Schaltpläne (LED-Vorwiderstand, NE555, Multivibrator mit und ohne Dioden, LM317, zwei Transistoren, jeweils mit 1 bis 30 LEDs): Jeder Plan meldet beim Zeichnen seine Leitungen und Bauteile, der Test prüft, welche Anschlüsse verbunden sind. Ein Fehler wie in 2.5 (zweiter Strang hinter dem ersten Widerstand) fällt so im automatischen Build auf.
- Grenzwerte der Bauteile genau an und knapp über der Grenze, Bezug auf die empfohlene Bauform, Basisstrom mit Diode.

## 2.5.1 – 17. November 2026

### Schaltplan
- Stränge parallel: Der angedeutete zweite Strang zweigt jetzt vor dem ersten Vorwiderstand ab (direkt an der Quelle), wie es elektrisch richtig ist. Vorher hing er zeichnerisch hinter dem ersten Widerstand.

### Rechenweg
- Neuer Schritt 6 «Aufteilung der Leistung»: wie viel der Leistung aus der Quelle in den LEDs ankommt und wie viel die Widerstände verheizen, je mit Anteil in Prozent (bei Strängen parallel für alle Stränge zusammen).

## Unveröffentlicht

### Projektseite
- Kurzer Satz zur Herkunft des Projekts angepasst; Klicks auf externe Links im Seitenfuss und in den Fragen werden anonym mitgezählt (GoatCounter, ohne Cookies).
- Seite auf 2.5: neue Bilder (Hauptfenster mit drei LEDs und zwei Strängen, Warnung mit «+X K über Umgebung»), Downloads und Texte.
- Anonyme Besucherzählung mit GoatCounter (ohne Cookies, ohne persönliche Daten), mit Hinweis im Seitenfuss.

## 2.5 – 17. November 2026

### Schaltplan
- Mehrere LEDs in Reihe sind jetzt gezeichnet: 1 bis 3 LEDs einzeln, ab 4 LEDs zwei Symbole mit drei Punkten dazwischen. Die Beschriftung «n × LED …» bleibt.
- Stränge parallel: Rechts deutet ein grau gestrichelter Zweig mit eigenem Widerstand und «× k» den zweiten Strang an. Die LED-Beschriftung steht dann links neben der Säule.

### Erwärmung
- Die Erwärmung heisst jetzt überall «ca. +X K über Umgebung» (Statuszeile, Rechenweg, Kopieren, LED-Info), damit niemand sie als absolute Temperatur liest. Die LED-Info erklärt den Unterschied mit einem Beispiel.

### Rechenweg
- Bei Strängen parallel heisst Schritt 4 «Verlustleistung je Widerstand».

### Eingaben
- Grenzen für Hobbyschaltungen: Speisespannung höchstens 60 V (Schutzkleinspannung), höchstens 30 LEDs in Reihe und 20 Stränge parallel (vorher 1000 LEDs und 100 Stränge, Spannung ohne Grenze). Darüber nennt die Meldung den erlaubten Bereich statt fälschlich «mindestens 1». Die Pfeiltasten bleiben im gültigen Bereich.

## 2.4 – 14. November 2026

### Konstantstrom
- Neuer Reiter «Konstantstrom» (Strg+3) mit zwei Schaltungen: LM317 als Stromquelle und Konstantstromquelle mit zwei Transistoren. Die gewählte Schaltung bleibt beim nächsten Start erhalten.
- Speisespannung als Bereich «von … bis» (z. B. 12 … 14,4 V im Auto): Das Programm zeigt, wie wenig sich der Strom über den Bereich ändert, und zum Vergleich, um wie viel er mit einem einfachen Vorwiderstand steigen würde.
- LM317: Fühlerwiderstand R = 1,25 V / I aus der E-Reihe (nächsthöherer Wert), Leistung und Belastbarkeit von R, Mindestspannung (LEDs + 1,25 V + ca. 2 V Regler), Verlust im Regler. Bis 100 mA wird der LM317L (TO-92) vorgeschlagen, darüber der LM317 (TO-220), mit Hinweis auf einen Kühlkörper samt nötigem Wärmewiderstand. Warnungen unter 10 mA (Mindestlast) und über 40 V am Regler.
- Zwei Transistoren: Fühlerwiderstand R_S = 0,6 V / I und Basiswiderstand R_B; T1 wird nach Strom und Verlustleistung vorgeschlagen (BC547, BC337 oder BD139), T2 bleibt ein BC547. Schaltplan mit sauberen Transistorsymbolen.
- Karten, Rechenweg, Statuszeile und Kopieren (Strg+Umschalt+C) wie in den anderen Reitern, Deutsch und Englisch.
- LED-Info: Kapitel «Konstantstrom» neu geschrieben (LM317, zwei Transistoren, Wärme und Kühlkörper).

### Vorwiderstand
- Neues Feld «Stränge parallel»: mehrere gleiche LED-Stränge, jeder mit eigenem Vorwiderstand. Karten, Schaltplan und Statuszeile zeigen Gesamtstrom und Gesamtleistung. LED-Info: Abschnitt zu parallelen Strängen.

### Rechenweg
- In Zeilen mit eingesetzten Zahlen steht jetzt × statt · (z. B. 0,693 × 69 kΩ × 10 µF); Formeln mit Symbolen behalten den Punkt.
- Ist der Schaltplan zu klein, klappt der Rechenweg automatisch zu.
- Unter den Schritten erklärt «Zeichen:» die Formelzeichen des aktuellen Reiters (z. B. U_F Durchlassspannung einer LED, R_S Fühlerwiderstand), in gleicher Schrift wie der Rechenweg, bei Bedarf zweizeilig.
- Knopf «Kopieren» in der Kopfzeile des Rechenwegs: kopiert das Resultat, den kompletten Rechenweg und die Zeichen-Erklärung als einfachen Text. Strg+Umschalt+C macht dasselbe.

### Fenster ohne Menüleiste
- Die Menüleiste ist weg (sie blieb unter Windows ausserdem hell). Oben rechts in der Reiterzeile stehen jetzt kleine Symbole mit Tooltip: ↺ Eingaben zurücksetzen, DE/EN für die Sprache, ein LED-Symbol für die LED-Info (F1) und ⓘ für «Über LedPreResistor». Ko-fi bleibt der Knopf unten rechts.
- Programmsymbol neu gezeichnet: dieselbe gelbe LED wie bisher, jetzt scharf in allen Grössen von 16 bis 256 Pixel (vorher nur 32 Pixel, bei hoher Skalierung unscharf in Taskleiste, Explorer und Info-Fenster). Vorlage als SVG in docs/symbol/.
- Tastenkürzel bleiben: Strg+1/2/3 für die Reiter, F1 für die LED-Info, Strg+Umschalt+C zum Kopieren. Beenden mit dem X oder Alt+F4.
- Das Fenster «Über LedPreResistor» ist jetzt dunkel wie das Hauptfenster; der Text hat auch auf Deutsch ganz Platz, Knopfschrift und Programmsymbol wachsen mit der Windows-Skalierung mit (das Symbol geglättet).
- Behoben: Die Beschriftung neben «Diode über R2» bzw. «Symmetrisch 1:1» war bei 125–200 % unten abgeschnitten. In den Resultatkarten rutscht eine Einheit nicht mehr allein auf die nächste Zeile (z. B. «½» / «W»). Beim NE555-Wechselblinker steht U_OUT jetzt unter der Ausgangsleitung statt auf der Leitung von LED 2.

### Schaltpläne
- Alle Schaltpläne werden geglättet gezeichnet: schräge Linien, Transistorkreise, LED-Dreiecke und Pfeile ohne Treppenstufen. Gerade Leitungen, Widerstände und Beschriftungen bleiben gestochen scharf.

### Quelltext
- Alle Units und Tests ausführlich kommentiert: Kopf mit Zweck, Idee, Formeln und Rechenbeispiel, Autor und Versionen; Abschnitte als Kästen; vor jeder Prozedur und Funktion ein Kasten mit Parametern, Rückgabe und Ablauf; Zeilenkommentare rechts in einer eigenen Spalte.

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
