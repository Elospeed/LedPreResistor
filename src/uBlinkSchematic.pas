{==============================================================================
  uBlinkSchematic - Schaltpläne der Blinkschaltungen und Zeichenhilfen
==============================================================================
  Zweck:     Zeichnet im Reiter «Blinkschaltung» den Schaltplan mit den
             aktuellen Werten:
               - NE555 astabil            (Vorlage 580 × 320 Punkte)
               - Multivibrator, zwei
                 Transistoren             (Vorlage 600 × 300 Punkte)
             Die LEDs werden hell oder dunkel gezeichnet; so blinkt der
             Schaltplan im Takt der Schaltung mit.

  Idee:      Jeder Plan ist für eine feste Vorlage entworfen. TMap rechnet
             Vorlagen-Punkte in Pixel um (Massstab S, Versatz OX/OY), damit
             der Plan in jedes Rechteck passt. Strichstärken und Schrift
             wachsen mit.

  Zeichen-   Leitung (Wire), Punkt (Dot), Widerstand ohne/mit Ringen (ResV,
  hilfen:    ResBands), LED (LedDown), Kondensator (CapV, CapH), NPN-
             Transistor (Npn), Text (Txt). Sie werden auch von uKsqSchematic
             benutzt, damit alle Schaltpläne gleich aussehen.

  Symbole:   Transistor immer sauber: Kreis, Basisbalken, Kollektor und
             Emitter schräg, Pfeil am Emitter zeigt nach aussen (NPN).

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  geglättet, Transistorsymbole, Kommentare
             2.3  11.11.2026  neu: Schaltpläne NE555 und Multivibrator
==============================================================================}
unit uBlinkSchematic;

{$mode objfpc}{$H+}

interface

uses
  Types, Graphics, uColorCode, uBlink;

{==============================================================================
  TYPEN
==============================================================================}
type
  // Alles, was die Blink-Schaltpläne anzeigen, als fertiger Text.
  // Tiefgestellte Zeichen mit «_» (siehe uRichText), z. B. «R_V».
  TBlinkSchemValues = record
    UBText: string;                                      // Speisespannung, "U_B = 9 V"
    R1Text: string;                                      // "R1 = 1 kΩ" bzw. "R_B_1 = 33 kΩ"
    R2Text: string;                                      // "R2 = 68 kΩ" bzw. "R_B_2 = 33 kΩ"
    CText: string;                                       // "C = 10 µF"
    C2Text: string;                                      // Multivibrator: "C2 = 10 µF"
    RV1Text: string;                                     // Vorwiderstand, "R_V = 390 Ω"
    RV2Text: string;                                     // zweiter Vorwiderstand
    Led1Text: string;                                    // "LED rot" bzw. "LED 1"
    Led2Text: string;                                    // "LED 2"
    UOutText: string;                                    // NE555: "U_O_U_T ≈ 7,3 V"
    T1Text: string;                                      // Multivibrator: "T1 BC547"
    T2Text: string;                                      // Multivibrator: "T2 BC547"
    LedColor: TColor;                                    // Leuchtfarbe der LEDs
    Led1Lit: Boolean;                                    // LED 1 leuchtet gerade
    Led2Lit: Boolean;                                    // LED 2 leuchtet gerade
    Bands1: TBandArray;                                  // Farbringe Vorwiderstand 1 (leer = ohne)
    Bands2: TBandArray;                                  // Farbringe Vorwiderstand 2
    Diode: Boolean;                                      // NE555: Diode über R2 eingezeichnet
    Conn: TLedConn;                                      // NE555: Anschluss der LED(s)
    Elko: Boolean;                                       // Zeitkondensator ist ein Elko (Plus-Zeichen)
  end;

  // Farben für die Zeichnung
  TBlinkSchemColors = record
    Line: TColor;                                        // Leitungen
    Text: TColor;                                        // Beschriftung
    Accent: TColor;                                      // Werte der Bauteile
    Dim: TColor;                                         // Pin-Nummern, Nebentext
    Body: TColor;                                        // Füllung der Bauteile (Hintergrund)
    LedOff: TColor;                                      // LED dunkel
  end;

