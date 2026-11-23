{==============================================================================
  uAc - Rechenlogik für LEDs an Wechselspannung
==============================================================================
  Zweck:     Rechnet die beiden Schaltungen des Reiters «Wechselstrom» aus,
             z. B. für den Lichtausgang eines Modellbahn-Trafos (16 V~):
               1. Einfach: Vorwiderstand R und Schutzdiode D antiparallel
                  zu den LEDs. Die LEDs leuchten nur in der positiven
                  Halbwelle (50-mal pro Sekunde, flackert leicht), D hält
                  die Sperrspannung an den LEDs bei etwa 0,7 V.
               2. Ohne Flackern: Brückengleichrichter und Elko C machen
                  aus der Wechselspannung eine fast glatte Gleichspannung,
                  danach rechnet R wie beim normalen Vorwiderstand.

  Idee:      Ein Trafo mit 16 V~ liefert eine Sinusspannung mit dem
             Effektivwert 16 V. Ihre Spitze ist √2-mal so hoch, also
             22,6 V. Die LEDs leiten nur, solange die Spannung über ihrer
             Durchlassspannung liegt.
             Einfach: R wird so gewählt, dass in der Spitze höchstens der
             eingegebene LED-Strom fliesst. Die LED wird so nie
             überlastet, leuchtet aber nur etwa ein Drittel so hell wie mit
             gleich viel Gleichstrom (der mittlere Strom wird angezeigt).
             Mindestens ein Viertel der Spitze muss am Widerstand bleiben,
             sonst steigt der Strom zu stark, wenn die LEDs etwas weniger
             Spannung brauchen. Ein Trafo ohne Last liefert oft 10 ... 20 %
             mehr als aufgedruckt: dann fliesst entsprechend mehr Strom.
             Darum im Programm und in der LED-Info: Spannung messen.
             Ohne Flackern: Der Elko lädt sich auf die Spitze (minus zwei
             Diodenspannungen im Gleichrichter) auf und fällt zwischen den
             Ladestössen (100-mal pro Sekunde) nur wenig ab. Er wird so
             gross gewählt, dass der LED-Strom höchstens etwa ±10 %
             schwankt: Brummspannung = 20 % der Spannung am Widerstand.

  Benutzung: Eingaben in TAcInput füllen, CalculateAc aufrufen und das
             Ergebnis aus TAcResult lesen. Nur wenn Status = asOk ist,
             sind die Werte gültig; Warnings enthält zusätzliche Hinweise.

  Regeln:    Wie uCalc: keine Oberfläche, keine Texte, alle Werte in
             SI-Einheiten (V, A, Ω, F, W). Texte und Formatierung macht uMain.

  Formeln:   Spitzenspannung     Û   = U~ × √2
             Einfach:
               R      = (Û - U_LEDs) / I                (Spitze = I)
               θ      = arcsin(U_LEDs / Û)              (Beginn des Leitens)
               I_mitt = (2 Û cos θ - U_LEDs (π - 2θ)) / (2π R)
               P_R    = Mittelwert von u_R² / R über beide Halbwellen
                        (negative Halbwelle über die Schutzdiode)
             Ohne Flackern:
               U_DC   = Û - 2 × 0,7 V                   (Gleichrichter)
               ΔU     = 0,2 × (U_DC - U_LEDs) / 1,1     (Brummspannung)
               C      = I / (2 × 50 Hz × ΔU)            -> Normwert darüber (E6)
               U_mitt = U_DC - ΔU / 2                   (mit dem Normwert)
               R      = (U_mitt - U_LEDs) / I
               Elko-Spannung mindestens 1,25 × U_DC     -> 10, 16, 25, 35, 50, 63, 100 V
             Beispiel 16 V~, 1 weisse LED (3,2 V), 20 mA:
               Einfach:       Û = 22,6 V; R = 19,4 V / 20 mA = 971 Ω -> 1 kΩ (E12)
                              Spitze 19,4 mA, Mittel 5,7 mA
               Ohne Flackern: U_DC = 21,2 V; ΔU = 3,3 V; C = 61 µF -> 68 µF
                              (35 V); U_mitt = 19,8 V; R = 828 Ω -> 1 kΩ;
                              I = 16,6 mA

  Autor:     Elospeed
  Versionen: 2.7  23.11.2026  neu: LEDs an Wechselspannung (Einfach, Ohne Flackern);
                              Grenze Rückstrom Schutzdiode, Hinweis «sehr dunkel»
==============================================================================}
unit uAc;

