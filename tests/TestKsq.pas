{==============================================================================
  TestKsq - Tests
==============================================================================
  Zweck:     Tests für uKsq: LM317 und Konstantstromquelle mit zwei
             Transistoren. Beispiel aus dem Konzept: Auto 12–14,4 V, zwei
             weisse LEDs (3,2 V), 20 mA.

  Benutzung: Die Tests laufen mit LedPreResistorTests (FPCUnit). Jede
             Prozedur unter «published» ist ein Test.

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  neu
==============================================================================}
unit TestKsq;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, uESeries, uKsq;

{==============================================================================
  TESTKLASSE
==============================================================================}
type
  { Prüft die Rechnung der Konstantstromquellen }
  TTestKsq = class(TTestCase)
  private
    { Grundeingabe: 12–14,4 V, 2 × 3,2 V, 20 mA, E12 }
    function Basis(Circuit: TKsqCircuit): TKsqInput;
  published
    procedure LM317Beispiel;
    procedure LM317GrosserStrom;
    procedure LM317KleinerStrom;
    procedure TransistorenBeispiel;
    procedure TransistorenGrosserStrom;
    procedure BereichVertauschtUndLeer;
    procedure SpannungZuKlein;
    procedure Fehler;
  end;

implementation

{==============================================================================
  TESTFÄLLE
==============================================================================}

{------------------------------------------------------------------------------
  Basis
------------------------------------------------------------------------------
  Liefert Grund-Eingaben für die gewählte Schaltung, auf denen die einzelnen
  Tests aufbauen.
------------------------------------------------------------------------------}
function TTestKsq.Basis(Circuit: TKsqCircuit): TKsqInput;
begin
  Result := Default(TKsqInput);
  Result.Circuit := Circuit;
  Result.UMin := 12;
  Result.UMax := 14.4;
  Result.Ud := 3.2;
  Result.I := 0.020;
  Result.N := 2;
  Result.Series := esE12;
end;

{------------------------------------------------------------------------------
  LM317Beispiel
------------------------------------------------------------------------------
  LM317-Beispiel aus dem Konzept: Auto 12 ... 14,4 V, zwei weisse LEDs, 20
  mA.
------------------------------------------------------------------------------}
procedure TTestKsq.LM317Beispiel;
var
  R: TKsqResult;                                         // Resultat
begin
  R := CalculateKsq(Basis(kcLM317));
  AssertTrue('Status', R.Status = ksOk);
  AssertEquals('R berechnet', 62.5, R.RCalc, 1e-9);
  AssertEquals('R Normwert', 68, R.R, 1e-9);
  AssertEquals('I in mA', 18.382, R.IAct * 1000, 0.001);
  AssertEquals('P_R in mW', 22.98, R.PR * 1000, 0.01);
  AssertEquals('Bauform ⅛ W', 0.125, R.RRating, 1e-12);
  AssertEquals('Mindestspannung', 9.65, R.UNeed, 1e-9);
  AssertEquals('Reserve', 2.35, R.Reserve, 1e-9);
  AssertEquals('Verlust bei 12 V in mW', 79.96, R.PLossMin * 1000, 0.01);
  AssertEquals('Verlust bei 14,4 V in mW', 124.08, R.PLossMax * 1000, 0.01);
  AssertTrue('LM317L reicht', R.Part = kpLM317L);
  AssertTrue('keine Hinweise', R.Warnings = []);
  AssertEquals('Vorwiderstand +43 %', 0.4286, R.RvRise, 0.0001);
  AssertEquals('Vorwiderstand bei 12 V', 280, R.RvCalc, 1e-6);
  AssertEquals('LM317 hält den Strom', 0, R.KsqRise, 1e-12);
end;

{------------------------------------------------------------------------------
  LM317GrosserStrom
------------------------------------------------------------------------------
  LM317 mit grossem Strom: Bauteil, Verlust und Kühlkörper-Hinweis.
------------------------------------------------------------------------------}
procedure TTestKsq.LM317GrosserStrom;
var
  E: TKsqInput;                                          // Eingabe
  R: TKsqResult;                                         // Resultat
begin
  E := Basis(kcLM317);
  E.I := 0.35;                                           // 1-W-LED: 1,25 V / 0,35 A = 3,57 Ω -> 3,9 Ω
  E.N := 1;
  E.Ud := 3.3;
  R := CalculateKsq(E);
  AssertTrue(R.Status = ksOk);
  AssertEquals(3.9, R.R, 1e-9);
  AssertTrue('LM317 im TO-220', R.Part = kpLM317);
  // Verlust bei 14,4 V: (14,4 − 3,3 − 1,25) · 0,3205 A = 3,16 W
  AssertEquals(3.157, R.PLossMax, 0.001);
  AssertTrue('Kühlkörper', kwHeatsink in R.Warnings);
  // 70 K / 3,157 W − 5 − 1 = 16,2 K/W
  AssertEquals(16.17, R.HeatsinkRth, 0.01);
  // 1,25 V · 0,32 A = 0,4 W: mit höchstens 50 % Auslastung 1 W
  AssertEquals('Fühlerwiderstand 1 W', 1.0, R.RRating, 1e-12);
end;

{------------------------------------------------------------------------------
  LM317KleinerStrom
------------------------------------------------------------------------------
  LM317 unter dem Mindestlaststrom: Hinweis.
------------------------------------------------------------------------------}
procedure TTestKsq.LM317KleinerStrom;
var
  E: TKsqInput;                                          // Eingabe
begin
  E := Basis(kcLM317);
  E.I := 0.002;
  AssertTrue(kwMinLoad in CalculateKsq(E).Warnings);
end;

