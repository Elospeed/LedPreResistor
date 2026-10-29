{ LED-Info: Die Seite «Die Leuchtdiode» (src/info/led-info.html) steckt als
  Ressource LEDINFO (RCDATA) in der EXE, eingetragen in den Projektoptionen
  unter Ressourcen. Zum Anzeigen wird sie in den Temp-Ordner geschrieben und
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
  Classes, SysUtils, LCLType, LCLIntf;

const
  { Name der Ressource in der EXE }
  RES_NAME = 'LEDINFO';
  { Dateiname im Temp-Ordner }
  INFO_FILE = 'LedPreResistor-LED-Info.html';

function ShowLedInfo: Boolean;
var
  Res: TResourceStream;  // Ressource aus der EXE
  FS: TFileStream;       // Zieldatei im Temp-Ordner
  FileName: string;      // vollständiger Pfad der Zieldatei
begin
  Result := False;
  if FindResource(HInstance, RES_NAME, RT_RCDATA) = 0 then
    Exit;
  FileName := IncludeTrailingPathDelimiter(GetTempDir(False)) + INFO_FILE;
  try
    Res := TResourceStream.Create(HInstance, RES_NAME, RT_RCDATA);
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