{==============================================================================
  ÖFFENTLICHE FUNKTIONEN: SCHALTPLÄNE
==============================================================================}

{------------------------------------------------------------------------------
  DrawSchematic555
------------------------------------------------------------------------------
  Zeichnet den NE555 als astabilen Kippschalter mit R1, R2, C (Zeitglied)
  und der LED bzw. den LEDs am Ausgang (Pin 3). Je nach Anschluss (V.Conn)
  liegt die LED nach Masse, nach +U_B oder beides (Wechselblinker).
  Parameter: Canvas - Leinwand
             Rect   - verfügbarer Platz; die Vorlage wird eingepasst
             V      - Texte, Farbringe, LED-Zustand, Diode, Anschluss
             Col    - Farben
------------------------------------------------------------------------------}
procedure DrawSchematic555(Canvas: TCanvas; const Rect: TRect;
  const V: TBlinkSchemValues; const Col: TBlinkSchemColors);

{------------------------------------------------------------------------------
  DrawSchematicMulti
------------------------------------------------------------------------------
  Zeichnet den astabilen Multivibrator: zwei Transistoren, die sich über
  die Kondensatoren C1 und C2 gegenseitig ein- und ausschalten. In jedem
  Kollektorzweig liegen Vorwiderstand und LED; sie blinken abwechselnd.
  Parameter: wie DrawSchematic555
------------------------------------------------------------------------------}
procedure DrawSchematicMulti(Canvas: TCanvas; const Rect: TRect;
  const V: TBlinkSchemValues; const Col: TBlinkSchemColors);

{==============================================================================
  ZEICHENHILFEN (auch für uKsqSchematic)
==============================================================================}

type
  // Umrechnung Vorlage -> Pixel: Pixel = Versatz + Vorlagen-Punkt × S
  TMap = record
    S: Double;                                           // Massstab: Pixel pro Vorlagen-Punkt
    OX, OY: Double;                                      // Versatz links/oben, damit der Plan mittig sitzt
  end;

