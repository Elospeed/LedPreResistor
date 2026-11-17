{==============================================================================
  TestSchaltplan - Tests
==============================================================================
  Zweck:     Prüft, ob die gezeichneten Schaltpläne richtig verbunden sind:
             Jeder Plan wird auf ein Bild gezeichnet, dabei meldet er seine
             Leitungen und Bauteile an uSchemNetz. Danach wird geprüft,
             welche Anschlüsse zusammenhängen.
             Anlass: In 2.5 hing der angedeutete zweite Strang zwischen dem
             ersten Widerstand und der LED statt direkt an der Quelle. Die
             Rechentests merkten das nicht, weil sie nur Zahlen prüfen.

  Geprüft:   - jeder Plan: kein Anschluss offen, keine losen Leitungsenden,
               kein Bauteil kurzgeschlossen
             - LED-Vorwiderstand: Quelle -> R1 -> LEDs in Reihe -> Quelle,
               bei Strängen parallel hat der zweite Strang seinen eigenen
               Widerstand direkt an der Quelle
             - NE555 (alle LED-Anschlüsse, mit und ohne Diode),
               Multivibrator, LM317, zwei Transistoren: jede LED in Reihe
               mit ihrem Vorwiderstand an den richtigen Knoten

  Benutzung: Die Tests laufen mit LedPreResistorTests (FPCUnit). Jede
             Prozedur unter «published» ist ein Test. Braucht die LCL
             (Zeichnen auf ein TBitmap), unter Linux also eine Anzeige
             (im Build-Workflow über xvfb-run).

  Autor:     Elospeed
  Versionen: 2.5.1 17.11.2026  neu
==============================================================================}
unit TestSchaltplan;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry;

{==============================================================================
  TESTKLASSE
==============================================================================}
type
  { Prüft die Verbindungen in allen Schaltplänen }
  TTestSchaltplan = class(TTestCase)
  private
    { Gemeinsame Prüfung jedes Plans: nichts offen, nichts lose, nichts überbrückt }
    procedure PruefeGrundregeln(const Plan: string);
    { Erwartet, dass A und B verbunden sind }
    procedure Verbunden(const Plan, A, B: string);
    { Erwartet, dass A und B NICHT verbunden sind }
    procedure Getrennt(const Plan, A, B: string);
    { Zeichnet den Plan «LED-Vorwiderstand» mit N LEDs und K Strängen }
    procedure ZeichneVorwiderstand(N, K: Integer);
    { Prüft den Plan «LED-Vorwiderstand» mit N LEDs und K Strängen }
    procedure PruefeVorwiderstand(N, K: Integer);
    procedure KsqKette(const Plan: string; N: Integer; const Von, Bis: string);
  published
    procedure VorwiderstandEineLed;
    procedure VorwiderstandMehrereLedsInReihe;
    procedure VorwiderstandStraengeParallel;
    procedure Ne555LedNachMasse;
    procedure Ne555LedNachPlus;
    procedure Ne555Wechselblinker;
    procedure Ne555MitDiode;
    procedure Multivibrator;
    procedure KonstantstromLM317;
    procedure KonstantstromTransistoren;
  end;

implementation

uses
  SysUtils, Types, Graphics, uSchemNetz, uSchematic, uBlink, uBlinkSchematic, uKsqSchematic;

var
  Bild: TBitmap;                                         // Zeichenfläche für alle Tests

{------------------------------------------------------------------------------
  Farben
------------------------------------------------------------------------------
  Beliebige Farben für die Blink- und Konstantstrom-Pläne (für die
  Verbindungen unwichtig).
------------------------------------------------------------------------------}
function Farben: TBlinkSchemColors;
begin
  Result.Line := clBlack;
  Result.Text := clBlack;
  Result.Accent := clRed;
  Result.Dim := clGray;
  Result.Body := clWhite;
  Result.LedOff := clGray;
end;

