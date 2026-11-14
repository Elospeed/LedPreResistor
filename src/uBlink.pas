{==============================================================================
  uBlink - Rechenlogik für die Blinkschaltungen
==============================================================================
  Zweck:     Berechnet die zwei Blinkschaltungen im Reiter «Blinkschaltung»:
               - NE555 astabil (Kippschaltung mit dem Timer-IC)
               - astabiler Multivibrator mit zwei Transistoren (BC547)
             dazu den Vorwiderstand jeder LED mit Normwert.

  Idee:      Ein Kondensator wird über Widerstände geladen und entladen. Die
             Zeit hängt von R · C ab: t = K · R · C.
             NE555: K = ln 2 ≈ 0,693 (Laden von 1/3 auf 2/3 U_B).
             Multivibrator: K hängt von U_B und vom Spannungssprung ab
             (siehe MultiFactor), im Lehrbuchfall ebenfalls ln 2.

  Richtung:  vorwärts:  aus R und C die Zeiten und die Frequenz
             rückwärts: aus Frequenz und Tastgrad passende Normwerte für R

  Formeln:   NE555 ohne Diode: t_High = K · (R1 + R2) · C,  t_Low = K · R2 · C
             NE555 mit Diode:  t_High = K · R1 · C,         t_Low = K · R2 · C
             Multivibrator:    t(T1 leitet) = K · R_B2 · C
                               t(T2 leitet) = K · R_B1 · C
             Frequenz f = 1 / (t_High + t_Low)

  Beispiel:  NE555, R1 = 1 kΩ, R2 = 68 kΩ, C = 10 µF, ohne Diode:
             t_High = 0,693 · 69 kΩ · 10 µF = 0,478 s
             t_Low  = 0,693 · 68 kΩ · 10 µF = 0,471 s
             f = 1 / 0,949 s ≈ 1,05 Hz

  Regeln:    Reine Logik ohne Oberfläche und ohne Texte (wie uCalc). Alle
             Werte in SI-Einheiten: V, A, Ω, F, s, Hz.

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  Kommentare ausführlicher
             2.3  11.11.2026  neu: Blinkschaltung NE555 und Multivibrator
==============================================================================}
unit uBlink;

{$mode objfpc}{$H+}

interface

uses
  uESeries;

{==============================================================================
  KONSTANTEN: BAUTEIL-DATEN
==============================================================================}
const
  // NE555 (bipolar), aus dem Datenblatt
  NE555_DROP_HIGH = 1.7;                                 // V, Ausgang High liegt so viel unter +U_B
                                                         //    (typisch 1,4 ... 1,7 V bei 15 ... 100 mA)
  NE555_LOW = 0.1;                                       // V, Restspannung am Ausgang bei Low
  NE555_U_MIN = 4.5;                                     // V, kleinste erlaubte Speisespannung
  NE555_U_MAX = 16.0;                                    // V, grösste erlaubte Speisespannung
  NE555_I_MAX = 0.2;                                     // A, höchster Ausgangsstrom
  NE555_R1_MIN = 1000.0;                                 // Ω, kleinster sinnvoller R1: schont den
                                                         //    Entladetransistor an Pin 7

  // BC547 (sichere Annahmen)
  BJT_UCE_SAT = 0.2;                                     // V, Kollektor-Emitter-Spannung, voll durchgeschaltet
  BJT_UBE = 0.6;                                         // V, Basis-Emitter-Spannung, wenn er leitet
  BJT_BETA = 100.0;                                      // Stromverstärkung (eher niedrig angenommen)
  BJT_UEB_MAX = 6.0;                                     // V, höchste Sperrspannung der Basis
  BJT_OVERDRIVE_MIN = 1.0;                               // Basisstrom mindestens I_C / β (Übersteuerung 1)

  // Grenzen für Hinweise
  BLINK_VISIBLE_MAX = 50.0;                              // Hz, darüber sieht das Auge kein Blinken mehr
                                                         //     (Vorschau zeigt dann Dauerlicht)
  R_TIMING_MAX = 1e6;                                    // Ω, darüber verfälscht der Leckstrom eines
                                                         //    Elkos die Zeiten

