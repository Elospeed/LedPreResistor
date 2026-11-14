{==============================================================================
  uSchematic - Schaltplan «LED mit Vorwiderstand» und Widerstand mit Ringen
==============================================================================
  Zweck:     Zeichnet im Reiter «LED-Vorwiderstand» den Schaltplan mit den
             aktuellen Werten (Speisespannung U_B, Widerstand R, Spannung am
             Widerstand U_R, Durchlassspannung U_F, Strom I) und den
             Widerstand mit seinen Farbringen.

  Idee:      Der Plan ist für eine feste Vorlage von 460 × 240 Punkten
             entworfen (Entwurf A «Labor 2»). Beim Zeichnen wird er in das
             übergebene Rechteck eingepasst: Faktor S = Pixel pro Punkt,
             OX/OY = Versatz, damit er mittig sitzt. So passt er bei jeder
             Fenstergrösse und Bildschirm-Skalierung.

  Aufbau:    links die Quelle (+ oben, − unten), oben der Widerstand,
             rechts die LED mit zwei Lichtpfeilen, unten der Stromrichtungs-
             pfeil. Die Beschriftungen kommen fertig als Text in
             TSchematicValues (uMain baut sie, Tiefstellung mit «_»).

  Technik:   Nur LCL-Canvas. Geglättet wird über uSmooth (vergrössert
             zeichnen, dann verkleinern); die Texte werden erst danach scharf
             darübergeschrieben.

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  geglättet (uSmooth), Stränge parallel, Kommentare
             2.0  29.10.2026  erste Fassung
==============================================================================}
unit uSchematic;

{$mode objfpc}{$H+}

interface

uses
  Types, Graphics, uColorCode;

{==============================================================================
  TYPEN
==============================================================================}
type
  // Alles, was der Schaltplan anzeigt, bereits als fertiger Text.
  // Tiefgestellte Zeichen mit «_» (siehe uRichText), z. B. «U_B».
  TSchematicValues = record
    RText: string;                                       // z. B. "R = 470 Ω"
    URText: string;                                      // z. B. "U_R = 8,8 V"
    UBText: string;                                      // z. B. "U_B = 12 V"
    LedText: string;                                     // z. B. "LED weiss" oder "3 × LED weiss" (in Reihe)
    UFText: string;                                      // z. B. "U_F = 3,2 V"
    IText: string;                                       // z. B. "I = 18,72 mA"
    StringsText: string;                                 // z. B. "× 3 Stränge parallel" (leer = ein Strang)
    LedColor: TColor;                                    // Füllfarbe des LED-Symbols
    Bands: TBandArray;                                   // Farbringe im Widerstand (leer = ohne Ringe)
  end;

{==============================================================================
  ÖFFENTLICHE FUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  DrawSchematic
------------------------------------------------------------------------------
  Zeichnet den Schaltplan in Rect. Der Hintergrund wird nicht gefüllt.
  Parameter: Canvas      - Leinwand
             Rect        - verfügbarer Platz; der Plan wird eingepasst
             V           - alle Texte, LED-Farbe und Farbringe
             LineColor   - Farbe der Leitungen und Symbole
             TextColor   - Farbe der normalen Beschriftung
             AccentColor - Farbe für R, I und den Strompfeil (hervorgehoben)
             BodyColor   - Füllung des Widerstandskastens
------------------------------------------------------------------------------}
procedure DrawSchematic(Canvas: TCanvas; const Rect: TRect; const V: TSchematicValues;
  LineColor, TextColor, AccentColor, BodyColor: TColor);

{------------------------------------------------------------------------------
  DrawResistor
------------------------------------------------------------------------------
  Zeichnet einen Widerstand mit Farbringen waagrecht in Rect, so wie er
  als Bauteil aussieht: Anschlussdraht, beiger Körper mit runden Enden,
  darauf die Ringe.
  Parameter: Canvas - Leinwand
             Rect   - Platz für Draht und Körper
             Bands  - Ringe von links nach rechts (aus uColorCode);
                      weniger als 3 Ringe = Körper ohne Ringe
------------------------------------------------------------------------------}
procedure DrawResistor(Canvas: TCanvas; const Rect: TRect; const Bands: TBandArray);

implementation

uses
  Math, uTheme, uRichText, uSmooth;

{------------------------------------------------------------------------------
  DrawResistor - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Draht quer durch die Mitte
    2. Körper von 20 % bis 80 % der Breite
    3. Ringe: Ziffern und Multiplikator links gruppiert, Toleranz rechts
       abgesetzt (so erkennt man die Leserichtung)
------------------------------------------------------------------------------}
procedure DrawResistor(Canvas: TCanvas; const Rect: TRect; const Bands: TBandArray);
var
  W, H: Integer;                                         // Grösse des Rechtecks
  BodyL, BodyR: Integer;                                 // linker und rechter Rand des Körpers
  BodyT, BodyB: Integer;                                 // obere und untere Kante des Körpers
  BW: Integer;                                           // Breite eines Rings
  I, X: Integer;                                         // Ring-Zähler und Position
  N: Integer;                                            // Anzahl Ringe
