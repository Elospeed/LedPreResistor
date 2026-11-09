# Ideen – Elospeed LedPreResistor

🇬🇧 *This file is kept in German. English readers: see the [README](../README.md).*

Ideen, die (noch) nicht eingeplant sind. Wird eine davon umgesetzt, wandert sie in die [TODO](../TODO.md).

| Idee | Notiz |
|---|---|
| **Parallelschaltung mehrerer LEDs** | Jede LED bzw. jeder Strang bekommt einen eigenen Vorwiderstand (nie mehrere LEDs parallel an einem Widerstand). Anzeige: Anzahl Stränge, Gesamtstrom, Gesamtleistung. |
| Weitere Normreihen (E6, E48, E192) | Tabellen in `uESeries` ergänzen; E48/E192 ebenfalls mit 5 Ringen. |
| Rückwärtsrechnung | Vorhandenen Widerstand eingeben und Strom durch die LED anzeigen. |
| AppImage für Linux | Eine Datei, die GTK2 selbst mitbringt (für Systeme ohne GTK2). Braucht linuxdeploy/appimagetool im Build. Erst, wenn jemand nach dem tar.gz danach fragt. |
| Linux: Flatpak / Paketquellen | Flathub, AUR. Später, falls Nachfrage. |
| Konstantstromquelle statt Widerstand | Hinweis, ab welcher Leistung ein Widerstand unsinnig wird. |

## Weitere LED-Schaltungen zum Berechnen

Typische Hobby-Schaltungen rund um LEDs, die LedPreResistor später berechnen könnte. ⭐ = naheliegendste Kandidaten (passen am besten zum heutigen Rechner).

| Bereich | Schaltung | Was gerechnet würde |
|---|---|---|
| Grundlagen | ⭐ Mehrere LEDs in Reihe und parallel (je Strang ein Widerstand) | Anzahl Stränge, Vorwiderstände, Gesamtstrom, Gesamtleistung (siehe oben «Parallelschaltung») |
| Grundlagen | LED-Matrix aus Reihen-Strängen | beste Aufteilung in Stränge für eine gegebene Speisespannung |
| Konstantstrom | ⭐ Konstantstromquelle mit LM317 | R = 1,25 V / I, Leistung am LM317, minimale Speisespannung |
| Konstantstrom | Zwei-Transistor-KSQ, Konstantstromdiode | Fühlerwiderstand R = 0,6 V / I, Verlustleistung |
| Schalten | ⭐ LED am Mikrocontroller-Pin, mit NPN-Transistor oder MOSFET | Pin-Strom, Basiswiderstand (Sättigung) bzw. Gatewiderstand |
| Schalten | Optokoppler-Eingang | Vorwiderstand der IR-LED, CTR-Hinweis |
| Netz/AC | LED an 230 V mit Kondensatornetzteil (X2) | Kapazität aus dem Strom; deutlicher Sicherheitshinweis |
| Netz/AC | LED an Wechselspannung mit Antiparallel-Diode | Vorwiderstand mit Spitzenspannung, Sperrspannung der LED |
| Blinken/Effekte | ⭐ NE555-Blinker, astabile Kippstufe mit 2 Transistoren | Konzept liegt vor (siehe TODO, Entscheid offen) |
| Blinken/Effekte | Lauflicht mit CD4017 + NE555 | Takt, Schrittzeit, Vorwiderstände |
| Blinken/Effekte | Fading/Atmen, PWM-Dimmung | mittlerer Strom und Helligkeit aus dem Tastgrad |
| Anzeigen | 7-Segment-Anzeige (Widerstand pro Segment, Multiplex) | Segmentwiderstände, Spitzenstrom beim Multiplexen |
| Anzeigen | Bargraph mit LM3914/LM3915 | Stromeinstellwiderstand, Teiler für den Messbereich |
| Anzeigen | Batteriewächter mit Z-Diode | Z-Spannung und Vorwiderstand für die Schaltschwelle |
| Farbe | RGB-LED mit drei Widerständen | je Farbe eigener Vorwiderstand |
| Farbe | WS2812-Strips | Strombedarf pro Meter, Netzteilgrösse, Einspeisepunkte |
| Hilfen | Solar-Gartenlicht / Joule Thief | Hinweise und Richtwerte |
| Hilfen | Power-LEDs: Leistung und Kühlung | Verlustleistung, nötiger Kühlkörper (K/W) |
