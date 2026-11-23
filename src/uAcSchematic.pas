{==============================================================================
  uAcSchematic - Schaltpläne für LEDs an Wechselspannung
==============================================================================
  Zweck:     Zeichnet im Reiter «Wechselstrom» den Schaltplan der gewählten
             Schaltung mit den aktuellen Werten (Vorlage 580 × 300 Punkte):
               - Einfach: Trafo, Vorwiderstand R, LEDs, Schutzdiode D
                 antiparallel zu den LEDs (Kathode oben an der Anode der
                 ersten LED, Anode unten an der Kathode der letzten)
               - Ohne Flackern: Trafo, Brückengleichrichter, Elko C
                 (Plus oben), Vorwiderstand R, LEDs

  Symbole:   Wechselspannungsquelle: Kreis mit Sinuswelle.
             Brückengleichrichter: Kasten mit Diodensymbol, links die
             beiden Wechselspannungs-Anschlüsse «~», rechts «+» und «–».
             Diode: Dreieck mit Querstrich (Kathode), wie in uBlinkSchematic.

  Technik:   Die Zeichenhilfen (Leitung, Widerstand, LED, Elko, Punkt, Text)
             und die Umrechnung Vorlage -> Pixel (TMap) kommen aus
             uBlinkSchematic, die LED-Säule aus uKsqSchematic, damit alle
             Schaltpläne gleich aussehen. Jedes Bauteil wird für die
             Verbindungstests an uSchemNetz gemeldet.

  Autor:     Elospeed
  Versionen: 2.7  23.11.2026  neu: Schaltpläne Einfach und Ohne Flackern
==============================================================================}
unit uAcSchematic;

{$mode objfpc}{$H+}

interface

uses
  Types, Graphics, uColorCode, uBlinkSchematic;

{==============================================================================
  TYPEN
==============================================================================}
type
  // Alles, was die Wechselstrom-Schaltpläne anzeigen, als fertiger Text.
  // Tiefgestellte Zeichen mit «_» (siehe uRichText).
  TAcSchemValues = record
    UText: string;                                       // Trafospannung, "U = 16 V~"
    UPeakText: string;                                   // Spitze, "Û = 22,6 V"
    RText: string;                                       // "R = 1 kΩ"
    RSubText: string;                                    // "Î = 19,4 mA" bzw. "I = 16,6 mA"
    DiodeText: string;                                   // Einfach: "D 1N4148"
    DiodeSubText: string;                                // Einfach: "Schutzdiode"
    CapText: string;                                     // Ohne Flackern: "C = 68 µF"
    CapSubText: string;                                  // Ohne Flackern: "35 V"
    BridgeText: string;                                  // Ohne Flackern: "B80C1500"
    UDcText: string;                                     // Ohne Flackern: "U_D_C = 21,2 V" (Spitze am Elko)
    LedText: string;                                     // "2 × LED weiss"
    UFText: string;                                      // "U_F = 2 × 3,2 V"
    LedColor: TColor;                                    // Leuchtfarbe der LEDs
    LedCount: Integer;                                   // LEDs in Reihe
    Bands: TBandArray;                                   // Farbringe von R
  end;

{==============================================================================
  ÖFFENTLICHE FUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  DrawSchematicAcSimple
------------------------------------------------------------------------------
  Zeichnet die einfache Schaltung: Trafo, R, LEDs und Schutzdiode.
  Parameter: Canvas - Leinwand
             Rect   - verfügbarer Platz; die Vorlage wird eingepasst
             V      - Texte, LED-Farbe und Farbringe
             Col    - Farben (Leitung, Text, Hervorhebung ...)
------------------------------------------------------------------------------}
procedure DrawSchematicAcSimple(Canvas: TCanvas; const Rect: TRect;
  const V: TAcSchemValues; const Col: TBlinkSchemColors);

{------------------------------------------------------------------------------
  DrawSchematicAcBridge
------------------------------------------------------------------------------
  Zeichnet die Schaltung ohne Flackern: Trafo, Gleichrichter, Elko, R, LEDs.
  Parameter: wie DrawSchematicAcSimple
------------------------------------------------------------------------------}
procedure DrawSchematicAcBridge(Canvas: TCanvas; const Rect: TRect;
  const V: TAcSchemValues; const Col: TBlinkSchemColors);

implementation

uses
  uTheme, uSmooth, uSchemNetz, uKsqSchematic;

{==============================================================================
  ZEICHENHILFEN
==============================================================================}