{------------------------------------------------------------------------------
  Flaeche
------------------------------------------------------------------------------
  Liefert ein Bild in passender Grösse (einmal angelegt, dann wiederverwendet).
------------------------------------------------------------------------------}
function Flaeche: TCanvas;
begin
  if Bild = nil then
  begin
    Bild := TBitmap.Create;
    Bild.SetSize(600, 320);
  end;
  Result := Bild.Canvas;
end;

{==============================================================================
  HILFEN
==============================================================================}

procedure TTestSchaltplan.PruefeGrundregeln(const Plan: string);
begin
  AssertEquals(Plan + ': offene Anschlüsse', '', NetzOffeneAnschluesse);
  AssertEquals(Plan + ': lose Leitungsenden', '', NetzOffeneEnden);
  AssertEquals(Plan + ': kurzgeschlossene Bauteile', '', NetzKurzschluesse);
end;

procedure TTestSchaltplan.Verbunden(const Plan, A, B: string);
begin
  AssertTrue(Plan + ': ' + A + ' soll mit ' + B + ' verbunden sein', NetzVerbunden(A, B));
end;

procedure TTestSchaltplan.Getrennt(const Plan, A, B: string);
begin
  AssertFalse(Plan + ': ' + A + ' darf nicht mit ' + B + ' verbunden sein', NetzVerbunden(A, B));
end;

procedure TTestSchaltplan.ZeichneVorwiderstand(N, K: Integer);
var
  V: TSchematicValues;                                   // Werte des Plans
begin
  V := Default(TSchematicValues);
  V.LedCount := N;
  V.StringCount := K;
  V.LedColor := clRed;
  NetzStart;
  DrawSchematic(Flaeche, Rect(0, 0, 460, 240), V, clBlack, clBlack, clRed, clWhite);
  NetzStop;
end;

{------------------------------------------------------------------------------
  PruefeVorwiderstand
------------------------------------------------------------------------------
  Erwartete Kette: UB.+ -> R1 -> LED1 -> ... -> LEDn -> UB.-. Ab 4 LEDs
  stehen Punkte (PUNKTE) für die ausgelassenen LEDs zwischen LED1 und LEDn.
  Bei mehreren Strängen: R2 hängt direkt an UB.+ (nicht hinter R1), dann
  dieselbe Kette S2_LED1 ... S2_LEDn (bzw. S2_PUNKTE) bis UB.-.
------------------------------------------------------------------------------}
procedure TTestSchaltplan.PruefeVorwiderstand(N, K: Integer);
var
  Plan: string;                                          // Name für die Meldungen
  I: Integer;                                            // Zähler der LEDs
begin
  Plan := Format('Vorwiderstand %d LED, %d Strang', [N, K]);
  ZeichneVorwiderstand(N, K);
  PruefeGrundregeln(Plan);
  Verbunden(Plan, 'UB.+', 'R1.1');
  Verbunden(Plan, 'R1.2', 'LED1.A');
  Getrennt(Plan, 'R1.1', 'R1.2');
  if N <= 3 then
  begin
    for I := 1 to N - 1 do                               // LEDs direkt hintereinander
      Verbunden(Plan, 'LED' + IntToStr(I) + '.K', 'LED' + IntToStr(I + 1) + '.A');
  end
  else
  begin
    Verbunden(Plan, 'LED1.K', 'PUNKTE.A');               // LED, Punkte, letzte LED
    Verbunden(Plan, 'PUNKTE.K', 'LED' + IntToStr(N) + '.A');
  end;
  Verbunden(Plan, 'LED' + IntToStr(N) + '.K', 'UB.-');
  if K > 1 then
  begin
    // zweiter Strang mit eigenem Widerstand direkt an der Quelle und gleich vielen LEDs
    Verbunden(Plan, 'UB.+', 'R2.1');
    Getrennt(Plan, 'R2.1', 'R1.2');                      // der Fehler aus 2.5
    Getrennt(Plan, 'R2.1', 'R2.2');
    Verbunden(Plan, 'R2.2', 'S2_LED1.A');
    Getrennt(Plan, 'R2.2', 'R1.2');
    if N <= 3 then
    begin
      for I := 1 to N - 1 do
        Verbunden(Plan, 'S2_LED' + IntToStr(I) + '.K', 'S2_LED' + IntToStr(I + 1) + '.A');
      for I := 1 to N do                                 // jede LED des ersten Strangs hat ihr Gegenstück
        AssertTrue(Plan + ': S2_LED' + IntToStr(I) + ' fehlt', NetzHat('S2_LED' + IntToStr(I) + '.A'));
    end
    else
    begin
      Verbunden(Plan, 'S2_LED1.K', 'S2_PUNKTE.A');       // auch hier: LED, Punkte, letzte LED
      Verbunden(Plan, 'S2_PUNKTE.K', 'S2_LED' + IntToStr(N) + '.A');
    end;
    Verbunden(Plan, 'S2_LED' + IntToStr(N) + '.K', 'UB.-');
    Getrennt(Plan, 'S2_LED1.A', 'LED1.A');               // die Stränge berühren sich nur an der Quelle
  end
  else
    AssertFalse(Plan + ': ohne zweiten Strang', NetzHat('R2.1'));
