{ Schaltpläne der Blinkschaltungen: NE555 astabil (Vorlage 580 × 320 Punkte)
  und astabiler Multivibrator mit zwei Transistoren (Vorlage 600 × 300).
  Wie uSchematic nur LCL-Canvas; die Vorlage wird in das übergebene
  Rechteck eingepasst, Strichstärken und Schrift wachsen mit. Die LEDs
  werden hell oder dunkel gezeichnet, so blinkt der Schaltplan mit. }
unit uBlinkSchematic;

{$mode objfpc}{$H+}

interface

uses
  Types, Graphics, uColorCode, uBlink;

type
  { Alles, was die Blink-Schaltpläne anzeigen, als fertiger Text.
    Tiefgestellte Zeichen mit "_" (siehe uRichText). }
  TBlinkSchemValues = record
    UBText: string;      // "U_B = 9 V"
    R1Text: string;      // "R1 = 1 kΩ" bzw. "R_B_1 = 33 kΩ"
    R2Text: string;      // "R2 = 68 kΩ" bzw. "R_B_2 = 33 kΩ"
    CText: string;       // "C = 10 µF"
    C2Text: string;      // Multivibrator: "C2 = 10 µF"
    RV1Text: string;     // "R_V = 390 Ω"
    RV2Text: string;     // zweiter Vorwiderstand
    Led1Text: string;    // "LED rot" bzw. "LED 1"
    Led2Text: string;    // "LED 2"
    UOutText: string;    // NE555: "U_O_U_T ≈ 7,3 V"
    T1Text: string;      // Multivibrator: "T1 BC547"
    T2Text: string;      // Multivibrator: "T2 BC547"
    LedColor: TColor;    // Leuchtfarbe der LEDs
    Led1Lit: Boolean;    // LED 1 leuchtet gerade
    Led2Lit: Boolean;    // LED 2 leuchtet gerade
    Bands1: TBandArray;  // Farbringe Vorwiderstand 1 (leer = ohne)
    Bands2: TBandArray;  // Farbringe Vorwiderstand 2
    Diode: Boolean;      // NE555: Diode über R2 eingezeichnet
    Conn: TLedConn;      // NE555: Anschluss der LED(s)
    Elko: Boolean;       // Zeitkondensator ist ein Elko (Plus-Zeichen)
  end;

  { Farben für die Zeichnung }
  TBlinkSchemColors = record
    Line: TColor;     // Leitungen
    Text: TColor;     // Beschriftung
    Accent: TColor;   // Werte der Bauteile
    Dim: TColor;      // Pin-Nummern, Nebentext
    Body: TColor;     // Füllung der Bauteile (Hintergrund)
    LedOff: TColor;   // LED dunkel
  end;

{ NE555 astabil mit LED(s) am Ausgang }
procedure DrawSchematic555(Canvas: TCanvas; const Rect: TRect;
  const V: TBlinkSchemValues; const Col: TBlinkSchemColors);

{ Astabiler Multivibrator mit zwei Transistoren und zwei LEDs }
procedure DrawSchematicMulti(Canvas: TCanvas; const Rect: TRect;
  const V: TBlinkSchemValues; const Col: TBlinkSchemColors);

implementation

uses
  Math, uTheme, uRichText;

type
  { Umrechnung Vorlage -> Pixel }
  TMap = record
    S, OX, OY: Double;
  end;

function MakeMap(const Rect: TRect; BW, BH: Double): TMap;
begin
  Result.S := Min((Rect.Right - Rect.Left) / BW, (Rect.Bottom - Rect.Top) / BH);
  Result.OX := Rect.Left + ((Rect.Right - Rect.Left) - BW * Result.S) / 2;
  Result.OY := Rect.Top + ((Rect.Bottom - Rect.Top) - BH * Result.S) / 2;
end;

function MX(const M: TMap; V: Double): Integer;
begin
  Result := Round(M.OX + V * M.S);
end;

function MY(const M: TMap; V: Double): Integer;
begin
  Result := Round(M.OY + V * M.S);
end;

function MP(const M: TMap; X, Y: Double): TPoint;
begin
  Result := Point(MX(M, X), MY(M, Y));
end;

function MW(const M: TMap; V: Double): Integer;
begin
  Result := Max(1, Round(V * M.S));
end;