begin
  W := Rect.Right - Rect.Left;
  H := Rect.Bottom - Rect.Top;
  if (W < 20) or (H < 6) then Exit;                      // zu klein zum Zeichnen
  // ----- 1. Draht -----
  Canvas.Pen.Color := clrWire;
  Canvas.Pen.Width := Max(1, H div 12);
  Canvas.Line(Rect.Left, Rect.Top + H div 2, Rect.Right, Rect.Top + H div 2);
  // ----- 2. Körper (20 % bis 80 % der Breite) -----
  BodyL := Rect.Left + W * 20 div 100;
  BodyR := Rect.Left + W * 80 div 100;
  BodyT := Rect.Top + H div 7;
  BodyB := Rect.Bottom - H div 7;
  Canvas.Pen.Width := SmoothPx(1);
  Canvas.Pen.Color := clrResistorEdge;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := clrResistorBody;
  Canvas.RoundRect(BodyL, BodyT, BodyR, BodyB, (BodyB - BodyT) * 4 div 5, (BodyB - BodyT) * 4 div 5);
  // ----- 3. Ringe -----
  N := Length(Bands);
  if N < 3 then Exit;
  BW := Max(2, (BodyR - BodyL) * 9 div 100);             // Ring = 9 % der Körperbreite
  Canvas.Pen.Style := psClear;                           // Ringe ohne Rand
  for I := 0 to N - 1 do
  begin
    if I < N - 1 then
      X := BodyL + (BodyR - BodyL) * (15 + I * (55 div (N - 1))) div 100  // gleichmässig ab 15 %
    else
      X := BodyL + (BodyR - BodyL) * 78 div 100;         // Toleranzring bei 78 %
    Canvas.Brush.Color := BandScreenColor(Bands[I]);
    Canvas.Rectangle(X, BodyT + 1, X + BW, BodyB);
  end;
  Canvas.Pen.Style := psSolid;
end;

{------------------------------------------------------------------------------
  DrawSchematic - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Massstab S und Versatz OX/OY bestimmen (Vorlage 460 × 240 einpassen)
    2. Leitungen
    3. Quelle (Batterie-Symbol)
    4. Widerstand mit Farbringen
    5. LED-Symbol mit Lichtpfeilen
    6. Pfeil für die Stromrichtung
    7. Beschriftung
------------------------------------------------------------------------------}
procedure DrawSchematic(Canvas: TCanvas; const Rect: TRect; const V: TSchematicValues;
  LineColor, TextColor, AccentColor, BodyColor: TColor);
var
  S: Double;                                             // Pixel pro Vorlagen-Punkt
  OX, OY: Double;                                        // Versatz für die Zentrierung

  {----------------------------------------------------------------------------
    X
  ----------------------------------------------------------------------------
    Rechnet eine waagrechte Vorlagen-Koordinate (0 ... 460) in Pixel um.
  ----------------------------------------------------------------------------}
  function X(V: Double): Integer;
  begin
    Result := SmoothCoord(OX + V * S);
  end;

  {----------------------------------------------------------------------------
    Y
  ----------------------------------------------------------------------------
    Rechnet eine senkrechte Vorlagen-Koordinate (0 ... 240) in Pixel um.
  ----------------------------------------------------------------------------}
  function Y(V: Double): Integer;
  begin
    Result := SmoothCoord(OY + V * S);
  end;

  {----------------------------------------------------------------------------
    PW
  ----------------------------------------------------------------------------
    Rechnet eine Strichstärke der Vorlage in Pixel um (mindestens 1).
  ----------------------------------------------------------------------------}
  function PW(V: Double): Integer;
  begin
    Result := SmoothWidth(V * S);
  end;

  {----------------------------------------------------------------------------
    Txt
  ----------------------------------------------------------------------------
    Schreibt einen Text mit Auszeichnung (Tiefstellung mit «_»).
    Parameter: BX, BaseY - Ankerpunkt in Vorlagen-Koordinaten; BaseY ist
                           die Grundlinie der Schrift (wie im SVG-Entwurf)
               T         - Text; leer = nichts zeichnen
               C         - Farbe
               Align     - 0 = links, 1 = Mitte, 2 = rechts am Ankerpunkt
               Bold      - fett
  ----------------------------------------------------------------------------}
  procedure Txt(BX, BaseY: Double; const T: string; C: TColor; Align: Integer; Bold: Boolean);
  var
    TW, TX, TY: Integer;                                 // Breite und Startpunkt
  begin
    if T = '' then Exit;
    if SmoothCapturing then
    begin
      // geglättet: Text erst nach dem Verkleinern scharf zeichnen
      SmoothAddText(Canvas, X(BX), Y(BaseY), T, C, Align, Bold);  // merken, später zeichnen
      Exit;
    end;
    if Bold then Canvas.Font.Style := [fsBold] else Canvas.Font.Style := [];
    TW := RichWidth(Canvas, T);
    case Align of
      1: TX := X(BX) - TW div 2;
      2: TX := X(BX) - TW;
    else
      TX := X(BX);
    end;
    TY := Y(BaseY) - Canvas.TextHeight('Ag') * 4 div 5;  // Grundlinie -> Oberkante
    DrawRich(Canvas, TX, TY, T, C, C);
    Canvas.Font.Style := [];
  end;

