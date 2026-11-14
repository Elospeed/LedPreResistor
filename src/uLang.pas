{==============================================================================
  uLang - Mehrsprachigkeit (Deutsch und Englisch)
==============================================================================
  Zweck:     Übersetzt alle sichtbaren Texte. Aufbau wie uLang in StemMaker.

  Idee:      Das Programm ist auf Deutsch geschrieben. Jeder sichtbare Text
             läuft durch die kleine Funktion _():

               Caption := _('Speisespannung');

             _() sucht den deutschen Text in der geladenen Übersetzung. Gibt
             es eine, kommt sie zurück, sonst der deutsche Text. Es kann also
             nie «nichts» angezeigt werden; schlimmstenfalls steht etwas auf
             Deutsch da.

  Über-      Steht in src/lang/en.po im üblichen gettext-Format (mit Poedit
  setzung:   bearbeitbar) und steckt als Ressource LANG_EN in der EXE. So
             bleibt es eine einzige EXE ohne lang-Ordner.

               msgid "Speisespannung"
               msgstr "Supply voltage"

  Sprach-    Beim ersten Start: Deutsch bei deutschem Windows (Linux:
  wahl:      LANG=de...), sonst Englisch. Wählt man oben rechts DE oder EN,
             steht die Wahl in LedPreResistor.ini neben der EXE (Linux:
             ~/.config/LedPreResistor/).

  Regel:     Logik stützt sich nie auf übersetzten Text, nur auf den
             Sprachcode ('de' oder 'en').

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  Sprachwechsel über DE/EN statt Menü, Kommentare
             2.1  08.11.2026  neu: Deutsch/Englisch
==============================================================================}
unit uLang;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

{==============================================================================
  ÖFFENTLICHE FUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  _
------------------------------------------------------------------------------
  Übersetzt einen Text: deutsch rein, aktuelle Sprache raus.
  Parameter: S - deutscher Originaltext
  Rückgabe:  Übersetzung; ohne Übersetzung der deutsche Text
------------------------------------------------------------------------------}
function _(const S: string): string;

{------------------------------------------------------------------------------
  LangLoad
------------------------------------------------------------------------------
  Lädt eine Sprache.
  Parameter: Code - 'de' = Original (keine Übersetzung nötig),
                    'en' = aus der Ressource LANG_EN
  Rückgabe:  False, wenn die Übersetzung fehlt; dann bleibt es bei Deutsch
------------------------------------------------------------------------------}
function LangLoad(const Code: string): Boolean;

{------------------------------------------------------------------------------
  LangCode
------------------------------------------------------------------------------
  Rückgabe:  aktuell geladene Sprache, 'de' oder 'en'
------------------------------------------------------------------------------}
function LangCode: string;

{------------------------------------------------------------------------------
  LangSystemDefault
------------------------------------------------------------------------------
  Rückgabe:  Sprache des Systems: 'de' bei deutschem Windows (Linux:
             Umgebungsvariable LANG beginnt mit «de»), sonst 'en'
------------------------------------------------------------------------------}
function LangSystemDefault: string;

{------------------------------------------------------------------------------
  LangStartCode
------------------------------------------------------------------------------
  Rückgabe:  Sprache für den Programmstart: die gespeicherte Wahl aus der
             INI, sonst die Sprache des Systems
------------------------------------------------------------------------------}
function LangStartCode: string;

{------------------------------------------------------------------------------
  LangSaveChoice
------------------------------------------------------------------------------
  Speichert die gewählte Sprache in der INI.
  Parameter: Code - 'de' oder 'en'
  Fehler werden still übergangen (z. B. EXE in einem schreibgeschützten
  Ordner); dann gilt die Wahl nur bis zum Beenden.
------------------------------------------------------------------------------}
procedure LangSaveChoice(const Code: string);

{------------------------------------------------------------------------------
  IniFileName
------------------------------------------------------------------------------
  Rückgabe:  vollständiger Pfad der Einstellungsdatei
             (Windows: neben der EXE, Linux: ~/.config/LedPreResistor/).
             Auch für andere Einstellungen als die Sprache.
------------------------------------------------------------------------------}
function IniFileName: string;

{------------------------------------------------------------------------------
  LangLoadFromPo
------------------------------------------------------------------------------
  Liest eine Übersetzung aus Zeilen im .po-Format. Öffentlich, damit die
  Tests sie ohne Ressource prüfen können.
  Parameter: PoLines - Zeilen der .po-Datei
             Code    - Sprachcode, der danach gilt
------------------------------------------------------------------------------}
procedure LangLoadFromPo(PoLines: TStrings; const Code: string);

implementation

uses
  IniFiles {$IFDEF WINDOWS}, Windows{$ENDIF};            // Windows: RT_RCDATA

