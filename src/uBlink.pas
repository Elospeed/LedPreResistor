{ Rechenlogik für die Blinkschaltungen von LedPreResistor:
  NE555 astabil und astabiler Multivibrator mit zwei Transistoren (BC547).
  Gerechnet wird vorwärts (aus R und C die Zeiten) oder rückwärts (aus
  Frequenz und Tastgrad passende Normwerte für R). Dazu der Vorwiderstand
  der LED(s) mit Normwert. Wie uCalc: keine GUI, keine Texte, alles in
  SI-Einheiten (V, A, Ω, F, s, Hz). }
unit uBlink;

{$mode objfpc}{$H+}

interface

uses
  uESeries;

const
  { NE555 (bipolar): Spannungsabfall am Ausgang bei High gegenüber +Ub
    (Datenblatt: typisch 1,4–1,7 V bei 15–100 mA) und Restspannung bei Low }
  NE555_DROP_HIGH = 1.7;
  NE555_LOW = 0.1;
  { erlaubte Speisespannung des NE555 }
  NE555_U_MIN = 4.5;
  NE555_U_MAX = 16.0;
  { höchster Ausgangsstrom des NE555 }
  NE555_I_MAX = 0.2;
  { kleinster sinnvoller R1: schont den Entladetransistor (Pin 7) }
  NE555_R1_MIN = 1000.0;

  { BC547: Sättigungsspannung, Basis-Emitter-Spannung, Stromverstärkung
    (sichere Annahme) und höchste Sperrspannung der Basis }
  BJT_UCE_SAT = 0.2;
  BJT_UBE = 0.6;
  BJT_BETA = 100.0;
  BJT_UEB_MAX = 6.0;
  { Basisstrom soll mindestens so gross sein wie I_C / β (Übersteuerung 1) }
  BJT_OVERDRIVE_MIN = 1.0;

  { Über dieser Frequenz sieht das Auge kein Blinken mehr (Vorschau zeigt
    dann Dauerlicht mit passender Helligkeit) }
  BLINK_VISIBLE_MAX = 25.0;
  { Über diesem Wert verfälscht der Leckstrom eines Elkos die Zeiten }
  R_TIMING_MAX = 1e6;

