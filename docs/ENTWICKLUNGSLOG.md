# Entwicklungslog – Elospeed LedPreResistor

🇬🇧 *This file is kept in German. English readers: see the [README](../README.md).*

Hier steht, welche Probleme bei der Entwicklung aufgetaucht sind und wie sie gelöst wurden. Gedacht für später: damit man nachlesen kann, *warum* etwas so gebaut ist, und dieselben Fehler nicht nochmals macht.

Neueste Einträge oben.

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
