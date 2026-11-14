{==============================================================================
  uKsq - Rechenlogik der Konstantstromquellen (KSQ)
==============================================================================
  Zweck:     Rechnet die beiden Konstantstromquellen des Reiters
             «Konstantstrom» aus:
               1. LM317 als Stromquelle (Regler + ein Fühlerwiderstand R)
               2. zwei Transistoren (T2 = BC547 als Fühler, T1 je nach
                  Strom BC547, BC337 oder BD139, dazu R_S und R_B)

  Idee:      Eine Konstantstromquelle hält den LED-Strom fest, auch wenn
             die Speisespannung schwankt (z. B. im Auto 12 ... 14,4 V).
             Ein einfacher Vorwiderstand kann das nicht: Dort steigt der
             Strom mit der Spannung. Darum darf die Speisespannung als
             Bereich «von ... bis» angegeben werden; Verlust und der
             Vergleich mit einem Vorwiderstand gelten für den ganzen Bereich.

  Benutzung: Eingaben in TKsqInput füllen, CalculateKsq aufrufen und das
             Ergebnis aus TKsqResult lesen. Nur wenn Status = ksOk ist,
             sind die Werte gültig; Warnings enthält zusätzliche Hinweise
             (Kühlkörper, Überspannung ...).

  Regeln:    Wie uCalc: keine Oberfläche, keine Texte, alle Werte in
             SI-Einheiten (V, A, Ω, W). Texte und Formatierung macht uMain.

  Formeln:   LM317:            R   = 1,25 V / I
             zwei Transistoren: R_S = 0,6 V / I
                                R_B = (U_B,min - 1,3 V) / I_RB
             Verlust im Regler bzw. T1:
                                P   = (U_B - U_LEDs - U_R) * I
             Beispiel LM317, 12 V, 1 weisse LED (3,2 V), 20 mA:
                                R = 1,25 V / 0,020 A = 62,5 Ω -> 68 Ω (E12)
                                I = 1,25 V / 68 Ω = 18,4 mA
                                P = (12 - 3,2 - 1,25) V * 18,4 mA = 139 mW

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  neu: Konstantstrom mit LM317 und zwei Transistoren
==============================================================================}
unit uKsq;

{$mode objfpc}{$H+}

interface

uses
  uESeries;                                              // Normreihen E6 ... E96, NextStdValue

{==============================================================================
  KONSTANTEN
------------------------------------------------------------------------------
  Werte aus den Datenblättern (LM317, BC547, BC337, BD139), meist mit etwas
  Reserve, damit die Schaltung auch mit Bauteilstreuung sicher funktioniert.
==============================================================================}
const
  // ----- LM317 -----

  // Referenzspannung zwischen OUT und ADJ: Der LM317 regelt so, dass am
  // Fühlerwiderstand immer genau diese Spannung liegt.
  LM317_UREF = 1.25;                                     // V

  // Spannung, die der Regler selbst mindestens braucht (Dropout). Datenblatt:
  // etwa 1,5 V bei kleinem Strom bis 2,5 V bei 1,5 A; hier mit Reserve 2 V.
  LM317_DROPOUT = 2.0;                                   // V

  // Kleinster Strom, mit dem der LM317 sicher regelt. Datenblatt: typisch
  // 3,5 mA, höchstens 10 mA. Darunter gibt es den Hinweis kwMinLoad.
  LM317_I_MIN = 0.010;                                   // A

  // Höchste Spannung zwischen IN und OUT (sonst Hinweis kwOverVoltage).
  LM317_UDIFF_MAX = 40.0;                                // V

  // Höchster Strom für beide Schaltungen (LM317 im TO-220 und BD139).
  KSQ_I_MAX = 1.5;                                       // A

  // ----- ZWEI TRANSISTOREN -----

  // T2 beginnt zu leiten, sobald an R_S etwa 0,6 V liegen (U_BE von T2).
  // Damit bestimmt R_S den Strom: I = 0,6 V / R_S.
  KSQ_UBE_SENSE = 0.6;                                   // V

  // Basis-Emitter-Spannung von T1 (sitzt auf R_S, Basis also bei 1,3 V).
  KSQ_UBE_T1 = 0.7;                                      // V

  // Spannung, die T1 zwischen Kollektor und Emitter mindestens braucht,
  // damit er noch regelt und nicht ganz durchschaltet (Sättigung).
  KSQ_UCE_T1_MIN = 0.6;                                  // V

  // R_B liefert mindestens diesen Strom, damit T2 genug «wegnehmen» kann.
  KSQ_IRB_MIN = 0.002;                                   // A

  // R_B liefert mindestens so viel mal den Basisstrom, den T1 braucht.
  KSQ_IRB_FACTOR = 2.0;                                  // Faktor

  // Höchste Spannung zwischen Kollektor und Emitter von T1 (BC547/BC337).
  KSQ_UCE_MAX = 45.0;                                    // V

  // Temperaturspannung bei 25 °C. Braucht man für die kleine Stromänderung,
  // weil U_BE von T2 mit dem Strom durch R_B leicht steigt.
  KSQ_UT = 0.026;                                        // V

  // Temperaturgang von U_BE: pro Grad wärmer etwa 2 mV weniger.
  KSQ_UBE_TC = -0.002;                                   // V/K

  // ----- WÄRME -----

  // Umgebung bis 40 °C, Sperrschicht höchstens 110 °C -> 70 K Reserve.
  KSQ_DELTA_T = 70.0;                                    // K

  // Wärmewiderstand Gehäuse -> Kühlkörper (mit Wärmeleitpaste, isoliert).
  KSQ_RTH_CS = 1.0;                                      // K/W

