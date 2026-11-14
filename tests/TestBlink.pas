{==============================================================================
  TestBlink - Tests
==============================================================================
  Zweck:     Tests für uBlink: NE555 und Multivibrator, vorwärts und
             rückwärts. Referenzwerte aus dem Konzept vom 9.11.2026 (9 V,
             rote LED, 15 mA).

  Benutzung: Die Tests laufen mit LedPreResistorTests (FPCUnit). Jede
             Prozedur unter «published» ist ein Test.

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  Kommentare ausführlicher
             2.3  11.11.2026  neu
==============================================================================}
unit TestBlink;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, uESeries, uBlink;

{==============================================================================
  TESTKLASSE
==============================================================================}
type
  { Prüft die Rechnung der Blinkschaltungen }
  TTestBlink = class(TTestCase)
  private
    { Grundeingabe: 9 V, rote LED 2,0 V, 15 mA, E12 }
    function Basis(Circuit: TBlinkCircuit): TBlinkInput;
  published
    procedure NE555Vorwaerts;
    procedure NE555LedNachPlus;
    procedure NE555Wechselblinker;
    procedure NE555MitDiode;
    procedure NE555Rueckwaerts;
    procedure NE555RueckwaertsBrauchtDiode;
    procedure NE555Hinweise;
    procedure MultivibratorVorwaerts;
    procedure MultivibratorRueckwaerts;
    procedure MultivibratorFaktorLehrbuch;
    procedure NaechsterNormwert;
    procedure Fehler;
  end;

implementation

{==============================================================================
  TESTFÄLLE
==============================================================================}

uses
  Math;

const
  EPS = 1e-6;                                            // Toleranz für Vergleiche

{------------------------------------------------------------------------------
  Basis
------------------------------------------------------------------------------
  Liefert Grund-Eingaben für die gewählte Schaltung, auf denen die einzelnen
  Tests aufbauen.
------------------------------------------------------------------------------}
function TTestBlink.Basis(Circuit: TBlinkCircuit): TBlinkInput;
begin
  Result := Default(TBlinkInput);
  Result.Circuit := Circuit;
  Result.U := 9;
  Result.Ud := 2.0;
  Result.I := 0.015;
  Result.Series := esE12;
  Result.Conn := cnGnd;
end;

{------------------------------------------------------------------------------
  NE555Vorwaerts
------------------------------------------------------------------------------
  NE555 vorwärts: aus R1, R2 und C die Zeiten, Frequenz und den
  Vorwiderstand rechnen.
------------------------------------------------------------------------------}
procedure TTestBlink.NE555Vorwaerts;
var
  I: TBlinkInput;                                        // Eingabe
  R: TBlinkResult;                                       // Resultat
begin
  I := Basis(bcNE555);
  I.R1 := 1000;
  I.R2 := 68000;
  I.C := 10e-6;
  R := CalculateBlink(I);
  AssertTrue('Status', R.Status = bsOk);
  AssertEquals('t High', Ln(2) * 69000 * 10e-6, R.THigh, EPS);
  AssertEquals('t Low', Ln(2) * 68000 * 10e-6, R.TLow, EPS);
  AssertEquals('f', 1.0531, R.F, 1e-4);
  AssertEquals('Tastgrad', 69 / 137, R.Duty1, EPS);
  AssertEquals('LED an = High', R.THigh, R.TOn1, EPS);
  AssertEquals('U Ausgang', 7.3, R.UOut, EPS);
  // (7,3 − 2,0) / 15 mA = 353 Ω -> 390 Ω
  AssertEquals('R_V', 390, R.Led1.R, EPS);
  AssertEquals('I', 5.3 / 390, R.Led1.IAct, EPS);
  AssertFalse('keine zweite LED', R.Led2.Used);
  AssertTrue('keine Hinweise', R.Warnings = []);
end;

{------------------------------------------------------------------------------
  NE555LedNachPlus
------------------------------------------------------------------------------
  NE555 mit LED nach +U_B: die LED leuchtet in der Low-Phase.
------------------------------------------------------------------------------}
procedure TTestBlink.NE555LedNachPlus;
var
  I: TBlinkInput;                                        // Eingabe
  R: TBlinkResult;                                       // Resultat