{$mode objfpc}{$H+}

interface

uses
  uESeries;                                              // Normreihen, NextStdValue

{==============================================================================
  KONSTANTEN
==============================================================================}
const
  // Netzfrequenz in Europa. Bei 60 Hz (z. B. USA) reicht der gleiche Elko
  // erst recht, darum wird immer mit 50 Hz gerechnet.
  AC_FREQ = 50.0;                                        // Hz

  // Höchste Trafospannung (Effektivwert). Spitze 42 V × √2 = 59,4 V, also
  // wie beim Gleichstrom höchstens 60 V (Kleinspannung).
  AC_U_MAX = 42.0;                                       // V~

  // Höchster LED-Strom (Gleichrichter z. B. B80C1500, Schutzdiode 1N4007)
  AC_I_MAX = 1.0;                                        // A

  // Durchlassspannung einer Siliziumdiode (Schutzdiode, Gleichrichter)
  AC_UD_DIODE = 0.7;                                     // V

  // Der Gleichrichter hat immer zwei Dioden im Stromweg
  AC_BRIDGE_DIODES = 2;                                  // Stück

  // Brummspannung am Elko als Anteil der Spannung am Widerstand. 20 % von
  // Spitze zu Spitze: der LED-Strom schwankt um etwa ±10 %, das sieht man
  // bei 100 Hz nicht.
  AC_RIPPLE = 0.2;                                       // Anteil

  // Elko-Spannung mindestens so viel mal die Spitze am Elko (Reserve für
  // den Trafo ohne Last, der oft 10 ... 20 % mehr liefert)
  AC_CAP_MARGIN = 1.25;                                  // Faktor

  // Ab dieser Grösse gibt es den Hinweis awBigCap (Elko wird gross)
  AC_CAP_BIG = 4700e-6;                                  // F

  // 1N4148: höchster wiederholter Spitzenstrom laut Datenblatt 450 mA;
  // mit Reserve bis 300 mA, darüber 1N4007 (1 A Dauerstrom)
  AC_1N4148_I_PEAK = 0.3;                                // A

  // Mindestens so viel Spannung muss am Widerstand übrig bleiben, sonst
  // hängt der Strom zu stark von der LED und vom Trafo ab
  AC_UR_MIN = 1.0;                                       // V

  // Zusätzlich muss mindestens ein Viertel der Spitze (bzw. der Spannung am
  // Elko) am Widerstand bleiben. Sonst steigt der LED-Strom stark, wenn der
  // Trafo ohne Last 10 ... 20 % mehr liefert oder die LEDs etwas weniger
  // Durchlassspannung haben (bei 18 LEDs an 42 V~ sonst bis 5-mal zu viel).
  AC_UR_FRAC = 0.25;                                     // Anteil

  // Höchster Spitzenstrom durch die Schutzdiode (1N4007: 1 A Dauerstrom).
  // Mit vielen LEDs wird R klein, in der negativen Halbwelle liegt dann
  // fast die ganze Spitze an R, und der Rückstrom wird ein Vielfaches des
  // LED-Stroms. Darüber gibt es den Fehler asRevTooHigh.
  AC_I_REV_MAX = 1.0;                                    // A

  // Unter diesem Anteil der Helligkeit (mittlerer Strom / eingegebener
  // Strom) gibt es den Hinweis awDim: der Widerstand verheizt dann fast
  // alles, und der Strom hängt stark von der echten LED-Spannung ab.
  AC_DIM_MIN = 0.2;                                      // Anteil

