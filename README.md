# Elospeed LedPreResistor 2.0.1

**by Elospeed**

🇩🇪 **Deutsche Anleitung:** [LIESMICH.md](LIESMICH.md)

**Website:** [elospeed.github.io/LedPreResistor](https://elospeed.github.io/LedPreResistor/) · **Download:** [latest release](https://github.com/Elospeed/LedPreResistor/releases/latest)

![LedPreResistor main window: 12 V, white LED, 20 mA → 470 Ω, ½ W](site/img/ledpreresistor-main.png)

LedPreResistor calculates the series resistor for one or more LEDs. It is the new edition of the freeware tool *LED Pre-Resistor* (Delphi 7, 2004), rebuilt from scratch in Lazarus: a single 64-bit Windows exe, no installer, no extra packages.

**What it does**

- **Live calculation** while you type: supply voltage, forward voltage, LED current and number of LEDs in series.
- **Nearest standard value** from the E12, E24 or E96 series (always the next higher value, so the LED never gets more current than planned).
- **Real current and power** in the resistor, in the LEDs and in total, plus a recommended resistor rating (⅛ / ¼ / ½ / 1 W) with a warning above 50 % load and an estimated temperature rise.
- **Colour bands** of the resistor (4 bands, 5 bands for E96) and a **schematic** with all values at the components.
- **"How it is calculated"** panel that walks through the calculation step by step with your own numbers.
- Presets for red, yellow, green, blue, white and infrared LEDs, or your own forward voltage from the datasheet.
- **LED preview**: a 5 mm LED in the chosen colour with anode, cathode and flat side labelled, optionally blinking.
- **LED info** "Die Leuchtdiode" built in (F1, opens in your browser, also offline).
- Copy the result with Ctrl+Shift+C. Comma and dot both work as decimal separator.
- The program is in German for now; an English translation is planned.

**Example:** 12 V supply, one white LED (3.2 V), 20 mA → 440 Ω calculated, **470 Ω** (E12, yellow-violet-brown-gold), 18.72 mA real current, 164.8 mW in the resistor → use a ½ W resistor.

LedPreResistor is a one-person hobby project. If it helps you, you can [buy me a coffee on Ko-fi](https://ko-fi.com/elospeed) ☕. Entirely optional, the tool stays free either way. The program never asks; there is just a small "Kaffee spendieren" button in the status bar.

## Getting started

1. Download the ZIP from the [latest release](https://github.com/Elospeed/LedPreResistor/releases/latest) and unzip it anywhere.
2. Start `LedPreResistor.exe`. Nothing to install. Windows SmartScreen may warn because the exe is not signed: "More info" → "Run anyway".
3. Optional: compare the SHA-256 checksum with the one in the release notes (`certutil -hashfile LedPreResistor.exe SHA256`).

## Building

Lazarus 3.8 (FPC 3.2.2), LCL only:

```
lazbuild -B --os=win64 --cpu=x86_64 --ws=win32 src/LedPreResistor.lpi
```

Every pull request and every push to `main` is built automatically by GitHub Actions (`.github/workflows/build.yml`).

## Repository layout

| Path | Content |
|---|---|
| `src/` | Lazarus project and units |
| `src/lang/` | Translations (German / English) |
| `tests/` | Unit tests of the calculation (FPCUnit, run by every build) |
| `docs/` | Project overview, development log, ideas, test builds (German) |
| `docs/legacy/` | Original Delphi 7 source code from 2004, for reference only |
| `docs/design/` | Approved design draft (open the HTML file in a browser) |
| `site/` | Project website (GitHub Pages, English and German) |

## License

MIT, see [LICENSE](LICENSE).
