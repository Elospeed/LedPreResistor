{ Rechenlogik für die Konstantstromquellen (KSQ) von LedPreResistor:
  LM317 als Stromquelle und Konstantstromquelle mit zwei Transistoren
  (T2 = BC547 als Fühler, T1 je nach Strom BC547, BC337 oder BD139).
  Die Speisespannung darf als Bereich angegeben werden (von … bis, z. B.
  Auto 12–14,4 V): Verlust und Vergleich mit einem einfachen Vorwiderstand
  gelten dann für den ganzen Bereich. Wie uCalc: keine GUI, keine Texte,
  alles in SI-Einheiten (V, A, Ω, W). }
unit uKsq;

{$mode objfpc}{$H+}

interface

uses
  uESeries;

const
  { LM317: Referenzspannung zwischen OUT und ADJ }
  LM317_UREF = 1.25;
  { LM317: Spannungsabfall im Regler (Dropout); Datenblatt etwa 1,5 V bei
    kleinem bis 2,5 V bei 1,5 A, hier mit Reserve ca. 2 V }
  LM317_DROPOUT = 2.0;
  { LM317: kleinster Laststrom, mit dem er sicher regelt (Datenblatt
    typisch 3,5 mA, höchstens 10 mA); darunter gibt es einen Hinweis }
  LM317_I_MIN = 0.010;
  { LM317: höchste Spannung zwischen IN und OUT }
  LM317_UDIFF_MAX = 40.0;
  { LM317 und BD139: höchster Strom }
  KSQ_I_MAX = 1.5;

  { Zwei Transistoren: T2 leitet ab ca. 0,6 V an R_S (U_BE) }
  KSQ_UBE_SENSE = 0.6;
  { Zwei Transistoren: U_BE von T1 }
  KSQ_UBE_T1 = 0.7;
  { Zwei Transistoren: Spannung, die T1 mindestens braucht (nicht gesättigt) }
  KSQ_UCE_T1_MIN = 0.6;
  { Zwei Transistoren: Strom durch R_B mindestens (T2 braucht etwas zum Wegnehmen) }
  KSQ_IRB_MIN = 0.002;
  { Zwei Transistoren: R_B liefert mindestens so viel mal den Basisstrom von T1 }
  KSQ_IRB_FACTOR = 2.0;
  { höchste Spannung zwischen Kollektor und Emitter von T1 (BC547/BC337: 45 V) }
  KSQ_UCE_MAX = 45.0;
  { Temperaturspannung bei 25 °C (für die kleine Stromänderung durch U_BE von T2) }
  KSQ_UT = 0.026;
  { Temperaturgang von U_BE in V/K }
  KSQ_UBE_TC = -0.002;

  { Wärme: Umgebung bis 40 °C, Sperrschicht höchstens 110 °C -> 70 K Reserve }
  KSQ_DELTA_T = 70.0;
  { Wärmewiderstand Gehäuse -> Kühlkörper (Wärmeleitpaste, isoliert) in K/W }
  KSQ_RTH_CS = 1.0;