{------------------------------------------------------------------------------
  AcSource
------------------------------------------------------------------------------
  Wechselspannungsquelle (Trafo): Kreis mit einer Sinuswelle, Anschlüsse
  oben und unten.
  Parameter: C, M - Leinwand und Umrechnung
             X, Y - Mitte des Kreises (Vorlage); Radius 22 Punkte
             Col  - Farben
------------------------------------------------------------------------------}
procedure AcSource(C: TCanvas; const M: TMap; X, Y: Double; const Col: TBlinkSchemColors);
const
  STEPS = 24;                                            // Stützpunkte der Sinuswelle
var
  Pts: array of TPoint;                                  // Sinuswelle in Pixeln
  I: Integer;                                            // Zähler
begin
  NetzName('TRAFO');                                     // für die Verbindungstests
  NetzBauteil('TRAFO', ['1', '2'], [X, Y - 22, X, Y + 22]);
  C.Pen.Color := Col.Line;
  C.Pen.Width := MW(M, 1.6);
  C.Brush.Style := bsSolid;
  C.Brush.Color := Col.Body;
  C.Ellipse(MX(M, X - 22), MY(M, Y - 22), MX(M, X + 22), MY(M, Y + 22));
  // eine volle Sinuswelle, 26 Punkte breit, 7 Punkte hoch
  SetLength(Pts, STEPS + 1);
  for I := 0 to STEPS do
    Pts[I] := MP(M, X - 13 + 26 * I / STEPS, Y - 7 * Sin(2 * Pi * I / STEPS));
  C.Brush.Style := bsClear;
  C.PolyLine(Pts);
end;

{------------------------------------------------------------------------------
  DiodeSeg
------------------------------------------------------------------------------
  Diode zwischen Anode (XA, YA) und Kathode (XK, YK), in jeder Richtung.
  Das Dreieck (18 Punkte breit, 16 lang) sitzt in der Mitte und zeigt zur
  Kathode, dort steht der Querstrich.
  Parameter: Netz  - True: an uSchemNetz melden (Name vorher mit NetzName)
             Color - Farbe
------------------------------------------------------------------------------}
procedure DiodeSeg(C: TCanvas; const M: TMap; XA, YA, XK, YK: Double; Netz: Boolean;
  Color: TColor);
var
  L: Double;                                             // Länge (Vorlage)
  DX, DY: Double;                                        // Richtung Anode -> Kathode, Länge 1
  NX, NY: Double;                                        // quer dazu, Länge 1
  BX, BY, TX, TY: Double;                                // Mitte der Grundlinie, Spitze
begin
  if Netz then
    NetzBauteil('D', ['A', 'K'], [XA, YA, XK, YK]);
  L := Sqrt(Sqr(XK - XA) + Sqr(YK - YA));
  if L <= 0 then Exit;
  DX := (XK - XA) / L;
  DY := (YK - YA) / L;
  NX := -DY;
  NY := DX;
  BX := (XA + XK) / 2 - 8 * DX;
  BY := (YA + YK) / 2 - 8 * DY;
  TX := (XA + XK) / 2 + 8 * DX;
  TY := (YA + YK) / 2 + 8 * DY;
  C.Pen.Color := Color;
  C.Pen.Width := MW(M, 1.6);
  C.Line(MX(M, XA), MY(M, YA), MX(M, BX), MY(M, BY));    // Anschluss Anode
  C.Line(MX(M, TX), MY(M, TY), MX(M, XK), MY(M, YK));    // Anschluss Kathode
  C.Brush.Style := bsSolid;
  C.Brush.Color := Color;
  C.Polygon([MP(M, BX + 9 * NX, BY + 9 * NY), MP(M, BX - 9 * NX, BY - 9 * NY), MP(M, TX, TY)]);
  C.Brush.Style := bsClear;
  C.Pen.Width := MW(M, 2.2);
  C.Line(MX(M, TX + 9 * NX), MY(M, TY + 9 * NY), MX(M, TX - 9 * NX), MY(M, TY - 9 * NY));  // Querstrich
  C.Pen.Width := MW(M, 1.6);
end;

{------------------------------------------------------------------------------
  Prepare
------------------------------------------------------------------------------
  Massstab bestimmen (Vorlage 580 × 300) und Stift, Schrift setzen.
  Rückgabe:  False, wenn kein Platz zum Zeichnen ist
------------------------------------------------------------------------------}
function Prepare(C: TCanvas; const Rect: TRect; const Col: TBlinkSchemColors; out M: TMap): Boolean;
begin
  M := MakeMap(Rect, 580, 300);
  Result := M.S > 0;
  if not Result then Exit;
  C.Font.Name := FONT_UI;
  C.Font.Height := SmoothFontHeight(9, 12 * M.S);
  C.Pen.Color := Col.Line;
  C.Pen.Width := MW(M, 1.6);
  C.Brush.Style := bsClear;
