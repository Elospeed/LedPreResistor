{==============================================================================
  TestAc - Tests
==============================================================================
  Zweck:     Tests für uAc: LEDs an Wechselspannung (Einfach mit Schutzdiode,
             Ohne Flackern mit Gleichrichter und Elko). Beispiel aus dem
             Unit-Kopf: Modellbahn-Trafo 16 V~, eine weisse LED (3,2 V),
             20 mA, E12. Mittelwerte werden zusätzlich mit einer einfachen
             Summe über 100 000 Punkte der Sinuskurve nachgerechnet, damit
             ein Fehler in den Formeln auffällt.

  Benutzung: Die Tests laufen mit LedPreResistorTests (FPCUnit). Jede
             Prozedur unter «published» ist ein Test.

  Autor:     Elospeed
  Versionen: 2.7  23.11.2026  neu (mit Rückstrom-Grenze und Hinweis «sehr dunkel»)
==============================================================================}
unit TestAc;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, uESeries, uAc;

{==============================================================================
  TESTKLASSE
==============================================================================}
type
  { Prüft die Rechnung für LEDs an Wechselspannung }
  TTestAc = class(TTestCase)
  private
    { Grundeingabe: 16 V~, 1 × 3,2 V, 20 mA, E12 }
    function Basis(Circuit: TAcCircuit): TAcInput;
  published
    procedure EinfachBeispiel;
    procedure EinfachMittelwertNumerisch;
    procedure EinfachGrosserStrom;
    procedure ElkoBeispiel;
    procedure ElkoNormwerte;
    procedure SpannungZuKlein;
    procedure EinfachVieleLeds;
    procedure Fehler;
  end;

implementation

uses
  Math;                                                  // Sin, Sqr, Pi

{------------------------------------------------------------------------------
  Numerisch
------------------------------------------------------------------------------
  Mittelwert von Strom bzw. Leistung über eine Periode, als Summe über viele
  Punkte gerechnet (unabhängig von den Formeln in uAc).
  Parameter: UPeak - Spitze (V); UFwd - Spannung am Bauteil in Reihe (V);
             R - Widerstand (Ω); Power - True: Leistung in R, sonst Strom
  Rückgabe:  Mittelwert (A bzw. W)
------------------------------------------------------------------------------}
function Numerisch(UPeak, UFwd, R: Double; Power: Boolean): Double;
const
  STEPS = 100000;                                        // Punkte pro Periode
var
  K: Integer;                                            // Zähler
  U: Double;                                             // Spannung am Widerstand (V)
  Sum: Double;                                           // Summe
begin
  Sum := 0;
  for K := 0 to STEPS - 1 do
  begin
    U := UPeak * Sin(2 * Pi * (K + 0.5) / STEPS) - UFwd;
    if U > 0 then
      if Power then Sum := Sum + Sqr(U) / R else Sum := Sum + U / R;
  end;
  Result := Sum / STEPS;
end;

{------------------------------------------------------------------------------
  Basis
------------------------------------------------------------------------------
  Grund-Eingaben, auf denen die einzelnen Tests aufbauen.
------------------------------------------------------------------------------}
function TTestAc.Basis(Circuit: TAcCircuit): TAcInput;
begin
  Result := Default(TAcInput);
  Result.Circuit := Circuit;
  Result.U := 16;
  Result.Ud := 3.2;
  Result.I := 0.020;
  Result.N := 1;
  Result.Series := esE12;
end;

{------------------------------------------------------------------------------
  EinfachBeispiel
------------------------------------------------------------------------------
  16 V~: Spitze 22,63 V, R = 971 Ω -> 1 kΩ, Spitzenstrom 19,4 mA,
  Schutzdiode 1N4148, Sperrspannung an der LED 0,7 V.
------------------------------------------------------------------------------}
procedure TTestAc.EinfachBeispiel;
var
  R: TAcResult;                                          // Resultat