{==============================================================================
  KONSTANTEN UND VARIABLEN
==============================================================================}
const
  INI_NAME = 'LedPreResistor.ini';                       // Name der Einstellungsdatei
  INI_SECTION = 'Allgemein';                             // Abschnitt in der INI
  INI_KEY = 'Sprache';                                   // Schlüssel für die Sprache

var
  GCode: string = 'de';                                  // aktuelle Sprache
  GTable: TStringList = nil;                             // sortierte deutsche Originaltexte; das
                                                         // «Objekt» daneben ist die Nummer der
                                                         // Übersetzung in GTrans
  GTrans: TStringList = nil;                             // die Übersetzungen

{==============================================================================
  ÜBERSETZEN
==============================================================================}

{------------------------------------------------------------------------------
  LangCode - siehe Interface
------------------------------------------------------------------------------}
function LangCode: string;
begin
  Result := GCode;
end;

{------------------------------------------------------------------------------
  _
------------------------------------------------------------------------------
  siehe Interface. GTable ist sortiert, darum ist die Suche mit Find
  schnell (halbieren statt alle durchgehen).
------------------------------------------------------------------------------}
function _(const S: string): string;
var
  I: Integer;                                            // Fundstelle in GTable
begin
  Result := S;
  if (GTable = nil) or (S = '') then Exit;               // Deutsch: nichts zu tun
  if GTable.Find(S, I) then
    Result := GTrans[PtrInt(GTable.Objects[I])];         // Nummer -> Übersetzung
end;

{------------------------------------------------------------------------------
  Unescape
------------------------------------------------------------------------------
  Löst Sonderzeichen in einem .po-Text auf: \n (neue Zeile), \t (Tab),
  \" (Anführungszeichen), \\ (Rückstrich). Unbekannte bleiben stehen.
------------------------------------------------------------------------------}
function Unescape(const S: string): string;
var
  I: Integer;                                            // Position im Text
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

{------------------------------------------------------------------------------
  Quoted
------------------------------------------------------------------------------
  Rückgabe:  Text zwischen dem ersten und dem letzten Anführungszeichen
             einer Zeile, Sonderzeichen aufgelöst; ohne zwei
             Anführungszeichen leer
------------------------------------------------------------------------------}
function Quoted(const Line: string): string;
var
  A, B: Integer;                                         // Lage der beiden Anführungszeichen
begin
  A := Pos('"', Line);
  B := Length(Line);
  while (B > A) and (Line[B] <> '"') do Dec(B);
  if (A > 0) and (B > A) then
    Result := Unescape(Copy(Line, A + 1, B - A - 1))
  else
    Result := '';
end;

{------------------------------------------------------------------------------
  LangLoadFromPo - siehe Interface
------------------------------------------------------------------------------
  Aufbau einer .po-Datei (vereinfacht):
  #, fuzzy                    <- unsicher übersetzt -> weglassen
  msgid "Erste Zeile "
  "Fortsetzung"               <- mehrzeilige Texte werden zusammengehängt
  msgstr "Translation"
------------------------------------------------------------------------------}
procedure LangLoadFromPo(PoLines: TStrings; const Code: string);
var
  I: Integer;                                            // Zeilenzähler
  Mode: Integer;                                         // 0 = nichts, 1 = in msgid, 2 = in msgstr
  Line: string;                                          // aktuelle Zeile ohne Leerraum
  Id, Str: string;                                       // deutscher Text und Übersetzung des Eintrags
  Fuzzy: Boolean;                                        // Eintrag als unsicher markiert

  {----------------------------------------------------------------------------
    Flush
  ----------------------------------------------------------------------------
    Übernimmt den fertigen Eintrag (leere und unsichere weglassen) und
    beginnt einen neuen.
  ----------------------------------------------------------------------------}
  procedure Flush;
  begin
    if (Id <> '') and (Str <> '') and not Fuzzy then
    begin
      GTrans.Add(Str);
      GTable.AddObject(Id, TObject(PtrInt(GTrans.Count - 1)));  // Nummer der Übersetzung merken
    end;
    Id := ''; Str := ''; Fuzzy := False; Mode := 0;
  end;

begin
  FreeAndNil(GTable);
  FreeAndNil(GTrans);
  GTable := TStringList.Create;
  GTable.CaseSensitive := True;                          // «Rot» und «rot» sind verschieden
  GTrans := TStringList.Create;
  Id := ''; Str := ''; Fuzzy := False; Mode := 0;
  for I := 0 to PoLines.Count - 1 do
  begin
    Line := Trim(PoLines[I]);
    if Line = '' then
      Flush                                              // Leerzeile = Eintrag fertig
    else if Copy(Line, 1, 2) = '#,' then
    begin
      if Mode = 2 then Flush;
      Fuzzy := Pos('fuzzy', Line) > 0;                   // unsicher übersetzt
    end
    else if Line[1] = '#' then
      // Kommentar
    else if Copy(Line, 1, 6) = 'msgid ' then
    begin
      if Mode = 2 then Flush;                            // neuer Eintrag ohne Leerzeile davor
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
        1: Id := Id + Quoted(Line);                      // Fortsetzung des Originals
        2: Str := Str + Quoted(Line);                    // Fortsetzung der Übersetzung
      end;
  end;
  Flush;
  GTable.Sorted := True;                                 // erst JETZT sortieren
  GCode := LowerCase(Code);
