{==============================================================================
  uKsqSchematic - Schaltpläne der Konstantstromquellen
==============================================================================
  Zweck:     Zeichnet im Reiter «Konstantstrom» den Schaltplan der gewählten
             Schaltung mit den aktuellen Werten:
               - LM317 als Stromquelle   (Vorlage 580 × 300 Punkte)
               - zwei Transistoren       (Vorlage 600 × 300 Punkte)

  Idee:      LM317: Der Regler hält zwischen OUT und ADJ immer 1,25 V. Liegt
             dort der Widerstand R, fliesst I = 1,25 V / R, egal wie viele
             LEDs dahinter hängen.
             Zwei Transistoren: T1 lässt den LED-Strom durch. Sobald an R_S
             (Fühlerwiderstand) etwa 0,65 V abfallen, schaltet T2 ein und
             nimmt T1 den Basisstrom weg. So bleibt I = 0,65 V / R_S.

  Technik:   Die Zeichenhilfen (Leitung, Widerstand, LED, Transistor, Punkt,
             Text) und die Umrechnung Vorlage -> Pixel (TMap) kommen aus
             uBlinkSchematic, damit alle Schaltpläne gleich aussehen.
             Die LEDs leuchten hier dauernd (kein Blinken).

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  neu: Schaltpläne LM317 und zwei Transistoren
==============================================================================}
unit uKsqSchematic;

{$mode objfpc}{$H+}

interface

uses
  Types, Graphics, uColorCode, uBlinkSchematic;

{==============================================================================
  TYPEN
==============================================================================}
type
  // Alles, was die Konstantstrom-Schaltpläne anzeigen, als fertiger Text.
  // Tiefgestellte Zeichen mit «_» (siehe uRichText), z. B. «R_S».
  TKsqSchemValues = record
    UBText: string;                                      // Speisespannung, "U_B = 12 … 14,4 V"
    ChipText: string;                                    // LM317: "LM317" bzw. "LM317L"
    RefText: string;                                     // LM317: "U_R_E_F = 1,25 V"
    RText: string;                                       // "R = 68 Ω" bzw. "R_S = 33 Ω"
    RSubText: string;                                    // "I = 18,4 mA"
    RBText: string;                                      // zwei Transistoren: "R_B = 4,7 kΩ"
    T1Text: string;                                      // zwei Transistoren: "T1 BC547"
    T2Text: string;                                      // zwei Transistoren: "T2 BC547"
    LedText: string;                                     // "2 × LED weiss"
    UFText: string;                                      // "U_F = 2 × 3,2 V"
    LedColor: TColor;                                    // Leuchtfarbe der LEDs
    TwoLeds: Boolean;                                    // zwei LED-Symbole zeichnen (mehrere LEDs in Reihe)
    Bands: TBandArray;                                   // Farbringe von R bzw. R_S (Fühlerwiderstand)
    BandsB: TBandArray;                                  // Farbringe von R_B
  end;

{==============================================================================
  ÖFFENTLICHE FUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  DrawSchematicLM317
------------------------------------------------------------------------------
  Zeichnet den LM317 als Konstantstromquelle: +U_B an IN, OUT über R zum
  Knoten mit ADJ, von dort die LEDs nach Masse.
  Parameter: Canvas - Leinwand
             Rect   - verfügbarer Platz; die Vorlage wird eingepasst
             V      - Texte, LED-Farbe und Farbringe
             Col    - Farben (Leitung, Text, Hervorhebung ...)
------------------------------------------------------------------------------}
procedure DrawSchematicLM317(Canvas: TCanvas; const Rect: TRect;
  const V: TKsqSchemValues; const Col: TBlinkSchemColors);

{------------------------------------------------------------------------------
  DrawSchematicKsqT
------------------------------------------------------------------------------
  Zeichnet die Konstantstromquelle mit zwei NPN-Transistoren: LEDs von +U_B
  zum Kollektor von T1, Emitter von T1 über R_S nach Masse, T2 misst die
  Spannung an R_S und regelt über die Basis von T1. R_B liefert den
  Basisstrom für T1.
  Parameter: wie DrawSchematicLM317
------------------------------------------------------------------------------}
procedure DrawSchematicKsqT(Canvas: TCanvas; const Rect: TRect;
  const V: TKsqSchemValues; const Col: TBlinkSchemColors);

implementation

uses
  Math, uTheme, uSmooth;

{------------------------------------------------------------------------------
  Leds
------------------------------------------------------------------------------
  Zeichnet eine oder zwei LEDs senkrecht nach unten, Anode oben.
  Parameter: C, M - Leinwand und Umrechnung Vorlage -> Pixel
             X    - waagrechte Lage der Leitung (Vorlage)
             Top  - Oberkante der ersten LED (Vorlage)
             V    - LED-Farbe und TwoLeds (zwei Symbole = mehrere in Reihe)
             Col  - Farben
  Rückgabe:  Unterkante der letzten LED (Vorlage); dort geht die Leitung
             weiter.
------------------------------------------------------------------------------}
function Leds(C: TCanvas; const M: TMap; X, Top: Double; const V: TKsqSchemValues;
  const Col: TBlinkSchemColors): Double;
