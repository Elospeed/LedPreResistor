{ Mehrsprachigkeit (Deutsch und Englisch), Aufbau wie uLang in StemMaker.

  Das Programm ist auf Deutsch geschrieben. Jeder sichtbare Text läuft durch
  die kleine Funktion _():

        Caption := _('Speisespannung');

  _() sucht den deutschen Text in der geladenen Übersetzung. Gibt es eine,
  kommt sie zurück, sonst einfach der deutsche Text. Es kann also nie
  «nichts» angezeigt werden, schlimmstenfalls steht etwas auf Deutsch da.

  DIE ÜBERSETZUNG
  Steht in src/lang/en.po im üblichen gettext-Format (mit Poedit
  bearbeitbar) und steckt als Ressource LANG_EN in der EXE. So bleibt es
  eine einzige EXE ohne lang-Ordner.

        msgid "Speisespannung"
        msgstr "Supply voltage"

  DIE SPRACHWAHL
  Beim ersten Start: Deutsch bei deutschem Windows (Linux: LANG=de...),
  sonst Englisch. Wählt man oben rechts eine Sprache (DE/EN), steht sie in
  LedPreResistor.ini neben der EXE (Linux: ~/.config/LedPreResistor/).
  Logik stützt sich nie auf übersetzten Text, nur auf den Sprachcode. }
unit uLang;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

{ Text übersetzen (deutsch rein -> aktuelle Sprache raus) }
function _(const S: string): string;

{ Sprache laden: 'de' = Original (keine Übersetzung nötig), 'en' aus der
  Ressource LANG_EN. Gibt False zurück, wenn die Übersetzung fehlt; dann
  bleibt es bei Deutsch. }
function LangLoad(const Code: string): Boolean;

{ aktuell geladene Sprache, 'de' oder 'en' }
function LangCode: string;

{ Sprache von Windows: 'de' bei deutschem Windows, sonst 'en' }
function LangSystemDefault: string;

{ gespeicherte Sprache aus der INI, sonst die Sprache von Windows }
function LangStartCode: string;

{ gewählte Sprache in der INI speichern (Fehler werden still übergangen,
  z. B. wenn die EXE in einem schreibgeschützten Ordner liegt) }
procedure LangSaveChoice(const Code: string);

{ Pfad der Einstellungsdatei (Windows: neben der EXE, Linux:
  ~/.config/LedPreResistor/); auch für andere Einstellungen als die Sprache }
function IniFileName: string;

{ Übersetzung aus einem Text im .po-Format lesen; für die Tests offen }
procedure LangLoadFromPo(PoLines: TStrings; const Code: string);

implementation

uses
  IniFiles {$IFDEF WINDOWS}, Windows{$ENDIF};  // Windows: RT_RCDATA

const
  { Name der INI-Datei neben der EXE }
  INI_NAME = 'LedPreResistor.ini';
  { Abschnitt und Schlüssel für die Sprache }
  INI_SECTION = 'Allgemein';
  INI_KEY = 'Sprache';

var
  GCode: string = 'de';        // aktuelle Sprache
  GTable: TStringList = nil;   // sortierte deutsche Originaltexte; das
                               // «Objekt» daneben ist die Nummer der
                               // Übersetzung in GTrans
  GTrans: TStringList = nil;   // die Übersetzungen

function LangCode: string;
begin
  Result := GCode;
end;

{ Nachschlagen. GTable ist sortiert -> schnelle Suche mit Find. }
function _(const S: string): string;
var
  I: Integer;  // Fundstelle in GTable
begin
  Result := S;
  if (GTable = nil) or (S = '') then Exit;
  if GTable.Find(S, I) then
    Result := GTrans[PtrInt(GTable.Objects[I])];
end;

