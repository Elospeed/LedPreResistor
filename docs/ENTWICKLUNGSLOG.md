# Entwicklungslog – Elospeed LedPreResistor

🇬🇧 *This file is kept in German. English readers: see the [README](../README.md).*

Hier steht, welche Probleme bei der Entwicklung aufgetaucht sind und wie sie gelöst wurden. Gedacht für später: damit man nachlesen kann, *warum* etwas so gebaut ist, und dieselben Fehler nicht nochmals macht.

Neueste Einträge oben.

---

## Blinkschaltung, 2.3 (November 2026)

- **Multivibrator genauer als 0,69 · R · C.** Die Lehrbuchformel nimmt an, dass der Kollektor bis zur vollen Versorgung springt. Mit LED im Kollektorkreis springt er nur um ΔU = U − U_F − 0,2 V. Darum rechnet `uBlink` den Faktor k = ln((U − 0,6 + ΔU) / (U − 0,6)); bei kleiner LED-Spannung und hoher Versorgung geht k gegen ln 2 (Test `MultivibratorFaktorLehrbuch`).
- **Sperrspannung an der Basis.** Beim Umschalten liegt an der gesperrten Basis etwa −(ΔU − 0,6) V. Der BC547 verträgt nur rund 6 V (U_EB0); darüber Warnung mit Hinweis auf eine 1N4148 in Reihe zur Basis.
- **NE555 rückwärts ohne Diode:** R1 = (2D − 1) · S wird bei Tastgrad ≤ 50 % null oder negativ. Statt eines unsinnigen Werts kommt der Hinweis, die Diode zu nehmen.
- **Ruckeln bei schnellem Blinken:** Der Timer läuft unter Windows in Schritten von etwa 16 ms, dazu kommt das Neuzeichnen von LED und Schaltplan. Ab etwa 10 Hz wirkte das Blinken ruckelig. Darum blinkt die Vorschau nur, wenn An- und Aus-Zeit mindestens 80 ms lang sind (`BLINK_ANIM_MIN_PHASE`); sonst zeigt sie Dauerlicht mit der Helligkeit des Tastgrads (mindestens 15 %). Die Frequenz steht gross in der Vorschau. Zweite Ursache für ungleichmässiges Blinken: Der Timer schaltete bei jedem Wechsel sein Intervall um (an-Zeit, aus-Zeit). Unter Windows startet das den Timer neu, und jede verspätete Timer-Meldung (WM_TIMER hat niedrige Priorität, kommt erst, wenn das Fenster frei ist) verschob den ganzen weiteren Takt. Jetzt läuft der Timer fest mit 10 ms, und an/aus wird aus der Zeit seit dem Start berechnet (`GetTickCount64`); eine Verspätung wirkt nur noch einmal und summiert sich nicht. Die Warnung «zu schnell fürs Auge» kommt ab 50 Hz (Flimmerverschmelzung), vorher 25 Hz.
- **Platz bei 100 %:** Der zweite Reiter brauchte mehr Höhe; der Rechenweg klappte im Blinkmodus sonst automatisch zu. Fensterhöhe darum 820 (96 dpi), die Eingaben im Blinkmodus enger gesetzt.
- **Screenshots unter Wine:** `wine reg add` startet einen eigenen wineserver ohne Display; danach `wineserver -k; wineserver -w`, sonst bleibt das Fenster schwarz. Mehrere Aufnahmen nur nacheinander.

## Linux-Version, 2.2 (November 2026)