end;

{==============================================================================
  LED-VORWIDERSTAND
==============================================================================}

procedure TTestSchaltplan.VorwiderstandEineLed;
begin
  PruefeVorwiderstand(1, 1);
end;

procedure TTestSchaltplan.VorwiderstandMehrereLedsInReihe;
var
  N: Integer;                                            // LEDs in Reihe
begin
  for N := 2 to 6 do PruefeVorwiderstand(N, 1);
  PruefeVorwiderstand(30, 1);
end;

procedure TTestSchaltplan.VorwiderstandStraengeParallel;
var
  N: Integer;                                            // LEDs in Reihe
begin
  for N := 1 to 5 do PruefeVorwiderstand(N, 2);
  PruefeVorwiderstand(30, 20);
end;

{==============================================================================
  BLINKSCHALTUNG
==============================================================================}

{------------------------------------------------------------------------------
  Zeichne555
------------------------------------------------------------------------------
  Zeichnet den NE555-Plan mit dem gewählten LED-Anschluss und prüft das
  Zeitglied (gilt für alle Varianten).
------------------------------------------------------------------------------}
procedure Zeichne555(T: TTestSchaltplan; Conn: TLedConn; Diode: Boolean);
var
  V: TBlinkSchemValues;                                  // Werte des Plans
begin
  V := Default(TBlinkSchemValues);
  V.Conn := Conn;
  V.Diode := Diode;
  V.Elko := True;
  V.LedColor := clRed;
  NetzStart;
  DrawSchematic555(Flaeche, Rect(0, 0, 580, 320), V, Farben);
  NetzStop;
  T.PruefeGrundregeln('NE555');
  T.Verbunden('NE555', 'UB.+', 'R1.1');                  // Zeitglied
  T.Verbunden('NE555', 'R1.2', 'IC.7');
  T.Verbunden('NE555', 'R1.2', 'R2.1');
  T.Verbunden('NE555', 'R2.2', 'IC.6');
  T.Verbunden('NE555', 'IC.6', 'IC.2');
  T.Verbunden('NE555', 'IC.6', 'C.1');
  T.Verbunden('NE555', 'C.2', 'UB.-');
  T.Verbunden('NE555', 'IC.8', 'UB.+');                  // Speisung, Reset, Masse
  T.Verbunden('NE555', 'IC.4', 'UB.+');
  T.Verbunden('NE555', 'IC.1', 'UB.-');
  T.Verbunden('NE555', 'IC.5', 'C5.1');                  // Steuerspannung über 10 nF
  T.Verbunden('NE555', 'C5.2', 'UB.-');
  T.Getrennt('NE555', 'IC.3', 'IC.6');                   // Ausgang nicht am Zeitglied
end;

procedure TTestSchaltplan.Ne555LedNachMasse;
begin
  Zeichne555(Self, cnGnd, False);
  Verbunden('NE555', 'IC.3', 'RV1.1');
  Verbunden('NE555', 'RV1.2', 'LED1.A');
  Verbunden('NE555', 'LED1.K', 'UB.-');
end;

