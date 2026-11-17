{==============================================================================
  uSchemNetz - Verbindungen der Schaltpläne aufzeichnen und prüfen
==============================================================================
  Zweck:     Die Schaltpläne (uSchematic, uBlinkSchematic, uKsqSchematic)
             melden beim Zeichnen jede Leitung und jedes Bauteil mit seinen
             Anschlüssen hierher. Die Tests (TestSchaltplan) schalten die
             Aufzeichnung ein, zeichnen einen Plan und prüfen dann, welche
             Anschlüsse miteinander verbunden sind. So fällt auf, wenn eine
             Leitung im Bild an der falschen Stelle ansetzt (wie in 2.5: der
             zweite Strang hing hinter dem ersten Widerstand).

  Idee:      Alles in Vorlagen-Koordinaten (Punkte der Vorlage, nicht
             Pixel), also unabhängig von Fenstergrösse und Skalierung.
             Verbunden ist, was sich berührt:
               - zwei Leitungen, wenn ein Ende der einen auf der anderen
                 liegt (Ecke oder T-Abzweig). Kreuzen sich zwei Leitungen
                 nur in der Mitte, sind sie NICHT verbunden (wie im
                 Schaltplan üblich ohne Punkt).
               - ein Anschluss mit einer Leitung, wenn er auf ihr liegt
               - zwei Anschlüsse, wenn sie am selben Punkt liegen
             Bauteilkörper (Kasten, Dreieck, Platten) werden nicht als
             Leitung gemeldet, sonst wären die Anschlüsse kurzgeschlossen.

  Benutzung: Bauteil benennen mit NetzName('R1'), danach das Bauteil
             zeichnen; die Zeichenhilfe meldet es mit NetzBauteil. Ohne
             Namen bekommt es einen fortlaufenden Namen («R?3»). Anschlüsse
             heissen danach z. B. «R1.1», «LED1.A», «T1.B».
             Ohne NetzStart wird nichts aufgezeichnet (im Programm).

  Technik:   Reines Pascal ohne LCL. Verbindungen über Union-Find
             (jede Leitung und jeder Anschluss ist ein Element).

  Autor:     Elospeed
  Versionen: 2.5.1 17.11.2026  neu
==============================================================================}
unit uSchemNetz;

{$mode objfpc}{$H+}

interface

{==============================================================================
  AUFZEICHNEN (von den Schaltplänen aufgerufen)
==============================================================================}

{------------------------------------------------------------------------------
  NetzStart / NetzStop
------------------------------------------------------------------------------
  NetzStart löscht die bisherige Aufzeichnung und schaltet sie ein,
  NetzStop schaltet sie aus (die Daten bleiben für die Prüfung erhalten).
------------------------------------------------------------------------------}
procedure NetzStart;
procedure NetzStop;

{------------------------------------------------------------------------------
  NetzLeitung
------------------------------------------------------------------------------
  Meldet eine gerade Leitung von (X1, Y1) nach (X2, Y2).
------------------------------------------------------------------------------}
procedure NetzLeitung(X1, Y1, X2, Y2: Double);

{------------------------------------------------------------------------------
  NetzLinienzug
------------------------------------------------------------------------------
  Meldet eine Leitung durch mehrere Punkte: [X1, Y1, X2, Y2, ...].
------------------------------------------------------------------------------}
procedure NetzLinienzug(const P: array of Double);

{------------------------------------------------------------------------------
  NetzFreiesEnde
------------------------------------------------------------------------------
  Erlaubt ein freies Leitungsende bei (X, Y): Die Speiseleitungen (+U_B,
  Masse) laufen absichtlich über das letzte Bauteil hinaus.
------------------------------------------------------------------------------}
procedure NetzFreiesEnde(X, Y: Double);

{------------------------------------------------------------------------------
  NetzName
------------------------------------------------------------------------------
  Legt den Namen für das nächste gemeldete Bauteil fest (z. B. 'R_V1').
------------------------------------------------------------------------------}
procedure NetzName(const Name: string);

{------------------------------------------------------------------------------
  NetzBauteil
------------------------------------------------------------------------------
  Meldet ein Bauteil mit seinen Anschlüssen.
  Parameter: Art   - Kurzname, falls vorher kein NetzName kam ('R', 'LED')
             Namen - Namen der Anschlüsse, z. B. ['1', '2'] oder ['A', 'K']
             P     - Lage der Anschlüsse paarweise [X1, Y1, X2, Y2, ...]
------------------------------------------------------------------------------}
procedure NetzBauteil(const Art: string; const Namen: array of string; const P: array of Double);

{==============================================================================
  PRÜFEN (von den Tests aufgerufen)
==============================================================================}