type
  { die beiden Schaltungen }
  TBlinkCircuit = (bcNE555, bcMulti);

  { Anschluss der LED am NE555-Ausgang (Pin 3) }
  TLedConn = (
    cnGnd,   // LED nach Masse: leuchtet, wenn der Ausgang High ist
    cnVcc,   // LED nach +Ub: leuchtet, wenn der Ausgang Low ist
    cnBoth   // beide: Wechselblinker (LED 1 nach Masse, LED 2 nach +Ub)
  );

  { Eingaben, alle in SI-Einheiten }
  TBlinkInput = record
    Circuit: TBlinkCircuit;
    Reverse: Boolean;   // True = aus Frequenz und Tastgrad rechnen
    R1: Double;         // NE555: R1; Multivibrator: R_B1 (Basis T1), in Ω
    R2: Double;         // NE555: R2; Multivibrator: R_B2 (Basis T2), in Ω
    C: Double;          // Zeitkondensator in F (Multivibrator: C1 = C2 = C)
    F: Double;          // gewünschte Frequenz in Hz (nur rückwärts)
    Duty: Double;       // gewünschter Anteil «LED 1 an», 0..1 (nur rückwärts)
    Diode: Boolean;     // NE555: Diode über R2 (Tastgrad unter 50 % möglich)
    Conn: TLedConn;     // NE555: Anschluss der LED
    U: Double;          // Speisespannung in V
    Ud: Double;         // Durchlassspannung der LED in V
    I: Double;          // gewünschter LED-Strom in A
    Series: TESeries;   // Normreihe für alle Widerstände
  end;

  { Ergebnis der Prüfung der Eingaben }
  TBlinkStatus = (
    bsOk,
    bsInvalidU,        // Speisespannung fehlt oder <= 0
    bsInvalidUd,       // Durchlassspannung fehlt oder <= 0
    bsInvalidI,        // Strom fehlt oder <= 0
    bsInvalidR1,       // R1 bzw. R_B1 fehlt oder <= 0
    bsInvalidR2,       // R2 bzw. R_B2 fehlt oder <= 0
    bsInvalidC,        // Kondensator fehlt oder <= 0
    bsInvalidF,        // Frequenz fehlt oder <= 0
    bsInvalidDuty,     // Tastgrad nicht zwischen 0 und 100 %
    bsDutyNeedsDiode,  // NE555 ohne Diode: High-Anteil muss über 50 % sein
    bsUTooLow,         // es bleibt keine Spannung für den Vorwiderstand
    bsNoStdValue       // kein Normwert gefunden (sollte nicht vorkommen)
  );

  { Hinweise zu einem gültigen Resultat }
  TBlinkWarning = (
    bwSupply555,       // NE555 ausserhalb 4,5–16 V
    bwR1Small,         // NE555: R1 unter 1 kΩ
    bwOutCurrent,      // NE555: Ausgangsstrom über 200 mA
    bwBaseReverse,     // Multivibrator: Basis wird mit mehr als 6 V gesperrt
    bwNotSaturated,    // Multivibrator: Basisstrom reicht nicht sicher
    bwRHigh,           // Zeitwiderstand über 1 MΩ (Leckstrom des Elkos)
    bwTooFast          // schneller als das Auge: wirkt wie Dauerlicht
  );
  TBlinkWarnings = set of TBlinkWarning;

  { Vorwiderstand einer LED mit Normwert }
  TLedResistor = record
    Used: Boolean;      // diese LED gibt es in der Schaltung
    UR: Double;         // Spannung am Widerstand in V
    RCalc: Double;      // berechneter Widerstand in Ω
    Std: TStdValue;     // Normwert (nächsthöher)
    R: Double;          // Normwert in Ω
    IAct: Double;       // tatsächlicher Strom in A
    P: Double;          // Leistung im Widerstand in W (während die LED leuchtet)
  end;

  { Alle Resultate, in SI-Einheiten }
  TBlinkResult = record
    Status: TBlinkStatus;   // nur bei bsOk sind die Werte unten gültig
    Warnings: TBlinkWarnings;
    R1Calc, R2Calc: Double; // rückwärts: ideale Werte vor dem Runden
    R1, R2, C: Double;      // verwendete Bauteile (rückwärts: Normwerte)
    K: Double;              // Faktor der Zeitformel: t = K · R · C
    THigh, TLow: Double;    // NE555: Ausgang High / Low in s;
                            // Multivibrator: T1 leitet / T2 leitet in s
    T: Double;              // Periodendauer in s
    F: Double;              // Frequenz in Hz
    TOn1, TOff1: Double;    // LED 1 an / aus in s
    Duty1: Double;          // Anteil «LED 1 an», 0..1
    UOut: Double;           // NE555: Ausgangsspannung bei High in V
    DeltaU: Double;         // Multivibrator: Spannungssprung am Kollektor in V
    URev: Double;           // Multivibrator: Sperrspannung der Basis in V
    IB: Double;             // Multivibrator: Basisstrom in A
    Overdrive: Double;      // Multivibrator: I_B · β / I_C
    Led1, Led2: TLedResistor; // Vorwiderstände (LED 2 nur bei Wechselblinker)
  end;

{ Rechnet alles aus. Bei ungültigen Eingaben steht in Status der Grund. }
function CalculateBlink(const Input: TBlinkInput): TBlinkResult;

{ Liefert den Normwert der Reihe, der R am nächsten liegt (im Verhältnis,
  also 14,4 kΩ -> 15 kΩ). Für die Zeitwiderstände bei der Rückwärtsrechnung. }
function NearestStdValue(R: Double; Series: TESeries; out Std: TStdValue): Boolean;

{ Faktor K der Multivibrator-Formel t = K · R_B · C. Die Basis springt beim
  Umschalten um DeltaU nach unten und lädt sich über R_B Richtung +Ub auf,
  bis sie wieder 0,6 V erreicht: K = ln((Ub − 0,6 + ΔU) / (Ub − 0,6)).
  Ist ΔU = Ub − 0,6 (Lehrbuchfall), ist K = ln 2. }
function MultiFactor(U, DeltaU: Double): Double;

{ Vorwiderstand einer LED: an UR Volt soll der Strom I fliessen. }
function LedResistor(UR, I: Double; Series: TESeries; out LR: TLedResistor): Boolean;

implementation

uses
  Math;

function NearestStdValue(R: Double; Series: TESeries; out Std: TStdValue): Boolean;
var
  Decade, E, I, DigitCount: Integer;  // wie in NextStdValue
  V, Best, D: Double;                 // Kandidat, bester Abstand, Abstand
begin
  Result := False;
  Std := Default(TStdValue);
  if IsNan(R) or IsInfinite(R) or (R <= 0) then
    Exit;
  DigitCount := SeriesDigitCount(Series);
  Decade := Floor(Log10(R));
  Best := MaxDouble;
  for E := Decade - 1 to Decade + 1 do
    for I := 0 to SeriesCount(Series) - 1 do
    begin
      V := SeriesDigits(Series, I) * IntPower(10, E - DigitCount + 1);
      D := Abs(Ln(V / R));
      if D < Best - 1e-12 then
      begin
        Best := D;
        Std.Value := V;
        Std.Digits := SeriesDigits(Series, I);
        Std.DigitCount := DigitCount;
        Std.Exponent := E - DigitCount + 1;
        Result := True;
      end;
    end;
