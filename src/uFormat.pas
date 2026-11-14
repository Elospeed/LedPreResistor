{==============================================================================
  uFormat - Zahlen schön als Text ausgeben
==============================================================================
  Zweck:     Macht aus den gerechneten SI-Werten gut lesbare Texte für
             Karten, Schaltplan, Rechenweg und Statuszeile:
               Spannung     12 V, 8,8 V
               Widerstand   470 Ω, 4,7 kΩ, 1 MΩ
               Strom        18,72 mA
               Leistung     164,8 mW, 1,25 W
               Bauform      ⅛ W, ¼ W, ½ W, 1 W
               Prozent      66 %
               Zeit         0,48 s, 47,1 ms
               Frequenz     1,05 Hz, 1,2 kHz
               Kondensator  10 µF, 100 nF, 220 pF

  Regeln:    Keine überflüssigen Nachkommastellen (4,7 kΩ statt 4700,00 Ω).
             Dezimalzeichen und Prozent-Abstand hängen von der Sprache ab:
             Deutsch «4,7» und «66 %», Englisch «4.7» und «66%»; gesetzt
             werden sie in uMain.ApplyLanguage.

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  Kommentare ausführlicher
             2.3  11.11.2026  Zeit, Frequenz, Kondensator, gültige Stellen (Blinkschaltung)
             2.1  08.11.2026  Dezimalzeichen und Prozent-Abstand je Sprache
             2.0  29.10.2026  erste Fassung
==============================================================================}
unit uFormat;

{$mode objfpc}{$H+}

interface

{==============================================================================
  EINSTELLUNGEN (je nach Sprache)
==============================================================================}
var
  DisplayDecimal: Char = ',';                            // Dezimalzeichen: ',' Deutsch, '.' Englisch
  PercentSpace: string = ' ';                            // vor dem %: ' ' Deutsch (66 %), '' Englisch (66%)

{==============================================================================
  ÖFFENTLICHE FUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  FormatNum
------------------------------------------------------------------------------
  Zahl mit höchstens MaxDec und mindestens MinDec Nachkommastellen,
  gerundet; überzählige Nullen am Ende werden weggelassen.
------------------------------------------------------------------------------}
function FormatNum(V: Double; MaxDec, MinDec: Integer): string;

{------------------------------------------------------------------------------
  FormatVolt
------------------------------------------------------------------------------
  Spannung, z. B. "12 V", "8,8 V", "3,25 V"
------------------------------------------------------------------------------}
function FormatVolt(V: Double): string;

{------------------------------------------------------------------------------
  FormatOhm
------------------------------------------------------------------------------
  Widerstand mit Vorsatz, z. B. "470 Ω", "4,7 kΩ", "1 MΩ", "0,47 Ω"
------------------------------------------------------------------------------}
function FormatOhm(R: Double): string;

{------------------------------------------------------------------------------
  FormatMilliAmp
------------------------------------------------------------------------------
  Strom in mA mit 1–2 Nachkommastellen, z. B. "18,72 mA", "20,0 mA"
------------------------------------------------------------------------------}
function FormatMilliAmp(I: Double): string;

{------------------------------------------------------------------------------
  FormatPower
------------------------------------------------------------------------------
  Leistung: unter 1 W in mW mit einer Nachkommastelle ("164,8 mW"),
  ab 1 W in W mit zwei ("1,25 W")
------------------------------------------------------------------------------}
function FormatPower(P: Double): string;

{------------------------------------------------------------------------------
  FormatRating
------------------------------------------------------------------------------
  Bauform als Bruch: "⅛ W", "¼ W", "½ W", "1 W"
------------------------------------------------------------------------------}
function FormatRating(W: Double): string;

{------------------------------------------------------------------------------
  FormatPercent
------------------------------------------------------------------------------
  Anteil als ganze Prozent, z. B. 0.659 -> "66 %"
------------------------------------------------------------------------------}
function FormatPercent(X: Double): string;

{------------------------------------------------------------------------------
  FormatPercent1
------------------------------------------------------------------------------
  Anteil mit einer Nachkommastelle, z. B. 0.5036 -> "50,4 %"
------------------------------------------------------------------------------}
function FormatPercent1(X: Double): string;

{------------------------------------------------------------------------------
  FormatSeconds
------------------------------------------------------------------------------
  Zeit: ab 0,1 s in s ("0,48 s", "1,25 s", "12,3 s"), darunter in ms ("47,1 ms")
------------------------------------------------------------------------------}
function FormatSeconds(T: Double): string;

{------------------------------------------------------------------------------
  FormatFreq
------------------------------------------------------------------------------
  Frequenz mit drei gültigen Stellen: "1,05 Hz", "0,25 Hz", "12,3 Hz", "1,2 kHz"
------------------------------------------------------------------------------}
function FormatFreq(F: Double): string;

{------------------------------------------------------------------------------
  FormatCap
------------------------------------------------------------------------------
  Kondensator mit Vorsatz: "10 µF", "100 nF", "4,7 nF", "220 pF"
------------------------------------------------------------------------------}
function FormatCap(C: Double): string;

{------------------------------------------------------------------------------
  FormatSig
------------------------------------------------------------------------------
  Zahl mit N gültigen Stellen (ohne Einheit), z. B. (1,0531; 3) -> "1,05"
------------------------------------------------------------------------------}
function FormatSig(V: Double; N: Integer): string;

implementation

