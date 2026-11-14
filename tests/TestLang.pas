{==============================================================================
  TestLang - Tests
==============================================================================
  Zweck:     Tests für uLang: .po lesen und Texte übersetzen.

  Benutzung: Die Tests laufen mit LedPreResistorTests (FPCUnit). Jede
             Prozedur unter «published» ist ein Test.

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  Kommentare ausführlicher
             2.1  08.11.2026  neu
==============================================================================}
unit TestLang;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uLang;

{==============================================================================
  TESTKLASSE
==============================================================================}
type
  { Prüft das Lesen der Übersetzung und das Nachschlagen }
  TTestLang = class(TTestCase)
  published
    procedure DeutschOhneUebersetzung;
    procedure EnglischAusPo;
  end;

implementation

{==============================================================================
  TESTFÄLLE
==============================================================================}

{------------------------------------------------------------------------------
  DeutschOhneUebersetzung
------------------------------------------------------------------------------
  Deutsch: Texte kommen unverändert zurück.
------------------------------------------------------------------------------}
procedure TTestLang.DeutschOhneUebersetzung;
begin
  LangLoad('de');
  AssertEquals('de', LangCode);
  AssertEquals('Speisespannung', _('Speisespannung'));
end;

{------------------------------------------------------------------------------
  EnglischAusPo
------------------------------------------------------------------------------
  Englisch: Übersetzung aus .po-Zeilen lesen und nachschlagen.
------------------------------------------------------------------------------}
procedure TTestLang.EnglischAusPo;
var
  L: TStringList;                                        // kleine .po-Datei
begin
  L := TStringList.Create;
  try
    L.Add('msgid ""');
    L.Add('msgstr ""');
    L.Add('');
    L.Add('msgid "Speisespannung"');
    L.Add('msgstr "Supply voltage"');
    L.Add('');
    L.Add('msgid "Erste "');
    L.Add('"Zeile"');
    L.Add('msgstr "First \"line\""');
    L.Add('');
    L.Add('#, fuzzy');
    L.Add('msgid "Unsicher"');
    L.Add('msgstr "Unsure"');
    LangLoadFromPo(L, 'en');
    AssertEquals('en', LangCode);
    AssertEquals('Supply voltage', _('Speisespannung'));
    AssertEquals('First "line"', _('Erste Zeile'));
    // unsicher markierte und fehlende Texte bleiben deutsch
    AssertEquals('Unsicher', _('Unsicher'));
    AssertEquals('Fehlt', _('Fehlt'));
  finally
    L.Free;
    LangLoad('de');
  end;
end;

initialization
  RegisterTest(TTestLang);
end.