{------------------------------------------------------------------------------
  TransistorenBeispiel
------------------------------------------------------------------------------
  Zwei Transistoren, Beispiel aus dem Konzept: R_S und R_B.
------------------------------------------------------------------------------}
procedure TTestKsq.TransistorenBeispiel;
var
  R: TKsqResult;                                         // Resultat
begin
  R := CalculateKsq(Basis(kcTransistors));
  AssertTrue(R.Status = ksOk);
  AssertEquals('R_S berechnet', 30, R.RCalc, 1e-9);
  AssertEquals('R_S Normwert', 33, R.R, 1e-9);
  AssertEquals('I in mA', 18.182, R.IAct * 1000, 0.001);
  AssertEquals('Mindestspannung', 7.6, R.UNeed, 1e-9);
  AssertEquals('Verlust bei 12 V in mW', 90.91, R.PLossMin * 1000, 0.01);
  AssertEquals('Verlust bei 14,4 V in mW', 134.55, R.PLossMax * 1000, 0.01);
  AssertTrue('T1 BC547 reicht', R.Part = kpBC547);
  AssertEquals('R_B berechnet', 5350, R.RBCalc, 1e-6);
  AssertEquals('R_B Normwert darunter', 4700, R.RB, 1e-9);
  AssertEquals('I_RB bei 14,4 V in mA', 2.787, R.IRBMax * 1000, 0.001);
  AssertEquals('R_B ⅛ W', 0.125, R.RBRating, 1e-12);
  AssertTrue('keine Hinweise', R.Warnings = []);
  // U_BE von T2 steigt um 26 mV · ln(13,1 / 10,7) = 5,3 mV -> +0,88 %
  AssertEquals('fast gleich', 0.0088, R.KsqRise, 0.0001);
end;

{------------------------------------------------------------------------------
  TransistorenGrosserStrom
------------------------------------------------------------------------------
  Zwei Transistoren mit grossem Strom: stärkerer Transistor und Basisstrom.
------------------------------------------------------------------------------}
procedure TTestKsq.TransistorenGrosserStrom;
var
  E: TKsqInput;                                          // Eingabe
  R: TKsqResult;                                         // Resultat
begin
  E := Basis(kcTransistors);
  E.UMax := 0;                                           // feste 12 V
  E.N := 3;
  E.I := 0.7;                                            // 0,6 V / 0,7 A = 0,857 Ω -> 1 Ω -> 0,6 A
  R := CalculateKsq(E);
  AssertTrue(R.Status = ksOk);
  AssertEquals(1.0, R.R, 1e-9);
  AssertEquals(0.6, R.IAct, 1e-9);
  AssertTrue('BD139', R.Part = kpBD139);
  AssertEquals('Verlust', 1.08, R.PLossMax, 1e-9);
  AssertTrue(kwHeatsink in R.Warnings);
  // β = 40: I_B = 15 mA, I_RB = 30 mA -> 356,7 Ω -> 330 Ω, 0,35 W -> Hinweis
  AssertEquals(330, R.RB, 1e-9);
  AssertTrue(kwBaseHigh in R.Warnings);
  AssertEquals('kein Bereich', 0, R.RvRise, 1e-12);
end;

{------------------------------------------------------------------------------
  BereichVertauschtUndLeer
------------------------------------------------------------------------------
  Spannungsbereich vertauscht oder «bis» leer: wird richtig behandelt.
------------------------------------------------------------------------------}
procedure TTestKsq.BereichVertauschtUndLeer;
var
  E: TKsqInput;                                          // Eingabe
  R: TKsqResult;                                         // Resultat
begin
  E := Basis(kcLM317);
  E.UMin := 14.4;
  E.UMax := 12;
  R := CalculateKsq(E);
  AssertEquals(12, R.UMin, 1e-12);
  AssertEquals(14.4, R.UMax, 1e-12);
  E.UMax := 0;
  R := CalculateKsq(E);
  AssertEquals('leer = fest', 14.4, R.UMax, 1e-12);
  AssertEquals(R.PLossMin, R.PLossMax, 1e-12);
end;

{------------------------------------------------------------------------------
  SpannungZuKlein
------------------------------------------------------------------------------
  Speisespannung reicht nicht für die LEDs: Fehler wird gemeldet.
------------------------------------------------------------------------------}
procedure TTestKsq.SpannungZuKlein;
var
  E: TKsqInput;                                          // Eingabe
begin
  E := Basis(kcLM317);
  E.UMin := 9;                                           // braucht 9,65 V
  AssertTrue(CalculateKsq(E).Status = ksUTooLow);
  E := Basis(kcTransistors);
  E.UMin := 7.6;                                         // genau die Mindestspannung reicht
  AssertTrue(CalculateKsq(E).Status = ksOk);
  E.UMin := 7.5;
  AssertTrue(CalculateKsq(E).Status = ksUTooLow);
end;

{------------------------------------------------------------------------------
  Fehler
------------------------------------------------------------------------------
  Ungültige Eingaben liefern den passenden Fehler und keine halben
  Resultate.
------------------------------------------------------------------------------}
procedure TTestKsq.Fehler;
var
  E: TKsqInput;                                          // Eingabe
begin
  E := Basis(kcLM317); E.UMin := 0; AssertTrue(CalculateKsq(E).Status = ksInvalidU);
  E := Basis(kcLM317); E.Ud := 0;   AssertTrue(CalculateKsq(E).Status = ksInvalidUd);
  E := Basis(kcLM317); E.I := 0;    AssertTrue(CalculateKsq(E).Status = ksInvalidI);
  E := Basis(kcLM317); E.N := 0;    AssertTrue(CalculateKsq(E).Status = ksInvalidN);
  E := Basis(kcLM317); E.I := 2;    AssertTrue(CalculateKsq(E).Status = ksTooMuchCurrent);
end;

initialization
  RegisterTest(TTestKsq);
end.