{ Text mit Auszeichnung; Align 0 = links, 1 = Mitte, 2 = rechts;
  BaseY ist die Grundlinie wie im SVG }
procedure Txt(C: TCanvas; const M: TMap; BX, BaseY: Double; const T: string;
  Color: TColor; Align: Integer; Bold: Boolean);
var
  TW, TX, TY: Integer;  // Breite und Startpunkt
begin
  if T = '' then Exit;
  if Bold then C.Font.Style := [fsBold] else C.Font.Style := [];
  TW := RichWidth(C, T);
  case Align of
    1: TX := MX(M, BX) - TW div 2;
    2: TX := MX(M, BX) - TW;
  else
    TX := MX(M, BX);
  end;
  TY := MY(M, BaseY) - C.TextHeight('Ag') * 4 div 5;
  C.Brush.Style := bsClear;
  DrawRich(C, TX, TY, T, Color, Color);
  C.Font.Style := [];
end;

{ Leitung durch mehrere Punkte der Vorlage }
procedure Wire(C: TCanvas; const M: TMap; const P: array of Double);
var
  Pts: array of TPoint;  // Punkte in Pixeln
  I: Integer;            // Zähler
begin
  SetLength(Pts, Length(P) div 2);
  for I := 0 to High(Pts) do
    Pts[I] := MP(M, P[2 * I], P[2 * I + 1]);
  C.PolyLine(Pts);
end;

{ Verbindungspunkt }
procedure Dot(C: TCanvas; const M: TMap; X, Y: Double; Color: TColor);
var
  R: Integer;  // Radius in Pixeln
begin
  R := Max(2, Round(2.8 * M.S));
  C.Brush.Style := bsSolid;
  C.Brush.Color := Color;
  C.Pen.Color := Color;
  C.Ellipse(MX(M, X) - R, MY(M, Y) - R, MX(M, X) + R + 1, MY(M, Y) + R + 1);
end;

{ Widerstand senkrecht als Rechteck (Zeitglied) von Y1 bis Y2 }
procedure ResV(C: TCanvas; const M: TMap; X, Y1, Y2: Double; const Col: TBlinkSchemColors);
begin
  C.Brush.Style := bsSolid;
  C.Brush.Color := Col.Body;
  C.Pen.Color := Col.Accent;
  C.Pen.Width := MW(M, 1.8);
  C.Rectangle(MX(M, X - 9), MY(M, Y1), MX(M, X + 9), MY(M, Y2));
  C.Pen.Color := Col.Line;
end;

{ Vorwiderstand senkrecht mit Farbringen (Körper beige wie im Hauptschaltplan) }
procedure ResBands(C: TCanvas; const M: TMap; X, Y1, Y2: Double; const Bands: TBandArray;
  const Col: TBlinkSchemColors);
var
  I, N, Y: Integer;   // Ring-Zähler, Anzahl, Lage
  T, B: Integer;      // Ober- und Unterkante in Pixeln
  L, R: Integer;      // linke und rechte Kante
  BH: Integer;        // Höhe eines Rings
begin
  L := MX(M, X - 9);
  R := MX(M, X + 9);
  T := MY(M, Y1);
  B := MY(M, Y2);
  C.Brush.Style := bsSolid;
  C.Brush.Color := clrResistorBody;
  C.Pen.Color := clrResistorEdge;
  C.Pen.Width := 1;
  C.Rectangle(L, T, R, B);
  N := Length(Bands);
  if N >= 3 then
  begin
    BH := Max(2, (B - T) * 8 div 100);
    C.Pen.Style := psClear;
    for I := 0 to N - 1 do
    begin
      // Ziffern und Multiplikator oben gruppiert, Toleranz unten abgesetzt
      if I < N - 1 then
        Y := T + (B - T) * (12 + I * (52 div (N - 1))) div 100
      else
        Y := T + (B - T) * 80 div 100;
      C.Brush.Color := BandScreenColor(Bands[I]);
      C.Rectangle(L + 1, Y, R, Y + BH);
    end;
    C.Pen.Style := psSolid;
  end;
  C.Pen.Color := Col.Line;
end;

{ LED nach unten zeigend (Anode oben), Dreieck von Top bis Top + 24;
  leuchtend mit Lichtpfeilen nach rechts oben }
