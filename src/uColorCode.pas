{ Farbringe eines Widerstands nach IEC 60062.
  E12 und E24: 4 Ringe (2 Ziffern, Multiplikator, Toleranz gold 5 %).
  E96: 5 Ringe (3 Ziffern, Multiplikator, Toleranz braun 1 %).
  Reine Logik ohne GUI; die Bildschirmfarben der Ringe kommen später aus uTheme. }
unit uColorCode;

{$mode objfpc}{$H+}

interface

uses
  uESeries;

type
  { Ringfarben. Die Reihenfolge bcBlack..bcWhite entspricht den Ziffern 0..9. }
  TBandColor = (bcBlack, bcBrown, bcRed, bcOrange, bcYellow, bcGreen,
                bcBlue, bcViolet, bcGrey, bcWhite, bcGold, bcSilver);

  { Die Ringe von links nach rechts }
  TBandArray = array of TBandColor;

{ Ermittelt die Farbringe für einen Normwert der angegebenen Reihe.
  Liefert False, wenn der Multiplikator ausserhalb von 0,01 bis 10^9 liegt
  (solche Werte lassen sich nicht mit Ringen darstellen). }
function ColorBands(const Std: TStdValue; Series: TESeries; out Bands: TBandArray): Boolean;

implementation

function ColorBands(const Std: TStdValue; Series: TESeries; out Bands: TBandArray): Boolean;
var
  I: Integer;       // Zähler für die Ziffern
  Rest: Integer;    // noch nicht verarbeitete Ziffern
  Count: Integer;   // Anzahl Ziffernringe (2 oder 3)
begin
  Result := False;
  Bands := nil;
  // Multiplikator: Silber = 10^-2, Gold = 10^-1, Schwarz..Weiss = 10^0..10^9
  if (Std.Exponent < -2) or (Std.Exponent > 9) or (Std.DigitCount < 2) then
    Exit;

  Count := Std.DigitCount;
  SetLength(Bands, Count + 2);

  // Ziffern von hinten nach vorne eintragen
  Rest := Std.Digits;
  for I := Count - 1 downto 0 do
  begin
    Bands[I] := TBandColor(Rest mod 10);
    Rest := Rest div 10;
  end;

  // Multiplikator
  case Std.Exponent of
    -2: Bands[Count] := bcSilver;
    -1: Bands[Count] := bcGold;
  else
    Bands[Count] := TBandColor(Std.Exponent);
  end;

  // Toleranzring
  if Series = esE96 then
    Bands[Count + 1] := bcBrown   // 1 %
  else
    Bands[Count + 1] := bcGold;   // 5 %

  Result := True;
end;

end.