type
  { die beiden Schaltungen }
  TKsqCircuit = (kcLM317, kcTransistors);

  { empfohlenes Bauteil für den Regler bzw. T1 }
  TKsqPart = (
    kpLM317L,  // LM317L im TO-92, bis 100 mA und kleine Verluste
    kpLM317,   // LM317 im TO-220, bis 1,5 A
    kpBC547,   // BC547 (TO-92), bis 100 mA
    kpBC337,   // BC337 (TO-92), bis 500 mA
    kpBD139    // BD139 (TO-126), bis 1,5 A
  );

  { Eingaben, alle in SI-Einheiten }
  TKsqInput = record
    Circuit: TKsqCircuit;
    UMin: Double;       // Speisespannung von (V)
    UMax: Double;       // Speisespannung bis (V); 0 = gleich wie UMin
    Ud: Double;         // Durchlassspannung einer LED in V
    I: Double;          // gewünschter LED-Strom in A
    N: Integer;         // Anzahl LEDs in Reihe
    Series: TESeries;   // Normreihe für die Widerstände
  end;

  { Ergebnis der Prüfung der Eingaben }
  TKsqStatus = (
    ksOk,
    ksInvalidU,       // Speisespannung fehlt oder <= 0
    ksInvalidUd,      // Durchlassspannung fehlt oder <= 0
    ksInvalidI,       // Strom fehlt oder <= 0
    ksInvalidN,       // Anzahl LEDs < 1
    ksTooMuchCurrent, // mehr als 1,5 A
    ksUTooLow,        // Speisespannung (von) unter der Mindestspannung
    ksNoStdValue      // kein Normwert gefunden (sollte nicht vorkommen)
  );

  { Hinweise zu einem gültigen Resultat }
  TKsqWarning = (
    kwHeatsink,      // Regler bzw. T1 braucht einen Kühlkörper
    kwTooHot,        // selbst mit grossem Kühlkörper zu viel Verlust
    kwMinLoad,       // LM317: Strom unter ca. 10 mA, regelt nicht sicher
    kwOverVoltage,   // mehr als 40 V am LM317 bzw. 45 V an T1
    kwBaseHigh,      // zwei Transistoren: grosser Basisstrom, R_B wird warm
    kwRPower         // Fühlerwiderstand braucht mehr als 1 W
  );
  TKsqWarnings = set of TKsqWarning;

  { Alle Resultate, in SI-Einheiten }
  TKsqResult = record
    Status: TKsqStatus;    // nur bei ksOk sind die Werte unten gültig
    Warnings: TKsqWarnings;
    UMin, UMax: Double;    // Speisespannung (geordnet, UMax >= UMin)
    ULeds: Double;         // Spannung an allen LEDs zusammen
    URef: Double;          // Spannung am Fühlerwiderstand (1,25 V bzw. 0,6 V)
    RCalc: Double;         // berechneter Fühlerwiderstand in Ω
    Std: TStdValue;        // Normwert (nächsthöher: Strom eher etwas kleiner)
    R: Double;             // Normwert in Ω
    IAct: Double;          // tatsächlicher Strom in A
    PR: Double;            // Leistung im Fühlerwiderstand in W
    RRating: Double;       // Bauform des Fühlerwiderstands in W (0 = über 1 W)
    Headroom: Double;      // Spannung, die Regler bzw. T1 mindestens braucht
    UNeed: Double;         // Mindestspannung = ULeds + URef + Headroom
    Reserve: Double;       // UMin − UNeed
    PLossMin: Double;      // Verlust im Regler bzw. T1 bei UMin
    PLossMax: Double;      // Verlust im Regler bzw. T1 bei UMax
    Part: TKsqPart;        // empfohlenes Bauteil
    HeatsinkRth: Double;   // nötiger Kühlkörper in K/W (0 = keiner nötig)
    { Vergleich mit einem einfachen Vorwiderstand, ausgelegt bei UMin }
    RvCalc: Double;        // Vorwiderstand für I bei UMin in Ω
    RvRise: Double;        // Stromanstieg von UMin bis UMax (0.43 = +43 %)
    KsqRise: Double;       // Stromänderung der KSQ von UMin bis UMax
    { nur zwei Transistoren }
    Beta1: Double;         // Stromverstärkung von T1 (sichere Annahme)
    IB1: Double;           // Basisstrom von T1 in A
    IRB: Double;           // gewünschter Strom durch R_B bei UMin in A
    RBCalc: Double;        // berechneter R_B in Ω
    RBStd: TStdValue;      // Normwert R_B (nächstkleiner: eher mehr Strom)
    RB: Double;            // Normwert R_B in Ω
    IRBMax: Double;        // Strom durch R_B bei UMax in A
    PRB: Double;           // Leistung in R_B bei UMax in W
    RBRating: Double;      // Bauform von R_B in W
  end;