{------------------------------------------------------------------------------
  NetzVerbunden
------------------------------------------------------------------------------
  True, wenn die beiden Anschlüsse (z. B. 'R1.2' und 'LED1.A') über
  Leitungen verbunden sind. Ein unbekannter Anschluss löst eine Exception
  aus, damit ein Tippfehler im Test nicht als «nicht verbunden» durchgeht.
------------------------------------------------------------------------------}
function NetzVerbunden(const A, B: string): Boolean;

{------------------------------------------------------------------------------
  NetzHat
------------------------------------------------------------------------------
  True, wenn ein Anschluss mit diesem Namen aufgezeichnet wurde.
------------------------------------------------------------------------------}
function NetzHat(const A: string): Boolean;

{------------------------------------------------------------------------------
  NetzOffeneAnschluesse
------------------------------------------------------------------------------
  Liefert alle Anschlüsse, die mit keinem anderen Anschluss verbunden sind
  (durch Komma getrennt). Leer = alle Anschlüsse sind angeschlossen.
------------------------------------------------------------------------------}
function NetzOffeneAnschluesse: string;

{------------------------------------------------------------------------------
  NetzOffeneEnden
------------------------------------------------------------------------------
  Liefert die Enden von Leitungen, die nichts berühren (weder eine andere
  Leitung noch einen Anschluss) und nicht mit NetzFreiesEnde erlaubt sind,
  als «(X|Y)». Leer = keine losen Enden.
------------------------------------------------------------------------------}
function NetzOffeneEnden: string;

{------------------------------------------------------------------------------
  NetzKurzschluesse
------------------------------------------------------------------------------
  Liefert die Bauteile, bei denen alle Anschlüsse am selben Netz hängen
  (überbrückt). Leer = kein Bauteil ist kurzgeschlossen.
------------------------------------------------------------------------------}
function NetzKurzschluesse: string;

implementation

uses
  SysUtils, Math;

{==============================================================================
  DATEN
==============================================================================}
type
  // Eine gemeldete Leitung (gerades Stück)
  TNetzLeitung = record
    X1, Y1, X2, Y2: Double;                              // Anfang und Ende (Vorlage)
  end;

  // Ein Punkt der Vorlage
  TNetzPunkt = record
    X, Y: Double;                                        // Lage (Vorlage)
  end;

  // Ein Anschluss eines Bauteils
  TNetzAnschluss = record
    Name: string;                                        // z. B. 'R1.2'
    Teil: string;                                        // Bauteil, z. B. 'R1'
    X, Y: Double;                                        // Lage (Vorlage)
  end;

const
  EPS = 0.01;                                            // Toleranz: gleicher Punkt

var
  Aktiv: Boolean;                                        // Aufzeichnung eingeschaltet
  Leitungen: array of TNetzLeitung;                      // alle Leitungsstücke
  Anschluesse: array of TNetzAnschluss;                  // alle Anschlüsse
  FreieEnden: array of TNetzPunkt;                       // erlaubte freie Leitungsenden
  NaechsterName: string;                                 // Name für das nächste Bauteil ('' = automatisch)
  Zaehler: Integer;                                      // für automatische Namen
  Eltern: array of Integer;                              // Union-Find: Leitungen 0..L-1, dann Anschlüsse
  Berechnet: Boolean;                                    // Eltern passen zur Aufzeichnung

{==============================================================================
  AUFZEICHNEN
==============================================================================}

procedure NetzStart;
begin
  Leitungen := nil;
  Anschluesse := nil;
  FreieEnden := nil;
  NaechsterName := '';
  Zaehler := 0;
  Berechnet := False;
  Aktiv := True;
end;

procedure NetzStop;
begin
  Aktiv := False;
end;

procedure NetzLeitung(X1, Y1, X2, Y2: Double);
var
  N: Integer;                                            // neue Anzahl
begin
  if not Aktiv then Exit;
  N := Length(Leitungen) + 1;
  SetLength(Leitungen, N);
  Leitungen[N - 1].X1 := X1;
  Leitungen[N - 1].Y1 := Y1;
  Leitungen[N - 1].X2 := X2;
  Leitungen[N - 1].Y2 := Y2;
  Berechnet := False;
end;

procedure NetzLinienzug(const P: array of Double);
var
  I: Integer;                                            // Zähler der Punkte
begin
  if not Aktiv then Exit;
  I := 0;
  while I + 3 <= High(P) do
  begin
    NetzLeitung(P[I], P[I + 1], P[I + 2], P[I + 3]);
    I := I + 2;
  end;
end;

procedure NetzFreiesEnde(X, Y: Double);
begin
  if not Aktiv then Exit;
  SetLength(FreieEnden, Length(FreieEnden) + 1);
  FreieEnden[High(FreieEnden)].X := X;
  FreieEnden[High(FreieEnden)].Y := Y;
end;

