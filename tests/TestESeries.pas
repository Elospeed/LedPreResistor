{ Tests für uESeries: Tabellen und Suche nach dem nächsthöheren Normwert. }
unit TestESeries;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, uESeries;

type
  { Prüft die Normreihen }
  TTestESeries = class(TTestCase)
  private
    { Sucht den Normwert zu R und prüft ihn gegen Expected (relativ 1e-12) }
    procedure CheckNext(R: Double; Series: TESeries; Expected: Double);
  published
    procedure AnzahlWerteProReihe;
    procedure ReihenAufsteigend;
    procedure Beispiel440OhmE12;
    procedure GenauerNormwertBleibt;
    procedure Genau330OhmBleibt330;
    procedure DekadenWechsel;
    procedure KleineUndGrosseWerte;
    procedure E24UndE96;
    procedure UngueltigeWerte;
  end;

implementation

uses
  SysUtils, Math;

procedure TTestESeries.CheckNext(R: Double; Series: TESeries; Expected: Double);
var
  Std: TStdValue;  // gefundener Normwert
begin
  AssertTrue('Normwert gefunden für ' + FloatToStrF(R, ffGeneral, 12, 0), NextStdValue(R, Series, Std));
  AssertTrue('Normwert zu ' + FloatToStrF(R, ffGeneral, 12, 0) + ': erwartet '
    + FloatToStrF(Expected, ffGeneral, 12, 0) + ', erhalten ' + FloatToStrF(Std.Value, ffGeneral, 12, 0),
    SameValue(Std.Value, Expected, Expected * 1e-12));
end;

procedure TTestESeries.AnzahlWerteProReihe;
begin
  AssertEquals(12, SeriesCount(esE12));
  AssertEquals(24, SeriesCount(esE24));
  AssertEquals(96, SeriesCount(esE96));
end;

procedure TTestESeries.ReihenAufsteigend;
var
  S: TESeries;  // geprüfte Reihe
  I: Integer;   // Index in der Reihe
begin
  for S := Low(TESeries) to High(TESeries) do
    for I := 1 to SeriesCount(S) - 1 do
      AssertTrue('Reihe aufsteigend', SeriesDigits(S, I) > SeriesDigits(S, I - 1));
end;

procedure TTestESeries.Beispiel440OhmE12;
var
  Std: TStdValue;  // gefundener Normwert
begin
  AssertTrue(NextStdValue(440, esE12, Std));
  AssertEquals(470.0, Std.Value, 1e-9);
  AssertEquals(47, Std.Digits);
  AssertEquals(2, Std.DigitCount);
  AssertEquals(1, Std.Exponent);
end;

procedure TTestESeries.GenauerNormwertBleibt;
begin
  CheckNext(470, esE12, 470);
  CheckNext(1000, esE12, 1000);
  CheckNext(4700, esE12, 4700);
  CheckNext(82, esE12, 82);
end;

procedure TTestESeries.Genau330OhmBleibt330;
begin
  // Fehler der Altversion: 3.3 * 100 = 329,99999… -> sprang auf 390
  CheckNext(3.3 * 100, esE12, 330);
  CheckNext(330, esE12, 330);
  CheckNext(330.000001, esE12, 390);
end;

procedure TTestESeries.DekadenWechsel;
begin
  CheckNext(83, esE12, 100);
  CheckNext(821, esE12, 1000);
  CheckNext(99.9, esE12, 100);
  CheckNext(100.1, esE12, 120);
end;

procedure TTestESeries.KleineUndGrosseWerte;
begin
  CheckNext(0.5, esE12, 0.56);
  CheckNext(1.05, esE12, 1.2);
  CheckNext(1, esE12, 1);
  CheckNext(1.5e6, esE12, 1.5e6);
  CheckNext(9.5e6, esE12, 10e6);
end;

procedure TTestESeries.E24UndE96;
var
  Std: TStdValue;  // gefundener Normwert
begin
  CheckNext(440, esE24, 470);
  CheckNext(431, esE24, 470);
  CheckNext(429, esE24, 430);
  CheckNext(440, esE96, 442);
  CheckNext(4900, esE96, 4990);
  CheckNext(977, esE96, 1000);
  AssertTrue(NextStdValue(4900, esE96, Std));
  AssertEquals(499, Std.Digits);
  AssertEquals(3, Std.DigitCount);
  AssertEquals(1, Std.Exponent);
end;

procedure TTestESeries.UngueltigeWerte;
var
  Std: TStdValue;  // gefundener Normwert
begin
  AssertFalse(NextStdValue(0, esE12, Std));
  AssertFalse(NextStdValue(-10, esE12, Std));
  AssertFalse(NextStdValue(NaN, esE12, Std));
end;

initialization
  RegisterTest(TTestESeries);
end.