{==============================================================================
  TYPEN
==============================================================================}
type
  // die beiden Schaltungen
  TBlinkCircuit = (bcNE555, bcMulti);

  // Anschluss der LED am NE555-Ausgang (Pin 3)
  TLedConn = (
    cnGnd,                                               // LED nach Masse: leuchtet, wenn der Ausgang High ist
    cnVcc,                                               // LED nach +Ub: leuchtet, wenn der Ausgang Low ist
    cnBoth                                               // beide: Wechselblinker (LED 1 nach Masse, LED 2 nach +Ub)
  );

  // Eingaben, alle in SI-Einheiten
  TBlinkInput = record
    Circuit: TBlinkCircuit;
    Reverse: Boolean;                                    // True = aus Frequenz und Tastgrad rechnen
    R1: Double;                                          // NE555: R1; Multivibrator: R_B1 (Basis T1), in Ω
    R2: Double;                                          // NE555: R2; Multivibrator: R_B2 (Basis T2), in Ω
    C: Double;                                           // Zeitkondensator in F (Multivibrator: C1 = C2 = C)
    F: Double;                                           // gewünschte Frequenz in Hz (nur rückwärts)
    Duty: Double;                                        // gewünschter Anteil «LED 1 an», 0..1 (nur rückwärts)
    Diode: Boolean;                                      // NE555: Diode über R2 (Tastgrad unter 50 % möglich)
    Conn: TLedConn;                                      // NE555: Anschluss der LED
    U: Double;                                           // Speisespannung U_B in V
    Ud: Double;                                          // Durchlassspannung U_F der LED in V
    I: Double;                                           // gewünschter LED-Strom in A
    Series: TESeries;                                    // Normreihe für alle Widerstände
  end;

  // Ergebnis der Prüfung der Eingaben
  TBlinkStatus = (
    bsOk,                                                // alles in Ordnung
    bsInvalidU,                                          // Speisespannung fehlt oder <= 0
    bsInvalidUd,                                         // Durchlassspannung fehlt oder <= 0
    bsInvalidI,                                          // Strom fehlt oder <= 0
    bsInvalidR1,                                         // R1 bzw. R_B1 fehlt oder <= 0
    bsInvalidR2,                                         // R2 bzw. R_B2 fehlt oder <= 0
    bsInvalidC,                                          // Kondensator fehlt oder <= 0
    bsInvalidF,                                          // Frequenz fehlt oder <= 0
    bsInvalidDuty,                                       // Tastgrad nicht zwischen 0 und 100 %
    bsDutyNeedsDiode,                                    // NE555 ohne Diode: High-Anteil muss über 50 % sein
    bsUTooLow,                                           // es bleibt keine Spannung für den Vorwiderstand
    bsNoStdValue                                         // kein Normwert gefunden (sollte nicht vorkommen)
  );

  // Hinweise zu einem gültigen Resultat (gerechnet wird trotzdem)
  TBlinkWarning = (
    bwSupply555,                                         // NE555 ausserhalb 4,5–16 V
    bwR1Small,                                           // NE555: R1 unter 1 kΩ
    bwOutCurrent,                                        // NE555: Ausgangsstrom über 200 mA
    bwBaseReverse,                                       // Multivibrator: Basis wird mit mehr als 6 V gesperrt
    bwNotSaturated,                                      // Multivibrator: Basisstrom reicht nicht sicher
    bwRHigh,                                             // Zeitwiderstand über 1 MΩ (Leckstrom des Elkos)
    bwTooFast                                            // schneller als das Auge: wirkt wie Dauerlicht
  );
  TBlinkWarnings = set of TBlinkWarning;

  // Vorwiderstand einer LED mit Normwert
  TLedResistor = record
    Used: Boolean;                                       // diese LED gibt es in der Schaltung
    UR: Double;                                          // Spannung am Widerstand in V
    RCalc: Double;                                       // berechneter Widerstand in Ω
    Std: TStdValue;                                      // Normwert (nächsthöher)
    R: Double;                                           // Normwert in Ω
    IAct: Double;                                        // tatsächlicher Strom in A
    P: Double;                                           // Leistung im Widerstand in W (während die LED leuchtet)
  end;

  // Alle Resultate, in SI-Einheiten
  TBlinkResult = record
    Status: TBlinkStatus;                                // nur bei bsOk sind die Werte unten gültig
    Warnings: TBlinkWarnings;
    R1Calc, R2Calc: Double;                              // rückwärts: ideale Werte vor dem Runden
    R1, R2, C: Double;                                   // verwendete Bauteile (rückwärts: Normwerte)
    K: Double;                                           // Faktor der Zeitformel: t = K · R · C
    THigh, TLow: Double;                                 // NE555: Ausgang High / Low in s;
                                                         // Multivibrator: T1 leitet / T2 leitet in s
    T: Double;                                           // Periodendauer in s
    F: Double;                                           // Frequenz in Hz
    TOn1, TOff1: Double;                                 // LED 1 an / aus in s
    Duty1: Double;                                       // Anteil «LED 1 an», 0..1
    UOut: Double;                                        // NE555: Ausgangsspannung bei High in V
    DeltaU: Double;                                      // Multivibrator: Spannungssprung am Kollektor in V
    URev: Double;                                        // Multivibrator: Sperrspannung der Basis in V
    IB: Double;                                          // Multivibrator: Basisstrom in A
    Overdrive: Double;                                   // Multivibrator: I_B · β / I_C
    Led1, Led2: TLedResistor;                            // Vorwiderstände (LED 2 nur bei Wechselblinker)
  end;

