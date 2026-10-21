{ Formatierte Ausgabe der Werte: Volt, Ohm, Milliampere, Leistung, Prozent.
  Keine überflüssigen Nachkommastellen (4,7 kΩ statt 4700,00 Ω).
  Das Dezimalzeichen ist einstellbar (Komma für Deutsch, Punkt für Englisch). }
unit uFormat;

{$mode objfpc}{$H+}

interface

var
  { Dezimalzeichen der Anzeige; Standard Komma }
  DisplayDecimal: Char = ',';

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
  Result := IntToStr(Round(X * 100)) + ' %';
end;

end.