var
  RBands: TRect;                                         // Rechteck des Widerstands im Schaltplan
  Tri: array[0..2] of TPoint;                            // Dreiecke (LED, Pfeile)
begin
  // ----- 1. Massstab: die Vorlage 460 × 240 so gross wie möglich -----
  S := Min((Rect.Right - Rect.Left) / 460, (Rect.Bottom - Rect.Top) / 240);
  if S <= 0 then Exit;
  OX := Rect.Left + ((Rect.Right - Rect.Left) - 460 * S) / 2;
  OY := Rect.Top + ((Rect.Bottom - Rect.Top) - 240 * S) / 2;  // mittig

  Canvas.Font.Name := FONT_UI;
  Canvas.Font.Height := SmoothFontHeight(9, 12 * S);
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := LineColor;
  Canvas.Pen.Width := PW(2);

  // ----- 2. Leitungen -----
  Canvas.PolyLine([Point(X(70), Y(108)), Point(X(70), Y(40)), Point(X(160), Y(40))]);  // + zum Widerstand
  Canvas.PolyLine([Point(X(250), Y(40)), Point(X(350), Y(40)), Point(X(350), Y(100))]);  // Widerstand zur LED
  Canvas.PolyLine([Point(X(350), Y(140)), Point(X(350), Y(205)), Point(X(70), Y(205)), Point(X(70), Y(128))]);

  // ----- 3. Quelle: langer dünner Strich (+), kurzer dicker Strich (−) -----
  Canvas.Pen.Width := PW(2.5);
  Canvas.Line(X(48), Y(108), X(92), Y(108));
  Canvas.Pen.Width := PW(6);
  Canvas.Line(X(59), Y(128), X(81), Y(128));

  // ----- 4. Widerstand mit Farbringen -----
  // Kasten füllen, Ringe hinein, dann den Rand nochmals darüber
  Canvas.Pen.Width := PW(2);
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := BodyColor;
  SmoothRectangle(Canvas, X(160), Y(29), X(250), Y(51));
  if Length(V.Bands) >= 3 then
  begin
    RBands := Types.Rect(X(162), Y(31), X(248), Y(49));
    DrawResistor(Canvas, RBands, V.Bands);
  end;
  Canvas.Pen.Color := LineColor;
  Canvas.Pen.Width := PW(2);
  Canvas.Brush.Style := bsClear;
  SmoothRectangle(Canvas, X(160), Y(29), X(250), Y(51));

  // ----- 5. LED-Symbol: Dreieck mit Querstrich und zwei Lichtpfeilen -----
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := V.LedColor;
  Tri[0] := Point(X(332), Y(100));
  Tri[1] := Point(X(368), Y(100));
  Tri[2] := Point(X(350), Y(138));
  Canvas.Polygon(Tri);                                   // Dreieck, Spitze nach unten
  Canvas.Pen.Width := PW(2.5);
  Canvas.Line(X(330), Y(140), X(370), Y(140));           // Querstrich (Kathode)
  Canvas.Pen.Width := PW(2);
  Canvas.Line(X(372), Y(112), X(392), Y(98));            // Lichtpfeile
  Canvas.Line(X(376), Y(124), X(396), Y(110));
  Canvas.Brush.Color := LineColor;
  Canvas.Pen.Width := 1;
  Canvas.Polygon([Point(X(392), Y(98)), Point(X(383), Y(99)), Point(X(388), Y(105))]);  // Pfeilspitzen
  Canvas.Polygon([Point(X(396), Y(110)), Point(X(387), Y(111)), Point(X(392), Y(117))]);

  // ----- 6. Stromrichtung (unten, nach links) -----
  Canvas.Brush.Color := AccentColor;
  Canvas.Pen.Color := AccentColor;
  Canvas.Polygon([Point(X(200), Y(205)), Point(X(212), Y(199)), Point(X(212), Y(211))]);
  Canvas.Brush.Style := bsClear;

  // ----- 7. Beschriftung -----
  Canvas.Font.Height := SmoothFontHeight(10, 14 * S);
  Txt(40, 104, '+', TextColor, 2, False);                // Pole der Quelle
  Txt(40, 134, '−', TextColor, 2, False);
  Canvas.Font.Height := SmoothFontHeight(9, 12 * S);
  Txt(96, 123, V.UBText, TextColor, 0, False);
  Txt(205, 22, V.RText, AccentColor, 1, True);           // R über dem Widerstand
  Txt(205, 70, V.URText, TextColor, 1, False);           // U_R darunter
  Txt(378, 150, V.LedText, TextColor, 0, False);         // rechts neben der LED
  Txt(378, 166, V.UFText, TextColor, 0, False);
  if V.StringsText <> '' then
    Txt(96, 150, V.StringsText, AccentColor, 0, True);
  Txt(210, 226, V.IText, AccentColor, 1, True);          // Strom unter der Leitung
end;

end.