{==============================================================================
  ÖFFENTLICHE FUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  CalculateBlink
------------------------------------------------------------------------------
  Rechnet die gewählte Blinkschaltung vollständig aus.
  Parameter: Input - alle Eingaben (Schaltung, Richtung, Bauteile, LED)
  Rückgabe:  Resultat. Bei ungültigen Eingaben steht in Status der Grund,
             alle anderen Werte sind dann 0 (keine halben Resultate).
------------------------------------------------------------------------------}
function CalculateBlink(const Input: TBlinkInput): TBlinkResult;

{------------------------------------------------------------------------------
  NearestStdValue
------------------------------------------------------------------------------
  Sucht den Normwert der Reihe, der R am nächsten liegt. «Am nächsten»
  gilt im Verhältnis (Abstand der Logarithmen), also 14,4 kΩ -> 15 kΩ.
  Gebraucht für die Zeitwiderstände bei der Rückwärtsrechnung; dort ist
  der nächste Wert besser als der nächsthöhere.
  Parameter: R      - gewünschter Widerstand in Ω
             Series - Normreihe (E12, E24, E96)
             Std    - (Rückgabe) gefundener Normwert
  Rückgabe:  False bei R <= 0 oder ungültiger Zahl
------------------------------------------------------------------------------}
function NearestStdValue(R: Double; Series: TESeries; out Std: TStdValue): Boolean;

{------------------------------------------------------------------------------
  MultiFactor
------------------------------------------------------------------------------
  Faktor K der Multivibrator-Formel t = K · R_B · C.
  Idee:      Schaltet ein Transistor ein, springt sein Kollektor um ΔU nach
             unten. Über den Kondensator springt die Basis des anderen
             Transistors mit, auf 0,6 V − ΔU. Von dort lädt sie sich über
             R_B Richtung +U_B auf, bis sie wieder 0,6 V erreicht.
  Formel:    K = ln((U_B − 0,6 + ΔU) / (U_B − 0,6))
             Ist ΔU = U_B − 0,6 (Lehrbuchfall), ist K = ln 2.
  Beispiel:  U_B = 9 V, ΔU = 6,8 V: K = ln(15,2 / 8,4) = 0,593
  Parameter: U      - Speisespannung U_B in V
             DeltaU - Spannungssprung am Kollektor in V
  Rückgabe:  K; bei unsinnigen Werten ln 2
------------------------------------------------------------------------------}
function MultiFactor(U, DeltaU: Double): Double;

{------------------------------------------------------------------------------
  LedResistor
------------------------------------------------------------------------------
  Bestimmt den Vorwiderstand einer LED: An UR Volt soll der Strom I
  fliessen. R = UR / I, aufgerundet auf den nächsthöheren Normwert (der
  Strom wird damit etwas kleiner, nie grösser).
  Parameter: UR     - Spannung am Widerstand in V
             I      - gewünschter Strom in A
             Series - Normreihe
             LR     - (Rückgabe) Werte des Widerstands
  Rückgabe:  False, wenn UR oder I nicht positiv sind (zu wenig Spannung)
------------------------------------------------------------------------------}
function LedResistor(UR, I: Double; Series: TESeries; out LR: TLedResistor): Boolean;

implementation

uses
  Math;

{==============================================================================
  HILFSFUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  NearestStdValue - siehe Interface
------------------------------------------------------------------------------
  Ablauf: alle Werte der Reihe in drei Dekaden (eine darunter, die von R,
  eine darüber) durchgehen und den mit dem kleinsten |ln(V / R)| nehmen.
------------------------------------------------------------------------------}
function NearestStdValue(R: Double; Series: TESeries; out Std: TStdValue): Boolean;
var
  Decade, E, I, DigitCount: Integer;                     // wie in NextStdValue
  V, Best, D: Double;                                    // Kandidat, bester Abstand, Abstand