{==============================================================================
  TYPEN
==============================================================================}
type
  // ----- Auswahl der Schaltung -----
  TAcCircuit = (
    acSimple,                                            // Vorwiderstand + Schutzdiode (Halbwelle)
    acBridge                                             // Gleichrichter + Elko + Vorwiderstand
  );

  // ----- Schutzdiode (nur Einfach) -----
  TAcDiode = (
    ad1N4148,                                            // kleine Signaldiode, bis 300 mA Spitze
    ad1N4007                                             // Gleichrichterdiode, 1 A
  );

  // ----- Eingaben (alle in SI-Einheiten) -----
  TAcInput = record
    Circuit: TAcCircuit;                                 // welche Schaltung
    U: Double;                                           // Trafospannung, Effektivwert (V~)
    Ud: Double;                                          // Durchlassspannung einer LED (V)
    I: Double;                                           // LED-Strom (A): Einfach = Spitze, sonst Dauerstrom
    N: Integer;                                          // Anzahl LEDs in Reihe
    Series: TESeries;                                    // Normreihe für den Widerstand
  end;

  // ----- Ergebnis der Prüfung der Eingaben -----
  TAcStatus = (
    asOk,                                                // alles gültig, Werte gerechnet
    asInvalidU,                                          // Trafospannung fehlt oder <= 0
    asInvalidUd,                                         // Durchlassspannung fehlt oder <= 0
    asInvalidI,                                          // Strom fehlt oder <= 0
    asInvalidN,                                          // Anzahl LEDs < 1
    asOverVoltage,                                       // über 42 V~ (Kleinspannung)
    asTooMuchCurrent,                                    // über 1 A
    asUTooLow,                                           // Spitze reicht nicht für die LEDs
    asNoStdValue,                                        // kein Normwert gefunden (sollte nicht vorkommen)
    asRevTooHigh                                         // Einfach: Rückstrom durch die Schutzdiode über 1 A
  );

  // ----- Hinweise zu einem gültigen Resultat -----
  TAcWarning = (
    awRPower,                                            // Widerstand braucht mehr als 1 W Bauform (über 0,5 W)
    awBigCap,                                            // Elko über 4700 µF
    awDim                                                // Einfach: unter 20 % der Helligkeit
  );
  TAcWarnings = set of TAcWarning;                       // mehrere Hinweise gleichzeitig möglich

  // ----- Alle Resultate (SI-Einheiten) -----
  TAcResult = record
    Status: TAcStatus;                                   // nur bei asOk sind die Werte gültig
    Warnings: TAcWarnings;                               // Hinweise, siehe TAcWarning
    UPeak: Double;                                       // Spitzenspannung des Trafos Û (V)
    ULeds: Double;                                       // Spannung an allen LEDs zusammen (V)
    UNeedAc: Double;                                     // kleinste Trafospannung, die reicht (V~)
    NMax: Integer;                                       // bei asUTooLow: so viele LEDs gingen (0 = keine)
    RCalc: Double;                                       // berechneter Widerstand (Ω)
    Std: TStdValue;                                      // Normwert (nächsthöher)
    R: Double;                                           // Normwert (Ω)
    PR: Double;                                          // mittlere Leistung im Widerstand (W)
    RRating: Double;                                     // Bauform (W: ¼ … 50, 0 = über 50 W)
    PLeds: Double;                                       // mittlere Leistung in allen LEDs (W)

    // nur Einfach (Halbwelle)
    IPeak: Double;                                       // Spitzenstrom durch die LEDs (A)
    IAvg: Double;                                        // mittlerer LED-Strom = Helligkeit (A)
    Brightness: Double;                                  // IAvg / I (0.29 = 29 % von Gleichstrom)
    Theta: Double;                                       // Beginn des Leitens (rad)
    IRevPeak: Double;                                    // Spitzenstrom durch die Schutzdiode (A)
    URevLed: Double;                                     // Sperrspannung an den LEDs (V)
    URevDiode: Double;                                   // Sperrspannung an der Schutzdiode (V)
    Diode: TAcDiode;                                     // empfohlene Schutzdiode

    // nur Ohne Flackern (Gleichrichter + Elko)
    UDc: Double;                                         // Spitze am Elko (V)
    RippleCalc: Double;                                  // gewünschte Brummspannung (V)
    CCalc: Double;                                       // berechneter Elko (F)
    C: Double;                                           // Normwert Elko (F, E6)
    CVolt: Double;                                       // Spannungsfestigkeit des Elkos (V)
    Ripple: Double;                                      // Brummspannung mit dem Normwert (V)
    UMean: Double;                                       // mittlere Spannung am Elko (V)
    IAct: Double;                                        // LED-Strom mit dem Normwert (A)
    IRipple: Double;                                     // Schwankung des LED-Stroms ± (Anteil, 0.08 = ±8 %)
  end;