- **Nativ statt Wine.** Der Quelltext ist reines LCL; `lazbuild -B --ws=gtk2` baut ihn unter Linux ohne Änderungen am Aufbau. Ressourcen (LED-Info, `en.po`) stecken auch im Linux-Programm (FPC bettet die `.res` ins ELF ein), `FindResource`/`TResourceStream` funktionieren gleich.
- **Absturz beim Start: «Failed to create handles».** Ursache: `uLedView` baut das LED-Bild in einem `TLazIntfImage` mit fest 24 Bit (`Init_BPP24_B8G8R8_BIO_TTB`) und ruft `CreateBitmaps`. GTK2 nimmt dieses Format nicht an («Incompatible BitsPerPixel»). Lösung unter Linux: das Bild von einer 24-Bit-`TBitmap` holen (`CreateIntfImage`) und mit `LoadFromIntfImage` zurückschreiben, wie es `uKofiButton` schon macht. Windows bleibt unverändert (dort war 24 Bit nötig, damit GDI-Text sichtbar bleibt). Gefunden mit `gdb` und Haltepunkt auf `fpc_raiseexception`.
- **Weiss auf weiss in Eingabefeldern (Ubuntu/Yaru):** GTK2-Themes mit eigener Zeichen-Engine übergehen `TEdit.Color`; die helle Schrift war unsichtbar. Unter Xvfb ohne Theme fiel das nicht auf. Lösung: unter Linux bei `TEdit` weder `Color` noch helle Schrift setzen (`Font.Color := clDefault`). Nachstellen: `apt install yaru-theme-gtk`, `~/.gtkrc-2.0` mit `gtk-theme-name="Yaru"`.
- **Schriften:** Segoe UI und Consolas gibt es unter Linux meist nicht. `uTheme` nimmt dort `Sans` und `Monospace` (fontconfig wählt z. B. DejaVu).
- **Einstellungen:** Programmordner sind unter Linux oft schreibgeschützt (`/opt`, `~/.local/bin` ist zwar beschreibbar, AppImages nicht). Darum `~/.config/LedPreResistor/LedPreResistor.ini` (`$XDG_CONFIG_HOME`). `GetAppConfigDir` ist ungeeignet: es nimmt den Anwendungstitel mit Leerzeichen («Elospeed LedPreResistor»).
- **Skalierung unter Linux:** LCL/GTK2 nimmt die Bildschirm-DPI von GDK (`Xft.dpi` bzw. die DPI des X-Servers). Getestet unter Xvfb mit 96 und 144 dpi (`-dpi 144`): Fenster wird auf den Bildschirm begrenzt, alles wächst mit.
- **Startprüfung im Build:** Eine LCL-Fehlermeldung beim Start beendet das Programm nicht. Der Build sucht darum unter Xvfb ein Fenster mit dem Titel «Elospeed LedPreResistor» (= Fehlermeldung) und verlangt das Hauptfenster «LedPreResistor · Elospeed …».
- **glibc:** Das Programm braucht glibc 2.34 oder neuer (Ubuntu 22.04, Debian 12, Fedora 35 und neuer).

---

## Englische Oberfläche, 2.1 (November 2026)

- **Kein LCLTranslator, sondern `uLang` wie bei StemMaker.** `_()` schlägt den deutschen Text in der Übersetzung nach. Die `resourcestring`s in `uMain.pas` bleiben deutsch und werden beim Anzeigen mit `_()` übersetzt. Vorteil: Umschalten zur Laufzeit ohne Neustart, keine Abhängigkeit von LCLTranslator.
- **Eine EXE bleibt eine EXE.** `en.po` steckt als RCDATA-Ressource `LANG_EN` in der EXE, die englische LED-Info als `LEDINFO_EN`. Der Build prüft beide mit `grep`.
- **Beschriftungen aus der LFM** (Menüs, Labels) stehen deutsch im Formular und werden in `ApplyLanguage` zur Laufzeit gesetzt. Neue Beschriftungen immer dort mit eintragen.
- **Stolperfalle beim Umbau:** Beim automatischen Einpacken in `_()` blieben zuerst alle Stellen wie `Format(rsX, …)` aussen vor (ein `(` direkt davor). Folge: Teile blieben deutsch, und weil `FormCreate` nicht umgebaut war, stürzte das Programm beim Start ab (`MenuLang` noch nicht erzeugt). Gefunden mit einem Protokoll in eine Datei unter Wine.
- **Ko-fi-Knopf beim Sprachwechsel:** Beim Start setzt `ApplyTheme` die Breite (vor der DPI-Umrechnung, siehe 2.0.1). Beim Umschalten zur Laufzeit wird nur der Unterschied der Textbreite addiert, gemessen auf demselben Canvas. So wird nichts doppelt skaliert (geprüft bei 100 % und 150 %).
- **Zahlenformat:** Englisch mit Punkt und «66%», Deutsch mit Komma und «66 %». Beim Umschalten werden die Zahlen in den Eingabefeldern umgestellt (3,2 ↔ 3.2); die Eingabe nimmt weiterhin beides an.

