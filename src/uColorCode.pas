{==============================================================================
  uColorCode - Farbringe eines Widerstands
==============================================================================
  Zweck:     Bestimmt zu einem Normwert die Farbringe nach IEC 60062, so wie
             sie auf einem bedrahteten Widerstand aufgedruckt sind.

  Aufbau:    E12 und E24: 4 Ringe = 2 Ziffern, Multiplikator, Toleranz
                                    (gold = 5 %)
             E96:         5 Ringe = 3 Ziffern, Multiplikator, Toleranz
                                    (braun = 1 %)
             Beispiel 470 Ω (E12): gelb (4), violett (7), braun (×10),
                                   gold (5 %)

  Regeln:    Reine Logik ohne Oberfläche. Die Bildschirmfarben der Ringe
             kommen aus uTheme, die Farbnamen als Text aus uMain.

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  Kommentare ausführlicher
             2.0  29.10.2026  erste Fassung
==============================================================================}
unit uColorCode;

{$mode objfpc}{$H+}

interface

uses
  uESeries;                                              // TStdValue (Ziffern + Exponent), TESeries

{==============================================================================
  TYPEN
==============================================================================}
type
  // Ringfarben. Die Reihenfolge bcBlack ... bcWhite entspricht genau den
  // Ziffern 0 ... 9; darum lässt sich eine Ziffer direkt umwandeln:
  // TBandColor(7) = bcViolet.
  TBandColor = (bcBlack, bcBrown, bcRed, bcOrange, bcYellow, bcGreen,
                bcBlue, bcViolet, bcGrey, bcWhite, bcGold, bcSilver);

  // Die Ringe von links nach rechts (4 oder 5 Einträge)
  TBandArray = array of TBandColor;

{==============================================================================
  ÖFFENTLICHE FUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  ColorBands - Farbringe für einen Normwert
------------------------------------------------------------------------------
  Parameter: Std    - Normwert als Ziffern + Zehnerexponent (aus uESeries)
             Series - Normreihe; bestimmt den Toleranzring
             Bands  - (Rückgabe) die Ringe von links nach rechts
  Rückgabe:  True, wenn es geklappt hat. False, wenn der Multiplikator
             ausserhalb von 0,01 bis 10^9 liegt; solche Werte lassen sich
             mit Ringen nicht darstellen.
------------------------------------------------------------------------------}
function ColorBands(const Std: TStdValue; Series: TESeries; out Bands: TBandArray): Boolean;

implementation

{------------------------------------------------------------------------------
  ColorBands - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Multiplikator prüfen (Silber 10^-2 ... Weiss 10^9)
    2. Ziffernringe von hinten nach vorne eintragen
    3. Multiplikatorring, dann Toleranzring
------------------------------------------------------------------------------}
function ColorBands(const Std: TStdValue; Series: TESeries; out Bands: TBandArray): Boolean;
var
  I: Integer;                                            // Zähler für die Ziffern
  Rest: Integer;                                         // noch nicht verarbeitete Ziffern
  Count: Integer;                                        // Anzahl Ziffernringe (2 oder 3)
begin
  Result := False;
  Bands := nil;

  // ----- 1. Multiplikator prüfen -----
  // Silber = 10^-2, Gold = 10^-1, Schwarz ... Weiss = 10^0 ... 10^9
  if (Std.Exponent < -2) or (Std.Exponent > 9) or (Std.DigitCount < 2) then
    Exit;

  Count := Std.DigitCount;
  SetLength(Bands, Count + 2);                           // Ziffern + Multiplikator + Toleranz

  // ----- 2. Ziffern von hinten nach vorne -----
  // Beispiel 470: Digits = 47 -> Ring 2 = 7 (violett), Ring 1 = 4 (gelb)
  Rest := Std.Digits;
  for I := Count - 1 downto 0 do
  begin
    Bands[I] := TBandColor(Rest mod 10);                 // letzte Ziffer
    Rest := Rest div 10;                                 // und weg damit
  end;

  // ----- 3. Multiplikator und Toleranz -----
  case Std.Exponent of
    -2: Bands[Count] := bcSilver;                        // × 0,01
    -1: Bands[Count] := bcGold;                          // × 0,1
  else
    Bands[Count] := TBandColor(Std.Exponent);            // × 10^Exponent, z. B. braun = × 10
  end;

  if Series = esE96 then
    Bands[Count + 1] := bcBrown                          // 1 % (Metallfilm, E96)
  else
    Bands[Count + 1] := bcGold;                          // 5 % (E12/E24)

  Result := True;
end;

end.
