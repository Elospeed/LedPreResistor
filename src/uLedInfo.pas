{ LED-Info: Die Seite «Die Leuchtdiode» (src/info/led-info.html) steckt als
  Ressource LEDINFO (RCDATA) in der EXE, die englische Fassung «The LED»
  (src/info/led-info-en.html) als LEDINFO_EN; beide eingetragen in den
  Projektoptionen unter Ressourcen. Welche erscheint, hängt von der
  gewählten Sprache ab (uLang). Zum Anzeigen wird sie in den Temp-Ordner geschrieben und
  im Standard-Browser geöffnet. So bleibt es eine einzige EXE ohne
  Zusatzdateien und ohne HTML-Komponente. }
unit uLedInfo;

{$mode objfpc}{$H+}

interface

{ Schreibt die LED-Info in den Temp-Ordner und öffnet sie im Browser.
  Liefert False, wenn die Ressource fehlt oder die Datei nicht geschrieben
  oder geöffnet werden konnte. }
function ShowLedInfo: Boolean;

implementation

uses
  Classes, SysUtils, LCLType, LCLIntf, uLang;

const
  { Name der Ressource in der EXE (Deutsch, Englisch) }
  RES_NAME_DE = 'LEDINFO';
  RES_NAME_EN = 'LEDINFO_EN';
  { Dateiname im Temp-Ordner (Deutsch, Englisch) }
  INFO_FILE_DE = 'LedPreResistor-LED-Info.html';
  INFO_FILE_EN = 'LedPreResistor-LED-Info-en.html';

function ShowLedInfo: Boolean;
var
  Res: TResourceStream;  // Ressource aus der EXE
  FS: TFileStream;       // Zieldatei im Temp-Ordner
  FileName: string;      // vollständiger Pfad der Zieldatei
  ResName: string;       // Ressource in der gewählten Sprache
  InfoFile: string;      // Dateiname in der gewählten Sprache
begin
  Result := False;
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
    Exit;
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
    Exit;  // Temp-Ordner nicht beschreibbar o. Ä.
  end;
  Result := OpenDocument(FileName);
end;

end.
