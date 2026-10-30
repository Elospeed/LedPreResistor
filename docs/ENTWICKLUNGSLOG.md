# Entwicklungslog – Elospeed LedPreResistor

🇬🇧 *This file is kept in German. English readers: see the [README](../README.md).*

Hier steht, welche Probleme bei der Entwicklung aufgetaucht sind und wie sie gelöst wurden. Gedacht für später: damit man nachlesen kann, *warum* etwas so gebaut ist, und dieselben Fehler nicht nochmals macht.

Neueste Einträge oben.

---

## Anzeigeskalierung (DPI), 2.0.1 (Oktober 2026)

Regel für alle Elospeed-Programme: jedes Fenster muss bei 100, 125, 150 und 200 % Windows-Skalierung stimmen. Keine festen Pixel in eigenem Code, die nach dem Aufbau gesetzt werden (immer `Scale96ToForm`), kein Fenster höher als der freie Bildschirm, Mindestgrösse kleiner als die Startgrösse. Vor jedem PR mit Änderungen an der Oberfläche: Test unter Wine mit 100 und 150 % und Bildschirmfotos.

| Problem | Lösung |
|---|---|
| Das Hauptfenster ist 780 Pixel hoch (Mindesthöhe 700). Lazarus rechnet es bei 150 % auf 1170, bei 200 % auf 1560 Pixel um: auf Full HD unten abgeschnitten, Statuszeile unsichtbar. | Unit `uSkalierung` (aus StemMaker) in der `.lpr`: sie begrenzt jedes Fenster beim Sichtbarwerden auf den freien Bildschirm und hält die Mindestgrösse unter der Startgrösse. |
| Die LED-Vorschau hatte eine feste Höhe; im begrenzten Fenster fielen «Blinken» und die halbe LED unten weg. | `PanelPreview` unten verankert, `PaintLed` füllt den Rest, die Blink-Zeile hängt unten. |
| Bei 150/200 % reicht die Höhe trotzdem nicht für Vorschau und offenen Rechenweg. | Nach dem ersten Anzeigen (per `QueueAsyncCall`, erst dann ist das Fenster begrenzt): ist die LED-Vorschau niedriger als 200 Pixel (96 dpi), wird der Rechenweg zugeklappt. |
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