begin
  I := Basis(bcNE555);
  I.R1 := 1000;
  I.R2 := 68000;
  I.C := 10e-6;
  I.Conn := cnVcc;
  R := CalculateBlink(I);
  AssertTrue('Status', R.Status = bsOk);
  // LED leuchtet bei Low
  AssertEquals('LED an = Low', R.TLow, R.TOn1, EPS);
  AssertEquals('Tastgrad', 68 / 137, R.Duty1, EPS);
  // (9 − 2,0 − 0,1) / 15 mA = 460 Ω -> 470 Ω
  AssertEquals('R_V', 470, R.Led1.R, EPS);
end;

{------------------------------------------------------------------------------
  NE555Wechselblinker
------------------------------------------------------------------------------
  NE555 als Wechselblinker: zwei LEDs, eine nach Masse, eine nach +U_B.
------------------------------------------------------------------------------}
procedure TTestBlink.NE555Wechselblinker;
var
  I: TBlinkInput;                                        // Eingabe
  R: TBlinkResult;                                       // Resultat
begin
  I := Basis(bcNE555);
  I.R1 := 1000;
  I.R2 := 68000;
  I.C := 10e-6;
  I.Conn := cnBoth;
  R := CalculateBlink(I);
  AssertTrue('Status', R.Status = bsOk);
  AssertEquals('R_V1 nach Masse', 390, R.Led1.R, EPS);
  AssertTrue('LED 2 vorhanden', R.Led2.Used);
  AssertEquals('R_V2 nach +Ub', 470, R.Led2.R, EPS);
end;

{------------------------------------------------------------------------------
  NE555MitDiode
------------------------------------------------------------------------------
  NE555 mit Diode über R2: High- und Low-Zeit getrennt einstellbar.
------------------------------------------------------------------------------}
procedure TTestBlink.NE555MitDiode;
var
  I: TBlinkInput;                                        // Eingabe
  R: TBlinkResult;                                       // Resultat
begin
  I := Basis(bcNE555);
  I.R1 := 47000;
  I.R2 := 47000;
  I.C := 10e-6;
  I.Diode := True;
  R := CalculateBlink(I);
  AssertTrue('Status', R.Status = bsOk);
  AssertEquals('genau 50 %', 0.5, R.Duty1, EPS);
end;

{------------------------------------------------------------------------------
  NE555Rueckwaerts
------------------------------------------------------------------------------
  NE555 rückwärts: aus Frequenz und Tastgrad passende Normwerte für R1 und
  R2.
------------------------------------------------------------------------------}
procedure TTestBlink.NE555Rueckwaerts;
var
  I: TBlinkInput;                                        // Eingabe
  R: TBlinkResult;                                       // Resultat
begin
  // 1 Hz, 55 % an, 10 µF: S = 144,3 kΩ, R2 = 64,9 kΩ -> 68 kΩ, R1 = 14,4 kΩ -> 15 kΩ
  I := Basis(bcNE555);
  I.Reverse := True;
  I.F := 1;
  I.Duty := 0.55;
  I.C := 10e-6;
  R := CalculateBlink(I);
  AssertTrue('Status', R.Status = bsOk);
  AssertEquals('R1 ideal', 0.1 / (Ln(2) * 10e-6), R.R1Calc, 1e-3);
  AssertEquals('R2 ideal', 0.45 / (Ln(2) * 10e-6), R.R2Calc, 1e-3);
  AssertEquals('R1', 15000, R.R1, EPS);
  AssertEquals('R2', 68000, R.R2, EPS);
  AssertEquals('f mit Normwerten', 1.44 / (151000 * 10e-6), R.F, 2e-3);
  // mit Diode geht auch 50 %: R1 = R2 = 72,1 kΩ -> 68 kΩ
  I.Duty := 0.5;
  I.Diode := True;
  R := CalculateBlink(I);
  AssertTrue('Status Diode', R.Status = bsOk);
  AssertEquals('R1 Diode', 68000, R.R1, EPS);
  AssertEquals('R2 Diode', 68000, R.R2, EPS);
end;

