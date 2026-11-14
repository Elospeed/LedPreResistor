{==============================================================================
  TestESeries - Tests
==============================================================================
  Zweck:     Tests für uESeries: Tabellen und Suche nach dem nächsthöheren
             Normwert.

  Benutzung: Die Tests laufen mit LedPreResistorTests (FPCUnit). Jede
             Prozedur unter «published» ist ein Test.

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  Kommentare ausführlicher
             2.0  29.10.2026  erste Fassung
==============================================================================}
unit TestESeries;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, uESeries;

{==============================================================================
  TESTKLASSE
==============================================================================}
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
    procedure NormwertDarunter;
  end;

implementation

{==============================================================================
  TESTFÄLLE
==============================================================================}

uses
  SysUtils, Math;

{------------------------------------------------------------------------------
  CheckNext
------------------------------------------------------------------------------
  Hilfsroutine: prüft den nächsthöheren Normwert eines Werts.
------------------------------------------------------------------------------}
procedure TTestESeries.CheckNext(R: Double; Series: TESeries; Expected: Double);
var
  Std: TStdValue;                                        // gefundener Normwert
begin
  AssertTrue('Normwert gefunden für ' + FloatToStrF(R, ffGeneral, 12, 0), NextStdValue(R, Series, Std));
  AssertTrue('Normwert zu ' + FloatToStrF(R, ffGeneral, 12, 0) + ': erwartet '
    + FloatToStrF(Expected, ffGeneral, 12, 0) + ', erhalten ' + FloatToStrF(Std.Value, ffGeneral, 12, 0),
    SameValue(Std.Value, Expected, Expected * 1e-12));
end;

{------------------------------------------------------------------------------
  AnzahlWerteProReihe
------------------------------------------------------------------------------
  Jede Normreihe hat die richtige Anzahl Werte (12, 24, 96).
------------------------------------------------------------------------------}
procedure TTestESeries.AnzahlWerteProReihe;
begin
  AssertEquals(12, SeriesCount(esE12));
  AssertEquals(24, SeriesCount(esE24));
  AssertEquals(96, SeriesCount(esE96));
end;

{------------------------------------------------------------------------------
  ReihenAufsteigend
------------------------------------------------------------------------------
  Die Werte jeder Reihe sind aufsteigend sortiert.
------------------------------------------------------------------------------}
procedure TTestESeries.ReihenAufsteigend;
var
  S: TESeries;                                           // geprüfte Reihe
  I: Integer;                                            // Index in der Reihe
begin
  for S := Low(TESeries) to High(TESeries) do
    for I := 1 to SeriesCount(S) - 1 do
      AssertTrue('Reihe aufsteigend', SeriesDigits(S, I) > SeriesDigits(S, I - 1));
end;

{------------------------------------------------------------------------------
  Beispiel440OhmE12
------------------------------------------------------------------------------
  440 Ω in E12 wird zu 470 Ω.
------------------------------------------------------------------------------}
procedure TTestESeries.Beispiel440OhmE12;
var
  Std: TStdValue;                                        // gefundener Normwert
begin
  AssertTrue(NextStdValue(440, esE12, Std));
  AssertEquals(470.0, Std.Value, 1e-9);
  AssertEquals(47, Std.Digits);
  AssertEquals(2, Std.DigitCount);
  AssertEquals(1, Std.Exponent);
end;

{------------------------------------------------------------------------------
  GenauerNormwertBleibt
------------------------------------------------------------------------------
  Ein genauer Normwert bleibt unverändert.
------------------------------------------------------------------------------}
procedure TTestESeries.GenauerNormwertBleibt;
begin
  CheckNext(470, esE12, 470);
  CheckNext(1000, esE12, 1000);
  CheckNext(4700, esE12, 4700);
  CheckNext(82, esE12, 82);
end;

{------------------------------------------------------------------------------
  Genau330OhmBleibt330
------------------------------------------------------------------------------
  330 Ω bleibt 330 Ω (keine Rundungsfehler).
------------------------------------------------------------------------------}
procedure TTestESeries.Genau330OhmBleibt330;
begin
  // Fehler der Altversion: 3.3 * 100 = 329,99999… -> sprang auf 390
  CheckNext(3.3 * 100, esE12, 330);
  CheckNext(330, esE12, 330);
  CheckNext(330.000001, esE12, 390);
end;

{------------------------------------------------------------------------------
  DekadenWechsel
------------------------------------------------------------------------------
  Über dem grössten Wert einer Dekade geht es in der nächsten weiter.
------------------------------------------------------------------------------}
procedure TTestESeries.DekadenWechsel;
begin
  CheckNext(83, esE12, 100);
  CheckNext(821, esE12, 1000);
  CheckNext(99.9, esE12, 100);
  CheckNext(100.1, esE12, 120);
end;

{------------------------------------------------------------------------------
  KleineUndGrosseWerte
------------------------------------------------------------------------------
  Sehr kleine und sehr grosse Werte.
------------------------------------------------------------------------------}
procedure TTestESeries.KleineUndGrosseWerte;
begin
  CheckNext(0.5, esE12, 0.56);
  CheckNext(1.05, esE12, 1.2);
  CheckNext(1, esE12, 1);
  CheckNext(1.5e6, esE12, 1.5e6);
  CheckNext(9.5e6, esE12, 10e6);
end;

{------------------------------------------------------------------------------
  E24UndE96
------------------------------------------------------------------------------
  Suche in den Reihen E24 und E96.
------------------------------------------------------------------------------}
procedure TTestESeries.E24UndE96;
var
  Std: TStdValue;                                        // gefundener Normwert
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

{------------------------------------------------------------------------------
  UngueltigeWerte
------------------------------------------------------------------------------
  Null, negative und ungültige Zahlen liefern False.
------------------------------------------------------------------------------}
procedure TTestESeries.UngueltigeWerte;
var
  Std: TStdValue;                                        // gefundener Normwert
begin
  AssertFalse(NextStdValue(0, esE12, Std));
  AssertFalse(NextStdValue(-10, esE12, Std));
  AssertFalse(NextStdValue(NaN, esE12, Std));
end;

{------------------------------------------------------------------------------
  NormwertDarunter
------------------------------------------------------------------------------
  Suche nach dem nächstkleineren Normwert.
------------------------------------------------------------------------------}
procedure TTestESeries.NormwertDarunter;
var
  S: TStdValue;                                          // gefundener Normwert
begin
  AssertTrue(PrevStdValue(5350, esE12, S));
  AssertEquals('5,35 kΩ -> 4,7 kΩ', 4700, S.Value, 1e-9);
  AssertTrue(PrevStdValue(4700, esE12, S));
  AssertEquals('genauer Normwert bleibt', 4700, S.Value, 1e-9);
  AssertTrue(PrevStdValue(99, esE12, S));
  AssertEquals('Dekadenwechsel', 82, S.Value, 1e-9);
  AssertTrue(PrevStdValue(356.7, esE24, S));
  AssertEquals('E24', 330, S.Value, 1e-9);
  AssertFalse(PrevStdValue(0, esE12, S));
end;

initialization
  RegisterTest(TTestESeries);
end.