{ Rechnet alles aus. Bei ungültigen Eingaben steht in Status der Grund. }
function CalculateKsq(const Input: TKsqInput): TKsqResult;

{ Stromverstärkung (sichere Annahme) eines Transistors }
function PartBeta(P: TKsqPart): Double;

implementation

uses
  Math, uCalc;

const
  { Belastbarkeit ohne Kühlkörper in W (bei ca. 70 K Erwärmung) und
    Wärmewiderstand Sperrschicht -> Gehäuse in K/W }
  PART_P_FREE: array[TKsqPart] of Double = (0.35, 1.0, 0.25, 0.3, 0.7);
  PART_RTH_JC: array[TKsqPart] of Double = (0, 5.0, 0, 0, 10.0);
  PART_I_MAX: array[TKsqPart] of Double = (0.1, 1.5, 0.1, 0.5, 1.5);

function PartBeta(P: TKsqPart): Double;
begin
  case P of
    kpBC547, kpBC337: Result := 100;
    kpBD139: Result := 40;
  else
    Result := 0;
  end;
end;

{ empfohlenes Bauteil nach Strom und grösstem Verlust }
function ChoosePart(Circuit: TKsqCircuit; I, P: Double): TKsqPart;
begin
  if Circuit = kcLM317 then
  begin
    if (I <= PART_I_MAX[kpLM317L]) and (P <= PART_P_FREE[kpLM317L]) then
      Result := kpLM317L
    else
      Result := kpLM317;
  end
  else if (I <= PART_I_MAX[kpBC547]) and (P <= PART_P_FREE[kpBC547]) then
    Result := kpBC547
  else if (I <= PART_I_MAX[kpBC337]) and (P <= PART_P_FREE[kpBC337]) then
    Result := kpBC337
  else
    Result := kpBD139;
end;

function CalculateKsq(const Input: TKsqInput): TKsqResult;
var
  U1, U2: Double;   // Speisespannung geordnet
  UBase: Double;    // Spannung an der Basis von T1 gegen Masse