procedure TTestSchaltplan.Ne555LedNachPlus;
begin
  Zeichne555(Self, cnVcc, False);
  Verbunden('NE555', 'UB.+', 'LED1.A');
  Verbunden('NE555', 'LED1.K', 'RV1.1');
  Verbunden('NE555', 'RV1.2', 'IC.3');
end;

procedure TTestSchaltplan.Ne555Wechselblinker;
begin
  Zeichne555(Self, cnBoth, False);
  Verbunden('NE555', 'IC.3', 'RV1.1');                   // LED 1 nach Masse
  Verbunden('NE555', 'RV1.2', 'LED1.A');
  Verbunden('NE555', 'LED1.K', 'UB.-');
  Verbunden('NE555', 'UB.+', 'LED2.A');                  // LED 2 von Plus
  Verbunden('NE555', 'LED2.K', 'RV2.1');
  Verbunden('NE555', 'RV2.2', 'IC.3');
end;

procedure TTestSchaltplan.Ne555MitDiode;
begin
  Zeichne555(Self, cnGnd, True);
  Verbunden('NE555', 'D.K', 'IC.7');                     // Diode parallel zu R2
  Verbunden('NE555', 'D.A', 'IC.6');
end;

procedure TTestSchaltplan.Multivibrator;
var
  V: TBlinkSchemValues;                                  // Werte des Plans
  Dioden: Boolean;                                       // mit den grauen 1N4148 vor den Basen
  Plan: string;                                          // Name für die Meldungen
  B1, B2: string;                                        // Anschluss, der zur Basis führt
begin
  for Dioden := False to True do
  begin
    V := Default(TBlinkSchemValues);
    V.Elko := True;
    V.LedColor := clRed;
    V.Led1Lit := True;
    V.BaseDiodes := Dioden;
    if Dioden then Plan := 'Multivibrator mit Dioden' else Plan := 'Multivibrator';
    NetzStart;
    DrawSchematicMulti(Flaeche, Rect(0, 0, 600, 300), V, Farben);
    NetzStop;
    PruefeGrundregeln(Plan);
    // linker Zweig: + -> R_V1 -> LED 1 -> T1 -> Masse
    Verbunden(Plan, 'UB.+', 'RV1.1');
    Verbunden(Plan, 'RV1.2', 'LED1.A');
    Verbunden(Plan, 'LED1.K', 'T1.C');
    Verbunden(Plan, 'T1.E', 'UB.-');
    // rechter Zweig: + -> R_V2 -> LED 2 -> T2 -> Masse
    Verbunden(Plan, 'UB.+', 'RV2.1');
    Verbunden(Plan, 'RV2.2', 'LED2.A');
    Verbunden(Plan, 'LED2.K', 'T2.C');
    Verbunden(Plan, 'T2.E', 'UB.-');
    // Mit Dioden führen R_B und C zur Anode, die Kathode zur Basis
    if Dioden then
    begin
      B1 := 'D1.A';
      B2 := 'D2.A';
      Verbunden(Plan, 'D1.K', 'T1.B');
      Verbunden(Plan, 'D2.K', 'T2.B');
      Getrennt(Plan, 'D1.A', 'D1.K');
      Getrennt(Plan, 'D2.A', 'D2.K');
    end
    else
    begin
      B1 := 'T1.B';
      B2 := 'T2.B';
      AssertFalse(Plan + ': ohne Dioden', NetzHat('D1.A'));
    end;
    // Basiswiderstände und Kreuzkopplung
    Verbunden(Plan, 'UB.+', 'R1.1');
    Verbunden(Plan, 'R1.2', B1);
    Verbunden(Plan, 'UB.+', 'R2.1');
    Verbunden(Plan, 'R2.2', B2);
    Verbunden(Plan, 'C1.1', 'T1.C');                     // C1: Kollektor T1 -> Basis T2
    Verbunden(Plan, 'C1.2', B2);
    Verbunden(Plan, 'C2.2', 'T2.C');                     // C2: Kollektor T2 -> Basis T1
    Verbunden(Plan, 'C2.1', B1);
    Getrennt(Plan, 'T1.B', 'T2.B');                      // die Leitungen kreuzen sich nur
    Getrennt(Plan, 'R1.2', 'C1.2');                      // Brücke über R_B1: keine Verbindung
    Getrennt(Plan, 'R2.2', 'C2.1');                      // Brücke über R_B2: keine Verbindung
  end;
