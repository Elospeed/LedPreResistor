# Testversionen

🇬🇧 *This file is kept in German. English readers: see the [README](../README.md).*

Testversionen sind fertig gebaute Programme zum **Ausprobieren**, bevor sie in ein offizielles Release kommen.
Sie werden automatisch von **GitHub Actions** gebaut, aber **nicht öffentlich auf GitHub veröffentlicht** (keine Vor-Releases).
Der Workflow steht in [`.github/workflows/build.yml`](../.github/workflows/build.yml).

## Wie es abläuft

1. Jeder Pull Request und jeder Push auf `main` baut `LedPreResistor.exe` auf Windows. Schlägt der Build fehl, ist der PR rot.
2. Die fertige EXE hängt als **Artefakt** am Build-Lauf unter *Actions* (nur mit GitHub-Login, 14 Tage), samt `SHA256SUMS.txt`.
3. Wer testet, bekommt die EXE als **ZIP mit Anleitung** im privaten Projektordner. Vorher wird die Prüfsumme kontrolliert und das Programm kurz unter Wine gestartet.

Alte Vor-Releases mit Tag `test-...` löscht der Job `aufraeumen` im Workflow automatisch.

## So testen

1. Prüfsumme kontrollieren: `certutil -hashfile LedPreResistor.exe SHA256` (Windows) und mit `SHA256SUMS.txt` vergleichen.
2. Starten. Es gibt nichts zu installieren und nichts aufzuräumen.
3. Referenzrechnung eintippen: 12 V, weisse LED (3,2 V), 20 mA, E12 → 470 Ω, 18,72 mA, 164,7 mW, Empfehlung ½ W.

Die EXE ist nicht signiert. Windows SmartScreen warnt deshalb: «Weitere Informationen» → «Trotzdem ausführen».

## Gut zu wissen

- Offizielle Releases legt Speedy von Hand an.
- Testversionen gehören nicht ins Repository: jede eingecheckte EXE bliebe für immer im Git-Verlauf.
