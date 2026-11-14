{==============================================================================
  uLedInfo - LED-Info «Die Leuchtdiode» im Browser anzeigen
==============================================================================
  Zweck:     Zeigt die Hilfeseite zur LED (Aufbau, Durchlassspannung,
             Vorwiderstand, Blinkschaltung, Konstantstrom ...).

  Technik:   Die Seite steckt als Ressource in der EXE:
               LEDINFO    = src/info/led-info.html     (Deutsch)
               LEDINFO_EN = src/info/led-info-en.html  (Englisch)
             Beide sind in den Projektoptionen unter «Ressourcen»
             eingetragen. Zum Anzeigen wird die passende Seite in den
             Temp-Ordner geschrieben und im Standard-Browser geöffnet.
             So bleibt es eine einzige EXE ohne Zusatzdateien und ohne
             HTML-Komponente.

  Sprache:   Welche Seite erscheint, hängt von der gewählten Sprache ab
             (uLang.LangCode).

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  Kommentare ausführlicher
             2.1  08.11.2026  englische LED-Info (LEDINFO_EN)
             2.0  29.10.2026  erste Fassung
==============================================================================}
unit uLedInfo;

{$mode objfpc}{$H+}

interface

{------------------------------------------------------------------------------
  ShowLedInfo - LED-Info in den Temp-Ordner schreiben und im Browser öffnen
------------------------------------------------------------------------------
  Rückgabe:  False, wenn die Ressource fehlt oder die Datei nicht
             geschrieben oder geöffnet werden konnte (uMain zeigt dann eine
             Fehlermeldung).
------------------------------------------------------------------------------}
function ShowLedInfo: Boolean;

implementation

uses
  Classes,                                               // TFileStream
  SysUtils,                                              // GetTempDir, IncludeTrailingPathDelimiter
  LCLType,                                               // RT_RCDATA, FindResource
  LCLIntf,                                               // OpenDocument (Standard-Browser)
  uLang;                                                 // LangCode: 'de' oder 'en'

{==============================================================================
  KONSTANTEN
==============================================================================}
const
  // Name der Ressource in der EXE
  RES_NAME_DE = 'LEDINFO';                               // Deutsch
  RES_NAME_EN = 'LEDINFO_EN';                            // Englisch

  // Dateiname im Temp-Ordner
  INFO_FILE_DE = 'LedPreResistor-LED-Info.html';         // Deutsch
  INFO_FILE_EN = 'LedPreResistor-LED-Info-en.html';      // Englisch

{------------------------------------------------------------------------------
  ShowLedInfo - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Ressource und Dateiname passend zur Sprache wählen
    2. Ressource in den Temp-Ordner kopieren (jedes Mal neu)
    3. Datei im Standard-Browser öffnen
------------------------------------------------------------------------------}
function ShowLedInfo: Boolean;
var
  Res: TResourceStream;                                  // Ressource aus der EXE
  FS: TFileStream;                                       // Zieldatei im Temp-Ordner
  FileName: string;                                      // vollständiger Pfad der Zieldatei
  ResName: string;                                       // Ressource in der gewählten Sprache
  InfoFile: string;                                      // Dateiname in der gewählten Sprache
begin
  Result := False;

  // ----- 1. Sprache -----
  if LangCode = 'en' then
  begin
    ResName := RES_NAME_EN;
    InfoFile := INFO_FILE_EN;
  end
  else
  begin
    ResName := RES_NAME_DE;
    InfoFile := INFO_FILE_DE;
  end;
  if FindResource(HInstance, PChar(ResName), RT_RCDATA) = 0 then
    Exit;                                                // Ressource fehlt (falscher Build)

  // ----- 2. In den Temp-Ordner schreiben -----
  FileName := IncludeTrailingPathDelimiter(GetTempDir(False)) + InfoFile;
  try
    Res := TResourceStream.Create(HInstance, ResName, RT_RCDATA);
    try
      // jedes Mal neu schreiben, damit immer die Seite dieser Version erscheint
      FS := TFileStream.Create(FileName, fmCreate);
      try
        FS.CopyFrom(Res, Res.Size);
      finally
        FS.Free;
      end;
    finally
      Res.Free;
    end;
  except
    Exit;                                                // Temp-Ordner nicht beschreibbar o. Ä.
  end;

  // ----- 3. Im Browser öffnen -----
  Result := OpenDocument(FileName);
end;

end.
