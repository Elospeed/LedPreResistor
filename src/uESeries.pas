{==============================================================================
  uESeries - Normreihen E12, E24 und E96
==============================================================================
  Zweck:     Widerstände gibt es nur in genormten Werten (IEC 60063). Diese
             Unit kennt die Reihen E12, E24 und E96 und sucht zu einem
             berechneten Wert den passenden Normwert:
               NextStdValue - nächster Wert DARÜBER (Vorwiderstand: der
                              Strom wird eher etwas kleiner, schont die LED)
               PrevStdValue - nächster Wert DARUNTER (Basiswiderstand:
                              lieber etwas mehr Strom)
             Beispiel E12: 440 Ω -> 470 Ω (darüber), 5,35 kΩ -> 4,7 kΩ
             (darunter).

  Aufbau:    Jede Reihe ist eine Liste von Ziffernfolgen pro Dekade, z. B.
             E12 = 10, 12, 15, 18, 22, 27, 33, 39, 47, 56, 68, 82.
             Ein Normwert = Ziffern × 10^Exponent (470 Ω = 47 × 10^1).
             Diese Zerlegung braucht uColorCode für die Farbringe.

  Regeln:    Reine Rechenlogik ohne Oberfläche; geprüft im Testprojekt
             (tests/TestESeries.pas).

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  PrevStdValue (Basiswiderstand der Konstantstromquelle)
             2.0  29.10.2026  erste Fassung
==============================================================================}
unit uESeries;

{$mode objfpc}{$H+}

interface

{==============================================================================
  TYPEN
==============================================================================}
type
  // Die wählbaren Normreihen
  TESeries = (
    esE12,                                               // 12 Werte pro Dekade, ±10 %
    esE24,                                               // 24 Werte pro Dekade, ±5 %
    esE96                                                // 96 Werte pro Dekade, ±1 %
  );

  // Ein Normwert, zerlegt in Ziffern und Zehnerpotenz:
  //   Value = Digits × 10^Exponent
  //   z. B. 470 Ω = 47 × 10^1 (E12) oder 4,99 kΩ = 499 × 10^1 (E96)
  TStdValue = record
    Value: Double;                                       // Widerstandswert in Ω
    Digits: Integer;                                     // Ziffernfolge aus der Reihe (2-stellig bei E12/E24, 3-stellig bei E96)
    DigitCount: Integer;                                 // Anzahl Ziffern: 2 oder 3
    Exponent: Integer;                                   // Zehnerpotenz, mit der Digits multipliziert wird
  end;

{==============================================================================
  KONSTANTEN
==============================================================================}
const
  // Relative Toleranz beim Vergleich mit dem berechneten Wert. Ohne sie
  // wird z. B. aus 3,3 × 100 = 329,99999... ein berechneter Wert von genau
  // 330 Ω fälschlich auf 390 Ω aufgerundet (Fehler der Altversion).
  E_TOLERANCE = 1e-9;

{==============================================================================
  ÖFFENTLICHE FUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  SeriesCount
------------------------------------------------------------------------------
  Liefert die Anzahl Werte pro Dekade der Reihe (12, 24 oder 96).
------------------------------------------------------------------------------}
function SeriesCount(Series: TESeries): Integer;

{------------------------------------------------------------------------------
  SeriesDigits
------------------------------------------------------------------------------
  Liefert die Ziffernfolge Nummer Index (0-basiert) der Reihe,
  z. B. SeriesDigits(esE12, 8) = 47.
------------------------------------------------------------------------------}
function SeriesDigits(Series: TESeries; Index: Integer): Integer;

{------------------------------------------------------------------------------
  SeriesDigitCount
------------------------------------------------------------------------------
  Liefert die Anzahl Ziffern der Reihe: 2 bei E12/E24, 3 bei E96.
------------------------------------------------------------------------------}
function SeriesDigitCount(Series: TESeries): Integer;

{------------------------------------------------------------------------------
  NextStdValue
------------------------------------------------------------------------------
  Sucht den kleinsten Normwert der Reihe, der grösser oder gleich R ist
  (über alle Dekaden). R muss grösser als 0 sein, sonst wird False geliefert.
------------------------------------------------------------------------------}
function NextStdValue(R: Double; Series: TESeries; out Std: TStdValue): Boolean;

{------------------------------------------------------------------------------
  PrevStdValue
------------------------------------------------------------------------------
  Wie NextStdValue, aber der grösste Normwert, der höchstens R ist
  (z. B. 5,35 kΩ -> 4,7 kΩ in E12). Für Widerstände, die eher etwas mehr
  Strom liefern sollen (Basiswiderstand).
------------------------------------------------------------------------------}
function PrevStdValue(R: Double; Series: TESeries; out Std: TStdValue): Boolean;

