{==============================================================================
  uCalc - Rechenlogik des Vorwiderstands
==============================================================================
  Zweck:     Rechnet den Reiter «Vorwiderstand» aus: Spannung am
             Widerstand, Vorwiderstand und Normwert, tatsächlicher Strom,
             Leistungen, Belastbarkeit (Bauform) und geschätzte Erwärmung,
             auch für mehrere gleiche LED-Stränge parallel.

  Formeln:   Spannung am Widerstand  U_R = U_B - n × U_F
             Vorwiderstand           R   = U_R / I  -> Normwert darüber
             tatsächlicher Strom     I   = U_R / R(Normwert)
             Leistung im Widerstand  P   = U_R × I
             Erwärmung (Näherung)    ΔT  = P × R_th (¼ W: ca. 225 °C/W)
             Beispiel: U_B = 12 V, weisse LED U_F = 3,2 V, 20 mA:
               U_R = 8,8 V; R = 440 Ω -> 470 Ω (E12); I = 18,72 mA;
               P = 164,8 mW -> ¼ W zu 66 % ausgelastet -> ½ W empfohlen

  Regeln:    Gerechnet wird immer in SI-Einheiten (V, A, Ω, W); umgerechnet
             wird nur bei Ein- und Ausgabe. Keine Oberfläche, keine Texte:
             Fehler und Warnungen kommen als Aufzählungswerte zurück, die
             Anzeige (uMain) übersetzt sie selbst. Geprüft im Testprojekt
             (tests/TestCalc.pas).

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  Stränge parallel (Gesamtstrom, Gesamtleistung)
             2.0  29.10.2026  erste Fassung
==============================================================================}
unit uCalc;

{$mode objfpc}{$H+}

interface

uses
  uESeries;                                              // Normreihen, NextStdValue

{==============================================================================
  KONSTANTEN
==============================================================================}
const
  // Nennleistungen der üblichen Bauformen in W, aufsteigend: ⅛, ¼, ½, 1 W
  RATINGS: array[0..3] of Double = (0.125, 0.25, 0.5, 1.0);

  // Ab dieser Auslastung gibt es eine Warnung (gelb). 50 % ist die übliche
  // Faustregel: ein Widerstand soll höchstens halb belastet sein.
  LOAD_WARN = 0.5;

  // Bauform, auf die sich Auslastung und Erwärmung in der Anzeige beziehen
  // (¼ W ist die häufigste Bastel-Bauform)
  RATING_REFERENCE = 0.25;

  // Wärmewiderstand R_th einer ¼-W-Bauform in °C/W (Näherung, typisch
  // 200 ... 250). Für andere Bauformen wird umgekehrt proportional zur
  // Nennleistung skaliert, d. h. bei voller Last wird jede Bauform gleich warm.
  RTH_QUARTER_WATT = 225.0;

{==============================================================================
  TYPEN
==============================================================================}
type
  // Die LED-Farben mit Vorgabewerten (Reihenfolge wie in der Auswahlliste)
  TLedColor = (lcRed, lcYellow, lcGreen, lcBlue, lcWhite, lcInfrared);

const
  // Typische Durchlassspannung U_F je LED-Farbe in V (Reihenfolge wie
  // TLedColor: rot, gelb, grün, blau, weiss, infrarot). Das Datenblatt der
  // verwendeten LED hat immer Vorrang.
  LED_DEFAULT_UD: array[TLedColor] of Double = (2.0, 2.1, 2.2, 3.2, 3.2, 1.3);