begin
  Result := False;
  Std := Default(TStdValue);
  if IsNan(R) or IsInfinite(R) or (R <= 0) then
    Exit;
  DigitCount := SeriesDigitCount(Series);
  Decade := Floor(Log10(R));                             // z. B. 14 400 -> 4
  Best := MaxDouble;
  for E := Decade - 1 to Decade + 1 do
    for I := 0 to SeriesCount(Series) - 1 do
    begin
      V := SeriesDigits(Series, I) * IntPower(10, E - DigitCount + 1);  // Kandidat in Ω
      D := Abs(Ln(V / R));                               // Abstand im Verhältnis
      if D < Best - 1e-12 then                           // bei Gleichstand der kleinere
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

{------------------------------------------------------------------------------
  MultiFactor - siehe Interface
------------------------------------------------------------------------------}
function MultiFactor(U, DeltaU: Double): Double;
begin
  if (U - BJT_UBE <= 0) or (DeltaU <= 0) then
    Exit(Ln(2));                                         // Lehrbuchwert als Notlösung
  Result := Ln((U - BJT_UBE + DeltaU) / (U - BJT_UBE));
end;

{------------------------------------------------------------------------------
  LedResistor - siehe Interface
------------------------------------------------------------------------------}
function LedResistor(UR, I: Double; Series: TESeries; out LR: TLedResistor): Boolean;
begin
  LR := Default(TLedResistor);
  Result := (UR > 0) and (I > 0);
  if not Result then Exit;
  LR.Used := True;
  LR.UR := UR;
  LR.RCalc := UR / I;                                    // Ohmsches Gesetz
  Result := NextStdValue(LR.RCalc, Series, LR.Std);      // aufrunden
  if not Result then Exit;
  LR.R := LR.Std.Value;
  LR.IAct := UR / LR.R;                                  // tatsächlicher Strom
  LR.P := UR * LR.IAct;                                  // Leistung P = U · I
end;

{------------------------------------------------------------------------------
  RoundTiming
------------------------------------------------------------------------------
  Rundet einen Zeitwiderstand (Rückwärtsrechnung) auf den nächsten
  Normwert.
  Parameter: RCalc  - idealer Wert in Ω
             Series - Normreihe
             R      - (Rückgabe) Normwert in Ω, 0 wenn keiner gefunden
  Rückgabe:  True, wenn ein Normwert gefunden wurde
------------------------------------------------------------------------------}
function RoundTiming(RCalc: Double; Series: TESeries; out R: Double): Boolean;
var
  Std: TStdValue;                                        // gefundener Normwert
begin
  Result := NearestStdValue(RCalc, Series, Std);
  if Result then R := Std.Value else R := 0;
end;

{------------------------------------------------------------------------------
  Calc555
------------------------------------------------------------------------------
  Rechnet den NE555 astabil.
  Parameter: Inp - Eingaben (bereits geprüft)
             Res - (Rückgabe) Resultat; Status bleibt bsOk oder nennt den
                   Fehler
  Ablauf:
    1. rückwärts: aus f und Tastgrad R1 und R2 bestimmen und auf Normwerte
       runden; vorwärts: R1 und R2 übernehmen
    2. Zeiten t_High und t_Low; welche davon «LED 1 an» ist, hängt vom
       Anschluss ab (LED nach +U_B leuchtet bei Low)
    3. Vorwiderstände: nach Masse gilt U_OUT − U_F, nach +U_B gilt
       U_B − U_F − 0,1 V
    4. Hinweise (Speisespannung, R1, Ausgangsstrom, grosser R)
------------------------------------------------------------------------------}
procedure Calc555(const Inp: TBlinkInput; var Res: TBlinkResult);
var
  K: Double;                                             // Zeitfaktor ln 2 ≈ 0,693
  S: Double;                                             // Summe der Zeitwiderstände aus der Periode: 1 / (f · K · C)
  DHigh: Double;                                         // gewünschter High-Anteil des Ausgangs (0 ... 1)
begin
  K := Ln(2);
  Res.K := K;
  // ----- 1. Zeitwiderstände -----
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
      // Beispiel: f = 1 Hz, DHigh = 0,6, C = 10 µF -> S = 144 kΩ,
      //           R2 = 0,4 · S = 57,7 kΩ, R1 = 0,2 · S = 28,9 kΩ
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

  // ----- 2. Zeiten -----
  if Inp.Diode then
    Res.THigh := K * Res.R1 * Res.C                      // Diode überbrückt R2 beim Laden
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

  // ----- 3. Vorwiderstände -----
  Res.UOut := Inp.U - NE555_DROP_HIGH;                   // Ausgang High
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

  // ----- 4. Hinweise -----
  if (Inp.U < NE555_U_MIN) or (Inp.U > NE555_U_MAX) then
    Include(Res.Warnings, bwSupply555);
  if Res.R1 < NE555_R1_MIN then
    Include(Res.Warnings, bwR1Small);
  if Max(Res.Led1.IAct, Res.Led2.IAct) > NE555_I_MAX then
    Include(Res.Warnings, bwOutCurrent);
  if Max(Res.R1, Res.R2) > R_TIMING_MAX then
    Include(Res.Warnings, bwRHigh);