procedure LedDown(C: TCanvas; const M: TMap; X, Top: Double; Lit: Boolean;
  const V: TBlinkSchemValues; const Col: TBlinkSchemColors);
begin
  C.Pen.Color := Col.Line;
  C.Pen.Width := MW(M, 1.6);
  C.Brush.Style := bsSolid;
  if Lit then C.Brush.Color := V.LedColor else C.Brush.Color := Col.LedOff;
  C.Polygon([MP(M, X - 14, Top), MP(M, X + 14, Top), MP(M, X, Top + 24)]);
  C.Pen.Width := MW(M, 2.2);
  C.Line(MX(M, X - 14), MY(M, Top + 24), MX(M, X + 14), MY(M, Top + 24));
  if Lit then
  begin
    C.Pen.Color := V.LedColor;
    C.Pen.Width := MW(M, 1.6);
    C.Line(MX(M, X + 18), MY(M, Top + 6), MX(M, X + 32), MY(M, Top - 4));
    C.Line(MX(M, X + 22), MY(M, Top + 16), MX(M, X + 36), MY(M, Top + 6));
    C.Brush.Color := V.LedColor;
    C.Pen.Width := 1;
    C.Polygon([MP(M, X + 32, Top - 4), MP(M, X + 24, Top - 3), MP(M, X + 28, Top + 3)]);
    C.Polygon([MP(M, X + 36, Top + 6), MP(M, X + 28, Top + 7), MP(M, X + 32, Top + 13)]);
  end;
  C.Pen.Color := Col.Line;
  C.Pen.Width := MW(M, 1.6);
end;

{ Kondensator waagrecht liegende Platten (Leitung senkrecht), Platten bei Y und Y + 8 }
procedure CapV(C: TCanvas; const M: TMap; X, Y: Double; Elko: Boolean; const Col: TBlinkSchemColors);
begin
  C.Pen.Width := MW(M, 2.4);
  C.Line(MX(M, X - 14), MY(M, Y), MX(M, X + 14), MY(M, Y));
  C.Line(MX(M, X - 14), MY(M, Y + 8), MX(M, X + 14), MY(M, Y + 8));
  C.Pen.Width := MW(M, 1.6);
  if Elko then
    Txt(C, M, X + 17, Y - 1, '+', Col.Dim, 0, False);
end;

{ Kondensator in waagrechter Leitung, Platten bei X und X + 8;
  PlusRight: Pluspol (Elko) an der rechten Platte }
procedure CapH(C: TCanvas; const M: TMap; X, Y: Double; Elko, PlusRight: Boolean;
  const Col: TBlinkSchemColors);
begin
  C.Pen.Width := MW(M, 2.4);
  C.Line(MX(M, X), MY(M, Y - 12), MX(M, X), MY(M, Y + 12));
  C.Line(MX(M, X + 8), MY(M, Y - 12), MX(M, X + 8), MY(M, Y + 12));
  C.Pen.Width := MW(M, 1.6);
  if Elko then
    if PlusRight then
      Txt(C, M, X + 12, Y - 14, '+', Col.Dim, 0, False)
    else
      Txt(C, M, X - 4, Y - 14, '+', Col.Dim, 2, False);
end;

procedure DrawSchematic555(Canvas: TCanvas; const Rect: TRect;
  const V: TBlinkSchemValues; const Col: TBlinkSchemColors);
var
  M: TMap;        // Vorlage -> Pixel
  C: TCanvas;     // Abkürzung
  OutEnd: Double; // rechtes Ende der Ausgangsleitung
