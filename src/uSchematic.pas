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
             rechts die LED-Säule (1 bis 3 LEDs einzeln, ab 4 zwei LEDs mit
             Punkten dazwischen), unten der Stromrichtungspfeil. Bei Strängen
             parallel steht rechts der zweite Strang, genau wie der erste
             gezeichnet (eigener Widerstand, gleich viele LEDs), darüber «Strang 1» und
             «Strang 2» bzw. «… Strang k». Die Beschriftungen kommen fertig als Text in
             TSchematicValues (uMain baut sie, Tiefstellung mit «_»).

  Technik:   Nur LCL-Canvas. Geglättet wird über uSmooth (vergrössert
             zeichnen, dann verkleinern); die Texte werden erst danach scharf
             darübergeschrieben.

  Autor:     Elospeed
  Versionen: 2.5.2 17.11.2026 Strom je Strang unter «k Stränge parallel»; zweiter
                              Strang genau wie der erste (gleich viele LEDs,
                              Farbringe), Säulen mit «Strang 1» / «… Strang k»
             2.5.1 17.11.2026 zweiter Strang zweigt vor dem ersten Widerstand ab;
                              Leitungen und Bauteile an uSchemNetz melden
                              (Verbindungstests)
             2.5  17.11.2026  mehrere LEDs in Reihe als Säule, zweiter Strang
                              rechts angedeutet (Stränge parallel)
             2.4  14.11.2026  geglättet (uSmooth), Stränge parallel, Kommentare
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
    IText: string;                                       // z. B. "I = 18,72 mA"; bei Strängen der Gesamtstrom (gemeinsame Rückleitung)
    StringsText: string;                                 // z. B. "× 3 Stränge parallel" (leer = ein Strang)
    IStringText: string;                                 // Strom je Strang bei Strängen parallel (leer = ein Strang)
    String1Text: string;                                 // «Strang 1» über der ersten Säule (leer = ein Strang)
    StringLastText: string;                              // «Strang 2» bzw. «… Strang k» über der zweiten Säule
    LedCount: Integer;                                   // LEDs in Reihe (0 oder 1 = eine)
    StringCount: Integer;                                // Stränge parallel (0 oder 1 = einer)
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
  SysUtils, Math, uTheme, uRichText, uSmooth, uSchemNetz;

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

const
  // Lage des zweiten Strangs (Vorlagen-Koordinaten)
  S2_X = 415;                                            // LED-Säule des zweiten Strangs
  S2_Y = 9;                                              // obere Leitung über dem ersten Widerstand
  S2_R1 = 300;                                           // zweiter Widerstand: linker Anschluss
  S2_R2 = 390;                                           // zweiter Widerstand: rechter Anschluss