{------------------------------------------------------------------------------
  NE555RueckwaertsBrauchtDiode
------------------------------------------------------------------------------
  NE555 rückwärts ohne Diode: High-Anteil unter 50 % ist nicht möglich und
  wird gemeldet.
------------------------------------------------------------------------------}
procedure TTestBlink.NE555RueckwaertsBrauchtDiode;
var
  I: TBlinkInput;                                        // Eingabe
  R: TBlinkResult;                                       // Resultat
begin
  I := Basis(bcNE555);
  I.Reverse := True;
  I.F := 1;
  I.Duty := 0.4;
  I.C := 10e-6;
  R := CalculateBlink(I);
  AssertTrue('ohne Diode nicht möglich', R.Status = bsDutyNeedsDiode);
  // LED nach +Ub: 40 % an heisst 60 % High, das geht ohne Diode
  I.Conn := cnVcc;
  R := CalculateBlink(I);
  AssertTrue('LED nach +Ub', R.Status = bsOk);
  AssertEquals('Tastgrad ungefähr 40 %', 0.4, R.Duty1, 0.05);
end;

{------------------------------------------------------------------------------
  NE555Hinweise
------------------------------------------------------------------------------
  NE555: Hinweise bei falscher Speisespannung, kleinem R1, zu grossem
  Ausgangsstrom.
------------------------------------------------------------------------------}
procedure TTestBlink.NE555Hinweise;
var
  I: TBlinkInput;                                        // Eingabe
  R: TBlinkResult;                                       // Resultat
begin
  I := Basis(bcNE555);
  I.U := 3.7;
  I.Ud := 1.8;
  I.R1 := 470;
  I.R2 := 2.2e6;
  I.C := 1e-6;
  R := CalculateBlink(I);
  AssertTrue('Status', R.Status = bsOk);
  AssertTrue('Speisespannung', bwSupply555 in R.Warnings);
  AssertTrue('R1 klein', bwR1Small in R.Warnings);
  AssertTrue('R gross', bwRHigh in R.Warnings);
  // schnell: 1 kΩ, 10 kΩ, 1 µF -> 68,7 Hz
  I := Basis(bcNE555);
  I.R1 := 1000;
  I.R2 := 10000;
  I.C := 1e-6;
  R := CalculateBlink(I);
  AssertTrue('zu schnell', bwTooFast in R.Warnings);
  // 1 kΩ, 15 kΩ, 1 µF -> 46,5 Hz: flackert noch, keine Warnung
  I.R2 := 15000;
  R := CalculateBlink(I);
  AssertFalse('46 Hz noch sichtbar', bwTooFast in R.Warnings);
end;

{------------------------------------------------------------------------------
  MultivibratorVorwaerts
------------------------------------------------------------------------------
  Multivibrator vorwärts: Zeiten aus R_B und C, Vorwiderstände und
  Sättigung.
------------------------------------------------------------------------------}
procedure TTestBlink.MultivibratorVorwaerts;
var
  I: TBlinkInput;                                        // Eingabe
  R: TBlinkResult;                                       // Resultat
  K: Double;                                             // erwarteter Faktor
begin
  I := Basis(bcMulti);
  I.R1 := 33000;
  I.R2 := 33000;
  I.C := 22e-6;
  R := CalculateBlink(I);
  AssertTrue('Status', R.Status = bsOk);
  // ΔU = 9 − 2,0 − 0,2 = 6,8 V; K = ln(15,2 / 8,4)
  AssertEquals('ΔU', 6.8, R.DeltaU, EPS);
  K := Ln(15.2 / 8.4);
  AssertEquals('K', K, R.K, EPS);
  AssertEquals('t', K * 33000 * 22e-6, R.TOn1, EPS);
  AssertEquals('symmetrisch', 0.5, R.Duty1, EPS);
  // (9 − 2,0 − 0,2) / 15 mA = 453 Ω -> 470 Ω
  AssertEquals('R_V1', 470, R.Led1.R, EPS);
  AssertEquals('R_V2', 470, R.Led2.R, EPS);
  // I_B = 8,4 V / 33 kΩ; I_C = 6,8 V / 470 Ω
  AssertEquals('I_B', 8.4 / 33000, R.IB, EPS);
  AssertEquals('Übersteuerung', 8.4 / 33000 * 100 / (6.8 / 470), R.Overdrive, 1e-4);
  // Sperrspannung 6,2 V > 6 V
  AssertEquals('Sperrspannung', 6.2, R.URev, EPS);
  AssertTrue('Basis gefährdet', bwBaseReverse in R.Warnings);
  // bei 5 V keine Gefahr mehr
  I.U := 5;
  R := CalculateBlink(I);
  AssertFalse('5 V sicher', bwBaseReverse in R.Warnings);