begin
  R := CalculateAc(Basis(acSimple));
  AssertTrue('Status', R.Status = asOk);
  AssertEquals('Spitze', 22.627, R.UPeak, 0.001);
  AssertEquals('R berechnet', 971.4, R.RCalc, 0.1);
  AssertEquals('R Normwert', 1000, R.R, 1e-9);
  AssertEquals('Spitzenstrom', 0.019427, R.IPeak, 1e-5);
  AssertTrue('Spitze höchstens I', R.IPeak <= 0.020);
  AssertEquals('Mittelwert', 0.00567, R.IAvg, 0.00005);
  AssertTrue('Helligkeit unter 35 %', (R.Brightness > 0.25) and (R.Brightness < 0.35));
  AssertTrue('Diode 1N4148', R.Diode = ad1N4148);
  AssertEquals('Sperrspannung LED', 0.7, R.URevLed, 1e-9);
  AssertEquals('Sperrspannung Diode', 3.2, R.URevDiode, 1e-9);
  AssertEquals('Strom Schutzdiode', 0.021927, R.IRevPeak, 1e-5);
  AssertEquals('Bauform', 0.5, R.RRating, 1e-9);           // etwa 0,21 W: ¼ W wäre über 50 % ausgelastet
end;

{------------------------------------------------------------------------------
  EinfachMittelwertNumerisch
------------------------------------------------------------------------------
  Strom und Leistung der Formeln stimmen mit der Summe über die Sinuskurve
  überein (auch mit mehreren LEDs und anderer Spannung).
------------------------------------------------------------------------------}
procedure TTestAc.EinfachMittelwertNumerisch;
var
  Inp: TAcInput;                                         // Eingabe
  R: TAcResult;                                          // Resultat
begin
  Inp := Basis(acSimple);
  Inp.U := 12;
  Inp.N := 3;
  Inp.Ud := 2.0;
  R := CalculateAc(Inp);
  AssertTrue('Status', R.Status = asOk);
  AssertEquals('Mittelwert', Numerisch(R.UPeak, R.ULeds, R.R, False), R.IAvg, 1e-7);
  AssertEquals('Leistung R', Numerisch(R.UPeak, R.ULeds, R.R, True)
    + Numerisch(R.UPeak, AC_UD_DIODE, R.R, True), R.PR, 1e-6);
  AssertEquals('Leistung LEDs', R.ULeds * R.IAvg, R.PLeds, 1e-12);
end;

{------------------------------------------------------------------------------
  EinfachGrosserStrom
------------------------------------------------------------------------------
  500 mA: Rückstrom über 300 mA, darum 1N4007 statt 1N4148; Leistung über
  1 W gibt den Hinweis awRPower.
------------------------------------------------------------------------------}
procedure TTestAc.EinfachGrosserStrom;
var
  Inp: TAcInput;                                         // Eingabe
  R: TAcResult;                                          // Resultat
begin
  Inp := Basis(acSimple);
  Inp.I := 0.5;
  R := CalculateAc(Inp);
  AssertTrue('Status', R.Status = asOk);
  AssertTrue('Diode 1N4007', R.Diode = ad1N4007);
  AssertTrue('Hinweis Leistung', awRPower in R.Warnings);
end;

{------------------------------------------------------------------------------
  ElkoBeispiel
------------------------------------------------------------------------------
  16 V~ mit Gleichrichter: 21,2 V am Elko, 61 µF -> 68 µF, 35 V,
  R = 828 Ω -> 1 kΩ, Strom 16,6 mA, Schwankung unter ±10 %.
------------------------------------------------------------------------------}
procedure TTestAc.ElkoBeispiel;
var
  R: TAcResult;                                          // Resultat
begin
  R := CalculateAc(Basis(acBridge));
  AssertTrue('Status', R.Status = asOk);
  AssertEquals('Spitze am Elko', 21.227, R.UDc, 0.001);
  AssertEquals('C berechnet', 61.0e-6, R.CCalc, 0.1e-6);
  AssertEquals('C Normwert', 68e-6, R.C, 1e-12);
  AssertEquals('Elko-Spannung', 35, R.CVolt, 1e-9);
  AssertEquals('Brumm', 2.941, R.Ripple, 0.001);
  AssertEquals('R berechnet', 827.8, R.RCalc, 0.1);
  AssertEquals('R Normwert', 1000, R.R, 1e-9);
  AssertEquals('Strom', 0.016557, R.IAct, 1e-5);
  AssertTrue('Schwankung', R.IRipple < 0.1);
  AssertEquals('Leistung R', R.IAct * R.IAct * R.R, R.PR, 1e-9);
  AssertTrue('kein grosser Elko', not (awBigCap in R.Warnings));
end;

