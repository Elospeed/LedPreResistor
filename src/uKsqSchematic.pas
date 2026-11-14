{ Schaltpläne der Konstantstromquellen: LM317 als Stromquelle (Vorlage
  580 × 300 Punkte) und Konstantstromquelle mit zwei Transistoren (Vorlage
  600 × 300). Zeichenhilfen und Transistorsymbol aus uBlinkSchematic, damit
  alle Schaltpläne gleich aussehen. Die LEDs leuchten dauernd. }
unit uKsqSchematic;

{$mode objfpc}{$H+}

interface

uses
  Types, Graphics, uColorCode, uBlinkSchematic;

type
  { Alles, was die Konstantstrom-Schaltpläne anzeigen, als fertiger Text.
    Tiefgestellte Zeichen mit "_" (siehe uRichText). }
  TKsqSchemValues = record
    UBText: string;      // "U_B = 12 … 14,4 V"
    ChipText: string;    // LM317: "LM317" bzw. "LM317L"
    RefText: string;     // LM317: "U_R_E_F = 1,25 V"
    RText: string;       // "R = 68 Ω" bzw. "R_S = 33 Ω"
    RSubText: string;    // "I = 18,4 mA"
    RBText: string;      // zwei Transistoren: "R_B = 4,7 kΩ"
    T1Text: string;      // zwei Transistoren: "T1 BC547"
    T2Text: string;      // zwei Transistoren: "T2 BC547"
    LedText: string;     // "2 × LED weiss"
    UFText: string;      // "U_F = 2 × 3,2 V"
    LedColor: TColor;    // Leuchtfarbe der LEDs
    TwoLeds: Boolean;    // zwei LED-Symbole zeichnen (mehrere LEDs in Reihe)
    Bands: TBandArray;   // Farbringe des Fühlerwiderstands
    BandsB: TBandArray;  // Farbringe von R_B
  end;

{ LM317 als Konstantstromquelle }
procedure DrawSchematicLM317(Canvas: TCanvas; const Rect: TRect;
  const V: TKsqSchemValues; const Col: TBlinkSchemColors);

{ Konstantstromquelle mit zwei Transistoren }
procedure DrawSchematicKsqT(Canvas: TCanvas; const Rect: TRect;
  const V: TKsqSchemValues; const Col: TBlinkSchemColors);

implementation

uses
  Math, uTheme, uSmooth;

{ eine oder zwei LEDs senkrecht ab Top; liefert die Unterkante }
function Leds(C: TCanvas; const M: TMap; X, Top: Double; const V: TKsqSchemValues;
  const Col: TBlinkSchemColors): Double;
var
  BV: TBlinkSchemValues;  // für LedDown: nur die Leuchtfarbe
begin
  BV := Default(TBlinkSchemValues);
  BV.LedColor := V.LedColor;
  LedDown(C, M, X, Top, True, BV, Col);
  Result := Top + 24;
  if V.TwoLeds then
  begin
    Wire(C, M, [X, Result, X, Result + 8]);
    LedDown(C, M, X, Result + 8, True, BV, Col);
    Result := Result + 32;
  end;
end;

procedure DrawSchematicLM317(Canvas: TCanvas; const Rect: TRect;
  const V: TKsqSchemValues; const Col: TBlinkSchemColors);
var
  M: TMap;        // Vorlage -> Pixel
  C: TCanvas;     // Abkürzung
  Top, Bot: Double; // Ober- und Unterkante der LEDs