{------------------------------------------------------------------------------
  MakeMap
------------------------------------------------------------------------------
  Passt eine Vorlage der Grösse BW × BH so gross wie möglich und mittig
  in Rect ein.
  Rückgabe:  Umrechnung; S <= 0 heisst: kein Platz, nichts zeichnen
------------------------------------------------------------------------------}
function MakeMap(const Rect: TRect; BW, BH: Double): TMap;
{------------------------------------------------------------------------------
  MX
------------------------------------------------------------------------------
  MX, MY und MP rechnen Vorlagen-Koordinaten in Pixel um:
  MX waagrecht, MY senkrecht, MP beides als Punkt.
------------------------------------------------------------------------------}
function MX(const M: TMap; V: Double): Integer;
function MY(const M: TMap; V: Double): Integer;
function MP(const M: TMap; X, Y: Double): TPoint;
{------------------------------------------------------------------------------
  MW
------------------------------------------------------------------------------
  Rechnet eine Länge bzw. Strichstärke der Vorlage in Pixel um
  (mindestens 1).
------------------------------------------------------------------------------}
function MW(const M: TMap; V: Double): Integer;
{------------------------------------------------------------------------------
  Txt
------------------------------------------------------------------------------
  Schreibt einen Text mit Auszeichnung (uRichText, Tiefstellung mit «_»).
  Parameter: BX, BaseY - Ankerpunkt in der Vorlage; BaseY = Grundlinie
             T         - Text; leer = nichts
             Color     - Farbe
             Align     - 0 = links, 1 = Mitte, 2 = rechts am Ankerpunkt
             Bold      - fett
------------------------------------------------------------------------------}
procedure Txt(C: TCanvas; const M: TMap; BX, BaseY: Double; const T: string;
  Color: TColor; Align: Integer; Bold: Boolean);
{------------------------------------------------------------------------------
  Wire
------------------------------------------------------------------------------
  Zeichnet eine Leitung durch die Punkte der Vorlage.
  Parameter: P - Koordinaten paarweise: [X1, Y1, X2, Y2, ...]
------------------------------------------------------------------------------}
procedure Wire(C: TCanvas; const M: TMap; const P: array of Double);
{------------------------------------------------------------------------------
  Dot
------------------------------------------------------------------------------
  Zeichnet einen Verbindungspunkt (Knoten, an dem Leitungen verbunden
  sind) bei (X, Y) in der Vorlage.
------------------------------------------------------------------------------}
procedure Dot(C: TCanvas; const M: TMap; X, Y: Double; Color: TColor);
{------------------------------------------------------------------------------
  ResV
------------------------------------------------------------------------------
  Zeichnet einen Widerstand senkrecht als Rechteck ohne Farbringe
  (Zeitglied), Mitte X, von Y1 bis Y2.
------------------------------------------------------------------------------}
procedure ResV(C: TCanvas; const M: TMap; X, Y1, Y2: Double; const Col: TBlinkSchemColors);
{------------------------------------------------------------------------------
  ResBands
------------------------------------------------------------------------------
  Zeichnet einen Widerstand senkrecht mit Farbringen (beiger Körper wie
  im Hauptschaltplan), Mitte X, von Y1 bis Y2. Bands leer = ohne Ringe.
------------------------------------------------------------------------------}
procedure ResBands(C: TCanvas; const M: TMap; X, Y1, Y2: Double; const Bands: TBandArray;
  const Col: TBlinkSchemColors);
{------------------------------------------------------------------------------
  LedDown
------------------------------------------------------------------------------
  Zeichnet eine LED, Spitze nach unten (Anode oben), von Top bis Top + 24.
  Parameter: Lit - True: in der Leuchtfarbe mit Lichtpfeilen,
                   False: dunkel (ausgeschaltet)
             V   - davon wird nur V.LedColor gebraucht
------------------------------------------------------------------------------}
procedure LedDown(C: TCanvas; const M: TMap; X, Top: Double; Lit: Boolean;
  const V: TBlinkSchemValues; const Col: TBlinkSchemColors);
{------------------------------------------------------------------------------
  Npn
------------------------------------------------------------------------------
  Zeichnet einen NPN-Transistor: Kreis, Basisbalken, Kollektor oben,
  Emitter unten mit Pfeil nach aussen.
  Parameter: CX, CY   - Mitte des Kreises (Vorlage)
             PX       - senkrechte Leitung, an der Kollektor und Emitter
                        enden
             FromLeft - True: Basis kommt von links, sonst von rechts
------------------------------------------------------------------------------}
procedure Npn(C: TCanvas; const M: TMap; CX, CY, PX: Double; FromLeft: Boolean;
  const Col: TBlinkSchemColors);

implementation

uses
  Math, uTheme, uRichText, uSmooth;

{==============================================================================
  ZEICHENHILFEN
==============================================================================}

{------------------------------------------------------------------------------
  MakeMap - siehe Interface
------------------------------------------------------------------------------}
function MakeMap(const Rect: TRect; BW, BH: Double): TMap;
begin
  Result.S := Min((Rect.Right - Rect.Left) / BW, (Rect.Bottom - Rect.Top) / BH);  // knappere Richtung
  Result.OX := Rect.Left + ((Rect.Right - Rect.Left) - BW * Result.S) / 2;
  Result.OY := Rect.Top + ((Rect.Bottom - Rect.Top) - BH * Result.S) / 2;
end;

{------------------------------------------------------------------------------
  MX - siehe Interface
------------------------------------------------------------------------------}
function MX(const M: TMap; V: Double): Integer;
begin
  Result := SmoothCoord(M.OX + V * M.S);
end;

