{ Rechenlogik von LedPreResistor: Vorwiderstand, tatsächlicher Strom,
  Leistungen, Belastbarkeit und geschätzte Erwärmung.
  Gerechnet wird immer in SI-Einheiten (V, A, Ω, W); umgerechnet wird nur
  bei Ein- und Ausgabe. Keine GUI, keine Texte: Fehler und Warnungen kommen
  als Aufzählungswerte zurück, die Anzeige übersetzt sie selbst. }
unit uCalc;

{$mode objfpc}{$H+}

interface

uses
  uESeries;

const
  { Nennleistungen der üblichen Bauformen in W, aufsteigend }
  RATINGS: array[0..3] of Double = (0.125, 0.25, 0.5, 1.0);

  { Ab dieser Auslastung gibt es eine Warnung (Beschluss 21.10.2026) }
  LOAD_WARN = 0.5;

  { Bauform, auf die sich Auslastung und Erwärmung in der Anzeige beziehen }
  RATING_REFERENCE = 0.25;

  { Wärmewiderstand einer ¼-W-Bauform in °C/W (Näherung, typisch 200–250).
    Für andere Bauformen wird umgekehrt proportional zur Nennleistung
    skaliert, d. h. bei voller Last wird jede Bauform gleich warm. }
  RTH_QUARTER_WATT = 225.0;

type
  { Die LED-Farben mit Vorgabewerten (Reihenfolge wie in der Auswahlliste) }
  TLedColor = (lcRed, lcYellow, lcGreen, lcBlue, lcWhite, lcInfrared);

const
  { Typische Durchlassspannung je LED-Farbe in V (Datenblatt hat Vorrang) }
  LED_DEFAULT_UD: array[TLedColor] of Double = (2.0, 2.1, 2.2, 3.2, 3.2, 1.3);

type
  { Eingabewerte, alle in SI-Einheiten }
  TCalcInput = record
    U: Double;          // Betriebsspannung in V
    Ud: Double;         // Durchlassspannung einer LED in V
    I: Double;          // gewünschter LED-Strom in A
    N: Integer;         // Anzahl LEDs in Reihe
    Series: TESeries;   // Normreihe für den Widerstand
    RatingW: Double;    // gewählte Bauform (Nennleistung) in W, z. B. 0.25
  end;

  { Ergebnis der Prüfung der Eingaben }
  TCalcStatus = (
    csOk,            // alles in Ordnung, Resultat gültig
    csInvalidU,      // Betriebsspannung fehlt oder <= 0
    csInvalidUd,     // Durchlassspannung fehlt oder <= 0
    csInvalidI,      // Strom fehlt oder <= 0
    csInvalidN,      // Anzahl LEDs < 1
    csUTooLow,       // U <= n * Ud: es bleibt keine Spannung für den Widerstand
    csNoStdValue     // kein Normwert gefunden (sollte nicht vorkommen)
  );

  { Bewertung der Auslastung des Widerstands }
  TLoadLevel = (
    llOk,        // höchstens 50 % (grün)
    llWarning,   // über 50 %, höchstens 100 % (gelb)
    llOverload   // über 100 % (rot)
  );

  { Alle Resultate, in SI-Einheiten }
  TCalcResult = record
    Status: TCalcStatus;  // nur bei csOk sind die Werte unten gültig
    UR: Double;           // Spannung am Widerstand in V
    RCalc: Double;        // berechneter Widerstand in Ω
    Std: TStdValue;       // gewählter Normwert (nächsthöher)
    R: Double;            // Normwert in Ω (= Std.Value)
    IAct: Double;         // tatsächlicher Strom mit dem Normwert in A
    PR: Double;           // Leistung im Widerstand in W
    PLed: Double;         // Leistung in allen LEDs zusammen in W
    PTotal: Double;       // Gesamtleistung aus der Quelle in W
    Load: Double;         // Auslastung der gewählten Bauform (0.66 = 66 %)
    LoadLevel: TLoadLevel; // Bewertung dieser Auslastung
    RecommendedW: Double; // kleinste Bauform mit Auslastung <= 50 %, 0 = keine bis 1 W
    TempRise: Double;     // geschätzte Erwärmung der gewählten Bauform in °C
  end;

{ Rechnet alles aus. Bei ungültigen Eingaben steht in Status der Grund,
  die übrigen Felder sind dann 0. }