end;

{------------------------------------------------------------------------------
  MultivibratorRueckwaerts
------------------------------------------------------------------------------
  Multivibrator rückwärts: aus Frequenz und Tastgrad passende R_B.
------------------------------------------------------------------------------}
procedure TTestBlink.MultivibratorRueckwaerts;
var
  I: TBlinkInput;                                        // Eingabe
  R: TBlinkResult;                                       // Resultat
begin
  I := Basis(bcMulti);
  I.Reverse := True;
  I.F := 1;
  I.Duty := 0.25;
  I.C := 22e-6;
  R := CalculateBlink(I);
  AssertTrue('Status', R.Status = bsOk);
  // LED 1 an = K · R_B2 · C = 0,25 s
  AssertEquals('R_B2 ideal', 0.25 / (R.K * 22e-6), R.R2Calc, 1e-3);
  AssertEquals('R_B1 ideal', 0.75 / (R.K * 22e-6), R.R1Calc, 1e-3);
  AssertEquals('Tastgrad ungefähr', 0.25, R.Duty1, 0.03);
  AssertEquals('Frequenz ungefähr', 1, R.F, 0.1);
end;

{------------------------------------------------------------------------------
  MultivibratorFaktorLehrbuch
------------------------------------------------------------------------------
  Zeitfaktor K im Lehrbuchfall (ΔU = U_B − 0,6 V) ist ln 2.
------------------------------------------------------------------------------}
procedure TTestBlink.MultivibratorFaktorLehrbuch;
begin
  // Kollektor springt um Ub − 0,6 V: dann ist K = ln 2
  AssertEquals(Ln(2), MultiFactor(9, 8.4), EPS);
end;

{------------------------------------------------------------------------------
  NaechsterNormwert
------------------------------------------------------------------------------
  NearestStdValue findet den nächsten Normwert (im Verhältnis).
------------------------------------------------------------------------------}
procedure TTestBlink.NaechsterNormwert;
var
  S: TStdValue;                                          // gefundener Normwert
begin
  AssertTrue(NearestStdValue(14400, esE12, S));
  AssertEquals(15000, S.Value, EPS);
  AssertTrue(NearestStdValue(64900, esE12, S));
  AssertEquals(68000, S.Value, EPS);
  AssertTrue(NearestStdValue(9.6, esE12, S));
  AssertEquals(10, S.Value, EPS);
  AssertTrue(NearestStdValue(72100, esE24, S));
  AssertEquals(75000, S.Value, EPS);
  AssertFalse(NearestStdValue(0, esE12, S));
end;

{------------------------------------------------------------------------------
  Fehler
------------------------------------------------------------------------------
  Ungültige Eingaben liefern den passenden Fehler und keine halben
  Resultate.
------------------------------------------------------------------------------}
procedure TTestBlink.Fehler;
var
  I: TBlinkInput;                                        // Eingabe
  R: TBlinkResult;                                       // Resultat
begin
  I := Basis(bcNE555);
  I.R1 := 1000;
  I.R2 := 68000;
  I.C := 0;
  AssertTrue('C fehlt', CalculateBlink(I).Status = bsInvalidC);
  I.C := 10e-6;
  I.R2 := 0;
  AssertTrue('R2 fehlt', CalculateBlink(I).Status = bsInvalidR2);
  I.R2 := 68000;
  I.U := 3.5;
  R := CalculateBlink(I);
  AssertTrue('zu wenig Spannung', R.Status = bsUTooLow);
  AssertEquals('keine halben Werte', 0, R.F, 0);
  I := Basis(bcMulti);
  I.Reverse := True;
  I.F := 1;
  I.Duty := 1;
  I.C := 10e-6;
  AssertTrue('Tastgrad 100 %', CalculateBlink(I).Status = bsInvalidDuty);
end;

initialization
  RegisterTest(TTestBlink);
end.