implementation

uses
  Math;                                                  // Floor, Log10, IntPower, IsNan

{==============================================================================
  ZIFFERNFOLGEN DER REIHEN (IEC 60063)
------------------------------------------------------------------------------
  Pro Dekade; E12/E24 zweistellig (10 = 1,0), E96 dreistellig (100 = 1,00).
==============================================================================}
const
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

{------------------------------------------------------------------------------
  SeriesCount - siehe Interface
------------------------------------------------------------------------------}
function SeriesCount(Series: TESeries): Integer;
begin
  case Series of
    esE12: Result := Length(E12_DIGITS);
    esE24: Result := Length(E24_DIGITS);
  else
    Result := Length(E96_DIGITS);
  end;
end;

{------------------------------------------------------------------------------
  SeriesDigits - siehe Interface
------------------------------------------------------------------------------}
function SeriesDigits(Series: TESeries; Index: Integer): Integer;
begin
  case Series of
    esE12: Result := E12_DIGITS[Index];
    esE24: Result := E24_DIGITS[Index];
  else
    Result := E96_DIGITS[Index];
  end;
end;

{------------------------------------------------------------------------------
  SeriesDigitCount - siehe Interface
------------------------------------------------------------------------------}
function SeriesDigitCount(Series: TESeries): Integer;
begin
  if Series = esE96 then
    Result := 3
  else
    Result := 2;
end;

{------------------------------------------------------------------------------
  NextStdValue - siehe Interface
------------------------------------------------------------------------------}
function NextStdValue(R: Double; Series: TESeries; out Std: TStdValue): Boolean;
var
  Decade: Integer;                                       // Zehnerpotenz von R (z. B. 2 für 440 Ω)
  E: Integer;                                            // Zehnerpotenz, die gerade durchsucht wird
  I: Integer;                                            // Index in der Ziffernfolge
  DigitCount: Integer;                                   // 2 oder 3 Ziffern je nach Reihe
  V: Double;                                             // Kandidat in Ω
begin
  Result := False;
  Std := Default(TStdValue);
  // NaN zuerst prüfen: ein Vergleich mit NaN löst sonst eine Exception aus
  if IsNan(R) or IsInfinite(R) or (R <= 0) then
    Exit;

  DigitCount := SeriesDigitCount(Series);
  Decade := Floor(Log10(R));                             // z. B. 440 Ω -> 2
  // Eine Dekade darunter beginnen, falls Log10 wegen Rundung knapp daneben
  // liegt; die erste Dekade, in der ein Wert passt, liefert den kleinsten.
  for E := Decade - 1 to Decade + 1 do
    for I := 0 to SeriesCount(Series) - 1 do
    begin
      // Ziffern auf die Dekade bringen: 47 bei 2 Ziffern = 4,7 * 10^E
      V := SeriesDigits(Series, I) * IntPower(10, E - DigitCount + 1);
      if V >= R * (1 - E_TOLERANCE) then                 // erster Wert >= R: gefunden
      begin
        Std.Value := V;
        Std.Digits := SeriesDigits(Series, I);
        Std.DigitCount := DigitCount;
        Std.Exponent := E - DigitCount + 1;
        Exit(True);
      end;
    end;
end;

{------------------------------------------------------------------------------
  PrevStdValue - siehe Interface
------------------------------------------------------------------------------}
function PrevStdValue(R: Double; Series: TESeries; out Std: TStdValue): Boolean;
var
  Decade: Integer;                                       // Zehnerpotenz von R
  E: Integer;                                            // Zehnerpotenz, die gerade durchsucht wird
  I: Integer;                                            // Index in der Ziffernfolge
  DigitCount: Integer;                                   // 2 oder 3 Ziffern je nach Reihe
  V: Double;                                             // Kandidat in Ω
begin
  Result := False;
  Std := Default(TStdValue);
  if IsNan(R) or IsInfinite(R) or (R <= 0) then
    Exit;

  DigitCount := SeriesDigitCount(Series);
  Decade := Floor(Log10(R));
  // von oben nach unten suchen: der erste Wert, der passt, ist der grösste
  for E := Decade + 1 downto Decade - 1 do
    for I := SeriesCount(Series) - 1 downto 0 do
    begin
      V := SeriesDigits(Series, I) * IntPower(10, E - DigitCount + 1);
      if V <= R * (1 + E_TOLERANCE) then                 // erster Wert <= R: gefunden
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