type
  // ----- Eingaben (alle in SI-Einheiten) -----
  TCalcInput = record
    U: Double;                                           // Speisespannung U_B in V
    Ud: Double;                                          // Durchlassspannung U_F einer LED in V
    I: Double;                                           // gewünschter LED-Strom in A
    N: Integer;                                          // Anzahl LEDs in Reihe
    Series: TESeries;                                    // Normreihe für den Widerstand
    RatingW: Double;                                     // gewählte Bauform (Nennleistung) in W, z. B. 0.25
    Strings: Integer;                                    // Stränge parallel, jeder mit eigenem Widerstand
                                                         // (0 = 1 Strang, negativ = ungültige Eingabe)
  end;

  // ----- Ergebnis der Prüfung der Eingaben -----
  TCalcStatus = (
    csOk,                                                // alles in Ordnung, Resultat gültig
    csInvalidU,                                          // Speisespannung fehlt oder <= 0
    csInvalidUd,                                         // Durchlassspannung fehlt oder <= 0
    csInvalidI,                                          // Strom fehlt oder <= 0
    csInvalidN,                                          // Anzahl LEDs < 1
    csUTooLow,                                           // U <= n * Ud: es bleibt keine Spannung für den Widerstand
    csNoStdValue,                                        // kein Normwert gefunden (sollte nicht vorkommen)
    csInvalidStrings                                     // Stränge parallel < 1
  );

  // ----- Bewertung der Auslastung des Widerstands -----
  TLoadLevel = (
    llOk,                                                // höchstens 50 % (grün)
    llWarning,                                           // über 50 %, höchstens 100 % (gelb)
    llOverload                                           // über 100 % (rot)
  );

  // ----- Alle Resultate (SI-Einheiten) -----
  TCalcResult = record
    Status: TCalcStatus;                                 // nur bei csOk sind die Werte unten gültig
    UR: Double;                                          // Spannung am Widerstand in V
    RCalc: Double;                                       // berechneter Widerstand in Ω
    Std: TStdValue;                                      // gewählter Normwert (nächsthöher)
    R: Double;                                           // Normwert in Ω (= Std.Value)
    IAct: Double;                                        // tatsächlicher Strom mit dem Normwert in A (je Strang)
    Strings: Integer;                                    // Anzahl Stränge (mindestens 1)
    ITotal: Double;                                      // Strom aller Stränge zusammen in A
    PR: Double;                                          // Leistung in einem Widerstand in W
    PLed: Double;                                        // Leistung in allen LEDs zusammen in W (alle Stränge)
    PTotal: Double;                                      // Gesamtleistung aus der Quelle in W (alle Stränge)
    Load: Double;                                        // Auslastung der gewählten Bauform (0.66 = 66 %)
    LoadLevel: TLoadLevel;                               // Bewertung dieser Auslastung
    RecommendedW: Double;                                // kleinste Bauform mit Auslastung <= 50 %, 0 = keine bis 1 W
    TempRise: Double;                                    // geschätzte Erwärmung der gewählten Bauform in °C
  end;

{==============================================================================
  ÖFFENTLICHE FUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  Calculate
------------------------------------------------------------------------------
  Rechnet alles aus. Bei ungültigen Eingaben steht in Status der Grund,
  die übrigen Felder sind dann 0.
------------------------------------------------------------------------------}
function Calculate(const Input: TCalcInput): TCalcResult;

{------------------------------------------------------------------------------
  LoadLevelOf
------------------------------------------------------------------------------
  Bewertet eine Auslastung (0.5 = 50 %) als grün, gelb oder rot.
------------------------------------------------------------------------------}
function LoadLevelOf(Load: Double): TLoadLevel;

{------------------------------------------------------------------------------
  RecommendRating
------------------------------------------------------------------------------
  Liefert die kleinste Bauform aus RATINGS, die mit der Leistung P höchstens
  zu 50 % ausgelastet ist; 0, wenn selbst 1 W nicht reicht.
------------------------------------------------------------------------------}
function RecommendRating(P: Double): Double;

{------------------------------------------------------------------------------
  EstimateTempRise
------------------------------------------------------------------------------
  Schätzt die Erwärmung eines Widerstands der Nennleistung RatingW, der mit
  der Leistung P belastet ist, in °C über der Umgebung (Näherung).
------------------------------------------------------------------------------}
function EstimateTempRise(P, RatingW: Double): Double;

{------------------------------------------------------------------------------
  ParseDecimal
------------------------------------------------------------------------------
  Wandelt einen eingegebenen Text in eine Zahl um. Komma und Punkt werden
  beide als Dezimalzeichen akzeptiert, unabhängig von der Ländereinstellung.
  Leerzeichen am Rand werden ignoriert. Liefert False bei leerem oder
  ungültigem Text (auch bei mehr als einem Dezimalzeichen).
------------------------------------------------------------------------------}
function ParseDecimal(const S: string; out Value: Double): Boolean;

implementation

uses
  SysUtils,                                              // Trim, TryStrToFloat
  Math;                                                  // Max, IsNan, IsInfinite

{------------------------------------------------------------------------------
  LoadLevelOf - siehe Interface
------------------------------------------------------------------------------}
function LoadLevelOf(Load: Double): TLoadLevel;
begin
  if Load > 1.0 then
    Result := llOverload
  else if Load > LOAD_WARN then
    Result := llWarning
  else
    Result := llOk;
end;