end;

{------------------------------------------------------------------------------
  LedTop
------------------------------------------------------------------------------
  Oberkante der ersten LED: mehr LEDs beginnen höher (eine 24, zwei 56,
  drei oder mit Punkten 88 Punkte hoch), wie beim LM317.
------------------------------------------------------------------------------}
function LedTop(N: Integer): Double;
begin
  if N >= 3 then Result := 156 else if N = 2 then Result := 168 else Result := 186;
end;

{------------------------------------------------------------------------------
  LedLabels
------------------------------------------------------------------------------
  Beschriftung rechts neben den LEDs und am Widerstand (beide Schaltungen
  gleich).
------------------------------------------------------------------------------}
procedure LedLabels(C: TCanvas; const M: TMap; const V: TAcSchemValues;
  const Col: TBlinkSchemColors);
begin
  Txt(C, M, 436, 96, V.RText, Col.Accent, 0, True);
  Txt(C, M, 436, 116, V.RSubText, Col.Dim, 0, False);
  if V.LedCount >= 2 then
  begin
    Txt(C, M, 462, 196, V.LedText, Col.Text, 0, False);
    Txt(C, M, 462, 216, V.UFText, Col.Dim, 0, False);
  end
  else
  begin
    Txt(C, M, 462, 198, V.LedText, Col.Text, 0, False);
    Txt(C, M, 462, 218, V.UFText, Col.Dim, 0, False);
  end;
end;

{==============================================================================
  SCHALTPLÄNE
==============================================================================}

{------------------------------------------------------------------------------
  DrawSchematicAcSimple - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Massstab
    2. Trafo links, Leitung oben zu R, Masse unten
    3. R und LEDs rechts senkrecht
    4. Schutzdiode links neben den LEDs, Kathode oben (antiparallel)
    5. Beschriftung
------------------------------------------------------------------------------}
procedure DrawSchematicAcSimple(Canvas: TCanvas; const Rect: TRect;
  const V: TAcSchemValues; const Col: TBlinkSchemColors);
var
  M: TMap;                                               // Vorlage -> Pixel
  C: TCanvas;                                            // Abkürzung
  Top, Bot: Double;                                      // Ober- und Unterkante der LEDs
begin
  // ----- 1. Massstab -----
  C := Canvas;
  if not Prepare(C, Rect, Col, M) then Exit;

  // ----- 2. Trafo und Leitungen -----
  Wire(C, M, [60, 148, 60, 60, 420, 60, 420, 72]);       // Trafo oben -> R
  Wire(C, M, [60, 192, 60, 280, 420, 280]);              // Trafo unten -> zurück
  AcSource(C, M, 60, 170, Col);

  // ----- 3. R und LEDs -----
  NetzName('R');
  ResBands(C, M, 420, 72, 120, V.Bands, Col);
  C.Pen.Color := Col.Line;                               // ResBands lässt dünnen Stift zurück
  C.Pen.Width := MW(M, 1.6);
  Top := LedTop(V.LedCount);
  Wire(C, M, [420, 120, 420, Top]);
  Bot := LedColumn(C, M, 420, Top, V.LedColor, V.LedCount, Col);
  Wire(C, M, [420, Bot, 420, 280]);

  // ----- 4. Schutzdiode antiparallel -----
  // Kathode oben (am Knoten zwischen R und erster LED), Anode unten an der
  // Rückleitung: In der negativen Halbwelle leitet die Diode und hält die
  // Sperrspannung an den LEDs bei etwa 0,7 V.
  Wire(C, M, [420, 150, 340, 150, 340, 183]);
  Wire(C, M, [340, 223, 340, 280]);
  NetzName('D');
  DiodeSeg(C, M, 340, 223, 340, 183, True, Col.Line);
  Dot(C, M, 420, 150, Col.Line);
  Dot(C, M, 340, 280, Col.Line);
  C.Pen.Color := Col.Line;

  // ----- 5. Beschriftung -----
  Txt(C, M, 96, 166, V.UText, Col.Text, 0, False);
  Txt(C, M, 96, 186, V.UPeakText, Col.Dim, 0, False);
  Txt(C, M, 326, 200, V.DiodeText, Col.Text, 2, False);
  Txt(C, M, 326, 220, V.DiodeSubText, Col.Dim, 2, False);
  LedLabels(C, M, V, Col);
