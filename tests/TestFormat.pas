{ Tests für uFormat: Anzeige ohne überflüssige Nachkommastellen. }
unit TestFormat;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, uFormat;

type
  { Prüft die formatierte Ausgabe }
  TTestFormat = class(TTestCase)
  published
    procedure Zahlen;
    procedure Spannung;
    procedure Widerstand;
    procedure Strom;
    procedure Leistung;
    procedure BauformUndProzent;
    procedure PunktAlsDezimalzeichen;
    procedure BlinkWerte;
  end;

implementation

procedure TTestFormat.Zahlen;
begin
  AssertEquals('12', FormatNum(12, 2, 0));
  AssertEquals('8,8', FormatNum(8.8, 2, 0));
  AssertEquals('20,0', FormatNum(20, 2, 1));
  AssertEquals('18,72', FormatNum(18.7234, 2, 1));
  AssertEquals('0', FormatNum(-0.001, 2, 0));
end;

procedure TTestFormat.Spannung;
begin
  AssertEquals('12 V', FormatVolt(12));
  AssertEquals('8,8 V', FormatVolt(12 - 3.2));
  AssertEquals('3,25 V', FormatVolt(3.25));
end;

procedure TTestFormat.Widerstand;
begin
  AssertEquals('470 Ω', FormatOhm(470));
  AssertEquals('440 Ω', FormatOhm(8.8 / 0.02));
  AssertEquals('4,7 kΩ', FormatOhm(4700));
  AssertEquals('4,99 kΩ', FormatOhm(4990));
  AssertEquals('1 MΩ', FormatOhm(1e6));
  AssertEquals('0,47 Ω', FormatOhm(0.47));
end;

procedure TTestFormat.Strom;
begin
  AssertEquals('18,72 mA', FormatMilliAmp(8.8 / 470));
  AssertEquals('20,0 mA', FormatMilliAmp(0.020));
end;

procedure TTestFormat.Leistung;
begin
  AssertEquals('164,8 mW', FormatPower(8.8 * 8.8 / 470));
  AssertEquals('224,7 mW', FormatPower(12 * 8.8 / 470));
  AssertEquals('1,25 W', FormatPower(1.25));
end;

procedure TTestFormat.BauformUndProzent;
begin
  AssertEquals('½ W', FormatRating(0.5));
  AssertEquals('⅛ W', FormatRating(0.125));
  AssertEquals('1 W', FormatRating(1));
  AssertEquals('66 %', FormatPercent(0.659));
end;

procedure TTestFormat.PunktAlsDezimalzeichen;
begin
  DisplayDecimal := '.';
  try
    AssertEquals('4.7 kΩ', FormatOhm(4700));
    AssertEquals('164.8 mW', FormatPower(8.8 * 8.8 / 470));
  finally
    DisplayDecimal := ',';
  end;
  // Englisch: Prozent ohne Leerschlag
  PercentSpace := '';
  try
    AssertEquals('66%', FormatPercent(0.659));
  finally
    PercentSpace := ' ';
  end;
end;

procedure TTestFormat.BlinkWerte;
begin
  AssertEquals('0', FormatSig(0, 3));
  AssertEquals('1,05', FormatSig(1.0512, 3));
  AssertEquals('476', FormatSig(476.2, 3));
  AssertEquals('0,476 s', FormatSeconds(0.4762));
  AssertEquals('1,25 s', FormatSeconds(1.2534));
  AssertEquals('52,3 ms', FormatSeconds(0.05234));
  AssertEquals('1,05 Hz', FormatFreq(1.0512));
  AssertEquals('2,4 kHz', FormatFreq(2400));
  AssertEquals('22 µF', FormatCap(22e-6));
  AssertEquals('100 nF', FormatCap(100e-9));
  AssertEquals('470 pF', FormatCap(470e-12));
  AssertEquals('50,4 %', FormatPercent1(0.5036));
end;

initialization
  RegisterTest(TTestFormat);

end.