{------------------------------------------------------------------------------
  MY - siehe Interface (MX)
------------------------------------------------------------------------------}
function MY(const M: TMap; V: Double): Integer;
begin
  Result := SmoothCoord(M.OY + V * M.S);
end;

{------------------------------------------------------------------------------
  MP - siehe Interface (MX)
------------------------------------------------------------------------------}
function MP(const M: TMap; X, Y: Double): TPoint;
begin
  Result := Point(MX(M, X), MY(M, Y));
end;

{------------------------------------------------------------------------------
  MW - siehe Interface
------------------------------------------------------------------------------}
function MW(const M: TMap; V: Double): Integer;
begin
  Result := SmoothWidth(V * M.S);
end;

{------------------------------------------------------------------------------
  Txt
------------------------------------------------------------------------------
  siehe Interface. Beim Glätten (uSmooth) wird der Text nur gemerkt und
  nach dem Verkleinern scharf gezeichnet.
------------------------------------------------------------------------------}
procedure Txt(C: TCanvas; const M: TMap; BX, BaseY: Double; const T: string;
  Color: TColor; Align: Integer; Bold: Boolean);
var
  TW, TX, TY: Integer;                                   // Breite und Startpunkt
begin
  if T = '' then Exit;
  if SmoothCapturing then
  begin
    // geglättet: Text erst nach dem Verkleinern scharf zeichnen
    SmoothAddText(C, MX(M, BX), MY(M, BaseY), T, Color, Align, Bold);
    Exit;
  end;
  if Bold then C.Font.Style := [fsBold] else C.Font.Style := [];
  TW := RichWidth(C, T);
  case Align of
    1: TX := MX(M, BX) - TW div 2;
    2: TX := MX(M, BX) - TW;
  else
    TX := MX(M, BX);
  end;
  TY := MY(M, BaseY) - C.TextHeight('Ag') * 4 div 5;     // Grundlinie -> Oberkante
  C.Brush.Style := bsClear;
  DrawRich(C, TX, TY, T, Color, Color);
  C.Font.Style := [];
end;

{------------------------------------------------------------------------------
  Wire
------------------------------------------------------------------------------
  siehe Interface
------------------------------------------------------------------------------}
procedure Wire(C: TCanvas; const M: TMap; const P: array of Double);
var
  Pts: array of TPoint;                                  // Punkte in Pixeln
  I: Integer;                                            // Zähler
begin
  SetLength(Pts, Length(P) div 2);                       // je 2 Zahlen = 1 Punkt
  for I := 0 to High(Pts) do
    Pts[I] := MP(M, P[2 * I], P[2 * I + 1]);
  C.PolyLine(Pts);
end;

{------------------------------------------------------------------------------
  Dot
------------------------------------------------------------------------------
  siehe Interface
------------------------------------------------------------------------------}
procedure Dot(C: TCanvas; const M: TMap; X, Y: Double; Color: TColor);
var
  R: Integer;                                            // Radius in Pixeln
begin
  R := Max(2, Round(2.8 * M.S));                         // Radius 2,8 Punkte, mind. 2 Pixel
  C.Brush.Style := bsSolid;
  C.Brush.Color := Color;
  C.Pen.Color := Color;
  C.Ellipse(MX(M, X) - R, MY(M, Y) - R, MX(M, X) + R + 1, MY(M, Y) + R + 1);
end;

{------------------------------------------------------------------------------
  ResV
------------------------------------------------------------------------------
  siehe Interface. Rand in der Hervorhebungsfarbe, weil die Werte der
  Zeitglieder hervorgehoben beschriftet sind.
------------------------------------------------------------------------------}
procedure ResV(C: TCanvas; const M: TMap; X, Y1, Y2: Double; const Col: TBlinkSchemColors);
begin
  C.Brush.Style := bsSolid;
  C.Brush.Color := Col.Body;
  C.Pen.Color := Col.Accent;
  C.Pen.Width := MW(M, 1.8);
  SmoothRectangle(C, MX(M, X - 9), MY(M, Y1), MX(M, X + 9), MY(M, Y2));
  C.Pen.Color := Col.Line;