begin
  Result := Default(TKsqResult);
  U1 := Input.UMin;
  U2 := Input.UMax;
  if not (U2 > 0) then U2 := U1;
  if U2 < U1 then
  begin
    U1 := Input.UMax;
    U2 := Input.UMin;
  end;

  // Eingaben prüfen; der erste Fehler gewinnt
  if not (U1 > 0) then
    Result.Status := ksInvalidU
  else if not (Input.Ud > 0) then
    Result.Status := ksInvalidUd
  else if not (Input.I > 0) then
    Result.Status := ksInvalidI
  else if Input.N < 1 then
    Result.Status := ksInvalidN
  else if Input.I > KSQ_I_MAX * (1 + 1e-9) then
    Result.Status := ksTooMuchCurrent;
  Result.UMin := U1;
  Result.UMax := U2;
  if Result.Status <> ksOk then
    Exit;

  Result.ULeds := Input.N * Input.Ud;
  if Input.Circuit = kcLM317 then
  begin
    Result.URef := LM317_UREF;
    Result.Headroom := LM317_DROPOUT;
  end
  else
  begin
    Result.URef := KSQ_UBE_SENSE;
    Result.Headroom := KSQ_UCE_T1_MIN;
  end;
  Result.UNeed := Result.ULeds + Result.URef + Result.Headroom;
  Result.Reserve := U1 - Result.UNeed;
  if Result.Reserve < -1e-9 then
  begin
    Result.Status := ksUTooLow;
    Exit;
  end;

  // Fühlerwiderstand: nächster Normwert darüber, der Strom wird eher etwas kleiner
  Result.RCalc := Result.URef / Input.I;
  if not NextStdValue(Result.RCalc, Input.Series, Result.Std) then
  begin
    Result.Status := ksNoStdValue;
    Exit;
  end;
  Result.R := Result.Std.Value;
  Result.IAct := Result.URef / Result.R;
  Result.PR := Result.URef * Result.IAct;
  Result.RRating := RecommendRating(Result.PR);
  if Result.RRating = 0 then
    Include(Result.Warnings, kwRPower);

  // Verlust im Regler bzw. T1: der Rest der Spannung mal Strom
  Result.PLossMin := (U1 - Result.ULeds - Result.URef) * Result.IAct;
  Result.PLossMax := (U2 - Result.ULeds - Result.URef) * Result.IAct;
  Result.Part := ChoosePart(Input.Circuit, Result.IAct, Result.PLossMax);
  if Result.PLossMax > PART_P_FREE[Result.Part] then
  begin
    Include(Result.Warnings, kwHeatsink);
    // Kühlkörper so wählen, dass die Sperrschicht höchstens 70 K wärmer wird
    Result.HeatsinkRth := KSQ_DELTA_T / Result.PLossMax - PART_RTH_JC[Result.Part] - KSQ_RTH_CS;
    if Result.HeatsinkRth < 1.0 then
    begin
      Include(Result.Warnings, kwTooHot);
      Result.HeatsinkRth := 0;
    end;
  end;

  if Input.Circuit = kcLM317 then
  begin
    if Result.IAct < LM317_I_MIN then
      Include(Result.Warnings, kwMinLoad);
    if U2 - Result.ULeds - Result.URef > LM317_UDIFF_MAX then
      Include(Result.Warnings, kwOverVoltage);
    // Netz- und Lastregelung des LM317 sind so gut, dass der Strom praktisch gleich bleibt
    Result.KsqRise := 0;
  end
  else
  begin
    if U2 - Result.ULeds - Result.URef > KSQ_UCE_MAX then
      Include(Result.Warnings, kwOverVoltage);
    // Basiswiderstand: liefert den Basisstrom von T1 mit Reserve, mindestens 2 mA
    Result.Beta1 := PartBeta(Result.Part);
    Result.IB1 := Result.IAct / Result.Beta1;
    Result.IRB := Max(KSQ_IRB_MIN, KSQ_IRB_FACTOR * Result.IB1);
    UBase := KSQ_UBE_SENSE + KSQ_UBE_T1;
    if U1 - UBase < 0.1 then
    begin
      // nur bei unsinnig kleiner Durchlassspannung: R_B hätte keine Spannung
      Result.Status := ksUTooLow;
      Exit;
    end;
    Result.RBCalc := (U1 - UBase) / Result.IRB;
    // nächster Normwert darunter: lieber etwas mehr Basisstrom
    if not PrevStdValue(Result.RBCalc, Input.Series, Result.RBStd) then
    begin
      Result.Status := ksNoStdValue;
      Exit;
    end;
    Result.RB := Result.RBStd.Value;
    Result.IRBMax := (U2 - UBase) / Result.RB;
    Result.PRB := Sqr(U2 - UBase) / Result.RB;
    Result.RBRating := RecommendRating(Result.PRB);
    if (Result.RBRating = 0) or (Result.RBRating > 0.25) or (Result.IRBMax > 0.1) then
      Include(Result.Warnings, kwBaseHigh);
    { Der Strom durch T2 wächst mit der Spannung (I_RB), dadurch steigt U_BE
      von T2 um U_T · ln(I_RB,max / I_RB,min) und mit ihm der LED-Strom }
    Result.KsqRise := KSQ_UT * Ln((U2 - UBase) / (U1 - UBase)) / KSQ_UBE_SENSE;
  end;

  // Vergleich: einfacher Vorwiderstand für den gleichen Strom bei UMin
  if U1 > Result.ULeds then
  begin
    Result.RvCalc := (U1 - Result.ULeds) / Input.I;
    Result.RvRise := (U2 - Result.ULeds) / (U1 - Result.ULeds) - 1;
  end;
end;

end.