begin
  M := MakeMap(Rect, 580, 320);
  if M.S <= 0 then Exit;
  C := Canvas;
  C.Font.Name := FONT_UI;
  C.Font.Height := -Max(9, Round(12 * M.S));
  C.Pen.Color := Col.Line;
  C.Pen.Width := MW(M, 1.6);
  C.Brush.Style := bsClear;

  // Speiseleitungen
  Wire(C, M, [60, 30, 520, 30]);
  Wire(C, M, [60, 295, 520, 295]);
  // R1 und R2 in Reihe, dazwischen Pin 7
  Wire(C, M, [170, 30, 170, 48]);
  Wire(C, M, [170, 92, 170, 132]);
  Wire(C, M, [170, 120, 250, 120]);
  Wire(C, M, [170, 176, 170, 236]);
  Wire(C, M, [170, 185, 220, 185]);
  Wire(C, M, [250, 170, 220, 170, 220, 200, 250, 200]);
  Wire(C, M, [170, 244, 170, 295]);
  // Diode über R2 (Anode unten an Pin 6/2, Kathode oben an Pin 7)
  if V.Diode then
  begin
    Wire(C, M, [170, 124, 136, 124, 136, 140]);
    Wire(C, M, [136, 166, 136, 181, 170, 181]);
    C.Brush.Style := bsSolid;
    C.Brush.Color := Col.Line;
    C.Polygon([MP(M, 126, 166), MP(M, 146, 166), MP(M, 136, 146)]);
    C.Pen.Width := MW(M, 2.2);
    C.Line(MX(M, 126), MY(M, 145), MX(M, 146), MY(M, 145));
    C.Pen.Width := MW(M, 1.6);
    Dot(C, M, 170, 124, Col.Line);
    Dot(C, M, 170, 181, Col.Line);
    C.Pen.Color := Col.Line;
  end;
  ResV(C, M, 170, 48, 92, Col);
  ResV(C, M, 170, 132, 176, Col);
  CapV(C, M, 170, 236, V.Elko, Col);
  Dot(C, M, 170, 120, Col.Line);
  Dot(C, M, 170, 185, Col.Line);
  Dot(C, M, 220, 185, Col.Line);
  C.Pen.Color := Col.Line;

  // Pins 8 und 4 an +Ub, Pin 1 an Masse, Pin 5 über 10 nF an Masse
  Wire(C, M, [276, 90, 276, 30]);
  Wire(C, M, [336, 90, 336, 30]);
  Wire(C, M, [310, 250, 310, 295]);
  Wire(C, M, [370, 220, 400, 220, 400, 250]);
  Wire(C, M, [400, 258, 400, 295]);
  CapV(C, M, 400, 250, False, Col);

  // IC-Gehäuse
  C.Brush.Style := bsSolid;
  C.Brush.Color := Col.Body;
  C.Pen.Color := Col.Line;
  C.Pen.Width := MW(M, 1.6);
  C.Rectangle(MX(M, 250), MY(M, 90), MX(M, 370), MY(M, 250));

  // Ausgang Pin 3 nach rechts
  case V.Conn of
    cnGnd: OutEnd := 470;
    cnVcc: OutEnd := 430;
  else
    OutEnd := 470;
  end;
  Wire(C, M, [370, 150, OutEnd, 150]);
  if V.Conn in [cnGnd, cnBoth] then
  begin
    // LED 1 vom Ausgang über R_V nach Masse
    Wire(C, M, [470, 150, 470, 160]);
    Wire(C, M, [470, 204, 470, 228]);
    Wire(C, M, [470, 252, 470, 295]);
    ResBands(C, M, 470, 160, 204, V.Bands1, Col);
    LedDown(C, M, 470, 228, V.Led1Lit, V, Col);
  end;
  if V.Conn in [cnVcc, cnBoth] then
  begin
    // LED von +Ub über R_V zum Ausgang (leuchtet bei Low)
    Wire(C, M, [430, 30, 430, 44]);
    Wire(C, M, [430, 68, 430, 82]);
    Wire(C, M, [430, 126, 430, 150]);
    if V.Conn = cnVcc then
    begin
      LedDown(C, M, 430, 44, V.Led1Lit, V, Col);
      ResBands(C, M, 430, 82, 126, V.Bands1, Col);
    end
    else
    begin
      LedDown(C, M, 430, 44, V.Led2Lit, V, Col);
      ResBands(C, M, 430, 82, 126, V.Bands2, Col);
    end;
    Dot(C, M, 430, 30, Col.Line);
  end;
  if V.Conn = cnBoth then
    Dot(C, M, 430, 150, Col.Line);
  C.Pen.Color := Col.Line;

  // Beschriftung
  Txt(C, M, 22, 34, '+Ub', Col.Text, 0, False);
  Txt(C, M, 22, 299, 'GND', Col.Text, 0, False);
  Txt(C, M, 70, 22, V.UBText, Col.Dim, 0, False);
  Txt(C, M, 156, 74, V.R1Text, Col.Accent, 2, True);
  if V.Diode then
    Txt(C, M, 122, 158, V.R2Text, Col.Accent, 2, True)
  else
    Txt(C, M, 156, 158, V.R2Text, Col.Accent, 2, True);
  Txt(C, M, 150, 244, V.CText, Col.Accent, 2, True);
  Txt(C, M, 416, 258, '10 nF', Col.Dim, 0, False);
  C.Font.Height := -Max(8, Round(16 * M.S));
  Txt(C, M, 316, 196, 'NE555', Col.Text, 1, True);
  C.Font.Height := -Max(7, Round(10 * M.S));
  Txt(C, M, 254, 124, '7 DIS', Col.Dim, 0, False);
  Txt(C, M, 254, 174, '6 THR', Col.Dim, 0, False);
  Txt(C, M, 254, 204, '2 TRI', Col.Dim, 0, False);
  Txt(C, M, 366, 154, 'OUT 3', Col.Dim, 2, False);
  Txt(C, M, 366, 224, 'CV 5', Col.Dim, 2, False);
  Txt(C, M, 270, 104, '8', Col.Dim, 0, False);
  Txt(C, M, 331, 104, '4', Col.Dim, 0, False);
  Txt(C, M, 304, 244, '1', Col.Dim, 0, False);
  C.Font.Height := -Max(9, Round(12 * M.S));
  if V.Conn = cnVcc then
    Txt(C, M, 376, 168, V.UOutText, Col.Dim, 0, False)
  else
    Txt(C, M, 376, 142, V.UOutText, Col.Dim, 0, False);
  if V.Conn in [cnGnd, cnBoth] then
  begin
    Txt(C, M, 486, 186, V.RV1Text, Col.Accent, 0, True);
    Txt(C, M, 490, 270, V.Led1Text, Col.Text, 0, False);
  end;
  if V.Conn = cnVcc then
  begin
    Txt(C, M, 446, 108, V.RV1Text, Col.Accent, 0, True);
    Txt(C, M, 470, 62, V.Led1Text, Col.Text, 0, False);
  end
  else if V.Conn = cnBoth then
  begin
    Txt(C, M, 446, 108, V.RV2Text, Col.Accent, 0, True);
    Txt(C, M, 470, 62, V.Led2Text, Col.Text, 0, False);
  end;