end;

{------------------------------------------------------------------------------
  ResBands
------------------------------------------------------------------------------
  siehe Interface
  Ablauf:
    1. Rand und Körper als gefüllte Flächen auf ganzen Bildpunkten
    2. Ringe: Ziffern und Multiplikator oben gruppiert, Toleranz unten
       abgesetzt (Leserichtung von oben nach unten)
------------------------------------------------------------------------------}
procedure ResBands(C: TCanvas; const M: TMap; X, Y1, Y2: Double; const Bands: TBandArray;
  const Col: TBlinkSchemColors);
var
  I, N, Y: Integer;                                      // Ring-Zähler, Anzahl, Lage
  T, B: Integer;                                         // Ober- und Unterkante in Pixeln
  L, R: Integer;                                         // linke und rechte Kante
  BH: Integer;                                           // Höhe eines Rings
  P: Integer;                                            // ein Bildpunkt (beim Glätten mehrere Pixel)
begin
  // ----- 1. Rand und Körper -----
  // Rand und Ringe als gefüllte Flächen auf ganzen Bildpunkten, damit sie
  // auch geglättet scharf bleiben (Stiftbreite 1: Kanten ohne Versatz)
  C.Pen.Width := 1;
  P := SmoothPx(1);
  L := MX(M, X - 9);
  R := MX(M, X + 9);
  T := MY(M, Y1);
  B := MY(M, Y2);
  C.Brush.Style := bsSolid;
  C.Brush.Color := clrResistorEdge;
  C.FillRect(L, T, R, B);                                // Rand (ganze Fläche)
  C.Brush.Color := clrResistorBody;
  C.FillRect(L + P, T + P, R - P, B - P);                // Körper 1 Bildpunkt kleiner
  // ----- 2. Ringe -----
  N := Length(Bands);
  if N >= 3 then
  begin
    BH := Max(2 * P, (B - T) * 8 div 100);               // Ring = 8 % der Länge
    BH := BH - BH mod P;                                 // auf ganze Bildpunkte
    for I := 0 to N - 1 do
    begin
      if I < N - 1 then
        Y := T + (B - T) * (12 + I * (52 div (N - 1))) div 100  // gleichmässig ab 12 %
      else
        Y := T + (B - T) * 80 div 100;                   // Toleranzring bei 80 %
      Y := Y - (Y - T) mod P;                            // auf ganze Bildpunkte
      C.Brush.Color := BandScreenColor(Bands[I]);
      C.FillRect(L + P, Y, R - P, Y + BH);
    end;
  end;
  C.Pen.Color := Col.Line;
end;

{------------------------------------------------------------------------------
  LedDown
------------------------------------------------------------------------------
  siehe Interface. Die Lichtpfeile zeigen nach rechts oben.
------------------------------------------------------------------------------}
procedure LedDown(C: TCanvas; const M: TMap; X, Top: Double; Lit: Boolean;
  const V: TBlinkSchemValues; const Col: TBlinkSchemColors);
begin
  C.Pen.Color := Col.Line;
  C.Pen.Width := MW(M, 1.6);
  C.Brush.Style := bsSolid;
  if Lit then C.Brush.Color := V.LedColor else C.Brush.Color := Col.LedOff;
  C.Polygon([MP(M, X - 14, Top), MP(M, X + 14, Top), MP(M, X, Top + 24)]);  // Dreieck
  C.Pen.Width := MW(M, 2.2);
  C.Line(MX(M, X - 14), MY(M, Top + 24), MX(M, X + 14), MY(M, Top + 24));  // Querstrich (Kathode)
  if Lit then
  begin
    C.Pen.Color := V.LedColor;
    C.Pen.Width := MW(M, 1.6);
    C.Line(MX(M, X + 18), MY(M, Top + 6), MX(M, X + 32), MY(M, Top - 4));  // Lichtpfeile
    C.Line(MX(M, X + 22), MY(M, Top + 16), MX(M, X + 36), MY(M, Top + 6));
    C.Brush.Color := V.LedColor;
    C.Pen.Width := 1;
    C.Polygon([MP(M, X + 32, Top - 4), MP(M, X + 24, Top - 3), MP(M, X + 28, Top + 3)]);  // Pfeilspitzen
    C.Polygon([MP(M, X + 36, Top + 6), MP(M, X + 28, Top + 7), MP(M, X + 32, Top + 13)]);
  end;
  C.Pen.Color := Col.Line;
  C.Pen.Width := MW(M, 1.6);