uses
  SysUtils,                                              // FloatToStrF, TFormatSettings
  Math;                                                  // Floor, Log10, SameValue

{------------------------------------------------------------------------------
  FormatNum - siehe Interface
------------------------------------------------------------------------------}
function FormatNum(V: Double; MaxDec, MinDec: Integer): string;
var
  FS: TFormatSettings;                                   // Einstellungen mit dem gewählten Dezimalzeichen
  P: Integer;                                            // Position des Dezimalzeichens
begin
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := DisplayDecimal;
  FS.ThousandSeparator := #0;                            // keine Tausender-Trennung (4700, nicht 4'700)
  Result := FloatToStrF(V, ffFixed, 15, MaxDec, FS);     // z. B. 8,80
  // überzählige Nullen am Ende entfernen, aber mindestens MinDec stehen lassen
  P := Pos(DisplayDecimal, Result);
  if P > 0 then
  begin
    while (Length(Result) - P > MinDec) and (Result[Length(Result)] = '0') do
      Delete(Result, Length(Result), 1);
    if Result[Length(Result)] = DisplayDecimal then
      Delete(Result, Length(Result), 1);                 // «12,» -> «12»
  end;
  if (Result = '-0') then                                // kleine negative Rundung nicht als «-0» zeigen
    Result := '0';
end;

{------------------------------------------------------------------------------
  FormatVolt - siehe Interface
------------------------------------------------------------------------------}
function FormatVolt(V: Double): string;
begin
  Result := FormatNum(V, 2, 0) + ' V';
end;

{------------------------------------------------------------------------------
  FormatOhm - siehe Interface
------------------------------------------------------------------------------}
function FormatOhm(R: Double): string;
begin
  if Abs(R) >= 1e6 then
    Result := FormatNum(R / 1e6, 2, 0) + ' MΩ'
  else if Abs(R) >= 1e3 then
    Result := FormatNum(R / 1e3, 2, 0) + ' kΩ'
  else
    Result := FormatNum(R, 2, 0) + ' Ω';
end;

{------------------------------------------------------------------------------
  FormatMilliAmp - siehe Interface
------------------------------------------------------------------------------}
function FormatMilliAmp(I: Double): string;
begin
  Result := FormatNum(I * 1000, 2, 1) + ' mA';
end;

{------------------------------------------------------------------------------
  FormatPower - siehe Interface
------------------------------------------------------------------------------}
function FormatPower(P: Double): string;
begin
  if Abs(P) >= 1 then
    Result := FormatNum(P, 2, 0) + ' W'
  else
    Result := FormatNum(P * 1000, 1, 1) + ' mW';
end;

{------------------------------------------------------------------------------
  FormatRating - siehe Interface
------------------------------------------------------------------------------}
function FormatRating(W: Double): string;
begin
  if SameValue(W, 0.125) then
    Result := '⅛ W'
  else if SameValue(W, 0.25) then
    Result := '¼ W'
  else if SameValue(W, 0.5) then
    Result := '½ W'
  else
    Result := FormatNum(W, 2, 0) + ' W';
end;

{------------------------------------------------------------------------------
  FormatPercent - siehe Interface
------------------------------------------------------------------------------}
function FormatPercent(X: Double): string;
begin
  Result := IntToStr(Round(X * 100)) + PercentSpace + '%';
end;

{------------------------------------------------------------------------------
  FormatPercent1 - siehe Interface
------------------------------------------------------------------------------}
function FormatPercent1(X: Double): string;
begin
  Result := FormatNum(X * 100, 1, 0) + PercentSpace + '%';
end;

{------------------------------------------------------------------------------
  FormatSig - siehe Interface
------------------------------------------------------------------------------}
function FormatSig(V: Double; N: Integer): string;
var
  Dec: Integer;                                          // Nachkommastellen für N gültige Stellen
begin
  if V = 0 then
    Exit('0');
  // Beispiel N = 3: 1,0531 -> 2 Stellen (1,05), 12,34 -> 1 Stelle (12,3)
  Dec := N - 1 - Floor(Log10(Abs(V)));
  if Dec < 0 then Dec := 0;
  Result := FormatNum(V, Dec, 0);
end;

{------------------------------------------------------------------------------
  FormatSeconds - siehe Interface
------------------------------------------------------------------------------}
function FormatSeconds(T: Double): string;
begin
  if T >= 0.1 then
    Result := FormatSig(T, 3) + ' s'
  else
    Result := FormatSig(T * 1000, 3) + ' ms';
end;

{------------------------------------------------------------------------------
  FormatFreq - siehe Interface
------------------------------------------------------------------------------}
function FormatFreq(F: Double): string;
begin
  if F >= 1000 then
    Result := FormatSig(F / 1000, 3) + ' kHz'
  else
    Result := FormatSig(F, 3) + ' Hz';
end;

{------------------------------------------------------------------------------
  FormatCap - siehe Interface
------------------------------------------------------------------------------}
function FormatCap(C: Double): string;
begin
  // kleine Toleranz, damit 1 µF nicht als 1000 nF erscheint
  if C >= 1e-6 * 0.9999 then
    Result := FormatSig(C * 1e6, 3) + ' µF'
  else if C >= 1e-9 * 0.9999 then
    Result := FormatSig(C * 1e9, 3) + ' nF'
  else
    Result := FormatSig(C * 1e12, 3) + ' pF';
end;

end.
