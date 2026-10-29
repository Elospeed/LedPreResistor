{ Tests für uCalc: Beispielrechnung aus der Projektübersicht, Prüfungen,
  Belastbarkeit, Erwärmung und Eingabe mit Komma oder Punkt. }
unit TestCalc;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, uESeries, uCalc;

type
  { Prüft die Rechenlogik }
  TTestCalc = class(TTestCase)
  private
    { Liefert die Eingaben der Beispielrechnung: 12 V, 1 weisse LED 3,2 V, 20 mA, E12, ¼ W }
    function Beispiel: TCalcInput;
  published
    procedure BeispielRechnung;
    procedure BeispielBelastbarkeit;
    procedure MehrereLedsInReihe;
    procedure SpannungZuKlein;
    procedure UngueltigeEingaben;
    procedure Auslastungsstufen;
    procedure EmpfehlungBauform;
    procedure Erwaermung;
    procedure EingabeKommaUndPunkt;
  end;

implementation

function TTestCalc.Beispiel: TCalcInput;
begin
  Result := Default(TCalcInput);
  Result.U := 12;
  Result.Ud := 3.2;
  Result.I := 0.020;
  Result.N := 1;
  Result.Series := esE12;
  Result.RatingW := 0.25;
end;

procedure TTestCalc.BeispielRechnung;
var
  R: TCalcResult;  // Resultat
begin
  R := Calculate(Beispiel);
  AssertTrue('Status ok', R.Status = csOk);
  AssertEquals('U_R', 8.8, R.UR, 1e-9);
  AssertEquals('R berechnet', 440, R.RCalc, 1e-6);
  AssertEquals('Normwert E12', 470, R.R, 1e-9);
  AssertEquals('I tatsächlich in mA', 18.72, R.IAct * 1000, 0.005);      // 18,7234 mA
  AssertEquals('P Widerstand in mW', 164.77, R.PR * 1000, 0.005);        // 164,766 mW
  AssertEquals('P LED in mW', 59.91, R.PLed * 1000, 0.005);              // 59,915 mW
  AssertEquals('P total in mW', 224.68, R.PTotal * 1000, 0.005);         // 224,681 mW
  AssertEquals('P total = P_R + P_LED', R.PTotal, R.PR + R.PLed, 1e-12);
end;

procedure TTestCalc.BeispielBelastbarkeit;
var
  R: TCalcResult;  // Resultat
begin
  R := Calculate(Beispiel);
  AssertEquals('Auslastung ¼ W in %', 66, Round(R.Load * 100));
  AssertTrue('Warnung (gelb)', R.LoadLevel = llWarning);
  AssertEquals('Empfehlung ½ W', 0.5, R.RecommendedW, 1e-12);
end;

procedure TTestCalc.MehrereLedsInReihe;
var
  E: TCalcInput;   // Eingaben
  R: TCalcResult;  // Resultat
begin
  E := Beispiel;
  E.N := 3;        // 3 * 3,2 V = 9,6 V -> U_R = 2,4 V -> 120 Ω
  R := Calculate(E);
  AssertTrue(R.Status = csOk);
  AssertEquals(2.4, R.UR, 1e-9);
  AssertEquals(120, R.RCalc, 1e-6);
  AssertEquals(120, R.R, 1e-9);
  AssertEquals(20, R.IAct * 1000, 1e-6);
  AssertEquals(3 * 3.2 * 0.020, R.PLed, 1e-12);
end;

procedure TTestCalc.SpannungZuKlein;
var
  E: TCalcInput;   // Eingaben
begin
  E := Beispiel;
  E.N := 4;        // 4 * 3,2 V = 12,8 V > 12 V
  AssertTrue(Calculate(E).Status = csUTooLow);
  E.N := 1;
  E.U := 3.2;      // genau gleich: kein Strom möglich
  AssertTrue(Calculate(E).Status = csUTooLow);
end;

procedure TTestCalc.UngueltigeEingaben;
var
  E: TCalcInput;   // Eingaben
begin
  E := Beispiel; E.U := 0;   AssertTrue(Calculate(E).Status = csInvalidU);
  E := Beispiel; E.Ud := -1; AssertTrue(Calculate(E).Status = csInvalidUd);
  E := Beispiel; E.I := 0;   AssertTrue(Calculate(E).Status = csInvalidI);
  E := Beispiel; E.N := 0;   AssertTrue(Calculate(E).Status = csInvalidN);
end;

procedure TTestCalc.Auslastungsstufen;
begin
  AssertTrue(LoadLevelOf(0.5) = llOk);
  AssertTrue(LoadLevelOf(0.51) = llWarning);
  AssertTrue(LoadLevelOf(1.0) = llWarning);
  AssertTrue(LoadLevelOf(1.01) = llOverload);
end;

procedure TTestCalc.EmpfehlungBauform;
begin
  AssertEquals(0.125, RecommendRating(0.0625), 1e-12);
  AssertEquals(0.25, RecommendRating(0.07), 1e-12);
  AssertEquals(1.0, RecommendRating(0.5), 1e-12);
  AssertEquals('über 0,5 W reicht keine Bauform bis 1 W', 0, RecommendRating(0.51), 1e-12);
end;

procedure TTestCalc.Erwaermung;
var
  R: TCalcResult;  // Resultat
begin
  // Beispiel: 164,8 mW in ¼ W * 225 °C/W ≈ 37 °C
  R := Calculate(Beispiel);
  AssertEquals(37, Round(R.TempRise));
  // gleiche Leistung in ½ W: halber Wärmewiderstand
  AssertEquals(EstimateTempRise(0.1, 0.25) / 2, EstimateTempRise(0.1, 0.5), 1e-12);
end;

procedure TTestCalc.EingabeKommaUndPunkt;
var
  V: Double;  // umgewandelte Zahl
begin
  AssertTrue(ParseDecimal('3,2', V));  AssertEquals(3.2, V, 1e-12);
  AssertTrue(ParseDecimal('3.2', V));  AssertEquals(3.2, V, 1e-12);
  AssertTrue(ParseDecimal(' 12 ', V)); AssertEquals(12, V, 1e-12);
  AssertTrue(ParseDecimal(',5', V));   AssertEquals(0.5, V, 1e-12);
  AssertFalse(ParseDecimal('', V));
  AssertFalse(ParseDecimal('abc', V));
  AssertFalse(ParseDecimal('1.000,5', V));
  AssertFalse(ParseDecimal('1,2,3', V));
end;

initialization
  RegisterTest(TTestCalc);
end.