end;

function MultiFactor(U, DeltaU: Double): Double;
begin
  if (U - BJT_UBE <= 0) or (DeltaU <= 0) then
    Exit(Ln(2));
  Result := Ln((U - BJT_UBE + DeltaU) / (U - BJT_UBE));
end;

function LedResistor(UR, I: Double; Series: TESeries; out LR: TLedResistor): Boolean;
begin
  LR := Default(TLedResistor);
  Result := (UR > 0) and (I > 0);
  if not Result then Exit;
  LR.Used := True;
  LR.UR := UR;
  LR.RCalc := UR / I;
  Result := NextStdValue(LR.RCalc, Series, LR.Std);
  if not Result then Exit;
  LR.R := LR.Std.Value;
  LR.IAct := UR / LR.R;
  LR.P := UR * LR.IAct;
end;

{ Zeitwiderstand rückwärts: idealen Wert merken und auf den nächsten
  Normwert runden }
function RoundTiming(RCalc: Double; Series: TESeries; out R: Double): Boolean;
var
  Std: TStdValue;  // gefundener Normwert
begin
  Result := NearestStdValue(RCalc, Series, Std);
  if Result then R := Std.Value else R := 0;
end;

procedure Calc555(const Inp: TBlinkInput; var Res: TBlinkResult);
var
  K: Double;      // ln 2
  S: Double;      // R1 + 2·R2 (ohne Diode) bzw. R1 + R2 (mit Diode) aus T
  DHigh: Double;  // gewünschter High-Anteil des Ausgangs
begin
  K := Ln(2);
  Res.K := K;
  if Inp.Reverse then
  begin
    // «LED 1 an» ist bei LED nach +Ub die Low-Phase
    if Inp.Conn = cnVcc then DHigh := 1 - Inp.Duty else DHigh := Inp.Duty;
    if Inp.Diode then
    begin
      // t_High = K·R1·C, t_Low = K·R2·C
      S := 1 / (Inp.F * K * Inp.C);
      Res.R1Calc := DHigh * S;
      Res.R2Calc := (1 - DHigh) * S;
    end
    else
    begin
      // t_High = K·(R1+R2)·C, t_Low = K·R2·C: High-Anteil immer über 50 %
      if DHigh <= 0.5 then
      begin
        Res.Status := bsDutyNeedsDiode;
        Exit;
      end;
      S := 1 / (Inp.F * K * Inp.C);
      Res.R2Calc := (1 - DHigh) * S;
      Res.R1Calc := (2 * DHigh - 1) * S;
    end;
    if not (RoundTiming(Res.R1Calc, Inp.Series, Res.R1) and
            RoundTiming(Res.R2Calc, Inp.Series, Res.R2)) then
    begin
      Res.Status := bsNoStdValue;
      Exit;
    end;
  end
  else
  begin
    Res.R1 := Inp.R1;
    Res.R2 := Inp.R2;
  end;
  Res.C := Inp.C;

  if Inp.Diode then
    Res.THigh := K * Res.R1 * Res.C
  else
    Res.THigh := K * (Res.R1 + Res.R2) * Res.C;
  Res.TLow := K * Res.R2 * Res.C;
  if Inp.Conn = cnVcc then
  begin
    Res.TOn1 := Res.TLow;
    Res.TOff1 := Res.THigh;
  end
  else
  begin
    Res.TOn1 := Res.THigh;
    Res.TOff1 := Res.TLow;
  end;

  // Vorwiderstände
  Res.UOut := Inp.U - NE555_DROP_HIGH;
  if Inp.Conn in [cnGnd, cnBoth] then
    if not LedResistor(Res.UOut - Inp.Ud, Inp.I, Inp.Series, Res.Led1) then
    begin
      Res.Status := bsUTooLow;
      Exit;
    end;
  if Inp.Conn in [cnVcc, cnBoth] then
  begin
    if Inp.Conn = cnVcc then
    begin
      if not LedResistor(Inp.U - Inp.Ud - NE555_LOW, Inp.I, Inp.Series, Res.Led1) then
      begin
        Res.Status := bsUTooLow;
        Exit;
      end;
    end
    else if not LedResistor(Inp.U - Inp.Ud - NE555_LOW, Inp.I, Inp.Series, Res.Led2) then
    begin
      Res.Status := bsUTooLow;
      Exit;
    end;
  end;

  if (Inp.U < NE555_U_MIN) or (Inp.U > NE555_U_MAX) then
    Include(Res.Warnings, bwSupply555);
  if Res.R1 < NE555_R1_MIN then
    Include(Res.Warnings, bwR1Small);
  if Max(Res.Led1.IAct, Res.Led2.IAct) > NE555_I_MAX then
    Include(Res.Warnings, bwOutCurrent);
  if Max(Res.R1, Res.R2) > R_TIMING_MAX then
    Include(Res.Warnings, bwRHigh);