end;

{------------------------------------------------------------------------------
  LangLoad - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Alte Übersetzung weg, zuerst Deutsch
    2. Deutsch gewünscht: fertig
    3. Sonst Ressource LANG_<CODE> aus der EXE lesen und auswerten
------------------------------------------------------------------------------}
function LangLoad(const Code: string): Boolean;
var
  ResName: string;                                       // Name der Ressource, z. B. LANG_EN
  Res: TResourceStream;                                  // Übersetzung aus der EXE
  L: TStringList;                                        // Zeilen der .po
begin
  // ----- 1. Zuerst Deutsch -----
  FreeAndNil(GTable);
  FreeAndNil(GTrans);
  GCode := 'de';
  // ----- 2. Deutsch gewünscht? -----
  if (Code = '') or SameText(Code, 'de') then
    Exit(True);                                          // Deutsch = Original
  Result := False;
  // ----- 3. Übersetzung aus der EXE -----
  ResName := 'LANG_' + UpperCase(Code);                  // z. B. LANG_EN
  if FindResource(HInstance, PChar(ResName), RT_RCDATA) = 0 then
    Exit;                                                // nicht eingebaut
  L := TStringList.Create;
  try
    try
      Res := TResourceStream.Create(HInstance, ResName, RT_RCDATA);
      try
        L.LoadFromStream(Res);                           // UTF-8 wie der Rest
      finally
        Res.Free;
      end;
    except
      Exit;                                              // Ressource fehlt: bei Deutsch bleiben
    end;
    LangLoadFromPo(L, Code);
    Result := True;
  finally
    L.Free;
  end;
end;

{==============================================================================
  SPRACHWAHL UND EINSTELLUNGEN
==============================================================================}

{------------------------------------------------------------------------------
  GetUserDefaultUILanguage (Windows)
------------------------------------------------------------------------------
  Sprache der Windows-Oberfläche, z. B. $0807 (Deutsch Schweiz) oder
  $0409 (Englisch USA). Die unteren 10 Bit sind die Hauptsprache,
  $07 = Deutsch.
------------------------------------------------------------------------------}
{$IFDEF WINDOWS}
function GetUserDefaultUILanguage: Word; stdcall; external 'kernel32.dll';
{$ENDIF}

{------------------------------------------------------------------------------
  LangSystemDefault - siehe Interface
------------------------------------------------------------------------------}
function LangSystemDefault: string;
begin
  Result := 'en';
  {$IFDEF WINDOWS}
  if GetUserDefaultUILanguage and $3FF = $07 then        // Hauptsprache Deutsch
    Result := 'de';
  {$ELSE}
  if LowerCase(Copy(GetEnvironmentVariable('LANG'), 1, 2)) = 'de' then
    Result := 'de';
  {$ENDIF}
end;

{------------------------------------------------------------------------------
  IniFileName - siehe Interface
------------------------------------------------------------------------------
  Windows: INI neben der EXE (portabel). Linux: Programme liegen oft in
  schreibgeschützten Ordnern (z. B. /opt, /usr/bin), darum dort im
  Einstellungsordner des Benutzers: ~/.config/LedPreResistor/
------------------------------------------------------------------------------}
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

{------------------------------------------------------------------------------
  LangStartCode - siehe Interface
------------------------------------------------------------------------------}
function LangStartCode: string;
var
  Ini: TIniFile;                                         // Einstellungen neben der EXE
begin
  Result := '';
  if FileExists(IniFileName) then
  try
    Ini := TIniFile.Create(IniFileName);
    try
      Result := LowerCase(Trim(Ini.ReadString(INI_SECTION, INI_KEY, '')));  // [Allgemein] Sprache=
    finally
      Ini.Free;
    end;
  except
    Result := '';
  end;
  if (Result <> 'de') and (Result <> 'en') then          // nichts oder Unsinn gespeichert
    Result := LangSystemDefault;
end;

{------------------------------------------------------------------------------
  LangSaveChoice - siehe Interface
------------------------------------------------------------------------------}
procedure LangSaveChoice(const Code: string);
var
  Ini: TIniFile;                                         // Einstellungen (Windows: neben der EXE)
begin
  try
    ForceDirectories(ExtractFilePath(IniFileName));      // Linux: ~/.config/...
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
