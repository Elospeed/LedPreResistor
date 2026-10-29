{ Zeichnungen für das Hauptfenster: Schaltplan mit Werten und ein
  Widerstand mit Farbringen. Nur LCL-Canvas. Der Schaltplan folgt der
  Vorlage aus Entwurf A «Labor 2» (460 × 240 Punkte) und wird in das
  übergebene Rechteck eingepasst. }
unit uSchematic;

{$mode objfpc}{$H+}

interface

uses
  Types, Graphics, uColorCode;

type
  { Alles, was der Schaltplan anzeigt, bereits als fertiger Text.
    Tiefgestellte Zeichen mit "_" (siehe uRichText). }
  TSchematicValues = record
    RText: string;      // z. B. "R = 470 Ω"
    URText: string;     // z. B. "U_R = 8,8 V"
    UBText: string;     // z. B. "U_B = 12 V"
    LedText: string;    // z. B. "LED weiss" oder "3 × LED weiss"
    UFText: string;     // z. B. "U_F = 3,2 V"
    IText: string;      // z. B. "I = 18,72 mA"
    LedColor: TColor;   // Füllfarbe des LED-Symbols
    Bands: TBandArray;  // Farbringe im Widerstand (leer = ohne Ringe)
  end;

{ Zeichnet den Schaltplan in Rect (Hintergrund wird nicht gefüllt). }
procedure DrawSchematic(Canvas: TCanvas; const Rect: TRect; const V: TSchematicValues;
  LineColor, TextColor, AccentColor, BodyColor: TColor);

{ Zeichnet einen Widerstand mit Farbringen waagrecht in Rect:
  Anschlussdraht, beiger Körper mit runden Enden, Ringe. }
procedure DrawResistor(Canvas: TCanvas; const Rect: TRect; const Bands: TBandArray);

implementation

uses
  Math, uTheme, uRichText;

procedure DrawResistor(Canvas: TCanvas; const Rect: TRect; const Bands: TBandArray);
var
  W, H: Integer;        // Grösse des Rechtecks
  BodyL, BodyR: Integer; // linker und rechter Rand des Körpers
  BodyT, BodyB: Integer; // obere und untere Kante des Körpers
  BW: Integer;          // Breite eines Rings
  I, X: Integer;        // Ring-Zähler und Position
  N: Integer;           // Anzahl Ringe
begin
  W := Rect.Right - Rect.Left;
  H := Rect.Bottom - Rect.Top;
  if (W < 20) or (H < 6) then Exit;
  // Draht
  Canvas.Pen.Color := clrWire;
  Canvas.Pen.Width := Max(1, H div 12);
  Canvas.Line(Rect.Left, Rect.Top + H div 2, Rect.Right, Rect.Top + H div 2);
  // Körper (20 % bis 80 % der Breite)
  BodyL := Rect.Left + W * 20 div 100;
  BodyR := Rect.Left + W * 80 div 100;
  BodyT := Rect.Top + H div 7;
  BodyB := Rect.Bottom - H div 7;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Color := clrResistorEdge;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := clrResistorBody;
  Canvas.RoundRect(BodyL, BodyT, BodyR, BodyB, (BodyB - BodyT) * 4 div 5, (BodyB - BodyT) * 4 div 5);
  // Ringe: Ziffern und Multiplikator links gruppiert, Toleranz rechts abgesetzt
  N := Length(Bands);
  if N < 3 then Exit;
  BW := Max(2, (BodyR - BodyL) * 9 div 100);
  Canvas.Pen.Style := psClear;
  for I := 0 to N - 1 do
  begin
    if I < N - 1 then
      X := BodyL + (BodyR - BodyL) * (15 + I * (55 div (N - 1))) div 100
    else
      X := BodyL + (BodyR - BodyL) * 78 div 100;
    Canvas.Brush.Color := BandScreenColor(Bands[I]);
    Canvas.Rectangle(X, BodyT + 1, X + BW, BodyB);
  end;
  Canvas.Pen.Style := psSolid;
end;

procedure DrawSchematic(Canvas: TCanvas; const Rect: TRect; const V: TSchematicValues;
  LineColor, TextColor, AccentColor, BodyColor: TColor);