end;

{------------------------------------------------------------------------------
  CapV
------------------------------------------------------------------------------
  Zeichnet einen Kondensator in einer senkrechten Leitung: zwei
  waagrechte Platten bei Y und Y + 8.
  Parameter: Elko - True: Plus-Zeichen an die obere Platte
------------------------------------------------------------------------------}
procedure CapV(C: TCanvas; const M: TMap; X, Y: Double; Elko: Boolean; const Col: TBlinkSchemColors);
begin
  C.Pen.Width := MW(M, 2.4);
  C.Line(MX(M, X - 14), MY(M, Y), MX(M, X + 14), MY(M, Y));
  C.Line(MX(M, X - 14), MY(M, Y + 8), MX(M, X + 14), MY(M, Y + 8));
  C.Pen.Width := MW(M, 1.6);
  if Elko then
    Txt(C, M, X + 17, Y - 1, '+', Col.Dim, 0, False);
end;

{------------------------------------------------------------------------------
  CapH
------------------------------------------------------------------------------
  Zeichnet einen Kondensator in einer waagrechten Leitung: zwei
  senkrechte Platten bei X und X + 8.
  Parameter: Elko      - True: Plus-Zeichen zeichnen
             PlusRight - Pluspol an der rechten Platte (sonst links)
------------------------------------------------------------------------------}
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

{==============================================================================
  SCHALTPLÄNE
==============================================================================}

{------------------------------------------------------------------------------
  DrawSchematic555 - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Massstab bestimmen (Vorlage 580 × 320 einpassen)
    2. Speiseleitungen und Zeitglied R1, R2, C (optional Diode über R2)
    3. Pins 8, 4, 1 und 5 anschliessen
    4. IC-Gehäuse
    5. Ausgang Pin 3 mit LED(s) und Vorwiderstand
    6. Beschriftung
------------------------------------------------------------------------------}
procedure DrawSchematic555(Canvas: TCanvas; const Rect: TRect;
  const V: TBlinkSchemValues; const Col: TBlinkSchemColors);
var
  M: TMap;                                               // Vorlage -> Pixel
  C: TCanvas;                                            // Abkürzung
  OutEnd: Double;                                        // rechtes Ende der Ausgangsleitung
