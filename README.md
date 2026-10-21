# Elospeed LedPreResistor 2.0

**by Elospeed**

🇩🇪 **Deutsche Anleitung:** [LIESMICH.md](LIESMICH.md)

> **Status:** in development. There is no release yet. Test builds are listed in [docs/TESTVERSIONEN.md](docs/TESTVERSIONEN.md) (German).

LedPreResistor calculates the series resistor for one or more LEDs. It is the new edition of the freeware tool *LED Pre-Resistor* (Delphi 7, 2004), rebuilt from scratch in Lazarus: a single 64-bit Windows exe, no installer, no extra packages.

**What it will do**

- **Live calculation** while you type: supply voltage, forward voltage, LED current and number of LEDs in series.
- **Nearest standard value** from the E12, E24 or E96 series (always the next higher value, so the LED never gets more current than planned).
- **Real current and power** in the resistor, in the LEDs and in total, plus a recommended resistor rating (⅛ / ¼ / ½ / 1 W) with a warning above 50 % load and an estimated temperature rise.
- **Colour bands** of the resistor (4 bands, 5 bands for E96) and a **schematic** with all values at the components.
- **"How it is calculated"** panel that walks through the calculation step by step with your own numbers.
- Presets for red, yellow, green, blue, white and infrared LEDs, or your own forward voltage from the datasheet.
- Comma and dot both work as decimal separator. German and English.

**Example:** 12 V supply, one white LED (3.2 V), 20 mA → 440 Ω calculated, **470 Ω** (E12, yellow-violet-brown-gold), 18.72 mA real current, 164.8 mW in the resistor → use a ½ W resistor.

LedPreResistor is a one-person hobby project. If it helps you, you can [buy me a coffee on Ko-fi](https://ko-fi.com/elospeed) ☕. Entirely optional, the tool stays free either way. The program never asks; there is just a small Ko-fi link in the status bar.

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

## License

MIT, see [LICENSE](LICENSE).