{------------------------------------------------------------------------------
  RecommendRating - siehe Interface
------------------------------------------------------------------------------}
function RecommendRating(P: Double): Double;
var
  I: Integer;                                            // Index in RATINGS
begin
  for I := Low(RATINGS) to High(RATINGS) do
    if P <= RATINGS[I] * LOAD_WARN then
      Exit(RATINGS[I]);
  Result := 0;
end;

{------------------------------------------------------------------------------
  EstimateTempRise - siehe Interface
------------------------------------------------------------------------------}
function EstimateTempRise(P, RatingW: Double): Double;
begin
  if RatingW <= 0 then
    Exit(0);
  // R_th der Bauform: ¼ W -> 225 °C/W, ½ W -> 112,5 °C/W usw.
  // Beispiel: 164,8 mW in ¼ W -> 0,1648 W × 225 °C/W = +37 °C
  Result := P * RTH_QUARTER_WATT * (0.25 / RatingW);
end;

{------------------------------------------------------------------------------
  Calculate - siehe Interface
------------------------------------------------------------------------------}
function Calculate(const Input: TCalcInput): TCalcResult;
begin
  Result := Default(TCalcResult);                        // alles 0, Status = csOk

  // ----- 1. Eingaben prüfen; der erste Fehler gewinnt -----
  // «not (x > 0)» fängt auch NaN ab (leeres oder ungültiges Feld)
  if not (Input.U > 0) then
    Result.Status := csInvalidU
  else if not (Input.Ud > 0) then
    Result.Status := csInvalidUd
  else if not (Input.I > 0) then
    Result.Status := csInvalidI
  else if Input.N < 1 then
    Result.Status := csInvalidN
  else if Input.Strings < 0 then
    Result.Status := csInvalidStrings
  else if Input.U <= Input.N * Input.Ud then
    Result.Status := csUTooLow;
  if Result.Status <> csOk then
    Exit;

  // ----- 2. Vorwiderstand und Normwert -----
  Result.UR := Input.U - Input.N * Input.Ud;             // z. B. 12 V - 3,2 V = 8,8 V
  Result.RCalc := Result.UR / Input.I;                   // z. B. 8,8 V / 20 mA = 440 Ω
  if not NextStdValue(Result.RCalc, Input.Series, Result.Std) then
  begin
    Result := Default(TCalcResult);
    Result.Status := csNoStdValue;
    Exit;
  end;

  // ----- 3. Strom und Leistungen mit dem Normwert -----
  Result.R := Result.Std.Value;                          // z. B. 470 Ω
  Result.IAct := Result.UR / Result.R;                   // z. B. 8,8 V / 470 Ω = 18,72 mA
  // jeder Strang hat seinen eigenen Widerstand mit den gleichen Werten
  Result.Strings := Max(1, Input.Strings);
  Result.ITotal := Result.Strings * Result.IAct;         // alle Stränge zusammen
  Result.PR := Result.UR * Result.IAct;                  // in EINEM Widerstand
  Result.PLed := Input.N * Input.Ud * Result.ITotal;     // in allen LEDs
  Result.PTotal := Input.U * Result.ITotal;              // aus der Quelle

  // ----- 4. Belastung und Erwärmung -----
  if Input.RatingW > 0 then
    Result.Load := Result.PR / Input.RatingW;
  Result.LoadLevel := LoadLevelOf(Result.Load);
  Result.RecommendedW := RecommendRating(Result.PR);
  Result.TempRise := EstimateTempRise(Result.PR, Input.RatingW);
end;

{------------------------------------------------------------------------------
  ParseDecimal - siehe Interface
------------------------------------------------------------------------------}
function ParseDecimal(const S: string; out Value: Double): Boolean;
var
  T: string;                                             // bereinigter Text
  FS: TFormatSettings;                                   // feste Einstellungen mit Punkt als Dezimalzeichen
begin
  Value := 0;
  T := Trim(S);                                          // Leerzeichen am Rand weg
  // Komma wie Punkt behandeln; zwei Dezimalzeichen sind ungültig ("1.000,5")
  T := StringReplace(T, ',', '.', [rfReplaceAll]);
  if (T = '') or (Pos('.', T) <> LastDelimiter('.', T)) then
    Exit(False);

  // fest mit Punkt umwandeln, unabhängig von der Ländereinstellung
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  FS.ThousandSeparator := #0;
  Result := TryStrToFloat(T, Value, FS) and not IsNan(Value) and not IsInfinite(Value);
  if not Result then
    Value := 0;
end;

end.