{ Sonderzeichen in Anführungszeichen auflösen: \n \t \" \\ }
function Unescape(const S: string): string;
var
  I: Integer;  // Position im Text
begin
  Result := '';
  I := 1;
  while I <= Length(S) do
  begin
    if (S[I] = '\') and (I < Length(S)) then
    begin
      Inc(I);
      case S[I] of
        'n': Result := Result + LineEnding;
        't': Result := Result + #9;
        '"': Result := Result + '"';
        '\': Result := Result + '\';
      else
        Result := Result + '\' + S[I];
      end;
    end
    else
      Result := Result + S[I];
    Inc(I);
  end;
end;

{ Text zwischen dem ersten und dem letzten Anführungszeichen einer Zeile }
function Quoted(const Line: string): string;
var
  A, B: Integer;  // Lage der beiden Anführungszeichen
begin
  A := Pos('"', Line);
  B := Length(Line);
  while (B > A) and (Line[B] <> '"') do Dec(B);
  if (A > 0) and (B > A) then
    Result := Unescape(Copy(Line, A + 1, B - A - 1))
  else
    Result := '';
end;

{ .po lesen. Aufbau (vereinfacht):
      #, fuzzy                    <- unsicher übersetzt -> weglassen
      msgid "Erste Zeile "
      "Fortsetzung"               <- mehrzeilige Texte werden zusammengehängt
      msgstr "Translation" }
procedure LangLoadFromPo(PoLines: TStrings; const Code: string);
var
  I: Integer;          // Zeilenzähler
  Mode: Integer;       // 0 = nichts, 1 = in msgid, 2 = in msgstr
  Line: string;        // aktuelle Zeile ohne Leerraum
  Id, Str: string;     // deutscher Text und Übersetzung des Eintrags
  Fuzzy: Boolean;      // Eintrag als unsicher markiert

  procedure Flush;
  begin
    // fertigen Eintrag übernehmen (leere und unsichere weglassen)
    if (Id <> '') and (Str <> '') and not Fuzzy then
    begin
      GTrans.Add(Str);
      GTable.AddObject(Id, TObject(PtrInt(GTrans.Count - 1)));
    end;
    Id := ''; Str := ''; Fuzzy := False; Mode := 0;
  end;

begin
  FreeAndNil(GTable);
  FreeAndNil(GTrans);
  GTable := TStringList.Create;
  GTable.CaseSensitive := True;
  GTrans := TStringList.Create;
  Id := ''; Str := ''; Fuzzy := False; Mode := 0;
  for I := 0 to PoLines.Count - 1 do
  begin
    Line := Trim(PoLines[I]);
    if Line = '' then
      Flush
    else if Copy(Line, 1, 2) = '#,' then
    begin
      if Mode = 2 then Flush;
      Fuzzy := Pos('fuzzy', Line) > 0;
    end
    else if Line[1] = '#' then
      // Kommentar
    else if Copy(Line, 1, 6) = 'msgid ' then
    begin
      if Mode = 2 then Flush;  // neuer Eintrag ohne Leerzeile davor
      Id := Quoted(Line);
      Mode := 1;
    end
    else if Copy(Line, 1, 7) = 'msgstr ' then
    begin
      Str := Quoted(Line);
      Mode := 2;
    end
    else if Line[1] = '"' then
      case Mode of
        1: Id := Id + Quoted(Line);
        2: Str := Str + Quoted(Line);
      end;
  end;
  Flush;
  GTable.Sorted := True;  // erst JETZT sortieren
  GCode := LowerCase(Code);
end;

function LangLoad(const Code: string): Boolean;
var
  ResName: string;          // Name der Ressource, z. B. LANG_EN
  Res: TResourceStream;     // Übersetzung aus der EXE
  L: TStringList;           // Zeilen der .po
begin
  FreeAndNil(GTable);
  FreeAndNil(GTrans);
  GCode := 'de';
  if (Code = '') or SameText(Code, 'de') then
    Exit(True);  // Deutsch = Original
  Result := False;
  ResName := 'LANG_' + UpperCase(Code);
  if FindResource(HInstance, PChar(ResName), RT_RCDATA) = 0 then
    Exit;
  L := TStringList.Create;
  try
    try
      Res := TResourceStream.Create(HInstance, ResName, RT_RCDATA);
      try
        L.LoadFromStream(Res);  // UTF-8 wie der Rest
      finally
        Res.Free;
      end;
    except
      Exit;  // Ressource fehlt: bei Deutsch bleiben
    end;
    LangLoadFromPo(L, Code);
    Result := True;
  finally
    L.Free;
  end;
end;

{ Windows-Sprache: GetUserDefaultUILanguage liefert z. B. $0807 (Deutsch
  Schweiz) oder $0409 (Englisch USA). Die unteren 10 Bit sind die
  Hauptsprache, $07 = Deutsch. }
{$IFDEF WINDOWS}
function GetUserDefaultUILanguage: Word; stdcall; external 'kernel32.dll';
{$ENDIF}

function LangSystemDefault: string;
begin
  Result := 'en';
  {$IFDEF WINDOWS}
  if GetUserDefaultUILanguage and $3FF = $07 then
    Result := 'de';
  {$ELSE}
  if LowerCase(Copy(GetEnvironmentVariable('LANG'), 1, 2)) = 'de' then
    Result := 'de';
  {$ENDIF}
end;

{ Windows: INI neben der EXE (portabel). Linux: Programme liegen oft in
  schreibgeschützten Ordnern (z. B. /opt, /usr/bin), darum dort im
  Einstellungsordner des Benutzers: ~/.config/LedPreResistor/ }
function IniFileName: string;
begin
  {$IFDEF WINDOWS}
  Result := ExtractFilePath(ParamStr(0)) + INI_NAME;
  {$ELSE}
  // nicht GetAppConfigDir: das nähme den Fenstertitel mit Leerzeichen
  Result := GetEnvironmentVariable('XDG_CONFIG_HOME');
  if Result = '' then
    Result := IncludeTrailingPathDelimiter(GetUserDir) + '.config';
  Result := IncludeTrailingPathDelimiter(Result) + 'LedPreResistor' +
    PathDelim + INI_NAME;
  {$ENDIF}
end;

function LangStartCode: string;
var
  Ini: TIniFile;  // Einstellungen neben der EXE
begin
  Result := '';
  if FileExists(IniFileName) then
  try
    Ini := TIniFile.Create(IniFileName);
    try
      Result := LowerCase(Trim(Ini.ReadString(INI_SECTION, INI_KEY, '')));
    finally
      Ini.Free;
    end;
  except
    Result := '';
  end;
  if (Result <> 'de') and (Result <> 'en') then
    Result := LangSystemDefault;
end;

procedure LangSaveChoice(const Code: string);
var
  Ini: TIniFile;  // Einstellungen (Windows: neben der EXE)
begin
  try
    ForceDirectories(ExtractFilePath(IniFileName));  // Linux: ~/.config/...
    Ini := TIniFile.Create(IniFileName);
    try
      Ini.WriteString(INI_SECTION, INI_KEY, Code);
    finally
      Ini.Free;
    end;
  except
    // nicht beschreibbar: Wahl gilt nur bis zum Beenden
  end;
end;

finalization
  FreeAndNil(GTable);
  FreeAndNil(GTrans);
end.