---

## Anzeigeskalierung (DPI), 2.0.1 (Oktober 2026)

Regel für alle Elospeed-Programme: jedes Fenster muss bei 100, 125, 150 und 200 % Windows-Skalierung stimmen. Keine festen Pixel in eigenem Code, die nach dem Aufbau gesetzt werden (immer `Scale96ToForm`), kein Fenster höher als der freie Bildschirm, Mindestgrösse kleiner als die Startgrösse. Vor jedem PR mit Änderungen an der Oberfläche: Test unter Wine mit 100 und 150 % und Bildschirmfotos.

| Problem | Lösung |
|---|---|
| Das Hauptfenster ist 780 Pixel hoch (Mindesthöhe 700). Lazarus rechnet es bei 150 % auf 1170, bei 200 % auf 1560 Pixel um: auf Full HD unten abgeschnitten, Statuszeile unsichtbar. | Unit `uSkalierung` (aus StemMaker) in der `.lpr`: sie begrenzt jedes Fenster beim Sichtbarwerden auf den freien Bildschirm und hält die Mindestgrösse unter der Startgrösse. |
| Die LED-Vorschau hatte eine feste Höhe; im begrenzten Fenster fielen «Blinken» und die halbe LED unten weg. | `PanelPreview` unten verankert, `PaintLed` füllt den Rest, die Blink-Zeile hängt unten. |
| Bei 150/200 % reicht die Höhe trotzdem nicht für Vorschau und offenen Rechenweg. | Nach dem ersten Anzeigen (per `QueueAsyncCall`, erst dann ist das Fenster begrenzt): ist die LED-Vorschau niedriger als 120 Pixel (96 dpi), wird der Rechenweg zugeklappt. |
| Rechenweg zu- und wieder aufklappen: das Feld rutschte unter die Statuszeile, auch bei 100 %. `alBottom` ordnet nach `Top`, nur `Height` setzen lässt die Oberkante stehen und die Unterkante wandert unter die Statuszeile. | `SetBounds` mit gleicher Unterkante (Top um den Zuwachs verkleinern). Beim Aufklappen wird das Fenster um den Zuwachs höher, `BegrenzeAufBildschirm` begrenzt. `PanelPreview` hat eine Mindesthöhe von 120 px, damit die Blink-Zeile nie über die Überschrift rutscht. |
| Resultatkarten bei Mindestbreite (820 px): Karte 1 ist nur ~140 px breit, der Widerstand (150 px) und «gelb · violett · braun · gold» ragten in die Nachbarkarte (beim Test unter Windows gefunden). | Widerstand auf die Kartenbreite begrenzt, Farbnamen nach dem zweiten Ring umbrechen, jede Karte mit `ClipRect`/`Clipping` gezeichnet. |
| Test unter Windows (125–200 %): Rechenweg zu- und aufklappen liess das Fenster jedes Mal wachsen, bis unter die Taskleiste. Bei 200 % mit offenem Rechenweg verschwand «Blinken». Fenster 2–4 px unter der Taskleiste. | Fensterhöhe beim Zu-/Aufklappen nicht mehr ändern: Mitwachsen lief mit Mindesthöhe und Bildschirmgrenze aus dem Ruder (jeder Durchgang eine andere Höhe). Der Rechenweg nimmt Platz von Schaltplan und Vorschau. Linke Spalte ist eine `TScrollBox`, `PanelPreview` füllt sie per `OnResize` bis unten (nicht verankert, sonst rollt die ScrollBox nicht) mit Mindesthöhe 120. `uSkalierung` misst Rahmen und Titelleiste mit `GetWindowRect`. |
| Ko-fi-Knopf: Breite in `FormCreate` mit `Screen.PixelsPerInch` gerechnet. Das Fenster steht dort noch auf 96 dpi und wird danach umgerechnet, der Rand war so doppelt skaliert. | Mit `PixelsPerInch` des Fensters (im Aufbau 96) messen. `Screen.PixelsPerInch` nur beim Zeichnen benutzen. |