begin
  // ----- 1. Massstab -----
  M := MakeMap(Rect, 580, 320);
  if M.S <= 0 then Exit;
  C := Canvas;
  C.Font.Name := FONT_UI;
  C.Font.Height := SmoothFontHeight(9, 12 * M.S);
  C.Pen.Color := Col.Line;
  C.Pen.Width := MW(M, 1.6);
  C.Brush.Style := bsClear;

  // ----- 2. Speiseleitungen und Zeitglied -----
  Wire(C, M, [60, 30, 520, 30]);                         // +U_B
  Wire(C, M, [60, 295, 520, 295]);                       // Masse
  // R1 und R2 in Reihe, dazwischen Pin 7
  Wire(C, M, [170, 30, 170, 48]);                        // +U_B -> R1
  Wire(C, M, [170, 92, 170, 132]);                       // R1 -> R2
  Wire(C, M, [170, 120, 250, 120]);                      // Knoten -> Pin 7
  Wire(C, M, [170, 176, 170, 236]);                      // R2 -> C
  Wire(C, M, [170, 185, 220, 185]);                      // Knoten -> Pin 6/2
  Wire(C, M, [250, 170, 220, 170, 220, 200, 250, 200]);  // Pin 6 und Pin 2 verbunden
  Wire(C, M, [170, 244, 170, 295]);                      // C -> Masse
  // Diode über R2 (Anode unten an Pin 6/2, Kathode oben an Pin 7)
  if V.Diode then
  begin
    Wire(C, M, [170, 124, 136, 124, 136, 140]);
    Wire(C, M, [136, 166, 136, 181, 170, 181]);
    C.Brush.Style := bsSolid;
    C.Brush.Color := Col.Line;
    C.Polygon([MP(M, 126, 166), MP(M, 146, 166), MP(M, 136, 146)]);  // Dreieck, Spitze oben
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

  // ----- 3. Pins 8 und 4 an +U_B, Pin 1 an Masse, Pin 5 über 10 nF an Masse -----
  Wire(C, M, [276, 90, 276, 30]);
  Wire(C, M, [336, 90, 336, 30]);
  Wire(C, M, [310, 250, 310, 295]);
  Wire(C, M, [370, 220, 400, 220, 400, 250]);
  Wire(C, M, [400, 258, 400, 295]);
  CapV(C, M, 400, 250, False, Col);

  // ----- 4. IC-Gehäuse -----
  C.Brush.Style := bsSolid;
  C.Brush.Color := Col.Body;
  C.Pen.Color := Col.Line;
  C.Pen.Width := MW(M, 1.6);
  SmoothRectangle(C, MX(M, 250), MY(M, 90), MX(M, 370), MY(M, 250));

  // ----- 5. Ausgang Pin 3 nach rechts -----
  case V.Conn of
    cnGnd: OutEnd := 470;                                // LED nach Masse (rechts)
    cnVcc: OutEnd := 430;                                // LED nach +U_B (weiter links)
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

  // ----- 6. Beschriftung -----
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
  C.Font.Height := SmoothFontHeight(8, 16 * M.S);
  Txt(C, M, 316, 196, 'NE555', Col.Text, 1, True);       // gross im Gehäuse
  C.Font.Height := SmoothFontHeight(7, 10 * M.S);        // Pin-Namen klein
  Txt(C, M, 254, 124, '7 DIS', Col.Dim, 0, False);
  Txt(C, M, 254, 174, '6 THR', Col.Dim, 0, False);
  Txt(C, M, 254, 204, '2 TRI', Col.Dim, 0, False);
  Txt(C, M, 366, 154, 'OUT 3', Col.Dim, 2, False);
  Txt(C, M, 366, 224, 'CV 5', Col.Dim, 2, False);
  Txt(C, M, 270, 104, '8', Col.Dim, 0, False);
  Txt(C, M, 331, 104, '4', Col.Dim, 0, False);
  Txt(C, M, 304, 244, '1', Col.Dim, 0, False);
  C.Font.Height := SmoothFontHeight(9, 12 * M.S);
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

{------------------------------------------------------------------------------
  Npn
------------------------------------------------------------------------------
  siehe Interface
  Ablauf:
    1. Kreis und Basisbalken
    2. Kollektor und Emitter schräg zur Leitung X = PX
    3. Pfeil am Emitter: Richtung der Emitterlinie als Einheitsvektor
       (DX, DY), Spitze 3 Punkte vor dem Ende, Basis 12 Punkte dahinter,
       5 Punkte breit nach jeder Seite
------------------------------------------------------------------------------}
procedure Npn(C: TCanvas; const M: TMap; CX, CY, PX: Double; FromLeft: Boolean;
  const Col: TBlinkSchemColors);
var
  BX: Double;                                            // Lage des Basisbalkens
  DX, DY, L: Double;                                     // Richtung des Emitters
  TX, TY: Double;                                        // Pfeilspitze
  Bx2, By2: Double;                                      // Mitte der Pfeilbasis