end;

{==============================================================================
  KONSTANTSTROM
==============================================================================}

{------------------------------------------------------------------------------
  KsqKette
------------------------------------------------------------------------------
  Prüft die LED-Kette einer Konstantstromquelle von Von (Anode der ersten
  LED) bis Bis (Kathode der letzten): 1 bis 3 LEDs einzeln, ab 4 LED1,
  Punkte, LEDn.
------------------------------------------------------------------------------}
procedure TTestSchaltplan.KsqKette(const Plan: string; N: Integer; const Von, Bis: string);
begin
  Verbunden(Plan, Von, 'LED1.A');
  if N = 1 then
    Verbunden(Plan, 'LED1.K', Bis)
  else
  begin
    if N = 2 then
      Verbunden(Plan, 'LED1.K', 'LED2.A')
    else if N = 3 then
    begin
      Verbunden(Plan, 'LED1.K', 'LED2.A');
      Verbunden(Plan, 'LED2.K', 'LED3.A');
    end
    else
    begin
      Verbunden(Plan, 'LED1.K', 'PUNKTE.A');
      Verbunden(Plan, 'PUNKTE.K', 'LED' + IntToStr(N) + '.A');
    end;
    Verbunden(Plan, 'LED' + IntToStr(N) + '.K', Bis);
  end;
end;

procedure TTestSchaltplan.KonstantstromLM317;
var
  V: TKsqSchemValues;                                    // Werte des Plans
  N: Integer;                                            // LEDs in Reihe
  Plan: string;                                          // Name für die Meldungen
begin
  for N in [1, 2, 3, 4, 30] do
  begin
    V := Default(TKsqSchemValues);
    V.LedCount := N;
    V.LedColor := clWhite;
    Plan := Format('LM317 %d LED', [N]);
    NetzStart;
    DrawSchematicLM317(Flaeche, Rect(0, 0, 580, 300), V, Farben);
    NetzStop;
    PruefeGrundregeln(Plan);
    Verbunden(Plan, 'UB.+', 'LM317.IN');
    Verbunden(Plan, 'LM317.OUT', 'R.1');
    Verbunden(Plan, 'R.2', 'LM317.ADJ');
    KsqKette(Plan, N, 'R.2', 'UB.-');
  end;
end;

procedure TTestSchaltplan.KonstantstromTransistoren;
var
  V: TKsqSchemValues;                                    // Werte des Plans
  N: Integer;                                            // LEDs in Reihe
  Plan: string;                                          // Name für die Meldungen
begin
  for N in [1, 2, 3, 4, 30] do
  begin
    V := Default(TKsqSchemValues);
    V.LedCount := N;
    V.LedColor := clWhite;
    Plan := Format('zwei Transistoren %d LED', [N]);
    NetzStart;
    DrawSchematicKsqT(Flaeche, Rect(0, 0, 600, 300), V, Farben);
    NetzStop;
    PruefeGrundregeln(Plan);
    KsqKette(Plan, N, 'UB.+', 'T1.C');                   // LEDs von Plus zum Kollektor T1
    Verbunden(Plan, 'T1.E', 'RS.1');                     // Emitter über R_S nach Masse
    Verbunden(Plan, 'RS.2', 'UB.-');
    Verbunden(Plan, 'UB.+', 'RB.1');                     // Basisstrom über R_B
    Verbunden(Plan, 'RB.2', 'T1.B');
    Verbunden(Plan, 'T2.C', 'T1.B');                     // T2 nimmt T1 den Basisstrom
    Verbunden(Plan, 'T2.B', 'RS.1');                     // Fühler: oberes Ende R_S
    Verbunden(Plan, 'T2.E', 'UB.-');
  end;
end;

initialization
  RegisterTest(TTestSchaltplan);

finalization
  FreeAndNil(Bild);
end.