var
  LabelY: Double;                                        // Grundlinie der LED-Beschriftung (unter der Säule)

  {----------------------------------------------------------------------------
    DrawLed
  ----------------------------------------------------------------------------
    Ein LED-Symbol: Dreieck mit Spitze nach unten, Querstrich (Kathode) und
    zwei Lichtpfeile.
    Parameter: CX  - Mitte waagrecht (Vorlagen-Koordinate)
               Top - Oberkante des Dreiecks
               Sc  - Grösse (1 = 40 Punkte hoch wie in 2.0)
  ----------------------------------------------------------------------------}
  procedure DrawLed(CX, Top, Sc: Double);
  var
    T: array[0..2] of TPoint;                            // Ecken des Dreiecks
  begin
    NetzBauteil('LED', ['A', 'K'], [CX, Top, CX, Top + 40 * Sc]);  // Anode oben, Kathode unten
    Canvas.Pen.Width := PW(2);
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := V.LedColor;
    T[0] := Point(X(CX - 18 * Sc), Y(Top));
    T[1] := Point(X(CX + 18 * Sc), Y(Top));
    T[2] := Point(X(CX), Y(Top + 38 * Sc));
    Canvas.Polygon(T);
    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Width := PW(2.5);
    Canvas.Line(X(CX - 20 * Sc), Y(Top + 40 * Sc), X(CX + 20 * Sc), Y(Top + 40 * Sc));  // Kathode
    // Lichtpfeile schräg nach rechts oben, mit gefüllten Spitzen
    Canvas.Pen.Width := PW(2);
    Canvas.Line(X(CX + 22 * Sc), Y(Top + 12 * Sc), X(CX + 42 * Sc), Y(Top - 2 * Sc));
    Canvas.Line(X(CX + 26 * Sc), Y(Top + 24 * Sc), X(CX + 46 * Sc), Y(Top + 10 * Sc));
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := Canvas.Pen.Color;
    Canvas.Pen.Width := 1;
    Canvas.Polygon([Point(X(CX + 42 * Sc), Y(Top - 2 * Sc)), Point(X(CX + 33 * Sc), Y(Top - 1 * Sc)),
      Point(X(CX + 38 * Sc), Y(Top + 5 * Sc))]);
    Canvas.Polygon([Point(X(CX + 46 * Sc), Y(Top + 10 * Sc)), Point(X(CX + 37 * Sc), Y(Top + 11 * Sc)),
      Point(X(CX + 42 * Sc), Y(Top + 17 * Sc))]);
    Canvas.Brush.Style := bsClear;
  end;

  {----------------------------------------------------------------------------
    DrawResistorBox
  ----------------------------------------------------------------------------
    Waagrechter Widerstand mit Farbringen zwischen X1 und X2, Mitte auf
    Höhe YM, Körper HH hoch. Kasten füllen, Ringe hinein, dann den Rand
    nochmals darüber. Meldet ihn unter Name an uSchemNetz.
  ----------------------------------------------------------------------------}
  procedure DrawResistorBox(X1, X2, YM, HH: Double; const Name: string);
  begin
    Canvas.Pen.Color := LineColor;
    Canvas.Pen.Width := PW(2);
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := BodyColor;
    SmoothRectangle(Canvas, X(X1), Y(YM - HH / 2), X(X2), Y(YM + HH / 2));
    NetzName(Name);
    NetzBauteil('R', ['1', '2'], [X1, YM, X2, YM]);      // Anschlüsse links und rechts
    if Length(V.Bands) >= 3 then
      DrawResistor(Canvas, Types.Rect(X(X1 + 2), Y(YM - HH / 2 + 2), X(X2 - 2), Y(YM + HH / 2 - 2)), V.Bands);
    Canvas.Pen.Color := LineColor;
    Canvas.Pen.Width := PW(2);
    Canvas.Brush.Style := bsClear;
    SmoothRectangle(Canvas, X(X1), Y(YM - HH / 2), X(X2), Y(YM + HH / 2));
  end;

  {----------------------------------------------------------------------------
    DrawLedColumn
  ----------------------------------------------------------------------------
    Senkrechte LED-Säule zwischen der oberen Leitung (Höhe YTop) und der
    unteren Leitung (y = 205). 1 bis 3 LEDs werden einzeln gezeichnet, ab 4
    LEDs zwei Symbole mit drei Punkten dazwischen (für die übrigen). Jeder
    Strang hat gleich viele LEDs, darum zeichnet der zweite Strang genau
    dieselbe Säule.
    Parameter: CX     - Mitte waagrecht (Vorlagen-Koordinate)
               YTop   - Höhe der Leitung, von der die Säule abgeht
               Prefix - Vorsilbe der Namen für die Verbindungstests
    Merkt sich in LabelY, wo die Beschriftung unter der untersten LED hingehört.
  ----------------------------------------------------------------------------}
  procedure DrawLedColumn(CX, YTop: Double; const Prefix: string);
  var
    N: Integer;                                          // LEDs in Reihe
    K: Integer;                                          // gezeichnete Plätze (LED oder Punkte)
    I: Integer;                                          // Zähler der Plätze
    Sc: Double;                                          // Grösse der Symbole
    H: Double;                                           // Höhe eines Platzes
    Top: Double;                                         // Oberkante des obersten Platzes
    YY: Double;                                          // Oberkante des aktuellen Platzes
  const
    GAP = 14;                                            // Leitungsstück zwischen zwei Plätzen
  begin
    N := Max(1, V.LedCount);
    K := Min(N, 3);                                      // ab 4: LED, Punkte, LED
    if K = 1 then Sc := 1 else if K = 2 then Sc := 0.9 else Sc := 0.72;
    if V.StringCount > 1 then Sc := Sc * 0.85;           // zwei Säulen nebeneinander: etwas kleiner
    H := 40 * Sc;
    Top := 120 - (K * H + (K - 1) * GAP) / 2;            // Säule um y = 120 mittig (eine LED wie bisher)
    Canvas.Pen.Color := LineColor;
    Canvas.Pen.Width := PW(2);
    Canvas.Line(X(CX), Y(YTop), X(CX), Y(Top));          // von oben zur ersten LED
    NetzLeitung(CX, YTop, CX, Top);
    YY := Top;
    for I := 1 to K do
    begin
      if (N > 3) and (I = 2) then
      begin
        // drei Punkte für die ausgelassenen LEDs
        Canvas.Brush.Style := bsSolid;
        Canvas.Brush.Color := LineColor;
        Canvas.Pen.Width := 1;
        Canvas.Ellipse(X(CX - 2.2), Y(YY + H * 0.2 - 2.2), X(CX + 2.2), Y(YY + H * 0.2 + 2.2));
        Canvas.Ellipse(X(CX - 2.2), Y(YY + H * 0.5 - 2.2), X(CX + 2.2), Y(YY + H * 0.5 + 2.2));
        Canvas.Ellipse(X(CX - 2.2), Y(YY + H * 0.8 - 2.2), X(CX + 2.2), Y(YY + H * 0.8 + 2.2));
        Canvas.Brush.Style := bsClear;
        NetzName(Prefix + 'PUNKTE');                     // steht für die ausgelassenen LEDs
        NetzBauteil('LED', ['A', 'K'], [CX, YY, CX, YY + H]);
      end
      else
      begin
        // Namen für die Verbindungstests: LED1 ... LEDn, die letzte heisst wie ihre Nummer
        if I = K then NetzName(Prefix + 'LED' + IntToStr(N)) else NetzName(Prefix + 'LED' + IntToStr(I));
        DrawLed(CX, YY, Sc);
      end;
      Canvas.Pen.Color := LineColor;
      Canvas.Pen.Width := PW(2);
      if I < K then
      begin
        Canvas.Line(X(CX), Y(YY + H), X(CX), Y(YY + H + GAP));  // Verbindung zum nächsten Platz
        NetzLeitung(CX, YY + H, CX, YY + H + GAP);
      end;
      YY := YY + H + GAP;
    end;
    Canvas.Line(X(CX), Y(YY - GAP), X(CX), Y(205));      // von der untersten LED nach unten
    NetzLeitung(CX, YY - GAP, CX, 205);
    LabelY := YY - GAP + 10;
  end;

  {----------------------------------------------------------------------------
    DrawSecondString
  ----------------------------------------------------------------------------
    Zeichnet rechts den zweiten Strang genau wie den ersten: eigener
    Widerstand mit Farbringen und gleich viele LEDs. Jeder Strang hängt
    direkt an der Quelle: oben zweigt er VOR dem ersten Widerstand ab
    (Knoten links, Leitung über dem ersten Widerstand nach rechts, darin
    der zweite Widerstand), unten an der Rückleitung zum Minuspol.
  ----------------------------------------------------------------------------}
  procedure DrawSecondString;
  begin
    Canvas.Pen.Color := LineColor;
    Canvas.Pen.Width := PW(2);
    Canvas.Brush.Style := bsClear;
    Canvas.PolyLine([Point(X(110), Y(40)), Point(X(110), Y(S2_Y)), Point(X(S2_R1), Y(S2_Y))]);
    NetzLinienzug([110, 40, 110, S2_Y, S2_R1, S2_Y]);   // Abzweig vor dem ersten Widerstand
    DrawResistorBox(S2_R1, S2_R2, S2_Y, 18, 'R2');       // zweiter Widerstand
    Canvas.Pen.Color := LineColor;
    Canvas.Pen.Width := PW(2);
    Canvas.Line(X(S2_R2), Y(S2_Y), X(S2_X), Y(S2_Y));
    NetzLeitung(S2_R2, S2_Y, S2_X, S2_Y);
    DrawLedColumn(S2_X, S2_Y, 'S2_');                    // gleiche Säule wie der erste Strang
    Canvas.Pen.Color := LineColor;
    Canvas.Pen.Width := PW(2);
    Canvas.Line(X(S2_X), Y(205), X(350), Y(205));        // unten zur gemeinsamen Rückleitung
    NetzLeitung(S2_X, 205, 350, 205);
    // Knotenpunkte, wo sich die Stränge verzweigen
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := LineColor;
    Canvas.Pen.Width := 1;
    Canvas.Ellipse(X(106.5), Y(36.5), X(113.5), Y(43.5));  // oben: vor dem Widerstand
    Canvas.Ellipse(X(346.5), Y(201.5), X(353.5), Y(208.5));  // unten: Rückleitung
    Canvas.Brush.Style := bsClear;
  end;

