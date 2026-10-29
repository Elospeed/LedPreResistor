{ Einfacher Text mit Auszeichnung für Schaltplan und Rechenweg:
    **fett**   schaltet Fettdruck (und hellere Farbe) ein und aus
    _X         schreibt das nächste Zeichen tiefgestellt (U_R -> U mit kleinem R)
  Nur LCL-Canvas, keine Zusatzbibliothek. }
unit uRichText;

{$mode objfpc}{$H+}

interface

uses
  Graphics;

{ Zeichnet S ab Punkt (X, Y) (Y = Oberkante der Zeile) auf Canvas.
  Normaltext in Color, Fetttext in BoldColor. Liefert die Breite in Pixel. }
function DrawRich(Canvas: TCanvas; X, Y: Integer; const S: string;
  Color, BoldColor: TColor): Integer;

{ Liefert die Breite, die DrawRich für S brauchen würde, ohne zu zeichnen. }
function RichWidth(Canvas: TCanvas; const S: string): Integer;

implementation

uses
  LazUTF8;

{ Gemeinsame Arbeit von DrawRich und RichWidth: läuft den Text ab und
  zeichnet nur, wenn Paint = True ist. }
function WalkRich(Canvas: TCanvas; X, Y: Integer; const S: string;
  Color, BoldColor: TColor; Paint: Boolean): Integer;
var
  I: Integer;           // Position im Text (Bytes)
  Bold: Boolean;        // Fettdruck gerade aktiv
  Sub: Boolean;         // nächstes Zeichen tiefgestellt
  Ch: string;           // aktuelles Zeichen (UTF-8, 1–4 Bytes)
  ChLen: Integer;       // Länge des Zeichens in Bytes
  BaseSize: Integer;    // ursprüngliche Schriftgrösse
  BaseStyle: TFontStyles; // ursprünglicher Schriftstil
  StartX: Integer;      // Startposition für die Breitenberechnung
  Run: string;          // gesammelter Text gleichen Stils
  BaseH: Integer;       // Zeilenhöhe der Grundschrift

  { Gibt den gesammelten Text im aktuellen Stil aus }
  procedure Flush;
  begin
    if Run = '' then
      Exit;
    if Bold then
    begin
      Canvas.Font.Style := BaseStyle + [fsBold];
      Canvas.Font.Color := BoldColor;
    end
    else
    begin
      Canvas.Font.Style := BaseStyle;
      Canvas.Font.Color := Color;
    end;
    if Paint then
      Canvas.TextOut(X, Y, Run);
    Inc(X, Canvas.TextWidth(Run));
    Run := '';
  end;

begin
  StartX := X;
  BaseSize := Canvas.Font.Size;
  BaseStyle := Canvas.Font.Style;
  BaseH := Canvas.TextHeight('Ag');
  Bold := False;
  Sub := False;
  Run := '';
  Canvas.Brush.Style := bsClear;
  I := 1;
  while I <= Length(S) do
  begin
    if (S[I] = '*') and (I < Length(S)) and (S[I + 1] = '*') then
    begin
      Flush;
      Bold := not Bold;
      Inc(I, 2);
      Continue;
    end;
    if (S[I] = '_') and (I < Length(S)) then
    begin
      Flush;
      Sub := True;
      Inc(I);
      Continue;
    end;
    ChLen := UTF8CodepointSize(@S[I]);
    Ch := Copy(S, I, ChLen);
    Inc(I, ChLen);
    if Sub then
    begin
      // tiefgestelltes Zeichen: kleinere Schrift, nach unten versetzt
      Canvas.Font.Size := Round(BaseSize * 0.72);
      if Bold then Canvas.Font.Style := BaseStyle + [fsBold] else Canvas.Font.Style := BaseStyle;
      Canvas.Font.Color := Color;
      if Paint then
        Canvas.TextOut(X, Y + BaseH - Canvas.TextHeight('Ag') + BaseH div 6, Ch);
      Inc(X, Canvas.TextWidth(Ch) + 1);
      Canvas.Font.Size := BaseSize;
      Sub := False;
    end
    else
      Run := Run + Ch;
  end;
  Flush;
  Canvas.Font.Style := BaseStyle;
  Canvas.Font.Color := Color;
  Result := X - StartX;
end;

function DrawRich(Canvas: TCanvas; X, Y: Integer; const S: string;
  Color, BoldColor: TColor): Integer;
begin
  Result := WalkRich(Canvas, X, Y, S, Color, BoldColor, True);
end;

function RichWidth(Canvas: TCanvas; const S: string): Integer;
begin
  Result := WalkRich(Canvas, 0, 0, S, clBlack, clBlack, False);
end;

end.