procedure NetzName(const Name: string);
begin
  if Aktiv then NaechsterName := Name;
end;

procedure NetzBauteil(const Art: string; const Namen: array of string; const P: array of Double);
var
  Teil: string;                                          // Name des Bauteils
  I, N: Integer;                                         // Zähler, Anzahl
begin
  if not Aktiv then Exit;
  if NaechsterName <> '' then
    Teil := NaechsterName
  else
  begin
    Inc(Zaehler);
    Teil := Art + '?' + IntToStr(Zaehler);               // unbenannt: z. B. «R?3»
  end;
  NaechsterName := '';
  for I := 0 to High(Namen) do
  begin
    N := Length(Anschluesse) + 1;
    SetLength(Anschluesse, N);
    Anschluesse[N - 1].Name := Teil + '.' + Namen[I];
    Anschluesse[N - 1].Teil := Teil;
    Anschluesse[N - 1].X := P[2 * I];
    Anschluesse[N - 1].Y := P[2 * I + 1];
  end;
  Berechnet := False;
end;

{==============================================================================
  VERBINDUNGEN BERECHNEN
==============================================================================}

{------------------------------------------------------------------------------
  AufLeitung
------------------------------------------------------------------------------
  True, wenn der Punkt (X, Y) auf der Leitung L liegt (Enden eingeschlossen).
------------------------------------------------------------------------------}
function AufLeitung(const L: TNetzLeitung; X, Y: Double): Boolean;
var
  DX, DY: Double;                                        // Richtung der Leitung
  Len2: Double;                                          // Länge im Quadrat
  T: Double;                                             // Lage des Lotfusspunkts (0 = Anfang, 1 = Ende)
  PX, PY: Double;                                        // Lotfusspunkt
begin
  DX := L.X2 - L.X1;
  DY := L.Y2 - L.Y1;
  Len2 := DX * DX + DY * DY;
  if Len2 < EPS * EPS then
    Exit((Abs(X - L.X1) < EPS) and (Abs(Y - L.Y1) < EPS));
  T := ((X - L.X1) * DX + (Y - L.Y1) * DY) / Len2;
  if (T < -EPS) or (T > 1 + EPS) then Exit(False);
  T := EnsureRange(T, 0, 1);
  PX := L.X1 + T * DX;
  PY := L.Y1 + T * DY;
  Result := Sqr(X - PX) + Sqr(Y - PY) < EPS * EPS;
end;

{------------------------------------------------------------------------------
  Wurzel / Verbinde
------------------------------------------------------------------------------
  Union-Find: Wurzel sucht den Vertreter einer Gruppe, Verbinde legt zwei
  Gruppen zusammen.
------------------------------------------------------------------------------}
function Wurzel(I: Integer): Integer;
begin
  while Eltern[I] <> I do
  begin
    Eltern[I] := Eltern[Eltern[I]];                      // Pfad verkürzen
    I := Eltern[I];
  end;
  Result := I;
end;

procedure Verbinde(A, B: Integer);
begin
  A := Wurzel(A);
  B := Wurzel(B);
  if A <> B then Eltern[A] := B;
end;

{------------------------------------------------------------------------------
  Berechne
------------------------------------------------------------------------------
  Fasst alle sich berührenden Leitungen und Anschlüsse zu Netzen zusammen.
------------------------------------------------------------------------------}
procedure Berechne;
var
  L, A: Integer;                                         // Anzahl Leitungen, Anschlüsse
  I, J: Integer;                                         // Zähler
begin
  if Berechnet then Exit;
  L := Length(Leitungen);
  A := Length(Anschluesse);
  SetLength(Eltern, L + A);
  for I := 0 to L + A - 1 do Eltern[I] := I;
  // Leitung an Leitung: ein Ende der einen liegt auf der anderen
  for I := 0 to L - 1 do
    for J := 0 to L - 1 do
      if (I <> J) and (AufLeitung(Leitungen[J], Leitungen[I].X1, Leitungen[I].Y1) or
        AufLeitung(Leitungen[J], Leitungen[I].X2, Leitungen[I].Y2)) then
        Verbinde(I, J);
  // Anschluss an Leitung
  for I := 0 to A - 1 do
    for J := 0 to L - 1 do
      if AufLeitung(Leitungen[J], Anschluesse[I].X, Anschluesse[I].Y) then
        Verbinde(L + I, J);
  // Anschluss an Anschluss (Bauteile direkt aneinander)
  for I := 0 to A - 1 do
    for J := I + 1 to A - 1 do
      if (Abs(Anschluesse[I].X - Anschluesse[J].X) < EPS) and
        (Abs(Anschluesse[I].Y - Anschluesse[J].Y) < EPS) then
        Verbinde(L + I, L + J);
  Berechnet := True;
end;