var
  BV: TBlinkSchemValues;                                 // für LedDown: nur die Leuchtfarbe
begin
  BV := Default(TBlinkSchemValues);
  BV.LedColor := V.LedColor;
  LedDown(C, M, X, Top, True, BV, Col);
  Result := Top + 24;                                    // eine LED ist 24 Punkte hoch
  if V.TwoLeds then
  begin
    Wire(C, M, [X, Result, X, Result + 8]);              // 8 Punkte Leitung dazwischen
    LedDown(C, M, X, Result + 8, True, BV, Col);
    Result := Result + 32;
  end;
end;

{------------------------------------------------------------------------------
  DrawSchematicLM317 - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Massstab bestimmen (Vorlage 580 × 300 einpassen)
    2. Leitungen und Widerstand R
    3. LEDs vom Knoten nach Masse
    4. Reglergehäuse
    5. Beschriftung
------------------------------------------------------------------------------}
procedure DrawSchematicLM317(Canvas: TCanvas; const Rect: TRect;
  const V: TKsqSchemValues; const Col: TBlinkSchemColors);
var
  M: TMap;                                               // Vorlage -> Pixel
  C: TCanvas;                                            // Abkürzung
  Top, Bot: Double;                                      // Ober- und Unterkante der LEDs
begin
  // ----- 1. Massstab -----
  M := MakeMap(Rect, 580, 300);
  if M.S <= 0 then Exit;
  C := Canvas;
  C.Font.Name := FONT_UI;
  C.Font.Height := SmoothFontHeight(9, 12 * M.S);
  C.Pen.Color := Col.Line;
  C.Pen.Width := MW(M, 1.6);
  C.Brush.Style := bsClear;

  // ----- 2. Leitungen: +U_B an IN, OUT über R zum Knoten mit ADJ -----
  Wire(C, M, [60, 60, 190, 60]);                         // +U_B -> IN
  Wire(C, M, [60, 280, 520, 280]);                       // Masse (GND)
  Wire(C, M, [310, 60, 420, 60, 420, 72]);               // OUT -> R oben
  Wire(C, M, [420, 120, 420, 150]);                      // R unten -> Knoten
  Wire(C, M, [250, 100, 250, 150, 420, 150]);            // ADJ -> Knoten
  ResBands(C, M, 420, 72, 120, V.Bands, Col);            // R senkrecht mit Ringen
  // ----- 3. LEDs vom Knoten nach Masse -----
  if V.TwoLeds then Top := 168 else Top := 186;          // zwei LEDs: höher beginnen
  Wire(C, M, [420, 150, 420, Top]);
  Bot := Leds(C, M, 420, Top, V, Col);
  Wire(C, M, [420, Bot, 420, 280]);
  Dot(C, M, 420, 150, Col.Line);                         // Verbindungspunkt am Knoten
  C.Pen.Color := Col.Line;

  // ----- 4. Reglergehäuse -----
  C.Brush.Style := bsSolid;
  C.Brush.Color := Col.Body;
  C.Pen.Width := MW(M, 1.6);
  SmoothRectangle(C, MX(M, 190), MY(M, 30), MX(M, 310), MY(M, 100));

  // ----- 5. Beschriftung -----
  Txt(C, M, 22, 64, '+Ub', Col.Text, 0, False);
  Txt(C, M, 22, 284, 'GND', Col.Text, 0, False);
  Txt(C, M, 66, 48, V.UBText, Col.Dim, 0, False);
  Txt(C, M, 404, 138, V.RefText, Col.Dim, 2, False);     // 1,25 V links vom Knoten
  Txt(C, M, 436, 96, V.RText, Col.Accent, 0, True);
  Txt(C, M, 436, 116, V.RSubText, Col.Dim, 0, False);
  if V.TwoLeds then                                      // Text mittig neben den LEDs
  begin
    Txt(C, M, 462, 196, V.LedText, Col.Text, 0, False);
    Txt(C, M, 462, 216, V.UFText, Col.Dim, 0, False);
  end
  else
  begin
    Txt(C, M, 462, 198, V.LedText, Col.Text, 0, False);
    Txt(C, M, 462, 218, V.UFText, Col.Dim, 0, False);
  end;
  C.Font.Height := SmoothFontHeight(8, 16 * M.S);
  Txt(C, M, 250, 74, V.ChipText, Col.Text, 1, True);     // «LM317» gross im Gehäuse
  C.Font.Height := SmoothFontHeight(7, 10 * M.S);        // Anschlussnamen klein
  Txt(C, M, 196, 52, 'IN', Col.Dim, 0, False);
  Txt(C, M, 304, 52, 'OUT', Col.Dim, 2, False);
  Txt(C, M, 250, 95, 'ADJ', Col.Dim, 1, False);
  C.Font.Height := SmoothFontHeight(9, 12 * M.S);        // Schrift zurücksetzen