{==============================================================================
  TYPEN
==============================================================================}
type
  // ----- Auswahl der Schaltung -----
  TKsqCircuit = (
    kcLM317,                                             // LM317 als Stromquelle
    kcTransistors                                        // zwei Transistoren
  );

  // ----- Empfohlenes Bauteil für den Regler bzw. T1 -----
  TKsqPart = (
    kpLM317L,                                            // LM317L im TO-92, bis 100 mA, kleine Verluste
    kpLM317,                                             // LM317 im TO-220, bis 1,5 A
    kpBC547,                                             // BC547 (TO-92), bis 100 mA
    kpBC337,                                             // BC337 (TO-92), bis 500 mA
    kpBD139                                              // BD139 (TO-126), bis 1,5 A
  );

  // ----- Eingaben (alle in SI-Einheiten) -----
  TKsqInput = record
    Circuit: TKsqCircuit;                                // welche Schaltung
    UMin: Double;                                        // Speisespannung von (V)
    UMax: Double;                                        // Speisespannung bis (V); 0 = gleich wie UMin
    Ud: Double;                                          // Durchlassspannung einer LED (V)
    I: Double;                                           // gewünschter LED-Strom (A)
    N: Integer;                                          // Anzahl LEDs in Reihe
    Series: TESeries;                                    // Normreihe für die Widerstände
  end;

  // ----- Ergebnis der Prüfung der Eingaben -----
  TKsqStatus = (
    ksOk,                                                // alles gültig, Werte gerechnet
    ksInvalidU,                                          // Speisespannung fehlt oder <= 0
    ksInvalidUd,                                         // Durchlassspannung fehlt oder <= 0
    ksInvalidI,                                          // Strom fehlt oder <= 0
    ksInvalidN,                                          // Anzahl LEDs < 1
    ksTooMuchCurrent,                                    // mehr als 1,5 A
    ksUTooLow,                                           // Speisespannung (von) unter der Mindestspannung
    ksNoStdValue                                         // kein Normwert gefunden (sollte nicht vorkommen)
  );

  // ----- Hinweise zu einem gültigen Resultat -----
  TKsqWarning = (
    kwHeatsink,                                          // Regler bzw. T1 braucht einen Kühlkörper
    kwTooHot,                                            // selbst mit grossem Kühlkörper zu viel Verlust
    kwMinLoad,                                           // LM317: unter ca. 10 mA, regelt nicht sicher
    kwOverVoltage,                                       // mehr als 40 V am LM317 bzw. 45 V an T1
    kwBaseHigh,                                          // zwei Transistoren: R_B wird warm
    kwRPower                                             // Fühlerwiderstand braucht mehr als 1 W
  );
  TKsqWarnings = set of TKsqWarning;                     // mehrere Hinweise gleichzeitig möglich

  // ----- Alle Resultate (SI-Einheiten) -----
  TKsqResult = record
    Status: TKsqStatus;                                  // nur bei ksOk sind die Werte gültig
    Warnings: TKsqWarnings;                              // Hinweise, siehe TKsqWarning
    UMin, UMax: Double;                                  // Speisespannung geordnet (UMax >= UMin)
    ULeds: Double;                                       // Spannung an allen LEDs zusammen (V)
    URef: Double;                                        // Spannung am Fühlerwiderstand (1,25 / 0,6 V)
    RCalc: Double;                                       // berechneter Fühlerwiderstand (Ω)
    Std: TStdValue;                                      // Normwert (nächsthöher: Strom eher kleiner)
    R: Double;                                           // Normwert (Ω)
    IAct: Double;                                        // tatsächlicher Strom mit dem Normwert (A)
    PR: Double;                                          // Leistung im Fühlerwiderstand (W)
    RRating: Double;                                     // Bauform des Fühlerwiderstands (W, 0 = über 1 W)
    Headroom: Double;                                    // Spannung, die Regler bzw. T1 mindestens braucht
    UNeed: Double;                                       // Mindestspannung = ULeds + URef + Headroom
    Reserve: Double;                                     // UMin - UNeed (V)
    PLossMin: Double;                                    // Verlust im Regler bzw. T1 bei UMin (W)
    PLossMax: Double;                                    // Verlust im Regler bzw. T1 bei UMax (W)
    Part: TKsqPart;                                      // empfohlenes Bauteil
    HeatsinkRth: Double;                                 // nötiger Kühlkörper (K/W, 0 = keiner nötig)

    // Vergleich mit einem einfachen Vorwiderstand, ausgelegt bei UMin
    RvCalc: Double;                                      // Vorwiderstand für I bei UMin (Ω)
    RvRise: Double;                                      // Stromanstieg UMin -> UMax (0.43 = +43 %)
    KsqRise: Double;                                     // Stromänderung der KSQ UMin -> UMax

    // nur bei zwei Transistoren
    Beta1: Double;                                       // Stromverstärkung von T1 (sichere Annahme)
    IB1: Double;                                         // Basisstrom von T1 (A)
    IRB: Double;                                         // gewünschter Strom durch R_B bei UMin (A)
    RBCalc: Double;                                      // berechneter R_B (Ω)
    RBStd: TStdValue;                                    // Normwert R_B (nächstkleiner: eher mehr Strom)
    RB: Double;                                          // Normwert R_B (Ω)
    IRBMax: Double;                                      // Strom durch R_B bei UMax (A)
    PRB: Double;                                         // Leistung in R_B bei UMax (W)
    RBRating: Double;                                    // Bauform von R_B (W)
  end;

