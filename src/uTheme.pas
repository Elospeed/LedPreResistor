{ Alle Farben und Schriften von LedPreResistor an einer Stelle
  (Entwurf A «Labor 2», dunkel). TColor ist unter Windows BGR, darum werden
  die Farben hier mit RGBToColor aus den gewohnten #RRGGBB-Werten gebildet. }
unit uTheme;

{$mode objfpc}{$H+}

interface

uses
  Graphics, uCalc, uColorCode;

const
  { Schriften: Segoe UI für Text; Zahlen in den Eingabefeldern in Consolas }
  FONT_UI = 'Segoe UI';
  FONT_MONO = 'Consolas';

var
  { Flächen }
  clrWindow: TColor;       // Grund des Fensters (#1E2228)
  clrPanel: TColor;        // linke Spalte und Karten (#23272E)
  clrDeep: TColor;         // Schaltplan, Eingabefelder, LED-Vorschau (#15181C)
  clrBar: TColor;          // Statuszeile (#16191D)
  clrBorder: TColor;       // Rahmenlinien (#333A42)
  clrEditBorder: TColor;   // Rahmen der Eingabefelder (#45505C)

  { Text }
  clrText: TColor;         // normaler Text (#DFE3E8)
  clrTextBright: TColor;   // Resultatwerte (#FFFFFF)
  clrTextDim: TColor;      // Nebentext, Überschriften (#7F8A96)
  clrTextSoft: TColor;     // Beschreibungen in Karten (#9AA4AE)
  clrAccent: TColor;       // Hervorhebung im Schaltplan, Nummern (#5AA9FF)
  clrLine: TColor;         // Schaltplan-Linien (#C9D1DA)

  { Zustände }
  clrOk: TColor;           // grün (#3DDC84)
  clrOkBack: TColor;       // Hintergrund grüner Hinweis (#10301E)
  clrWarn: TColor;         // gelb (#FFCC33)
  clrWarnBack: TColor;     // Hintergrund gelber Hinweis (#3A3110)
  clrError: TColor;        // rot (#FF5C5C)
  clrErrorBack: TColor;    // Hintergrund roter Hinweis (#3A1414)

  { Widerstand }
  clrResistorBody: TColor; // Körper (#E3C992)
  clrResistorEdge: TColor; // Umriss (#9C804C)
  clrWire: TColor;         // Anschlussdraht (#9AA3AB)

{ Farbe, in der eine LED leuchtet (Bildschirmfarbe, nicht Wellenlänge) }
function LedGlowColor(C: TLedColor): TColor;

{ Bildschirmfarbe eines Farbrings }
function BandScreenColor(B: TBandColor): TColor;

implementation

function LedGlowColor(C: TLedColor): TColor;
begin
  case C of
    lcRed:      Result := RGBToColor($FF, $2B, $2B);
    lcYellow:   Result := RGBToColor($FF, $D0, $00);
    lcGreen:    Result := RGBToColor($25, $E3, $5D);
    lcBlue:     Result := RGBToColor($2F, $7D, $FF);
    lcWhite:    Result := RGBToColor($FF, $FF, $FF);
  else
    // Infrarot ist unsichtbar; ein dunkles Purpur deutet es nur an
    Result := RGBToColor($9A, $2A, $6A);
  end;
end;

function BandScreenColor(B: TBandColor): TColor;
begin
  case B of
    bcBlack:  Result := RGBToColor($1A, $1A, $1A);
    bcBrown:  Result := RGBToColor($7A, $4A, $1D);
    bcRed:    Result := RGBToColor($D0, $2A, $2A);
    bcOrange: Result := RGBToColor($F0, $7A, $10);
    bcYellow: Result := RGBToColor($F4, $C3, $00);
    bcGreen:  Result := RGBToColor($2E, $A0, $43);
    bcBlue:   Result := RGBToColor($2F, $6B, $D8);
    bcViolet: Result := RGBToColor($8A, $3F, $D1);
    bcGrey:   Result := RGBToColor($8C, $8C, $8C);
    bcWhite:  Result := RGBToColor($F4, $F4, $F4);
    bcGold:   Result := RGBToColor($C9, $A3, $3A);
  else
    Result := RGBToColor($B8, $BC, $C2);  // Silber
  end;
end;

initialization
  clrWindow := RGBToColor($1E, $22, $28);
  clrPanel := RGBToColor($23, $27, $2E);
  clrDeep := RGBToColor($15, $18, $1C);
  clrBar := RGBToColor($16, $19, $1D);
  clrBorder := RGBToColor($33, $3A, $42);
  clrEditBorder := RGBToColor($45, $50, $5C);
  clrText := RGBToColor($DF, $E3, $E8);
  clrTextBright := RGBToColor($FF, $FF, $FF);
  clrTextDim := RGBToColor($7F, $8A, $96);
  clrTextSoft := RGBToColor($9A, $A4, $AE);
  clrAccent := RGBToColor($5A, $A9, $FF);
  clrLine := RGBToColor($C9, $D1, $DA);
  clrOk := RGBToColor($3D, $DC, $84);
  clrOkBack := RGBToColor($10, $30, $1E);
  clrWarn := RGBToColor($FF, $CC, $33);
  clrWarnBack := RGBToColor($3A, $31, $10);
  clrError := RGBToColor($FF, $5C, $5C);
  clrErrorBack := RGBToColor($3A, $14, $14);
  clrResistorBody := RGBToColor($E3, $C9, $92);
  clrResistorEdge := RGBToColor($9C, $80, $4C);
  clrWire := RGBToColor($9A, $A3, $AB);
end.