end;

{ NPN-Transistor: Kreis um (CX, CY), Basis kommt von links (FromLeft) oder
  rechts; Kollektor oben und Emitter unten auf der Linie X = PX }
procedure Npn(C: TCanvas; const M: TMap; CX, CY, PX: Double; FromLeft: Boolean;
  const Col: TBlinkSchemColors);
var
  BX: Double;        // Lage des Basisbalkens
  DX, DY, L: Double; // Richtung des Emitters
  TX, TY: Double;    // Pfeilspitze
  Bx2, By2: Double;  // Mitte der Pfeilbasis
begin
  if FromLeft then BX := CX - 14 else BX := CX + 14;
  C.Brush.Style := bsClear;
  C.Pen.Color := Col.Line;
  C.Pen.Width := MW(M, 1.6);
  C.Ellipse(MX(M, CX - 25), MY(M, CY - 25), MX(M, CX + 25), MY(M, CY + 25));
  // Basisbalken
  C.Pen.Width := MW(M, 3);
  C.Line(MX(M, BX), MY(M, CY - 17), MX(M, BX), MY(M, CY + 17));
  C.Pen.Width := MW(M, 1.6);
  // Kollektor und Emitter schräg zur senkrechten Leitung
  Wire(C, M, [BX, CY - 8, PX, CY - 22]);
  Wire(C, M, [BX, CY + 8, PX, CY + 22]);
  // Pfeil am Emitter zeigt nach aussen (NPN)
  DX := PX - BX;
  DY := 14;
  L := Sqrt(DX * DX + DY * DY);
  DX := DX / L;
  DY := DY / L;
  TX := PX - DX * 3;
  TY := CY + 22 - DY * 3;
  Bx2 := TX - DX * 12;
  By2 := TY - DY * 12;
  C.Brush.Style := bsSolid;
  C.Brush.Color := Col.Line;
  C.Pen.Width := 1;
  C.Polygon([MP(M, TX, TY), MP(M, Bx2 + DY * 5, By2 - DX * 5), MP(M, Bx2 - DY * 5, By2 + DX * 5)]);
  C.Pen.Width := MW(M, 1.6);