{==============================================================================
  ÖFFENTLICHE FUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  CalculateKsq - rechnet die ganze Konstantstromquelle aus
------------------------------------------------------------------------------
  Parameter: Input  - Schaltung, Speisespannung von/bis, LED-Daten, Strom,
                      Normreihe (siehe TKsqInput)
  Rückgabe:  alle Resultate; bei ungültigen Eingaben steht in Status der
             Grund und die übrigen Werte sind nicht gesetzt.
------------------------------------------------------------------------------}
function CalculateKsq(const Input: TKsqInput): TKsqResult;

{------------------------------------------------------------------------------
  PartBeta - Stromverstärkung eines Transistors (sichere Annahme)
------------------------------------------------------------------------------
  Parameter: P - Bauteil
  Rückgabe:  β (Kollektorstrom / Basisstrom); bewusst eher klein angesetzt,
             damit R_B auch mit einem schwachen Exemplar genug Strom liefert.
             Für die LM317-Typen 0 (haben keine Basis).
------------------------------------------------------------------------------}
function PartBeta(P: TKsqPart): Double;

implementation

uses
  Math,                                                  // Max, Ln, Sqr
  uCalc;                                                 // RecommendRating (Bauform eines Widerstands)

{==============================================================================
  BAUTEIL-DATEN
------------------------------------------------------------------------------
  Pro Bauteil (Reihenfolge wie TKsqPart: LM317L, LM317, BC547, BC337, BD139):
    PART_P_FREE - Verlust ohne Kühlkörper bei ca. 70 K Erwärmung (W)
    PART_RTH_JC - Wärmewiderstand Sperrschicht -> Gehäuse (K/W);
                  0 = kein Kühlkörper möglich (TO-92)
    PART_I_MAX  - höchster Dauerstrom (A)
==============================================================================}
const
  PART_P_FREE: array[TKsqPart] of Double = (0.35, 1.0, 0.25, 0.3, 0.7);
  PART_RTH_JC: array[TKsqPart] of Double = (0, 5.0, 0, 0, 10.0);
  PART_I_MAX: array[TKsqPart] of Double = (0.1, 1.5, 0.1, 0.5, 1.5);