{==============================================================================
  ÖFFENTLICHE FUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  CalculateAc - rechnet die ganze Wechselstrom-Schaltung aus
------------------------------------------------------------------------------
  Parameter: Input  - Schaltung, Trafospannung, LED-Daten, Strom, Normreihe
  Rückgabe:  alle Resultate; bei ungültigen Eingaben steht in Status der
             Grund und die übrigen Werte sind nicht gesetzt.
------------------------------------------------------------------------------}
function CalculateAc(const Input: TAcInput): TAcResult;

{------------------------------------------------------------------------------
  NextCapValue - nächster Elko-Normwert darüber (E6)
------------------------------------------------------------------------------
  Parameter: C - berechnete Kapazität (F), > 0
  Rückgabe:  kleinster Wert aus 1, 1,5, 2,2, 3,3, 4,7, 6,8 × 10^n µF, der
             mindestens C ist; 0 bei ungültigem C.
------------------------------------------------------------------------------}
function NextCapValue(C: Double): Double;

{------------------------------------------------------------------------------
  CapVoltage - Spannungsfestigkeit eines Elkos wählen
------------------------------------------------------------------------------
  Parameter: U - nötige Spannung (V)
  Rückgabe:  kleinste übliche Nennspannung (10, 16, 25, 35, 50, 63, 100 V),
             die mindestens U ist; 0 wenn auch 100 V nicht reicht.
------------------------------------------------------------------------------}
function CapVoltage(U: Double): Double;

{------------------------------------------------------------------------------
  HalfWaveAvg - mittlerer Strom einer Halbwelle durch R und LEDs
------------------------------------------------------------------------------
  Parameter: UPeak - Spitzenspannung (V)
             ULeds - Spannung an den LEDs (V), < UPeak
             R     - Widerstand (Ω)
  Rückgabe:  Mittelwert über eine ganze Periode (A); 0 wenn nichts leitet.
------------------------------------------------------------------------------}
function HalfWaveAvg(UPeak, ULeds, R: Double): Double;

{------------------------------------------------------------------------------
  HalfWavePower - mittlere Leistung in R während einer Halbwelle
------------------------------------------------------------------------------
  Parameter: wie HalfWaveAvg (ULeds = Spannung am Bauteil in Reihe zu R)
  Rückgabe:  Mittelwert von u_R² / R über eine ganze Periode (W)
------------------------------------------------------------------------------}
function HalfWavePower(UPeak, ULeds, R: Double): Double;

implementation

uses
  Math,                                                  // ArcSin, Floor, Log10, Power
  uCalc;                                                 // RecommendRating (Bauform eines Widerstands)

const
  // Elko-Werte pro Dekade (E6), in µF × 10 (10 = 1,0 µF)
  CAP_DIGITS: array[0..5] of Integer = (10, 15, 22, 33, 47, 68);

  // übliche Nennspannungen von Elkos (V), aufsteigend
  CAP_VOLTS: array[0..6] of Double = (10, 16, 25, 35, 50, 63, 100);

  // übliche Leistungswiderstände (W) über 1 W, aufsteigend
  AC_POWER_RATINGS: array[0..5] of Double = (2, 3, 5, 10, 25, 50);