end;

procedure DrawSchematicMulti(Canvas: TCanvas; const Rect: TRect;
  const V: TBlinkSchemValues; const Col: TBlinkSchemColors);
var
  M: TMap;     // Vorlage -> Pixel
  C: TCanvas;  // Abkürzung
begin
  M := MakeMap(Rect, 600, 300);
  if M.S <= 0 then Exit;
  C := Canvas;
  C.Font.Name := FONT_UI;
  C.Font.Height := -Max(9, Round(12 * M.S));
  C.Pen.Color := Col.Line;
  C.Pen.Width := MW(M, 1.6);
  C.Brush.Style := bsClear;

  Wire(C, M, [60, 25, 560, 25]);
  Wire(C, M, [60, 285, 560, 285]);
  // linker Kollektorzweig: R_V1, LED 1, T1
  Wire(C, M, [120, 25, 120, 40]);
  Wire(C, M, [120, 78, 120, 94]);
  Wire(C, M, [120, 118, 120, 208]);
  Wire(C, M, [120, 252, 120, 285]);
  // rechter Kollektorzweig: R_V2, LED 2, T2
  Wire(C, M, [480, 25, 480, 40]);
  Wire(C, M, [480, 78, 480, 94]);
  Wire(C, M, [480, 118, 480, 208]);
  Wire(C, M, [480, 252, 480, 285]);
  // Basiswiderstände
  Wire(C, M, [240, 25, 240, 45]);
  Wire(C, M, [240, 95, 240, 230, 146, 230]);
  Wire(C, M, [360, 25, 360, 45]);
  Wire(C, M, [360, 95, 360, 230, 454, 230]);
  // C1: Kollektor T1 -> Basis T2; C2: Kollektor T2 -> Basis T1
  Wire(C, M, [120, 150, 180, 150]);
  Wire(C, M, [188, 150, 360, 150]);
  Wire(C, M, [480, 180, 420, 180]);
  Wire(C, M, [412, 180, 240, 180]);
  // Pluspol jeweils auf der Seite des Kollektors
  CapH(C, M, 180, 150, V.Elko, False, Col);
  CapH(C, M, 412, 180, V.Elko, True, Col);
  ResBands(C, M, 120, 40, 78, V.Bands1, Col);
  ResBands(C, M, 480, 40, 78, V.Bands2, Col);
  LedDown(C, M, 120, 94, V.Led1Lit, V, Col);
  LedDown(C, M, 480, 94, V.Led2Lit, V, Col);
  ResV(C, M, 240, 45, 95, Col);
  ResV(C, M, 360, 45, 95, Col);
  Npn(C, M, 132, 230, 120, False, Col);
  Npn(C, M, 468, 230, 480, True, Col);
  Dot(C, M, 120, 150, Col.Line);
  Dot(C, M, 360, 150, Col.Line);
  Dot(C, M, 480, 180, Col.Line);
  Dot(C, M, 240, 180, Col.Line);
  Dot(C, M, 240, 25, Col.Line);
  Dot(C, M, 360, 25, Col.Line);
  C.Pen.Color := Col.Line;

  Txt(C, M, 22, 29, '+Ub', Col.Text, 0, False);
  Txt(C, M, 22, 289, 'GND', Col.Text, 0, False);
  Txt(C, M, 70, 17, V.UBText, Col.Dim, 0, False);
  Txt(C, M, 104, 64, V.RV1Text, Col.Accent, 2, True);
  Txt(C, M, 496, 64, V.RV2Text, Col.Accent, 0, True);
  Txt(C, M, 98, 112, V.Led1Text, Col.Text, 2, False);
  Txt(C, M, 520, 112, V.Led2Text, Col.Text, 0, False);
  Txt(C, M, 226, 74, V.R1Text, Col.Accent, 2, True);
  Txt(C, M, 376, 74, V.R2Text, Col.Accent, 0, True);
  Txt(C, M, 184, 171, V.CText, Col.Accent, 1, True);
  Txt(C, M, 416, 206, V.C2Text, Col.Accent, 1, True);
  Txt(C, M, 98, 268, V.T1Text, Col.Text, 2, False);
  Txt(C, M, 502, 268, V.T2Text, Col.Text, 0, False);
end;

end.
