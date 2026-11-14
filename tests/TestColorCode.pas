{==============================================================================
  TestColorCode - Tests
==============================================================================
  Zweck:     Tests für uColorCode: Farbringe für 4 und 5 Ringe.

  Benutzung: Die Tests laufen mit LedPreResistorTests (FPCUnit). Jede
             Prozedur unter «published» ist ein Test.

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  Kommentare ausführlicher
             2.0  29.10.2026  erste Fassung
==============================================================================}
unit TestColorCode;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, uESeries, uColorCode;

{==============================================================================
  TESTKLASSE
==============================================================================}
type
  { Prüft die Farbringe }
  TTestColorCode = class(TTestCase)
  private
    { Sucht den Normwert zu R und vergleicht die Ringe mit Expected }
    procedure CheckBands(R: Double; Series: TESeries; const Expected: array of TBandColor);
  published
    procedure Beispiel470Ohm;
    procedure Kiloohm;
    procedure KleineWerteMitGoldUndSilber;
    procedure E96MitFuenfRingen;
    procedure AusserhalbDesBereichs;
  end;

implementation

{==============================================================================
  TESTFÄLLE
==============================================================================}

uses
  SysUtils, TypInfo;

{------------------------------------------------------------------------------
  CheckBands
------------------------------------------------------------------------------
  Hilfsroutine: prüft die Farbringe eines Werts gegen die erwarteten Farben.
------------------------------------------------------------------------------}
procedure TTestColorCode.CheckBands(R: Double; Series: TESeries; const Expected: array of TBandColor);
var
  Std: TStdValue;                                        // Normwert zu R
  Bands: TBandArray;                                     // berechnete Ringe
  I: Integer;                                            // Ring-Index
begin
  AssertTrue(NextStdValue(R, Series, Std));
  AssertTrue('Ringe möglich', ColorBands(Std, Series, Bands));
  AssertEquals('Anzahl Ringe für ' + FloatToStr(R), Length(Expected), Length(Bands));
  for I := 0 to High(Expected) do
    AssertEquals(Format('Ring %d für %g', [I + 1, R]),
      GetEnumName(TypeInfo(TBandColor), Ord(Expected[I])),
      GetEnumName(TypeInfo(TBandColor), Ord(Bands[I])));
end;

{------------------------------------------------------------------------------
  Beispiel470Ohm
------------------------------------------------------------------------------
  470 Ω: gelb, violett, braun, gold.
------------------------------------------------------------------------------}
procedure TTestColorCode.Beispiel470Ohm;
begin
  // Referenz aus der Projektübersicht: gelb, violett, braun, gold
  CheckBands(440, esE12, [bcYellow, bcViolet, bcBrown, bcGold]);
end;

{------------------------------------------------------------------------------
  Kiloohm
------------------------------------------------------------------------------
  Werte im Kiloohm-Bereich.
------------------------------------------------------------------------------}
procedure TTestColorCode.Kiloohm;
begin
  CheckBands(4700, esE12, [bcYellow, bcViolet, bcRed, bcGold]);
  CheckBands(10000, esE24, [bcBrown, bcBlack, bcOrange, bcGold]);
  CheckBands(220, esE12, [bcRed, bcRed, bcBrown, bcGold]);
  CheckBands(1e6, esE12, [bcBrown, bcBlack, bcGreen, bcGold]);
end;

{------------------------------------------------------------------------------
  KleineWerteMitGoldUndSilber
------------------------------------------------------------------------------
  Kleine Werte mit Gold (× 0,1) und Silber (× 0,01) als Multiplikator.
------------------------------------------------------------------------------}
procedure TTestColorCode.KleineWerteMitGoldUndSilber;
begin
  CheckBands(10, esE12, [bcBrown, bcBlack, bcBlack, bcGold]);
  CheckBands(4.7, esE12, [bcYellow, bcViolet, bcGold, bcGold]);
  CheckBands(0.47, esE12, [bcYellow, bcViolet, bcSilver, bcGold]);
end;

{------------------------------------------------------------------------------
  E96MitFuenfRingen
------------------------------------------------------------------------------
  E96: fünf Ringe mit drei Ziffern und braunem Toleranzring.
------------------------------------------------------------------------------}
procedure TTestColorCode.E96MitFuenfRingen;
begin
  CheckBands(4990, esE96, [bcYellow, bcWhite, bcWhite, bcBrown, bcBrown]);
  CheckBands(442, esE96, [bcYellow, bcYellow, bcRed, bcBlack, bcBrown]);
  CheckBands(100, esE96, [bcBrown, bcBlack, bcBlack, bcBlack, bcBrown]);
end;

{------------------------------------------------------------------------------
  AusserhalbDesBereichs
------------------------------------------------------------------------------
  Werte ausserhalb des darstellbaren Bereichs liefern False.
------------------------------------------------------------------------------}
procedure TTestColorCode.AusserhalbDesBereichs;
var
  Std: TStdValue;                                        // Normwert
  Bands: TBandArray;                                     // Ringe
begin
  AssertTrue(NextStdValue(0.01, esE12, Std));            // 0,01 Ω = 10 * 10^-3
  AssertFalse('0,01 Ω hat keinen Multiplikator-Ring', ColorBands(Std, esE12, Bands));
end;

initialization
  RegisterTest(TTestColorCode);
end.