{------------------------------------------------------------------------------
  PartBeta - siehe Interface
------------------------------------------------------------------------------}
function PartBeta(P: TKsqPart): Double;
begin
  case P of
    kpBC547, kpBC337: Result := 100;                     // Datenblatt-Minimum ca. 110 bzw. 100
    kpBD139: Result := 40;                               // Datenblatt-Minimum 40 (bei 150 mA)
  else
    Result := 0;                                         // LM317/LM317L: keine Basis
  end;
end;

{------------------------------------------------------------------------------
  ChoosePart - wählt das kleinste Bauteil, das Strom und Verlust schafft
------------------------------------------------------------------------------
  Parameter: Circuit - Schaltung (LM317 oder zwei Transistoren)
             I       - LED-Strom (A)
             P       - grösster Verlust im Regler bzw. T1 (W)
  Rückgabe:  empfohlenes Bauteil. Gesucht wird vom kleinsten Gehäuse an
             aufwärts; das grösste (LM317 bzw. BD139) bleibt als Rest übrig,
             auch wenn es dann einen Kühlkörper braucht.
------------------------------------------------------------------------------}
function ChoosePart(Circuit: TKsqCircuit; I, P: Double): TKsqPart;
begin
  if Circuit = kcLM317 then
  begin
    if (I <= PART_I_MAX[kpLM317L]) and (P <= PART_P_FREE[kpLM317L]) then
      Result := kpLM317L                                 // klein genug für TO-92
    else
      Result := kpLM317;                                 // sonst TO-220
  end
  else if (I <= PART_I_MAX[kpBC547]) and (P <= PART_P_FREE[kpBC547]) then
    Result := kpBC547                                    // bis 100 mA, wenig Verlust
  else if (I <= PART_I_MAX[kpBC337]) and (P <= PART_P_FREE[kpBC337]) then
    Result := kpBC337                                    // bis 500 mA
  else
    Result := kpBD139;                                   // bis 1,5 A, evtl. mit Kühlkörper
end;

{------------------------------------------------------------------------------
  CalculateKsq - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Speisespannung ordnen (von <= bis) und Eingaben prüfen
    2. Mindestspannung: LEDs + Fühler + was Regler/T1 selbst braucht
    3. Fühlerwiderstand: nächster Normwert darüber, Strom und Leistung
    4. Verlust im Regler bzw. T1, Bauteil wählen, Kühlkörper rechnen
    5. Besonderheiten der Schaltung (LM317: Mindeststrom, Überspannung;
       zwei Transistoren: Basiswiderstand R_B, kleine Stromänderung)
    6. Vergleich mit einem einfachen Vorwiderstand
------------------------------------------------------------------------------}
function CalculateKsq(const Input: TKsqInput): TKsqResult;
var
  U1, U2: Double;                                        // Speisespannung geordnet: U1 = von, U2 = bis (V)
  UBase: Double;                                         // Spannung an der Basis von T1 gegen Masse (V)