{------------------------------------------------------------------------------
  NextCapValue - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Dekade bestimmen (z. B. 61 µF -> 10 µF ... 100 µF)
    2. ersten Wert der Dekade suchen, der reicht; sonst Anfang der nächsten
------------------------------------------------------------------------------}
function NextCapValue(C: Double): Double;
var
  Dec10: Double;                                         // Anfang der Dekade (F), z. B. 10 µF
  I: Integer;                                            // Index in CAP_DIGITS
begin
  Result := 0;
  if not (C > 0) then Exit;
  // ----- 1. Dekade -----
  Dec10 := Power(10, Floor(Log10(C) + 1e-9));
  // ----- 2. Wert suchen -----
  for I := Low(CAP_DIGITS) to High(CAP_DIGITS) do
    if CAP_DIGITS[I] / 10 * Dec10 >= C * (1 - 1e-9) then
      Exit(CAP_DIGITS[I] / 10 * Dec10);
  Result := 10 * Dec10;                                  // nächste Dekade, z. B. 100 µF
end;

{------------------------------------------------------------------------------
  CapVoltage - siehe Interface
------------------------------------------------------------------------------}
function CapVoltage(U: Double): Double;
var
  I: Integer;                                            // Index in CAP_VOLTS
begin
  for I := Low(CAP_VOLTS) to High(CAP_VOLTS) do
    if CAP_VOLTS[I] >= U - 1e-9 then
      Exit(CAP_VOLTS[I]);
  Result := 0;
end;

{------------------------------------------------------------------------------
  HalfWaveAvg - siehe Interface
------------------------------------------------------------------------------
  Strom i(φ) = (Û sin φ - U_LEDs) / R, solange er positiv ist, also von
  θ = arcsin(U_LEDs / Û) bis π - θ. Integral über diesen Bereich durch 2π:
    (2 Û cos θ - U_LEDs (π - 2θ)) / (2π R)
------------------------------------------------------------------------------}
function HalfWaveAvg(UPeak, ULeds, R: Double): Double;
var
  T: Double;                                             // θ, Beginn des Leitens (rad)
begin
  Result := 0;
  if (UPeak <= ULeds) or (R <= 0) then Exit;
  T := ArcSin(Max(0, ULeds) / UPeak);
  Result := (2 * UPeak * Cos(T) - ULeds * (Pi - 2 * T)) / (2 * Pi * R);
end;

{------------------------------------------------------------------------------
  HalfWavePower - siehe Interface
------------------------------------------------------------------------------
  u_R(φ) = Û sin φ - U_LEDs von θ bis π - θ. Integral von u_R²:
    Û² ((π - 2θ)/2 + sin(2θ)/2) - 4 Û U_LEDs cos θ + U_LEDs² (π - 2θ)
  geteilt durch 2π R.
------------------------------------------------------------------------------}
function HalfWavePower(UPeak, ULeds, R: Double): Double;
var
  T: Double;                                             // θ, Beginn des Leitens (rad)
  A, B: Double;                                          // Abkürzungen Û und U_LEDs (V)
begin
  Result := 0;
  if (UPeak <= ULeds) or (R <= 0) then Exit;
  A := UPeak;
  B := Max(0, ULeds);
  T := ArcSin(B / A);
  Result := (Sqr(A) * ((Pi - 2 * T) / 2 + Sin(2 * T) / 2) - 4 * A * B * Cos(T)
    + Sqr(B) * (Pi - 2 * T)) / (2 * Pi * R);
end;