{------------------------------------------------------------------------------
  ElkoNormwerte
------------------------------------------------------------------------------
  Elko-Normwerte E6 und Nennspannungen.
------------------------------------------------------------------------------}
procedure TTestAc.ElkoNormwerte;
begin
  AssertEquals('61 µF', 68e-6, NextCapValue(61e-6), 1e-12);
  AssertEquals('100 µF', 100e-6, NextCapValue(100e-6), 1e-12);
  AssertEquals('4,8 µF', 6.8e-6, NextCapValue(4.8e-6), 1e-12);
  AssertEquals('0,7 µF', 1e-6, NextCapValue(0.7e-6), 1e-12);
  AssertEquals('5000 µF', 6800e-6, NextCapValue(5000e-6), 1e-12);
  AssertEquals('26,5 V', 35, CapVoltage(26.5), 1e-9);
  AssertEquals('10 V', 10, CapVoltage(10), 1e-9);
  AssertEquals('über 100 V', 0, CapVoltage(101), 1e-9);
end;

{------------------------------------------------------------------------------
  SpannungZuKlein
------------------------------------------------------------------------------
  Fünf weisse LEDs (16 V) an 12 V~: Spitze 17 V reicht nicht.
------------------------------------------------------------------------------}
procedure TTestAc.SpannungZuKlein;
var
  Inp: TAcInput;                                         // Eingabe
  R: TAcResult;                                          // Resultat
begin
  Inp := Basis(acSimple);
  Inp.U := 12;
  Inp.N := 5;
  R := CalculateAc(Inp);
  AssertTrue('Einfach', R.Status = asUTooLow);
  AssertEquals('nötig', 16 / 0.75 / Sqrt(2), R.UNeedAc, 1e-6);   // ein Viertel bleibt am R
  Inp.Circuit := acBridge;
  R := CalculateAc(Inp);
  AssertTrue('Elko', R.Status = asUTooLow);
end;

{------------------------------------------------------------------------------
  EinfachVieleLeds
------------------------------------------------------------------------------
  Viele LEDs in «Einfach»: R wird klein, der Rückstrom durch die
  Schutzdiode gross. 16 V~, 4 × 3,2 V: Hinweis «sehr dunkel» (unter 20 %);
  42 V~, 18 × 3,2 V: zu wenig Spannung bleibt am R (Fehler);
  42 V~, 13 × 3,2 V, 0,5 A: Rückstrom 1,5 A über 1 A ist ein Fehler.
------------------------------------------------------------------------------}
procedure TTestAc.EinfachVieleLeds;
var
  Inp: TAcInput;                                         // Eingabe
  R: TAcResult;                                          // Resultat
begin
  Inp := Basis(acSimple);
  Inp.N := 3;
  R := CalculateAc(Inp);
  AssertTrue('3 LEDs hell genug', not (awDim in R.Warnings));
  Inp.N := 4;
  R := CalculateAc(Inp);
  AssertTrue('Status 4', R.Status = asOk);
  AssertTrue('4 LEDs dunkel', awDim in R.Warnings);
  Inp.U := 42;
  Inp.N := 18;
  R := CalculateAc(Inp);
  AssertTrue('18 LEDs: zu wenig Reserve am R', R.Status = asUTooLow);
  Inp.N := 13;                                           // 42 V~, 13 LEDs, 0,5 A: R = 39 Ω
  Inp.I := 0.5;
  R := CalculateAc(Inp);
  AssertTrue('Rückstrom', R.Status = asRevTooHigh);
  AssertTrue('Rückstrom über 1 A', R.IRevPeak > AC_I_REV_MAX);
end;

{------------------------------------------------------------------------------
  Fehler
------------------------------------------------------------------------------
  Ungültige Eingaben und Grenzen: 42 V~ und 1 A.
------------------------------------------------------------------------------}
procedure TTestAc.Fehler;
var
  Inp: TAcInput;                                         // Eingabe
begin
  Inp := Basis(acBridge);
  Inp.U := 0;
  AssertTrue('U 0', CalculateAc(Inp).Status = asInvalidU);
  Inp.U := 42.5;
  AssertTrue('U zu gross', CalculateAc(Inp).Status = asOverVoltage);
  Inp.U := 42;
  AssertTrue('42 V erlaubt', CalculateAc(Inp).Status = asOk);
  Inp := Basis(acSimple);
  Inp.I := 1.2;
  AssertTrue('I zu gross', CalculateAc(Inp).Status = asTooMuchCurrent);
  Inp := Basis(acSimple);
  Inp.Ud := 0;
  AssertTrue('Ud 0', CalculateAc(Inp).Status = asInvalidUd);
  Inp := Basis(acSimple);
  Inp.N := 0;
  AssertTrue('N 0', CalculateAc(Inp).Status = asInvalidN);
end;

initialization
  RegisterTest(TTestAc);
end.