end;

{------------------------------------------------------------------------------
  CalcMulti
------------------------------------------------------------------------------
  Rechnet den astabilen Multivibrator mit zwei Transistoren.
  Parameter: wie Calc555
  Ablauf:
    1. Vorwiderstände: LED und Widerstand liegen im Kollektor,
       U_R = U_B − U_F − U_CE,sat
    2. Spannungssprung ΔU und Zeitfaktor K
    3. rückwärts: R_B1 und R_B2 aus f und Tastgrad; vorwärts übernehmen
    4. Zeiten
    5. Sättigung prüfen: reicht der Basisstrom, damit der Transistor ganz
       durchschaltet? Übersteuerung = I_B · β / I_C (soll >= 1 sein)
    6. Hinweise
------------------------------------------------------------------------------}
procedure CalcMulti(const Inp: TBlinkInput; var Res: TBlinkResult);
var
  IC: Double;                                            // Kollektorstrom (LED-Strom mit Normwert)
begin
  // ----- 1. Vorwiderstände: LED und Widerstand liegen im Kollektor -----
  if not (LedResistor(Inp.U - Inp.Ud - BJT_UCE_SAT, Inp.I, Inp.Series, Res.Led1) and
          LedResistor(Inp.U - Inp.Ud - BJT_UCE_SAT, Inp.I, Inp.Series, Res.Led2)) then
  begin
    Res.Status := bsUTooLow;
    Exit;
  end;
  // ----- 2. Spannungssprung am Kollektor: von U_B − U_F (gesperrt) auf U_CE,sat -----
  Res.DeltaU := Inp.U - Inp.Ud - BJT_UCE_SAT;
  Res.K := MultiFactor(Inp.U, Res.DeltaU);
  Res.C := Inp.C;

  // ----- 3. Zeitwiderstände -----
  // LED 1 hängt am Kollektor von T1 und leuchtet, solange T1 leitet. T1
  // leitet, solange T2 gesperrt ist; T2 wird über C1 gesperrt und lädt
  // sich über R_B2 wieder auf: t(T1 leitet) = K · R_B2 · C.
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
  // ----- 4. Zeiten -----
  Res.THigh := Res.K * Res.R2 * Res.C;                   // T1 leitet, LED 1 an
  Res.TLow := Res.K * Res.R1 * Res.C;                    // T2 leitet, LED 2 an
  Res.TOn1 := Res.THigh;
  Res.TOff1 := Res.TLow;

  // ----- 5. Sättigung: Basisstrom über den grösseren R_B (ungünstigster Fall) -----
  IC := Res.Led1.IAct;
  Res.IB := (Inp.U - BJT_UBE) / Max(Res.R1, Res.R2);
  if IC > 0 then
    Res.Overdrive := Res.IB * BJT_BETA / IC;
  Res.URev := Res.DeltaU - BJT_UBE;                      // so weit wird die Basis negativ

  // ----- 6. Hinweise -----
  if Res.URev > BJT_UEB_MAX then
    Include(Res.Warnings, bwBaseReverse);
  if Res.Overdrive < BJT_OVERDRIVE_MIN then
    Include(Res.Warnings, bwNotSaturated);
  if Max(Res.R1, Res.R2) > R_TIMING_MAX then
    Include(Res.Warnings, bwRHigh);
end;

{------------------------------------------------------------------------------
  CalculateBlink - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Eingaben prüfen; der erste Fehler gewinnt
    2. Schaltung rechnen (Calc555 oder CalcMulti)
    3. Periode, Frequenz und Tastgrad; Hinweis, wenn zu schnell fürs Auge
    4. Bei Fehler nur den Grund behalten
------------------------------------------------------------------------------}
function CalculateBlink(const Input: TBlinkInput): TBlinkResult;
var
  St: TBlinkStatus;                                      // Grund eines Fehlers
begin
  Result := Default(TBlinkResult);

  // ----- 1. Eingaben prüfen; der erste Fehler gewinnt -----
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

  // ----- 2. Schaltung rechnen -----
  if Input.Circuit = bcNE555 then
    Calc555(Input, Result)
  else
    CalcMulti(Input, Result);

  // ----- 3. Periode, Frequenz, Tastgrad -----
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
    // ----- 4. Nur den Grund behalten, keine halben Resultate -----
    St := Result.Status;
    Result := Default(TBlinkResult);
    Result.Status := St;
  end;
end;

end.