{------------------------------------------------------------------------------
  CalculateAc - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Eingaben prüfen (der erste Fehler gewinnt)
    2. Spitzenspannung und Spannung an den LEDs, reicht die Spannung?
    3a. Einfach: R für den Spitzenstrom, mittlerer Strom, Leistung, Schutzdiode
    3b. Ohne Flackern: Elko, mittlere Spannung, R, Strom, Leistung
------------------------------------------------------------------------------}
function CalculateAc(const Input: TAcInput): TAcResult;
var
  UDrop: Double;                                         // Spannung, die vor den LEDs abgeht (Gleichrichter)
  URes: Double;                                          // Spannung am Widerstand (V)
  I: Integer;                                            // Index in AC_POWER_RATINGS

  {----------------------------------------------------------------------------
    NeedAc
  ----------------------------------------------------------------------------
    Kleinste Trafospannung (V~) für ULeds an den LEDs: Gleichrichter und
    Mindestspannung am R, mindestens 1 V und ein Viertel der Spitze bzw.
    der Spannung am Elko (beim Elko zusätzlich die Brummspannung, siehe 3b).
  ----------------------------------------------------------------------------}
  function NeedAc(ULeds: Double): Double;
  begin
    if Input.Circuit = acBridge then
      // U_R = (U_DC - U_LEDs) / 1,1 >= max(1 V, 0,25 × U_DC)
      Result := (Max(ULeds + AC_UR_MIN * (1 + AC_RIPPLE / 2),
        ULeds / (1 - AC_UR_FRAC * (1 + AC_RIPPLE / 2))) + AC_BRIDGE_DIODES * AC_UD_DIODE) / Sqrt(2)
    else
      // Û - U_LEDs >= max(1 V, 0,25 × Û)
      Result := Max(ULeds + AC_UR_MIN, ULeds / (1 - AC_UR_FRAC)) / Sqrt(2);
  end;