---

## LED-Info (Oktober 2026)

| Problem | Lösung |
|---|---|
| Die LCL hat keine HTML-Anzeige; eine Zusatzkomponente (z. B. IPro) wollen wir nicht. | Die Seite steckt als Ressource `LEDINFO` (RCDATA, Projektoptionen → Ressourcen) in der EXE. `uLedInfo` schreibt sie beim Öffnen in den Temp-Ordner und öffnet sie mit `OpenDocument` im Standard-Browser. |
| Der Entwurf lud Webschriften von Google; offline sähe die Seite anders aus, und jeder Aufruf ginge ins Netz. | Nur Systemschriften (Bahnschrift, Segoe UI, Consolas) mit Ersatz. |
| `lazbuild` meldet «File "info/led-info.html" not found», wenn es nicht aus dem Projektordner gestartet wird; die Ressource kommt trotzdem in die EXE. | Im Build geprüft; die EXE enthält die Seite vollständig. |

---

## Hauptfenster (Oktober 2026)

| Problem | Lösung |
|---|---|
| Die LED braucht Transparenz und weiche Verläufe (Leuchtschein), die LCL-Canvas kann unter Windows weder Alpha noch Kantenglättung. Geplant waren PNGs pro Farbe in einer TImageList. | `uLedView` rechnet das Bild Pixel für Pixel in ein `TLazIntfImage` (3×3-Unterabtastung, eigene Mischrechnung) nach der SVG-Vorlage des Entwurfs. Vorteil: jede Farbe und jede Grösse ohne Bilddateien, keine Zusatzbibliothek. Ein- und Aus-Bild werden zwischengespeichert, das Blinken schaltet nur um. |
| Windows zeichnet die Beschriftung von TCheckBox mit Design immer schwarz, auch im dunklen Fenster. | Häkchen ohne Text, daneben ein TLabel, das beim Klick umschaltet. |
| Auswahllisten (TComboBox) sind unter Windows hell. | `csOwnerDrawFixed` und eigenes Zeichnen (`ComboDrawItem`), bei der LED-Farbe mit Farbpunkt. |
| Das Menü (TMainMenu) bleibt unter Windows hell. | Bleibt vorerst so; ein dunkles Menü ginge nur mit eigenem Zeichnen aller Menüpunkte. |
| Tiefgestellte Zeichen (U_R, U_F) und Fettdruck im Rechenweg und Schaltplan. | Kleine Unit `uRichText`: `**fett**` und `_X` für ein tiefgestelltes Zeichen. |
| Der Entwurf hat kein Feld für mehrere LEDs in Reihe, die Spezifikation verlangt es. | Feld «LEDs in Reihe» neben der E-Reihe ergänzt. |

---

## Rechenkern (Oktober 2026)

