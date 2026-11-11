{ Formatierte Ausgabe der Werte: Volt, Ohm, Milliampere, Leistung, Prozent.
  Keine überflüssigen Nachkommastellen (4,7 kΩ statt 4700,00 Ω).
  Dezimalzeichen und Prozent-Abstand sind einstellbar (Komma und "66 %"
  für Deutsch, Punkt und "66%" für Englisch). }
unit uFormat;

{$mode objfpc}{$H+}

interface

var
  { Dezimalzeichen der Anzeige; Standard Komma }
  DisplayDecimal: Char = ',';
  { Abstand zwischen Zahl und Prozentzeichen: ' ' auf Deutsch ("66 %"),
    leer auf Englisch ("66%") }
  PercentSpace: string = ' ';

{ Zahl mit höchstens MaxDec und mindestens MinDec Nachkommastellen,
  gerundet; überzählige Nullen am Ende werden weggelassen. }
function FormatNum(V: Double; MaxDec, MinDec: Integer): string;

{ Spannung, z. B. "12 V", "8,8 V", "3,25 V" }
function FormatVolt(V: Double): string;

{ Widerstand mit Vorsatz, z. B. "470 Ω", "4,7 kΩ", "1 MΩ", "0,47 Ω" }
function FormatOhm(R: Double): string;

{ Strom in mA mit 1–2 Nachkommastellen, z. B. "18,72 mA", "20,0 mA" }
function FormatMilliAmp(I: Double): string;

{ Leistung: unter 1 W in mW mit einer Nachkommastelle ("164,8 mW"),
  ab 1 W in W mit zwei ("1,25 W") }
function FormatPower(P: Double): string;

{ Bauform als Bruch: "⅛ W", "¼ W", "½ W", "1 W" }
function FormatRating(W: Double): string;

{ Anteil als ganze Prozent, z. B. 0.659 -> "66 %" }
function FormatPercent(X: Double): string;

{ Anteil mit einer Nachkommastelle, z. B. 0.5036 -> "50,4 %" }
function FormatPercent1(X: Double): string;

{ Zeit: ab 0,1 s in s ("0,48 s", "1,25 s", "12,3 s"), darunter in ms ("47,1 ms") }
function FormatSeconds(T: Double): string;

{ Frequenz mit drei gültigen Stellen: "1,05 Hz", "0,25 Hz", "12,3 Hz", "1,2 kHz" }
function FormatFreq(F: Double): string;

{ Kondensator mit Vorsatz: "10 µF", "100 nF", "4,7 nF", "220 pF" }
function FormatCap(C: Double): string;

{ Zahl mit N gültigen Stellen (ohne Einheit), z. B. (1,0531; 3) -> "1,05" }
function FormatSig(V: Double; N: Integer): string;

implementation

uses
  SysUtils, Math;

function FormatNum(V: Double; MaxDec, MinDec: Integer): string;
var
  FS: TFormatSettings;  // Einstellungen mit dem gewählten Dezimalzeichen
  P: Integer;           // Position des Dezimalzeichens
begin
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := DisplayDecimal;
  FS.ThousandSeparator := #0;
  Result := FloatToStrF(V, ffFixed, 15, MaxDec, FS);
  // überzählige Nullen am Ende entfernen, aber mindestens MinDec stehen lassen
  P := Pos(DisplayDecimal, Result);
  if P > 0 then
  begin
    while (Length(Result) - P > MinDec) and (Result[Length(Result)] = '0') do
      Delete(Result, Length(Result), 1);
    if Result[Length(Result)] = DisplayDecimal then
      Delete(Result, Length(Result), 1);
  end;
  if (Result = '-0') then
    Result := '0';
end;

function FormatVolt(V: Double): string;
begin
  Result := FormatNum(V, 2, 0) + ' V';
end;

function FormatOhm(R: Double): string;
begin
  if Abs(R) >= 1e6 then
    Result := FormatNum(R / 1e6, 2, 0) + ' MΩ'
  else if Abs(R) >= 1e3 then
    Result := FormatNum(R / 1e3, 2, 0) + ' kΩ'
  else
    Result := FormatNum(R, 2, 0) + ' Ω';
end;

function FormatMilliAmp(I: Double): string;
begin
  Result := FormatNum(I * 1000, 2, 1) + ' mA';
end;

function FormatPower(P: Double): string;
begin
  if Abs(P) >= 1 then
    Result := FormatNum(P, 2, 0) + ' W'
  else
    Result := FormatNum(P * 1000, 1, 1) + ' mW';
end;

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

function FormatPercent(X: Double): string;
begin
  Result := IntToStr(Round(X * 100)) + PercentSpace + '%';
end;

function FormatPercent1(X: Double): string;
begin
  Result := FormatNum(X * 100, 1, 0) + PercentSpace + '%';
end;

function FormatSig(V: Double; N: Integer): string;
var
  Dec: Integer;  // Nachkommastellen für N gültige Stellen
begin
  if V = 0 then
    Exit('0');
  Dec := N - 1 - Floor(Log10(Abs(V)));
  if Dec < 0 then Dec := 0;
  Result := FormatNum(V, Dec, 0);
end;

function FormatSeconds(T: Double): string;
begin
  if T >= 0.1 then
    Result := FormatSig(T, 3) + ' s'
  else
    Result := FormatSig(T * 1000, 3) + ' ms';
end;

function FormatFreq(F: Double): string;
begin
  if F >= 1000 then
    Result := FormatSig(F / 1000, 3) + ' kHz'
  else
    Result := FormatSig(F, 3) + ' Hz';
end;

function FormatCap(C: Double): string;
begin
  if C >= 1e-6 * 0.9999 then
    Result := FormatSig(C * 1e6, 3) + ' µF'
  else if C >= 1e-9 * 0.9999 then
    Result := FormatSig(C * 1e9, 3) + ' nF'
  else
    Result := FormatSig(C * 1e12, 3) + ' pF';
end;

end.