begin
  Result := Default(TAcResult);                          // alle Werte auf 0, Status = asOk

  // ----- 1. Eingaben prüfen -----
  // «not (x > 0)» fängt auch NaN (leeres Feld) ab
  if not (Input.U > 0) then
    Result.Status := asInvalidU
  else if not (Input.Ud > 0) then
    Result.Status := asInvalidUd
  else if not (Input.I > 0) then
    Result.Status := asInvalidI
  else if Input.N < 1 then
    Result.Status := asInvalidN
  else if Input.U > AC_U_MAX + 1e-9 then
    Result.Status := asOverVoltage
  else if Input.I > AC_I_MAX + 1e-9 then
    Result.Status := asTooMuchCurrent;
  if Result.Status <> asOk then Exit;

  // ----- 2. Spannungen -----
  Result.UPeak := Input.U * Sqrt(2);                     // z. B. 16 V~ -> 22,6 V
  Result.ULeds := Input.N * Input.Ud;
  if Input.Circuit = acBridge then
    UDrop := AC_BRIDGE_DIODES * AC_UD_DIODE              // 1,4 V im Gleichrichter
  else
    UDrop := 0;
  Result.UNeedAc := NeedAc(Result.ULeds);
  if Input.U < Result.UNeedAc - 1e-9 then
  begin
    Result.Status := asUTooLow;
    // Wie viele LEDs gingen mit dieser Trafospannung? (für die Abhilfe)
    Result.NMax := Input.N - 1;
    while (Result.NMax > 0) and (Input.U < NeedAc(Result.NMax * Input.Ud) - 1e-9) do
      Dec(Result.NMax);
    Exit;
  end;

  if Input.Circuit = acSimple then
  begin
    // ----- 3a. Einfach: Vorwiderstand + Schutzdiode -----
    // R so, dass in der Spitze höchstens I fliesst (nächster Normwert darüber)
    Result.RCalc := (Result.UPeak - Result.ULeds) / Input.I;  // z. B. 19,4 V / 20 mA = 971 Ω
    if not NextStdValue(Result.RCalc, Input.Series, Result.Std) then
    begin
      Result.Status := asNoStdValue;
      Exit;
    end;
    Result.R := Result.Std.Value;
    Result.IPeak := (Result.UPeak - Result.ULeds) / Result.R;
    Result.Theta := ArcSin(Result.ULeds / Result.UPeak);
    Result.IAvg := HalfWaveAvg(Result.UPeak, Result.ULeds, Result.R);
    Result.Brightness := Result.IAvg / Input.I;
    // Leistung in R: positive Halbwelle über die LEDs, negative über die
    // Schutzdiode (dort fliesst fast gleich viel Strom zurück)
    Result.PR := HalfWavePower(Result.UPeak, Result.ULeds, Result.R)
      + HalfWavePower(Result.UPeak, AC_UD_DIODE, Result.R);
    Result.PLeds := Result.ULeds * Result.IAvg;
    // Schutzdiode: Spitzenstrom in der negativen Halbwelle
    Result.IRevPeak := (Result.UPeak - AC_UD_DIODE) / Result.R;
    if Result.IRevPeak <= AC_1N4148_I_PEAK then
      Result.Diode := ad1N4148
    else
      Result.Diode := ad1N4007;
    Result.URevLed := AC_UD_DIODE;                       // Diode hält die LEDs bei 0,7 V Sperrspannung
    Result.URevDiode := Result.ULeds;                    // Diode sperrt, solange die LEDs leuchten
    if Result.IRevPeak > AC_I_REV_MAX + 1e-9 then
    begin
      Result.Status := asRevTooHigh;                     // Werte bleiben für die Meldung gesetzt
      Exit;
    end;
    if Result.Brightness < AC_DIM_MIN then
      Include(Result.Warnings, awDim);
  end
  else
  begin
    // ----- 3b. Ohne Flackern: Gleichrichter + Elko -----
    Result.UDc := Result.UPeak - UDrop;                  // z. B. 22,6 - 1,4 = 21,2 V
    // Brummspannung 20 % der Spannung am Widerstand. Diese ist
    // U_DC - U_LEDs - ΔU/2, also ΔU = 0,2 × (U_DC - U_LEDs) / 1,1.
    Result.RippleCalc := AC_RIPPLE * (Result.UDc - Result.ULeds) / (1 + AC_RIPPLE / 2);
    Result.CCalc := Input.I / (2 * AC_FREQ * Result.RippleCalc);
    Result.C := NextCapValue(Result.CCalc);              // z. B. 61 µF -> 68 µF
    if Result.C <= 0 then
    begin
      Result.Status := asNoStdValue;
      Exit;
    end;
    Result.Ripple := Input.I / (2 * AC_FREQ * Result.C);
    Result.UMean := Result.UDc - Result.Ripple / 2;
    Result.CVolt := CapVoltage(AC_CAP_MARGIN * Result.UDc);
    URes := Result.UMean - Result.ULeds;
    Result.RCalc := URes / Input.I;
    if not NextStdValue(Result.RCalc, Input.Series, Result.Std) then
    begin
      Result.Status := asNoStdValue;
      Exit;
    end;
    Result.R := Result.Std.Value;
    Result.IAct := URes / Result.R;
    Result.IPeak := Result.IAct;                         // fast gleichmässig
    Result.IAvg := Result.IAct;
    Result.Brightness := Result.IAct / Input.I;
    // Brummspannung mit dem tatsächlichen Strom (etwas kleiner)
    Result.IRipple := Result.IAct / (2 * AC_FREQ * Result.C) / 2 / URes;
    Result.PR := URes * Result.IAct;
    Result.PLeds := Result.ULeds * Result.IAct;
    if Result.C > AC_CAP_BIG * (1 + 1e-9) then
      Include(Result.Warnings, awBigCap);
  end;
  Result.RRating := RecommendRating(Result.PR);          // ¼ W, ½ W, 1 W oder 0 = mehr
  if Result.RRating = 0 then
  begin
    // Leistungswiderstand: übliche Bauform mit doppelter Reserve (0 = über 50 W)
    Include(Result.Warnings, awRPower);
    for I := Low(AC_POWER_RATINGS) to High(AC_POWER_RATINGS) do
      if Result.PR <= AC_POWER_RATINGS[I] / 2 then
      begin
        Result.RRating := AC_POWER_RATINGS[I];
        Break;
      end;
  end;
end;

end.