begin
  // ----- 1. Massstab: die Vorlage 460 × 240 so gross wie möglich -----
  S := Min((Rect.Right - Rect.Left) / 460, (Rect.Bottom - Rect.Top) / 240);
  if S <= 0 then Exit;
  OX := Rect.Left + ((Rect.Right - Rect.Left) - 460 * S) / 2;
  OY := Rect.Top + ((Rect.Bottom - Rect.Top) - 240 * S) / 2;  // mittig

  Canvas.Font.Name := FONT_UI;
  Canvas.Font.Height := SmoothFontHeight(9, 12 * S);
  Canvas.Brush.Style := bsClear;
  // ----- 2. Zweiter Strang (nur bei Strängen parallel) -----
  if V.StringCount > 1 then DrawSecondString;

  // ----- 3. Leitungen -----
  Canvas.Pen.Color := LineColor;
  Canvas.Pen.Width := PW(2);
  Canvas.PolyLine([Point(X(70), Y(108)), Point(X(70), Y(40)), Point(X(160), Y(40))]);  // + zum Widerstand
  Canvas.Line(X(250), Y(40), X(350), Y(40));            // Widerstand zur LED-Säule
  Canvas.PolyLine([Point(X(350), Y(205)), Point(X(70), Y(205)), Point(X(70), Y(128))]);  // zurück zum −
  NetzLinienzug([70, 108, 70, 40, 160, 40]);             // dieselben Leitungen für die Verbindungstests
  NetzLeitung(250, 40, 350, 40);
  NetzLinienzug([350, 205, 70, 205, 70, 128]);
  NetzName('UB');
  NetzBauteil('UB', ['+', '-'], [70, 108, 70, 128]);     // Quelle: + oben, − unten

  // ----- 4. Quelle: langer dünner Strich (+), kurzer dicker Strich (−) -----
  Canvas.Pen.Width := PW(2.5);
  Canvas.Line(X(48), Y(108), X(92), Y(108));
  Canvas.Pen.Width := PW(6);
  Canvas.Line(X(59), Y(128), X(81), Y(128));

  // ----- 5. Widerstand mit Farbringen -----
  DrawResistorBox(160, 250, 40, 22, 'R1');

  // ----- 6. LED-Säule (eine oder mehrere LEDs in Reihe) -----
  DrawLedColumn(350, 40, '');

  // ----- 7. Stromrichtung (unten, nach links) -----
  Canvas.Brush.Color := AccentColor;
  Canvas.Pen.Color := AccentColor;
  Canvas.Polygon([Point(X(200), Y(205)), Point(X(212), Y(199)), Point(X(212), Y(211))]);
  Canvas.Brush.Style := bsClear;

  // ----- 8. Beschriftung -----
  Canvas.Font.Height := SmoothFontHeight(10, 14 * S);
  Txt(40, 104, '+', TextColor, 2, False);                // Pole der Quelle
  Txt(40, 134, '−', TextColor, 2, False);
  Canvas.Font.Height := SmoothFontHeight(9, 12 * S);
  Txt(96, 123, V.UBText, TextColor, 0, False);
  Txt(205, 22, V.RText, AccentColor, 1, True);           // R über dem Widerstand
  Txt(205, 70, V.URText, TextColor, 1, False);           // U_R darunter
  if V.StringCount > 1 then
  begin
    // rechts ist der zweite Strang: LED-Text links neben die Säule
    Txt(326, 174, V.LedText, TextColor, 2, False);
    Txt(326, 190, V.UFText, TextColor, 2, False);
    // Nummern über den Säulen: gezeichnet sind der erste und der letzte Strang
    Txt(343, 31, V.String1Text, TextColor, 2, False);
    Txt(408, 31, V.StringLastText, TextColor, 2, False);
  end
  else
  begin
    Txt(378, LabelY, V.LedText, TextColor, 0, False);    // rechts neben der untersten LED
    Txt(378, LabelY + 16, V.UFText, TextColor, 0, False);
  end;
  if V.StringsText <> '' then
    Txt(96, 150, V.StringsText, AccentColor, 0, True);
  Txt(96, 168, V.IStringText, TextColor, 0, False);      // Strom je Strang unter «k Stränge parallel» (leer = nichts)
  Txt(210, 226, V.IText, AccentColor, 1, True);          // Strom unter der Leitung
end;

end.