end;

procedure CalcMulti(const Inp: TBlinkInput; var Res: TBlinkResult);
var
  IC: Double;  // Kollektorstrom (LED-Strom mit Normwert)
begin
  // Vorwiderstände: LED und Widerstand liegen im Kollektor
  if not (LedResistor(Inp.U - Inp.Ud - BJT_UCE_SAT, Inp.I, Inp.Series, Res.Led1) and
          LedResistor(Inp.U - Inp.Ud - BJT_UCE_SAT, Inp.I, Inp.Series, Res.Led2)) then
  begin
    Res.Status := bsUTooLow;
    Exit;
  end;
  // Spannungssprung am Kollektor: von Ub − U_F (gesperrt) auf U_CE,sat
  Res.DeltaU := Inp.U - Inp.Ud - BJT_UCE_SAT;
  Res.K := MultiFactor(Inp.U, Res.DeltaU);
  Res.C := Inp.C;

  { LED 1 hängt am Kollektor von T1 und leuchtet, solange T1 leitet. T1
    leitet, solange T2 gesperrt ist; T2 wird über C1 gesperrt und lädt sich
    über R_B2 wieder auf: t(T1 leitet) = K · R_B2 · C. }
  if Inp.Reverse then
  begin
    Res.R2Calc := Inp.Duty / Inp.F / (Res.K * Res.C);
    Res.R1Calc := (1 - Inp.Duty) / Inp.F / (Res.K * Res.C);
    if not (RoundTiming(Res.R1Calc, Inp.Series, Res.R1) and
            RoundTiming(Res.R2Calc, Inp.Series, Res.R2)) then
    begin
      Res.Status := bsNoStdValue;
      Exit;
    end;
  end
  else
  begin
    Res.R1 := Inp.R1;
    Res.R2 := Inp.R2;
  end;
  Res.THigh := Res.K * Res.R2 * Res.C;  // T1 leitet, LED 1 an
  Res.TLow := Res.K * Res.R1 * Res.C;   // T2 leitet, LED 2 an
  Res.TOn1 := Res.THigh;
  Res.TOff1 := Res.TLow;

  // Sättigung: Basisstrom des leitenden Transistors über den kleineren Wert
  IC := Res.Led1.IAct;
  Res.IB := (Inp.U - BJT_UBE) / Max(Res.R1, Res.R2);
  if IC > 0 then
    Res.Overdrive := Res.IB * BJT_BETA / IC;
  Res.URev := Res.DeltaU - BJT_UBE;

  if Res.URev > BJT_UEB_MAX then
    Include(Res.Warnings, bwBaseReverse);
  if Res.Overdrive < BJT_OVERDRIVE_MIN then
    Include(Res.Warnings, bwNotSaturated);
  if Max(Res.R1, Res.R2) > R_TIMING_MAX then
    Include(Res.Warnings, bwRHigh);
end;

function CalculateBlink(const Input: TBlinkInput): TBlinkResult;
var
  St: TBlinkStatus;  // Grund eines Fehlers
begin
  Result := Default(TBlinkResult);

  // Eingaben prüfen; der erste Fehler gewinnt
  if not (Input.U > 0) then
    Result.Status := bsInvalidU
  else if not (Input.Ud > 0) then
    Result.Status := bsInvalidUd
  else if not (Input.I > 0) then
    Result.Status := bsInvalidI
  else if not Input.Reverse and not (Input.R1 > 0) then
    Result.Status := bsInvalidR1
  else if not Input.Reverse and not (Input.R2 > 0) then
    Result.Status := bsInvalidR2
  else if Input.Reverse and not (Input.F > 0) then
    Result.Status := bsInvalidF
  else if Input.Reverse and not ((Input.Duty > 0) and (Input.Duty < 1)) then
    Result.Status := bsInvalidDuty
  else if not (Input.C > 0) then
    Result.Status := bsInvalidC;
  if Result.Status <> bsOk then
    Exit;

  if Input.Circuit = bcNE555 then
    Calc555(Input, Result)
  else
    CalcMulti(Input, Result);

  if Result.Status = bsOk then
  begin
    Result.T := Result.THigh + Result.TLow;
    if Result.T > 0 then
    begin
      Result.F := 1 / Result.T;
      Result.Duty1 := Result.TOn1 / Result.T;
    end;
    if Result.F > BLINK_VISIBLE_MAX then
      Include(Result.Warnings, bwTooFast);
  end
  else
  begin
    // nur den Grund behalten, keine halben Resultate
    St := Result.Status;
    Result := Default(TBlinkResult);
    Result.Status := St;
  end;
end;

end.