function Calculate(const Input: TCalcInput): TCalcResult;

{ Bewertet eine Auslastung (0.5 = 50 %) als grün, gelb oder rot. }
function LoadLevelOf(Load: Double): TLoadLevel;

{ Liefert die kleinste Bauform aus RATINGS, die mit der Leistung P höchstens
  zu 50 % ausgelastet ist; 0, wenn selbst 1 W nicht reicht. }
function RecommendRating(P: Double): Double;

{ Schätzt die Erwärmung eines Widerstands der Nennleistung RatingW, der mit
  der Leistung P belastet ist, in °C über der Umgebung (Näherung). }
function EstimateTempRise(P, RatingW: Double): Double;

{ Wandelt einen eingegebenen Text in eine Zahl um. Komma und Punkt werden
  beide als Dezimalzeichen akzeptiert, unabhängig von der Ländereinstellung.
  Leerzeichen am Rand werden ignoriert. Liefert False bei leerem oder
  ungültigem Text (auch bei mehr als einem Dezimalzeichen). }
function ParseDecimal(const S: string; out Value: Double): Boolean;

implementation

uses
  SysUtils, Math;

function LoadLevelOf(Load: Double): TLoadLevel;
begin
  if Load > 1.0 then
    Result := llOverload
  else if Load > LOAD_WARN then
    Result := llWarning
  else
    Result := llOk;
end;

function RecommendRating(P: Double): Double;
var
  I: Integer;  // Index in RATINGS
begin
  for I := Low(RATINGS) to High(RATINGS) do
    if P <= RATINGS[I] * LOAD_WARN then
      Exit(RATINGS[I]);
  Result := 0;
end;

function EstimateTempRise(P, RatingW: Double): Double;
begin
  if RatingW <= 0 then
    Exit(0);
  // Rth der Bauform: ¼ W -> 225 °C/W, ½ W -> 112,5 °C/W usw.
  Result := P * RTH_QUARTER_WATT * (0.25 / RatingW);
end;

function Calculate(const Input: TCalcInput): TCalcResult;
begin
  Result := Default(TCalcResult);

  // Eingaben prüfen; der erste Fehler gewinnt
  if not (Input.U > 0) then
    Result.Status := csInvalidU
  else if not (Input.Ud > 0) then
    Result.Status := csInvalidUd
  else if not (Input.I > 0) then
    Result.Status := csInvalidI
  else if Input.N < 1 then
    Result.Status := csInvalidN
  else if Input.U <= Input.N * Input.Ud then
    Result.Status := csUTooLow;
  if Result.Status <> csOk then
    Exit;

  Result.UR := Input.U - Input.N * Input.Ud;
  Result.RCalc := Result.UR / Input.I;
  if not NextStdValue(Result.RCalc, Input.Series, Result.Std) then
  begin
    Result := Default(TCalcResult);
    Result.Status := csNoStdValue;
    Exit;
  end;

  Result.R := Result.Std.Value;
  Result.IAct := Result.UR / Result.R;
  Result.PR := Result.UR * Result.IAct;
  Result.PLed := Input.N * Input.Ud * Result.IAct;
  Result.PTotal := Input.U * Result.IAct;

  if Input.RatingW > 0 then
    Result.Load := Result.PR / Input.RatingW;
  Result.LoadLevel := LoadLevelOf(Result.Load);
  Result.RecommendedW := RecommendRating(Result.PR);
  Result.TempRise := EstimateTempRise(Result.PR, Input.RatingW);
end;

function ParseDecimal(const S: string; out Value: Double): Boolean;
var
  T: string;               // bereinigter Text
  FS: TFormatSettings;     // feste Einstellungen mit Punkt als Dezimalzeichen
begin
  Value := 0;
  T := Trim(S);
  // Komma wie Punkt behandeln; zwei Dezimalzeichen sind ungültig ("1.000,5")
  T := StringReplace(T, ',', '.', [rfReplaceAll]);
  if (T = '') or (Pos('.', T) <> LastDelimiter('.', T)) then
    Exit(False);

  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  FS.ThousandSeparator := #0;
  Result := TryStrToFloat(T, Value, FS) and not IsNan(Value) and not IsInfinite(Value);
  if not Result then
    Value := 0;
end;

end.