begin
  // ----- 1. Kreis und Basisbalken -----
  if FromLeft then BX := CX - 14 else BX := CX + 14;
  C.Brush.Style := bsClear;
  C.Pen.Color := Col.Line;
  C.Pen.Width := MW(M, 1.6);
  C.Ellipse(MX(M, CX - 25), MY(M, CY - 25), MX(M, CX + 25), MY(M, CY + 25));  // Kreis, Radius 25
  C.Pen.Width := MW(M, 3);
  C.Line(MX(M, BX), MY(M, CY - 17), MX(M, BX), MY(M, CY + 17));
  C.Pen.Width := MW(M, 1.6);
  // ----- 2. Kollektor und Emitter schräg zur senkrechten Leitung -----
  Wire(C, M, [BX, CY - 8, PX, CY - 22]);                 // Kollektor
  Wire(C, M, [BX, CY + 8, PX, CY + 22]);                 // Emitter
  // ----- 3. Pfeil am Emitter zeigt nach aussen (NPN) -----
  DX := PX - BX;
  DY := 14;                                              // Emitter fällt 14 Punkte
  L := Sqrt(DX * DX + DY * DY);                          // Länge -> Einheitsvektor
  DX := DX / L;
  DY := DY / L;
  TX := PX - DX * 3;
  TY := CY + 22 - DY * 3;
  Bx2 := TX - DX * 12;
  By2 := TY - DY * 12;
  C.Brush.Style := bsSolid;
  C.Brush.Color := Col.Line;
  C.Pen.Width := 1;
  C.Polygon([MP(M, TX, TY), MP(M, Bx2 + DY * 5, By2 - DX * 5), MP(M, Bx2 - DY * 5, By2 + DX * 5)]);  // Spitze, zwei Ecken quer
  C.Pen.Width := MW(M, 1.6);
end;

{------------------------------------------------------------------------------
  DrawSchematicMulti - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Massstab bestimmen (Vorlage 600 × 300 einpassen)
    2. Leitungen: zwei Kollektorzweige, Basiswiderstände, Kreuzkopplung
    3. Bauteile und Verbindungspunkte
    4. Beschriftung
------------------------------------------------------------------------------}
procedure DrawSchematicMulti(Canvas: TCanvas; const Rect: TRect;
  const V: TBlinkSchemValues; const Col: TBlinkSchemColors);
var
  M: TMap;                                               // Vorlage -> Pixel
  C: TCanvas;                                            // Abkürzung
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

  // ----- 2. Leitungen -----
  Wire(C, M, [60, 25, 560, 25]);                         // +U_B
  Wire(C, M, [60, 285, 560, 285]);                       // Masse
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
  // ----- 3. Bauteile -----
  // Pluspol jeweils auf der Seite des Kollektors (dort ist die Spannung höher)
  CapH(C, M, 180, 150, V.Elko, False, Col);
  CapH(C, M, 412, 180, V.Elko, True, Col);
  ResBands(C, M, 120, 40, 78, V.Bands1, Col);
  ResBands(C, M, 480, 40, 78, V.Bands2, Col);
  LedDown(C, M, 120, 94, V.Led1Lit, V, Col);
  LedDown(C, M, 480, 94, V.Led2Lit, V, Col);
  ResV(C, M, 240, 45, 95, Col);
  ResV(C, M, 360, 45, 95, Col);
  Npn(C, M, 132, 230, 120, False, Col);                  // T1, Basis von rechts
  Npn(C, M, 468, 230, 480, True, Col);                   // T2, Basis von links
  Dot(C, M, 120, 150, Col.Line);
  Dot(C, M, 360, 150, Col.Line);
  Dot(C, M, 480, 180, Col.Line);
  Dot(C, M, 240, 180, Col.Line);
  Dot(C, M, 240, 25, Col.Line);
  Dot(C, M, 360, 25, Col.Line);
  C.Pen.Color := Col.Line;

  // ----- 4. Beschriftung -----
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