begin
  M := MakeMap(Rect, 580, 300);
  if M.S <= 0 then Exit;
  C := Canvas;
  C.Font.Name := FONT_UI;
  C.Font.Height := SmoothFontHeight(9, 12 * M.S);
  C.Pen.Color := Col.Line;
  C.Pen.Width := MW(M, 1.6);
  C.Brush.Style := bsClear;

  // Speiseleitungen; +Ub an IN, OUT über R zum Knoten mit ADJ
  Wire(C, M, [60, 60, 190, 60]);
  Wire(C, M, [60, 280, 520, 280]);
  Wire(C, M, [310, 60, 420, 60, 420, 72]);
  Wire(C, M, [420, 120, 420, 150]);
  Wire(C, M, [250, 100, 250, 150, 420, 150]);
  ResBands(C, M, 420, 72, 120, V.Bands, Col);
  // LEDs vom Knoten nach Masse
  if V.TwoLeds then Top := 168 else Top := 186;
  Wire(C, M, [420, 150, 420, Top]);
  Bot := Leds(C, M, 420, Top, V, Col);
  Wire(C, M, [420, Bot, 420, 280]);
  Dot(C, M, 420, 150, Col.Line);
  C.Pen.Color := Col.Line;

  // Reglergehäuse
  C.Brush.Style := bsSolid;
  C.Brush.Color := Col.Body;
  C.Pen.Width := MW(M, 1.6);
  SmoothRectangle(C, MX(M, 190), MY(M, 30), MX(M, 310), MY(M, 100));

  // Beschriftung
  Txt(C, M, 22, 64, '+Ub', Col.Text, 0, False);
  Txt(C, M, 22, 284, 'GND', Col.Text, 0, False);
  Txt(C, M, 66, 48, V.UBText, Col.Dim, 0, False);
  Txt(C, M, 404, 138, V.RefText, Col.Dim, 2, False);
  Txt(C, M, 436, 96, V.RText, Col.Accent, 0, True);
  Txt(C, M, 436, 116, V.RSubText, Col.Dim, 0, False);
  if V.TwoLeds then
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
  Txt(C, M, 250, 74, V.ChipText, Col.Text, 1, True);
  C.Font.Height := SmoothFontHeight(7, 10 * M.S);
  Txt(C, M, 196, 52, 'IN', Col.Dim, 0, False);
  Txt(C, M, 304, 52, 'OUT', Col.Dim, 2, False);
  Txt(C, M, 250, 95, 'ADJ', Col.Dim, 1, False);
  C.Font.Height := SmoothFontHeight(9, 12 * M.S);
end;

procedure DrawSchematicKsqT(Canvas: TCanvas; const Rect: TRect;
  const V: TKsqSchemValues; const Col: TBlinkSchemColors);
var
  M: TMap;        // Vorlage -> Pixel
  C: TCanvas;     // Abkürzung
  Top, Bot: Double; // Ober- und Unterkante der LEDs
begin
  M := MakeMap(Rect, 600, 300);
  if M.S <= 0 then Exit;
  C := Canvas;
  C.Font.Name := FONT_UI;
  C.Font.Height := SmoothFontHeight(9, 12 * M.S);
  C.Pen.Color := Col.Line;
  C.Pen.Width := MW(M, 1.6);
  C.Brush.Style := bsClear;

  Wire(C, M, [60, 30, 540, 30]);
  Wire(C, M, [60, 280, 540, 280]);
  // R_B von +Ub zur Basis von T1, unterwegs Kollektor von T2
  Wire(C, M, [200, 30, 200, 48]);
  Wire(C, M, [200, 96, 200, 150, 394, 150]);
  Wire(C, M, [270, 150, 270, 208]);
  Wire(C, M, [270, 252, 270, 280]);
  // LEDs von +Ub zum Kollektor von T1
  if V.TwoLeds then Top := 44 else Top := 62;
  Wire(C, M, [420, 30, 420, Top]);
  Bot := Leds(C, M, 420, Top, V, Col);
  Wire(C, M, [420, Bot, 420, 128]);
  // Emitter von T1 über R_S nach Masse; Spannung an R_S zur Basis von T2
  Wire(C, M, [420, 172, 420, 196]);
  Wire(C, M, [420, 244, 420, 280]);
  Wire(C, M, [296, 230, 350, 230, 350, 186, 420, 186]);
  ResBands(C, M, 200, 48, 96, V.BandsB, Col);
  ResBands(C, M, 420, 196, 244, V.Bands, Col);
  Npn(C, M, 408, 150, 420, True, Col);
  Npn(C, M, 282, 230, 270, False, Col);
  Dot(C, M, 200, 30, Col.Line);
  Dot(C, M, 420, 30, Col.Line);
  Dot(C, M, 270, 150, Col.Line);
  Dot(C, M, 420, 186, Col.Line);
  C.Pen.Color := Col.Line;

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