begin
  Result := Default(TKsqResult);                         // alle Werte auf 0, Status = ksOk

  // ----- 1. Speisespannung ordnen und Eingaben prüfen -----
  U1 := Input.UMin;
  U2 := Input.UMax;
  if not (U2 > 0) then U2 := U1;                         // «bis» leer: feste Spannung
  if U2 < U1 then                                        // vertauscht eingegeben: tauschen
  begin
    U1 := Input.UMax;
    U2 := Input.UMin;
  end;

  // Der erste Fehler gewinnt; «not (x > 0)» fängt auch NaN (leeres Feld) ab
  if not (U1 > 0) then
    Result.Status := ksInvalidU
  else if not (Input.Ud > 0) then
    Result.Status := ksInvalidUd
  else if not (Input.I > 0) then
    Result.Status := ksInvalidI
  else if Input.N < 1 then
    Result.Status := ksInvalidN
  else if Input.I > KSQ_I_MAX * (1 + 1e-9) then          // kleine Toleranz für Rundung (1,5 A erlaubt)
    Result.Status := ksTooMuchCurrent;
  Result.UMin := U1;
  Result.UMax := U2;
  if Result.Status <> ksOk then
    Exit;

  // ----- 2. Mindestspannung -----
  Result.ULeds := Input.N * Input.Ud;                    // alle LEDs in Reihe
  if Input.Circuit = kcLM317 then
  begin
    Result.URef := LM317_UREF;                           // 1,25 V am Fühlerwiderstand
    Result.Headroom := LM317_DROPOUT;                    // ca. 2 V im Regler
  end
  else
  begin
    Result.URef := KSQ_UBE_SENSE;                        // 0,6 V an R_S
    Result.Headroom := KSQ_UCE_T1_MIN;                   // ca. 0,6 V an T1
  end;
  Result.UNeed := Result.ULeds + Result.URef + Result.Headroom;
  Result.Reserve := U1 - Result.UNeed;                   // Beispiel: 12 V - 6,45 V = 5,55 V
  if Result.Reserve < -1e-9 then                         // Spannung reicht nicht (Toleranz für Rundung)
  begin
    Result.Status := ksUTooLow;
    Exit;
  end;

  // ----- 3. Fühlerwiderstand -----
  // Nächster Normwert DARÜBER: Der Strom wird dadurch eher etwas kleiner,
  // das schont die LED.
  Result.RCalc := Result.URef / Input.I;                 // z. B. 1,25 V / 20 mA = 62,5 Ω
  if not NextStdValue(Result.RCalc, Input.Series, Result.Std) then
  begin
    Result.Status := ksNoStdValue;
    Exit;
  end;
  Result.R := Result.Std.Value;                          // z. B. 68 Ω (E12)
  Result.IAct := Result.URef / Result.R;                 // z. B. 1,25 V / 68 Ω = 18,4 mA
  Result.PR := Result.URef * Result.IAct;                // Leistung im Fühler: U * I
  Result.RRating := RecommendRating(Result.PR);          // ¼ W, ½ W, 1 W oder 0 = mehr
  if Result.RRating = 0 then
    Include(Result.Warnings, kwRPower);

  // ----- 4. Verlust im Regler bzw. T1 -----
  // Was die LEDs und der Fühler nicht brauchen, verheizt der Regler bzw. T1.
  Result.PLossMin := (U1 - Result.ULeds - Result.URef) * Result.IAct;
  Result.PLossMax := (U2 - Result.ULeds - Result.URef) * Result.IAct;
  Result.Part := ChoosePart(Input.Circuit, Result.IAct, Result.PLossMax);
  if Result.PLossMax > PART_P_FREE[Result.Part] then
  begin
    Include(Result.Warnings, kwHeatsink);
    // Kühlkörper so wählen, dass die Sperrschicht höchstens 70 K wärmer wird:
    // R_th,gesamt = 70 K / P; davon gehen R_th,JC (Bauteil) und R_th,CS
    // (Paste/Isolierung) ab, der Rest darf der Kühlkörper sein.
    Result.HeatsinkRth := KSQ_DELTA_T / Result.PLossMax - PART_RTH_JC[Result.Part] - KSQ_RTH_CS;
    if Result.HeatsinkRth < 1.0 then                     // unter 1 K/W: unpraktisch grosser Kühlkörper
    begin
      Include(Result.Warnings, kwTooHot);
      Result.HeatsinkRth := 0;
    end;
  end;

  // ----- 5. Besonderheiten der Schaltung -----
  if Input.Circuit = kcLM317 then
  begin
    if Result.IAct < LM317_I_MIN then
      Include(Result.Warnings, kwMinLoad);               // unter 10 mA regelt der LM317 unsicher
    if U2 - Result.ULeds - Result.URef > LM317_UDIFF_MAX then
      Include(Result.Warnings, kwOverVoltage);           // mehr als 40 V zwischen IN und OUT
    // Netz- und Lastregelung des LM317 sind so gut, dass der Strom
    // praktisch gleich bleibt.
    Result.KsqRise := 0;
  end
  else
  begin
    if U2 - Result.ULeds - Result.URef > KSQ_UCE_MAX then
      Include(Result.Warnings, kwOverVoltage);           // mehr als 45 V an T1

    // Basiswiderstand R_B: liefert den Basisstrom von T1 mit Reserve
    // (Faktor 2), mindestens aber 2 mA, damit T2 sauber regeln kann.
    Result.Beta1 := PartBeta(Result.Part);
    Result.IB1 := Result.IAct / Result.Beta1;            // z. B. 20 mA / 100 = 0,2 mA
    Result.IRB := Max(KSQ_IRB_MIN, KSQ_IRB_FACTOR * Result.IB1);
    UBase := KSQ_UBE_SENSE + KSQ_UBE_T1;                 // Basis T1 = 0,6 V + 0,7 V = 1,3 V
    if U1 - UBase < 0.1 then
    begin
      // nur bei unsinnig kleiner Durchlassspannung: R_B hätte keine Spannung
      Result.Status := ksUTooLow;
      Exit;
    end;
    Result.RBCalc := (U1 - UBase) / Result.IRB;          // z. B. (12 - 1,3) V / 2 mA = 5,35 kΩ
    // Nächster Normwert DARUNTER: lieber etwas mehr Basisstrom als zu wenig.
    if not PrevStdValue(Result.RBCalc, Input.Series, Result.RBStd) then
    begin
      Result.Status := ksNoStdValue;
      Exit;
    end;
    Result.RB := Result.RBStd.Value;                     // z. B. 4,7 kΩ
    Result.IRBMax := (U2 - UBase) / Result.RB;           // Strom durch R_B bei der höchsten Spannung
    Result.PRB := Sqr(U2 - UBase) / Result.RB;           // Leistung in R_B: U² / R
    Result.RBRating := RecommendRating(Result.PRB);
    if (Result.RBRating = 0) or (Result.RBRating > 0.25) or (Result.IRBMax > 0.1) then
      Include(Result.Warnings, kwBaseHigh);              // R_B wird warm oder T2 muss viel schlucken

    // Kleine Stromänderung: Der Strom durch T2 wächst mit der Spannung
    // (I_RB), dadurch steigt U_BE von T2 um U_T * ln(I_RB,max / I_RB,min)
    // und mit ihm der LED-Strom. Beispiel 12 -> 14,4 V: etwa +0,9 %.
    Result.KsqRise := KSQ_UT * Ln((U2 - UBase) / (U1 - UBase)) / KSQ_UBE_SENSE;
  end;

  // ----- 6. Vergleich mit einem einfachen Vorwiderstand -----
  // Vorwiderstand für den gleichen Strom bei UMin; bei UMax liegt mehr
  // Spannung an ihm, der Strom steigt im gleichen Verhältnis.
  if U1 > Result.ULeds then
  begin
    Result.RvCalc := (U1 - Result.ULeds) / Input.I;      // z. B. (12 - 3,2) V / 20 mA = 440 Ω
    Result.RvRise := (U2 - Result.ULeds) / (U1 - Result.ULeds) - 1;  // z. B. 11,2 / 8,8 - 1 = +27 %
  end;
end;

end.