| Problem | Lösung |
|---|---|
| Beispielrechnung in der Projektübersicht nannte 164,7 mW und 224,6 mW. Genau sind es 8,8² / 470 = 164,77 mW und 12 V × 18,723 mA = 224,68 mW, gerundet also 164,8 und 224,7 mW (vorher abgeschnitten statt gerundet). | Werte in Projektübersicht, README und LIESMICH korrigiert; die Tests prüfen auf 0,005 mW genau. |
| Testunit `tESeries` liess sich nicht übersetzen («"." expected»): Pascal unterscheidet keine Gross-/Kleinschreibung, der Unit-Name war gleich wie der Typ `TESeries`. | Testunits heissen `TestESeries`, `TestColorCode`, `TestCalc`. |
| `NextStdValue(NaN)` brach mit `EInvalidOp` ab: Free Pascal löst bei einem Vergleich mit NaN eine Exception aus. | Zuerst `IsNan`/`IsInfinite` prüfen, erst dann vergleichen. |
| Geschätzte Erwärmung: Richtwert 200–250 °C/W gilt nur für ¼-W-Bauformen. | Näherung: 225 °C/W für ¼ W, für andere Bauformen umgekehrt proportional zur Nennleistung (½ W = 112,5 °C/W). Bei voller Last wird so jede Bauform gleich warm (ca. 56 °C). In der Anzeige als Schätzung kennzeichnen. |
| Toleranzring: E12 wäre früher 10 % (silber). Heute sind Kohle- und Metallschichtwiderstände praktisch immer 5 % oder besser. | E12 und E24 mit Goldring (5 %), wie im Beispiel der Projektübersicht; E96 mit Braun (1 %). |
| Fehlermeldungen als Text in der Rechenlogik würden die Übersetzung erschweren. | `uCalc` liefert Status als Aufzählung (`csUTooLow` usw.), den Text erzeugt die Anzeige. |
| Das Testprogramm muss bei einem Fehler den Build rot machen. | Eigener kleiner Konsolen-Runner (`tests/LedPreResistorTests.lpr`) setzt Exitcode 1 bei Fehlern oder Abbrüchen; geprüft mit einem absichtlich fehlschlagenden Test. |

---

## Grundstruktur und Altversion (Oktober 2026)

| Problem | Lösung |
|---|---|
| Die Altversion (Delphi 7) braucht fast nur JVCL/JCL-Komponenten. Eine automatische Konvertierung nach Lazarus lohnt sich nicht. | Oberfläche wird neu gebaut, nur die Rechenlogik wird übernommen und korrigiert. Ersatz-Tabelle in [PROJEKTUEBERSICHT.md](PROJEKTUEBERSICHT.md). |
| Die Delphi-Quelltexte sind in Windows-1252 kodiert; Umlaute erscheinen auf GitHub und in Lazarus als Fragezeichen. | Beim Übernehmen nach `docs/legacy/` mit `iconv -f cp1252 -t utf-8` umgewandelt, Zeilenenden auf LF. Inhalt sonst unverändert. |
| E12-Suche der Altversion (`R_E12`): `3.3 * 100` ergibt in Gleitkomma 329,99999…, ein berechneter Wert von genau 330 Ω springt deshalb auf 390 Ω. | In `uESeries` mit relativer Toleranz 1e-9 vergleichen. Kommt als Testfall ins FPCUnit-Projekt. |
| `FloatToStr` zeigt Werte wie 6.6000000000000005. | Ausgabe immer formatiert mit festen Nachkommastellen. |
| `StrToFloat` hängt von der Ländereinstellung ab; mit deutschem Komma brach die Altversion ab. | Eigene Umwandlung mit festen `TFormatSettings`, Komma und Punkt werden beide akzeptiert. |
| Die Info-PDF war als Ressource in der EXE eingebettet und brauchte Acrobat Reader (Registry-Abfrage). | LED-Info wird neu geschrieben; Anzeige im Programm oder mit dem Standardprogramm (`OpenDocument`). |
| Fremde Code-Schnipsel und Newsgroup-Beiträge (mit Namen und E-Mail-Adressen Dritter, Lizenz unklar) lagen im alten Projektordner. | Nicht ins Repository übernommen. Nur der eigene Quelltext der Altversion liegt in `docs/legacy/`. |