end;

{------------------------------------------------------------------------------
  DrawSchematicKsqT - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Massstab bestimmen (Vorlage 600 × 300 einpassen)
    2. Speiseleitungen, R_B und Kollektor von T2
    3. LEDs von +U_B zum Kollektor von T1
    4. Emitter von T1 über R_S nach Masse, Fühlerleitung zur Basis von T2
    5. Bauteile und Verbindungspunkte
    6. Beschriftung
------------------------------------------------------------------------------}
procedure DrawSchematicKsqT(Canvas: TCanvas; const Rect: TRect;
  const V: TKsqSchemValues; const Col: TBlinkSchemColors);
var
  M: TMap;                                               // Vorlage -> Pixel
  C: TCanvas;                                            // Abkürzung
  Top, Bot: Double;                                      // Ober- und Unterkante der LEDs
begin
  // ----- 1. Massstab -----
  M := MakeMap(Rect, 600, 300);
  if M.S <= 0 then Exit;
  C := Canvas;
  C.Font.Name := FONT_UI;
  C.Font.Height := SmoothFontHeight(9, 12 * M.S);
  C.Pen.Color := Col.Line;
  C.Pen.Width := MW(M, 1.6);
  C.Brush.Style := bsClear;

  // ----- 2. Speiseleitungen, R_B zur Basis von T1, Kollektor von T2 -----
  Wire(C, M, [60, 30, 540, 30]);                         // +U_B oben
  Wire(C, M, [60, 280, 540, 280]);                       // Masse unten
  Wire(C, M, [200, 30, 200, 48]);
  Wire(C, M, [200, 96, 200, 150, 394, 150]);
  Wire(C, M, [270, 150, 270, 208]);                      // Kollektor T2 an Basisleitung
  Wire(C, M, [270, 252, 270, 280]);                      // Emitter T2 an Masse
  // ----- 3. LEDs von +U_B zum Kollektor von T1 -----
  if V.TwoLeds then Top := 44 else Top := 62;
  Wire(C, M, [420, 30, 420, Top]);
  Bot := Leds(C, M, 420, Top, V, Col);
  Wire(C, M, [420, Bot, 420, 128]);
  // ----- 4. Emitter T1 über R_S nach Masse, Fühlerleitung zu T2 -----
  Wire(C, M, [420, 172, 420, 196]);                      // Emitter T1 -> R_S
  Wire(C, M, [420, 244, 420, 280]);                      // R_S -> Masse
  Wire(C, M, [296, 230, 350, 230, 350, 186, 420, 186]);  // Basis T2 <- oberes Ende R_S
  // ----- 5. Bauteile und Verbindungspunkte -----
  ResBands(C, M, 200, 48, 96, V.BandsB, Col);
  ResBands(C, M, 420, 196, 244, V.Bands, Col);
  Npn(C, M, 408, 150, 420, True, Col);                   // T1, Basis links
  Npn(C, M, 282, 230, 270, False, Col);                  // T2, Basis rechts (gespiegelt)
  Dot(C, M, 200, 30, Col.Line);
  Dot(C, M, 420, 30, Col.Line);
  Dot(C, M, 270, 150, Col.Line);
  Dot(C, M, 420, 186, Col.Line);
  C.Pen.Color := Col.Line;

  // ----- 6. Beschriftung -----
  Txt(C, M, 22, 34, '+Ub', Col.Text, 0, False);
  Txt(C, M, 22, 284, 'GND', Col.Text, 0, False);
  Txt(C, M, 66, 22, V.UBText, Col.Dim, 0, False);
  Txt(C, M, 186, 76, V.RBText, Col.Accent, 2, True);
  if V.TwoLeds then
  begin
    Txt(C, M, 462, 66, V.LedText, Col.Text, 0, False);
    Txt(C, M, 462, 86, V.UFText, Col.Dim, 0, False);
  end
  else
  begin
    Txt(C, M, 462, 76, V.LedText, Col.Text, 0, False);
    Txt(C, M, 462, 96, V.UFText, Col.Dim, 0, False);
  end;
  Txt(C, M, 446, 155, V.T1Text, Col.Text, 0, False);
  Txt(C, M, 250, 235, V.T2Text, Col.Text, 2, False);
  Txt(C, M, 440, 218, V.RText, Col.Accent, 0, True);
  Txt(C, M, 440, 238, V.RSubText, Col.Dim, 0, False);
end;

end.