var
  S: Double;      // Pixel pro Vorlagen-Punkt
  OX, OY: Double; // Versatz für die Zentrierung

  { Vorlagen-X in Pixel }
  function X(V: Double): Integer;
  begin
    Result := Round(OX + V * S);
  end;

  { Vorlagen-Y in Pixel }
  function Y(V: Double): Integer;
  begin
    Result := Round(OY + V * S);
  end;

  { Strichstärke in Pixel }
  function PW(V: Double): Integer;
  begin
    Result := Max(1, Round(V * S));
  end;

  { Text mit Auszeichnung; Align: 0 = links, 1 = Mitte, 2 = rechts.
    BaseY ist die Grundlinie wie im SVG. }
  procedure Txt(BX, BaseY: Double; const T: string; C: TColor; Align: Integer; Bold: Boolean);
  var
    TW, TX, TY: Integer;  // Breite und Startpunkt
  begin
    if Bold then Canvas.Font.Style := [fsBold] else Canvas.Font.Style := [];
    TW := RichWidth(Canvas, T);
    case Align of
      1: TX := X(BX) - TW div 2;
      2: TX := X(BX) - TW;
    else
      TX := X(BX);
    end;
    TY := Y(BaseY) - Canvas.TextHeight('Ag') * 4 div 5;
    DrawRich(Canvas, TX, TY, T, C, C);
    Canvas.Font.Style := [];
  end;

var
  RBands: TRect;   // Rechteck des Widerstands im Schaltplan
  Tri: array[0..2] of TPoint;  // Dreiecke (LED, Pfeile)
begin
  S := Min((Rect.Right - Rect.Left) / 460, (Rect.Bottom - Rect.Top) / 240);
  if S <= 0 then Exit;
  OX := Rect.Left + ((Rect.Right - Rect.Left) - 460 * S) / 2;
  OY := Rect.Top + ((Rect.Bottom - Rect.Top) - 240 * S) / 2;

  Canvas.Font.Name := FONT_UI;
  Canvas.Font.Height := -Max(9, Round(12 * S));
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := LineColor;
  Canvas.Pen.Width := PW(2);

  // Leitungen
  Canvas.PolyLine([Point(X(70), Y(108)), Point(X(70), Y(40)), Point(X(160), Y(40))]);
  Canvas.PolyLine([Point(X(250), Y(40)), Point(X(350), Y(40)), Point(X(350), Y(100))]);
  Canvas.PolyLine([Point(X(350), Y(140)), Point(X(350), Y(205)), Point(X(70), Y(205)), Point(X(70), Y(128))]);

  // Quelle: langer dünner Strich (+), kurzer dicker Strich (−)
  Canvas.Pen.Width := PW(2.5);
  Canvas.Line(X(48), Y(108), X(92), Y(108));
  Canvas.Pen.Width := PW(6);
  Canvas.Line(X(59), Y(128), X(81), Y(128));

  // Widerstand mit Farbringen
  Canvas.Pen.Width := PW(2);
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := BodyColor;
  Canvas.Rectangle(X(160), Y(29), X(250), Y(51));
  if Length(V.Bands) >= 3 then
  begin
    RBands := Types.Rect(X(162), Y(31), X(248), Y(49));
    DrawResistor(Canvas, RBands, V.Bands);
  end;
  Canvas.Pen.Color := LineColor;
  Canvas.Pen.Width := PW(2);
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(X(160), Y(29), X(250), Y(51));

  // LED-Symbol: Dreieck mit Querstrich und zwei Lichtpfeilen
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := V.LedColor;
  Tri[0] := Point(X(332), Y(100));
  Tri[1] := Point(X(368), Y(100));
  Tri[2] := Point(X(350), Y(138));
  Canvas.Polygon(Tri);
  Canvas.Pen.Width := PW(2.5);
  Canvas.Line(X(330), Y(140), X(370), Y(140));
  Canvas.Pen.Width := PW(2);
  Canvas.Line(X(372), Y(112), X(392), Y(98));
  Canvas.Line(X(376), Y(124), X(396), Y(110));
  Canvas.Brush.Color := LineColor;
  Canvas.Pen.Width := 1;
  Canvas.Polygon([Point(X(392), Y(98)), Point(X(383), Y(99)), Point(X(388), Y(105))]);
  Canvas.Polygon([Point(X(396), Y(110)), Point(X(387), Y(111)), Point(X(392), Y(117))]);

  // Stromrichtung (unten, nach links)
  Canvas.Brush.Color := AccentColor;
  Canvas.Pen.Color := AccentColor;
  Canvas.Polygon([Point(X(200), Y(205)), Point(X(212), Y(199)), Point(X(212), Y(211))]);
  Canvas.Brush.Style := bsClear;

  // Beschriftung
  Canvas.Font.Height := -Max(10, Round(14 * S));
  Txt(40, 104, '+', TextColor, 2, False);
  Txt(40, 134, '−', TextColor, 2, False);
  Canvas.Font.Height := -Max(9, Round(12 * S));
  Txt(96, 123, V.UBText, TextColor, 0, False);
  Txt(205, 22, V.RText, AccentColor, 1, True);
  Txt(205, 70, V.URText, TextColor, 1, False);
  Txt(378, 150, V.LedText, TextColor, 0, False);
  Txt(378, 166, V.UFText, TextColor, 0, False);
  Txt(210, 226, V.IText, AccentColor, 1, True);
end;

end.