{------------------------------------------------------------------------------
  Index
------------------------------------------------------------------------------
  Liefert die Nummer des Anschlusses mit diesem Namen, sonst -1.
------------------------------------------------------------------------------}
function Index(const A: string): Integer;
var
  I: Integer;                                            // Zähler
begin
  for I := 0 to High(Anschluesse) do
    if Anschluesse[I].Name = A then Exit(I);
  Result := -1;
end;

{==============================================================================
  PRÜFEN
==============================================================================}

function NetzHat(const A: string): Boolean;
begin
  Result := Index(A) >= 0;
end;

function NetzVerbunden(const A, B: string): Boolean;
var
  IA, IB: Integer;                                       // Nummern der Anschlüsse
begin
  IA := Index(A);
  IB := Index(B);
  if IA < 0 then raise Exception.Create('Anschluss nicht gefunden: ' + A);
  if IB < 0 then raise Exception.Create('Anschluss nicht gefunden: ' + B);
  Berechne;
  Result := Wurzel(Length(Leitungen) + IA) = Wurzel(Length(Leitungen) + IB);
end;

function NetzOffeneAnschluesse: string;
var
  I, J: Integer;                                         // Zähler
  L: Integer;                                            // Anzahl Leitungen
  Allein: Boolean;                                       // kein anderer Anschluss im selben Netz
begin
  Berechne;
  Result := '';
  L := Length(Leitungen);
  for I := 0 to High(Anschluesse) do
  begin
    Allein := True;
    for J := 0 to High(Anschluesse) do
      if (I <> J) and (Wurzel(L + I) = Wurzel(L + J)) then
      begin
        Allein := False;
        Break;
      end;
    if Allein then
    begin
      if Result <> '' then Result := Result + ', ';
      Result := Result + Anschluesse[I].Name;
    end;
  end;
end;

function NetzOffeneEnden: string;
var
  I: Integer;                                            // Zähler der Leitungen
  E: Integer;                                            // 0 = Anfang, 1 = Ende

  {----------------------------------------------------------------------------
    Beruehrt
  ----------------------------------------------------------------------------
    True, wenn der Punkt eine andere Leitung als Nr. Selbst oder einen
    Anschluss berührt.
  ----------------------------------------------------------------------------}
  function Beruehrt(X, Y: Double; Selbst: Integer): Boolean;
  var
    J: Integer;                                          // Zähler
  begin
    for J := 0 to High(Leitungen) do
      if (J <> Selbst) and AufLeitung(Leitungen[J], X, Y) then Exit(True);
    for J := 0 to High(Anschluesse) do
      if (Abs(Anschluesse[J].X - X) < EPS) and (Abs(Anschluesse[J].Y - Y) < EPS) then Exit(True);
    for J := 0 to High(FreieEnden) do                    // absichtlich frei
      if (Abs(FreieEnden[J].X - X) < EPS) and (Abs(FreieEnden[J].Y - Y) < EPS) then Exit(True);
    Result := False;
  end;

var
  X, Y: Double;                                          // betrachtetes Ende
begin
  Result := '';
  for I := 0 to High(Leitungen) do
    for E := 0 to 1 do
    begin
      if E = 0 then
      begin
        X := Leitungen[I].X1;
        Y := Leitungen[I].Y1;
      end
      else
      begin
        X := Leitungen[I].X2;
        Y := Leitungen[I].Y2;
      end;
      if not Beruehrt(X, Y, I) then
      begin
        if Result <> '' then Result := Result + ', ';
        Result := Result + Format('(%g|%g)', [X, Y]);
      end;
    end;
end;

function NetzKurzschluesse: string;
var
  I, J: Integer;                                         // Zähler
  L: Integer;                                            // Anzahl Leitungen
  Anders: Boolean;                                       // ein Anschluss des Bauteils liegt an einem anderen Netz
  Mehrere: Boolean;                                      // das Bauteil hat mehr als einen Anschluss
begin
  Berechne;
  Result := '';
  L := Length(Leitungen);
  for I := 0 to High(Anschluesse) do
  begin
    // jedes Bauteil nur einmal prüfen: bei seinem ersten Anschluss
    if (I > 0) and (Anschluesse[I - 1].Teil = Anschluesse[I].Teil) then Continue;
    Anders := False;
    Mehrere := False;
    J := I + 1;
    while (J <= High(Anschluesse)) and (Anschluesse[J].Teil = Anschluesse[I].Teil) do
    begin
      Mehrere := True;
      if Wurzel(L + J) <> Wurzel(L + I) then Anders := True;
      Inc(J);
    end;
    if Mehrere and not Anders then
    begin
      if Result <> '' then Result := Result + ', ';
      Result := Result + Anschluesse[I].Teil;
    end;
  end;
end;

end.
