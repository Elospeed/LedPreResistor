{ Testprogramm für die Rechenlogik von LedPreResistor (FPCUnit, Konsole).
  Führt alle registrierten Tests aus, zeigt Fehler an und beendet sich mit
  Exitcode 1, wenn ein Test fehlschlägt. So bricht auch der Build-Workflow ab. }
program LedPreResistorTests;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fpcunit, testregistry, testutils,
  TestESeries, TestColorCode, TestCalc;

type
  { Gibt jeden Test mit Ergebnis auf der Konsole aus }
  TKonsolenAusgabe = class(TInterfacedObject, ITestListener)
  private
    FFehler: Boolean;  // der laufende Test hat einen Fehler oder Abbruch gemeldet
  public
    { Ein Test hat eine Prüfung nicht bestanden }
    procedure AddFailure(ATest: TTest; AFailure: TTestFailure);
    { Ein Test ist mit einer Exception abgebrochen }
    procedure AddError(ATest: TTest; AError: TTestFailure);
    { Ein Test beginnt: Fehler-Merker zurücksetzen }
    procedure StartTest(ATest: TTest);
    { Ein Test ist fertig: "ok" ausgeben, wenn kein Fehler gemeldet wurde }
    procedure EndTest(ATest: TTest);
    { Eine Testgruppe beginnt }
    procedure StartTestSuite(ATestSuite: TTestSuite);
    { Eine Testgruppe ist fertig }
    procedure EndTestSuite(ATestSuite: TTestSuite);
  end;

procedure TKonsolenAusgabe.AddFailure(ATest: TTest; AFailure: TTestFailure);
begin
  FFehler := True;
  WriteLn('  FEHLER  ', ATest.TestSuiteName, '.', ATest.TestName, ': ', AFailure.ExceptionMessage);
end;

procedure TKonsolenAusgabe.AddError(ATest: TTest; AError: TTestFailure);
begin
  FFehler := True;
  WriteLn('  ABBRUCH ', ATest.TestSuiteName, '.', ATest.TestName, ': ',
    AError.ExceptionClassName, ': ', AError.ExceptionMessage);
end;

procedure TKonsolenAusgabe.StartTest(ATest: TTest);
begin
  FFehler := False;
end;

procedure TKonsolenAusgabe.EndTest(ATest: TTest);
begin
  if not FFehler then
    WriteLn('  ok      ', ATest.TestSuiteName, '.', ATest.TestName);
end;

procedure TKonsolenAusgabe.StartTestSuite(ATestSuite: TTestSuite);
begin
end;

procedure TKonsolenAusgabe.EndTestSuite(ATestSuite: TTestSuite);
begin
end;

var
  Ergebnis: TTestResult;     // sammelt die Resultate aller Tests
  Ausgabe: ITestListener;    // schreibt den Fortschritt auf die Konsole
begin
  Ergebnis := TTestResult.Create;
  try
    Ausgabe := TKonsolenAusgabe.Create;
    Ergebnis.AddListener(Ausgabe);
    GetTestRegistry.Run(Ergebnis);
    WriteLn;
    WriteLn(Format('%d Tests, %d Fehler, %d Abbrüche',
      [Ergebnis.RunTests, Ergebnis.NumberOfFailures, Ergebnis.NumberOfErrors]));
    if (Ergebnis.NumberOfFailures > 0) or (Ergebnis.NumberOfErrors > 0) then
      ExitCode := 1;
  finally
    Ergebnis.Free;
  end;
end.
