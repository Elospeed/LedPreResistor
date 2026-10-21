# Testversionen

🇬🇧 *This file is kept in German. English readers: see the [README](../README.md).*

Testversionen sind fertig gebaute Programme zum **Ausprobieren**, bevor sie in ein offizielles Release kommen.
Sie werden automatisch von **GitHub Actions** gebaut. Der Workflow steht in [`.github/workflows/build.yml`](../.github/workflows/build.yml).

## Wo sie liegen

Als **Vor-Release (Pre-release)** mit festem Tag. Jeder neue Build löscht das alte Vor-Release samt Tag und legt es neu an, der Link bleibt also gleich:

| Tag | Inhalt | Direkter Download |
|---|---|---|
| `test-main` | aktueller Stand von `main` | `https://github.com/Elospeed/LedPreResistor/releases/download/test-main/LedPreResistor.exe` |
| `test-pr-<Nummer>` | Stand eines Pull Requests (nur PRs aus diesem Repository); wird beim Schliessen oder Mergen gelöscht | `https://github.com/Elospeed/LedPreResistor/releases/download/test-pr-<Nummer>/LedPreResistor.exe` |
| `test-<Branch>` | Workflow von Hand gestartet (*Actions* → *Build* → *Run workflow*) | `…/releases/download/test-<Branch>/LedPreResistor.exe` |

Die direkten Links funktionieren ohne Login, solange das Repository öffentlich ist.
Jedes Vor-Release enthält zusätzlich `SHA256SUMS.txt`. Ausserdem hängt jede EXE 14 Tage als Artefakt am Build-Lauf (nur mit GitHub-Login).

## So testen

1. `LedPreResistor.exe` herunterladen und Prüfsumme kontrollieren:
   `certutil -hashfile LedPreResistor.exe SHA256` (Windows) bzw. `sha256sum LedPreResistor.exe`.
2. Starten. Es gibt nichts zu installieren und nichts aufzuräumen.
3. Referenzrechnung eintippen: 12 V, weisse LED (3,2 V), 20 mA, E12 → 470 Ω, 18,72 mA, 164,7 mW, Empfehlung ½ W.

Die EXE ist nicht signiert. Windows SmartScreen warnt deshalb: «Weitere Informationen» → «Trotzdem ausführen».

## Gut zu wissen

- Vor-Releases werden mit `--latest=false` angelegt und sind nie «neuestes Release». Offizielle Releases legt Speedy von Hand an.
- Testversionen gehören nicht ins Repository: jede eingecheckte EXE bliebe für immer im Git-Verlauf.