end;

{------------------------------------------------------------------------------
  DrawSchematicAcBridge - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Massstab
    2. Trafo links an die beiden «~» des Gleichrichters
    3. Gleichrichter als Kasten, «+» oben rechts, «–» unten rechts
    4. Elko zwischen Plus und Minus (Plus oben)
    5. R und LEDs rechts senkrecht
    6. Beschriftung
------------------------------------------------------------------------------}
procedure DrawSchematicAcBridge(Canvas: TCanvas; const Rect: TRect;
  const V: TAcSchemValues; const Col: TBlinkSchemColors);
var
  M: TMap;                                               // Vorlage -> Pixel
  C: TCanvas;                                            // Abkürzung
  Top, Bot: Double;                                      // Ober- und Unterkante der LEDs
begin
  // ----- 1. Massstab -----
  C := Canvas;
  if not Prepare(C, Rect, Col, M) then Exit;

  // ----- 2. Trafo an den Gleichrichter -----
  Wire(C, M, [60, 148, 60, 130, 120, 130]);
  Wire(C, M, [60, 192, 60, 210, 120, 210]);
  AcSource(C, M, 60, 170, Col);

  // ----- 3. Gleichrichter -----
  Wire(C, M, [220, 130, 290, 130, 290, 60, 420, 60, 420, 72]);  // Plus -> R
  Wire(C, M, [220, 210, 290, 210, 290, 280, 420, 280]);         // Minus -> Rückleitung
  C.Brush.Style := bsSolid;
  C.Brush.Color := Col.Body;
  C.Pen.Width := MW(M, 1.6);
  SmoothRectangle(C, MX(M, 120), MY(M, 110), MX(M, 220), MY(M, 230));
  NetzName('GL');                                        // Anschlüsse am Rand des Kastens
  NetzBauteil('GL', ['~1', '~2', '+', '-'], [120, 130, 120, 210, 220, 130, 220, 210]);
  // Diodensymbol im Kasten (Zeichen für «Gleichrichter», kein eigenes Bauteil)
  DiodeSeg(C, M, 146, 170, 194, 170, False, Col.Line);

  // ----- 4. Elko -----
  Wire(C, M, [340, 60, 340, 158]);
  Wire(C, M, [340, 166, 340, 280]);
  NetzName('C');
  CapV(C, M, 340, 158, True, Col);
  Dot(C, M, 340, 60, Col.Line);
  Dot(C, M, 340, 280, Col.Line);
  C.Pen.Color := Col.Line;

  // ----- 5. R und LEDs -----
  NetzName('R');
  ResBands(C, M, 420, 72, 120, V.Bands, Col);
  C.Pen.Color := Col.Line;                               // ResBands lässt dünnen Stift zurück
  C.Pen.Width := MW(M, 1.6);
  Top := LedTop(V.LedCount);
  Wire(C, M, [420, 120, 420, Top]);
  Bot := LedColumn(C, M, 420, Top, V.LedColor, V.LedCount, Col);
  Wire(C, M, [420, Bot, 420, 280]);

  // ----- 6. Beschriftung -----
  Txt(C, M, 60, 254, V.UText, Col.Text, 1, False);
  Txt(C, M, 60, 274, V.UPeakText, Col.Dim, 1, False);
  Txt(C, M, 170, 254, V.BridgeText, Col.Text, 1, False);
  Txt(C, M, 318, 152, V.CapText, Col.Accent, 2, True);  // links vom Elko, die Platten reichen bis 326
  Txt(C, M, 318, 172, V.CapSubText, Col.Accent, 2, False);
  Txt(C, M, 300, 50, V.UDcText, Col.Dim, 0, False);
  C.Font.Height := SmoothFontHeight(8, 12 * M.S);        // Anschlussnamen
  Txt(C, M, 126, 126, '~', Col.Text, 0, False);
  Txt(C, M, 126, 224, '~', Col.Text, 0, False);
  Txt(C, M, 214, 126, '+', Col.Text, 2, False);
  Txt(C, M, 214, 224, '−', Col.Text, 2, False);       // Minuszeichen U+2212
  C.Font.Height := SmoothFontHeight(9, 12 * M.S);        // Schrift zurücksetzen
  LedLabels(C, M, V, Col);
end;

end.
