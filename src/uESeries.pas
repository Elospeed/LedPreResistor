{ Normreihen E12, E24 und E96 und die Suche nach dem nächsthöheren Normwert.
  Reine Rechenlogik ohne GUI, wird von uCalc und uColorCode benutzt und im
  Testprojekt (tests/) geprüft. }
unit uESeries;

{$mode objfpc}{$H+}

interface

type
  { Die wählbaren Normreihen }
  TESeries = (esE12, esE24, esE96);

  { Ein Normwert, zerlegt in Ziffern und Zehnerpotenz:
    Value = Digits * 10^Exponent, z. B. 470 Ω = 47 * 10^1 (E12)
    oder 4,99 kΩ = 499 * 10^1 (E96). Diese Zerlegung braucht der Farbcode. }
  TStdValue = record
    Value: Double;        // Widerstandswert in Ω
    Digits: Integer;      // Ziffernfolge aus der Reihe (2-stellig bei E12/E24, 3-stellig bei E96)
    DigitCount: Integer;  // Anzahl Ziffern: 2 oder 3
    Exponent: Integer;    // Zehnerpotenz, mit der Digits multipliziert wird
  end;

const
  { Relative Toleranz beim Vergleich mit dem berechneten Wert. Ohne sie wird
    z. B. aus 3,3 * 100 = 329,99999… ein berechneter Wert von genau 330 Ω
    fälschlich auf 390 Ω aufgerundet (Fehler der Altversion). }
  E_TOLERANCE = 1e-9;

{ Liefert die Anzahl Werte pro Dekade der Reihe (12, 24 oder 96). }
function SeriesCount(Series: TESeries): Integer;

{ Liefert die Ziffernfolge Nummer Index (0-basiert) der Reihe,
  z. B. SeriesDigits(esE12, 8) = 47. }
function SeriesDigits(Series: TESeries; Index: Integer): Integer;

{ Liefert die Anzahl Ziffern der Reihe: 2 bei E12/E24, 3 bei E96. }
function SeriesDigitCount(Series: TESeries): Integer;

{ Sucht den kleinsten Normwert der Reihe, der grösser oder gleich R ist
  (über alle Dekaden). R muss grösser als 0 sein, sonst wird False geliefert. }
function NextStdValue(R: Double; Series: TESeries; out Std: TStdValue): Boolean;

implementation

uses
  Math;

const
  { Ziffernfolgen der Reihen nach IEC 60063 }
  E12_DIGITS: array[0..11] of Integer =
    (10, 12, 15, 18, 22, 27, 33, 39, 47, 56, 68, 82);

  E24_DIGITS: array[0..23] of Integer =
    (10, 11, 12, 13, 15, 16, 18, 20, 22, 24, 27, 30,
     33, 36, 39, 43, 47, 51, 56, 62, 68, 75, 82, 91);

  E96_DIGITS: array[0..95] of Integer =
    (100, 102, 105, 107, 110, 113, 115, 118, 121, 124, 127, 130,
     133, 137, 140, 143, 147, 150, 154, 158, 162, 165, 169, 174,
     178, 182, 187, 191, 196, 200, 205, 210, 215, 221, 226, 232,
     237, 243, 249, 255, 261, 267, 274, 280, 287, 294, 301, 309,
     316, 324, 332, 340, 348, 357, 365, 374, 383, 392, 402, 412,
     422, 432, 442, 453, 464, 475, 487, 499, 511, 523, 536, 549,
     562, 576, 590, 604, 619, 634, 649, 665, 681, 698, 715, 732,
     750, 768, 787, 806, 825, 845, 866, 887, 909, 931, 953, 976);

function SeriesCount(Series: TESeries): Integer;
begin
  case Series of
    esE12: Result := Length(E12_DIGITS);
    esE24: Result := Length(E24_DIGITS);
  else
    Result := Length(E96_DIGITS);
  end;
end;

function SeriesDigits(Series: TESeries; Index: Integer): Integer;
begin
  case Series of
    esE12: Result := E12_DIGITS[Index];
    esE24: Result := E24_DIGITS[Index];
  else
    Result := E96_DIGITS[Index];
  end;
end;

function SeriesDigitCount(Series: TESeries): Integer;
begin
  if Series = esE96 then
    Result := 3
  else
    Result := 2;
end;

function NextStdValue(R: Double; Series: TESeries; out Std: TStdValue): Boolean;
var
  Decade: Integer;     // Zehnerpotenz von R (z. B. 2 für 440 Ω)
  E: Integer;          // Zehnerpotenz, die gerade durchsucht wird
  I: Integer;          // Index in der Ziffernfolge
  DigitCount: Integer; // 2 oder 3 Ziffern je nach Reihe
  V: Double;           // Kandidat in Ω
begin
  Result := False;
  Std := Default(TStdValue);
  // NaN zuerst prüfen: ein Vergleich mit NaN löst sonst eine Exception aus
  if IsNan(R) or IsInfinite(R) or (R <= 0) then
    Exit;

  DigitCount := SeriesDigitCount(Series);
  Decade := Floor(Log10(R));
  { Eine Dekade darunter beginnen, falls Log10 wegen Rundung knapp daneben
    liegt; die erste Dekade, in der ein Wert passt, liefert den kleinsten. }
  for E := Decade - 1 to Decade + 1 do
    for I := 0 to SeriesCount(Series) - 1 do
    begin
      // Ziffern auf die Dekade bringen: 47 bei 2 Ziffern = 4,7 * 10^E
      V := SeriesDigits(Series, I) * IntPower(10, E - DigitCount + 1);
      if V >= R * (1 - E_TOLERANCE) then
      begin
        Std.Value := V;
        Std.Digits := SeriesDigits(Series, I);
        Std.DigitCount := DigitCount;
        Std.Exponent := E - DigitCount + 1;
        Exit(True);
      end;
    end;
end;

end.
