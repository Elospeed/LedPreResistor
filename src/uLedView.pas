{==============================================================================
  uLedView - LED-Vorschau: realistische 5-mm-LED
==============================================================================
  Zweck:     Zeichnet die LED rechts im Fenster in der gewählten Farbe, mit
             Leuchtschein und Beschriftung der Beine (Anode +, Kathode −,
             flache Seite). Beim Blinken wechselt die Helligkeit.

  Idee:      Ohne Zusatzbibliothek: Für jedes Pixel wird ausgerechnet, was an
             dieser Stelle liegt (Schein, Bein, Kuppel, Chip, Kragen ...),
             und die Farben werden übereinander gemischt. Jedes Pixel wird
             3 × 3-mal abgetastet und gemittelt, so werden die Ränder glatt.
             Die Beschriftung schreibt danach die LCL-Canvas darüber.

  Masse:     Alle Masse gelten für eine Vorlage von 200 × 250 Punkten
             (Entwurf A «Labor 2»). Die Vorlage wird in die Bildgrösse
             eingepasst; das Seitenverhältnis bleibt.

  Plattform: Windows und Linux brauchen ein unterschiedliches Bildformat
             (siehe RenderLed).

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  Kommentare ausführlicher
             2.2  09.11.2026  Bildformat für Linux
             2.0  29.10.2026  erste Fassung
==============================================================================}
unit uLedView;

{$mode objfpc}{$H+}

interface

uses
  Graphics;

{==============================================================================
  TYPEN
==============================================================================}
type
  // Texte der Beschriftung (übersetzbar, darum von aussen übergeben)
  TLedLabels = record
    Anode: string;                                       // z. B. "Anode +"
    AnodeHint: string;                                   // z. B. "langes Bein"
    Cathode: string;                                     // z. B. "Kathode −"
    CathodeHint1: string;                                // z. B. "kurzes Bein,"
    CathodeHint2: string;                                // z. B. "flache Seite"
    Flat: string;                                        // z. B. "flach"
  end;

{==============================================================================
  ÖFFENTLICHE FUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  RenderLed
------------------------------------------------------------------------------
  Zeichnet die LED mit Beschriftung in ein Bild.
  Parameter: Bmp        - Zielbild; wird auf W × H gesetzt
             W, H       - Grösse in Pixel
             LedColor   - Leuchtfarbe der LED
             Back       - Hintergrundfarbe
             Glow       - Helligkeit: 0 = aus, 1 = voll leuchtend
             Labels     - Beschriftung der Beine (in der gewählten Sprache)
             LabelColor - Farbe der Beschriftung
------------------------------------------------------------------------------}
procedure RenderLed(Bmp: TBitmap; W, H: Integer; LedColor, Back: TColor;
  Glow: Double; const Labels: TLedLabels; LabelColor: TColor);

implementation

uses
  Math, IntfGraphics, GraphType, FPImage, LCLType, LCLIntf, uTheme;

{==============================================================================
  KONSTANTEN UND TYPEN
==============================================================================}
const
  BASE_W = 200;                                          // Breite der Vorlage
  BASE_H = 250;                                          // Höhe der Vorlage
  SS = 3;                                                // Unterabtastung je Achse (3 × 3 Proben pro Pixel)

type
  // Farbe mit Kanälen 0 ... 1 für die Mischrechnung
  TRGB = record
    R, G, B: Double;
  end;

{==============================================================================
  HILFSFUNKTIONEN: FARBEN UND GEOMETRIE
==============================================================================}

{------------------------------------------------------------------------------
  ToRGB
------------------------------------------------------------------------------
  Wandelt eine TColor (auch Systemfarbe) in TRGB mit Kanälen 0 ... 1.
------------------------------------------------------------------------------}
function ToRGB(C: TColor): TRGB;
begin
  C := ColorToRGB(C);                                    // Systemfarbe -> echte Farbe
  Result.R := Red(C) / 255;
  Result.G := Green(C) / 255;
  Result.B := Blue(C) / 255;
end;

{------------------------------------------------------------------------------
  Blend
------------------------------------------------------------------------------
  Legt Farbe C mit der Deckkraft A über den Grund P.
  Parameter: P - Grund; wird zum Ergebnis
             C - darübergelegte Farbe
             A - Deckkraft: 0 = unsichtbar, 1 = deckt ganz
  Beispiel:  Grund schwarz, C weiss, A = 0,5 -> Grau
------------------------------------------------------------------------------}
procedure Blend(var P: TRGB; const C: TRGB; A: Double);
begin
  if A <= 0 then Exit;                                   // nichts zu mischen
  if A > 1 then A := 1;                                  // höchstens ganz deckend
  P.R := P.R + (C.R - P.R) * A;
  P.G := P.G + (C.G - P.G) * A;
  P.B := P.B + (C.B - P.B) * A;
end;

{------------------------------------------------------------------------------
  Ramp3
------------------------------------------------------------------------------
  Gerader Verlauf über drei Stützstellen: bei T = 0 gilt V0, bei T = M
  gilt VM, bei T = 1 gilt V1; dazwischen wird gerade verbunden.
  Gebraucht für Leuchtschein und Farbverlauf der Kuppel.
  Rückgabe:  Wert an der Stelle T (ausserhalb 0 ... 1 = V0 bzw. V1)
------------------------------------------------------------------------------}
function Ramp3(T, V0, M, VM, V1: Double): Double;
begin
  if T <= 0 then Exit(V0);
  if T >= 1 then Exit(V1);
  if T < M then
    Result := V0 + (VM - V0) * (T / M)
  else
    Result := VM + (V1 - VM) * ((T - M) / (1 - M));
end;

{------------------------------------------------------------------------------
  SegDist
------------------------------------------------------------------------------
  Kürzester Abstand des Punkts (PX, PY) zur Strecke (AX, AY)-(BX, BY).
  So werden die Beine gezeichnet: Punkt gehört zum Bein, wenn der
  Abstand zur Mittellinie höchstens die halbe Beinbreite ist.
------------------------------------------------------------------------------}
function SegDist(PX, PY, AX, AY, BX, BY: Double): Double;
var
  DX, DY, T: Double;                                     // Richtung der Strecke und Projektion
begin
  DX := BX - AX;
  DY := BY - AY;
  T := ((PX - AX) * DX + (PY - AY) * DY) / (DX * DX + DY * DY);  // Lotfusspunkt auf der Geraden
  T := EnsureRange(T, 0, 1);                             // aber nicht über die Enden hinaus
  Result := Hypot(PX - (AX + T * DX), PY - (AY + T * DY));
end;

{------------------------------------------------------------------------------
  InDome
------------------------------------------------------------------------------
  Prüft, ob (X, Y) im Kuppelkörper liegt: Rechteck 60 ... 140 × 72 ... 141
  mit einem Halbkreis (Mitte 100/72, Radius 40) oben drauf.
------------------------------------------------------------------------------}
function InDome(X, Y: Double): Boolean;
begin
  if (X < 60) or (X > 140) or (Y > 141) then
    Exit(False);
  if Y >= 72 then
    Exit(True);
  Result := Sqr(X - 100) + Sqr(Y - 72) <= 1600;          // im Kreis: Abstand² <= 40²
end;

{------------------------------------------------------------------------------
  InPost
------------------------------------------------------------------------------
  Prüft, ob (X, Y) im Kathoden-Träger liegt (der grössere Metallteil in
  der LED, auf dem der Chip sitzt).
------------------------------------------------------------------------------}
function InPost(X, Y: Double): Boolean;
begin
  // Polygon 106,141 106,96 110,96 108,88 128,88 126,96 130,96 130,141 als
  // Rechteck unten plus Trapez oben
  if (Y >= 96) and (Y <= 141) then
    Exit((X >= 106) and (X <= 130));
  if (Y >= 88) and (Y < 96) then
    // Trapez: links von 108 (oben) nach 110 (unten), rechts von 128 nach 126
    Exit((X >= 108 + (Y - 88) / 4) and (X <= 128 - (Y - 88) / 4));
  Result := False;
end;

{==============================================================================
  BILD RECHNEN
==============================================================================}

{------------------------------------------------------------------------------
  Sample
------------------------------------------------------------------------------
  Berechnet die Farbe eines Abtastpunkts. Die Schichten werden von hinten
  nach vorne übereinander gelegt (Schritte 1 bis 8 im Code).
  Parameter: X, Y  - Punkt in Vorlagen-Koordinaten (0 ... 200, 0 ... 250)
             Back  - Hintergrund
             Led   - Leuchtfarbe
             Off   - Farbe der ausgeschalteten Kuppel (dunkles Grau)
             Glow  - Helligkeit 0 ... 1
  Rückgabe:  Farbe an diesem Punkt
------------------------------------------------------------------------------}
function Sample(X, Y: Double; const Back, Led, Off: TRGB; Glow: Double): TRGB;
const
  Leg: TRGB = (R: $B9 / 255; G: $C0 / 255; B: $C8 / 255);  // Beine (hellgrau)
  Anvil: TRGB = (R: $9A / 255; G: $A2 / 255; B: $AB / 255);  // Anodenstift
  PostC: TRGB = (R: $8A / 255; G: $92 / 255; B: $9B / 255);  // Kathoden-Träger
  White: TRGB = (R: 1; G: 1; B: 1);                      // Glanz, leuchtender Chip
  Grey: TRGB = (R: $55 / 255; G: $55 / 255; B: $55 / 255);  // Chip ausgeschaltet
var
  D, T, A: Double;                                       // Abstand, Gradientposition, Deckkraft
begin
  Result := Back;

  // 1. Leuchtschein rund um die LED (radial, Mitte 100/78, Radius 100)
  D := Hypot(X - 100, Y - 78) / 100;
  if D < 1 then
    Blend(Result, Led, Ramp3(D, 0.75 * Glow, 0.45, 0.28 * Glow, 0));

  // 2. Beine: Anode gerade (lang), Kathode mit Knick (kurz)
  if SegDist(X, Y, 82, 140, 82, 236) <= 2.25 then
    Result := Leg;
  if (SegDist(X, Y, 118, 140, 118, 170) <= 2.25) or
     (SegDist(X, Y, 118, 170, 126, 180) <= 2.25) or
     (SegDist(X, Y, 126, 180, 126, 206) <= 2.25) then
    Result := Leg;

  // 3. Kuppel: dunkler Grund, darüber die Farbe mit seitlichem Verlauf
  if InDome(X, Y) then
  begin
    Result := Off;
    T := (X - 60) / 80;
    Blend(Result, Led, Ramp3(T, 0.35 + 0.35 * Glow, 0.55, 0.55 + 0.45 * Glow, 0.3 + 0.3 * Glow));

    // 4. Innenleben: Anodenstift und Kathoden-Träger
    if (X >= 79) and (X <= 86) and (Y >= 96) then
      Result := Anvil;
    if InPost(X, Y) then
      Result := PostC;

    // 5. Leuchtpunkt über dem Chip (Ellipse 118/87, 34 × 30)
    D := Sqr((X - 118) / 34) + Sqr((Y - 87) / 30);
    if D < 1 then
    begin
      T := Hypot(X - 118, Y - 87) / 34;
      if T < 0.35 then
      begin
        // innen von Weiss zur LED-Farbe
        A := T / 0.35;
        Blend(Result, White, Glow * (1 - A));
        Blend(Result, Led, 0.9 * Glow * A);
      end
      else
        Blend(Result, Led, 0.9 * Glow * (1 - (T - 0.35) / 0.65));
    end;

    // 6. Chip
    if (X >= 115) and (X <= 121) and (Y >= 84) and (Y <= 88) then
      if Glow > 0.2 then Result := White else Result := Grey;

    // 7. Glanzlicht links (senkrechter Strich und Bogen)
    D := SegDist(X, Y, 68, 74, 68, 128);
    if (X < 100) and (Y < 74) and (Y > 44) then
      D := Min(D, Abs(Hypot(X - 100, Y - 74) - 32));
    if D <= 2.5 then
      Blend(Result, White, 0.45);

    // feiner heller Rand: Nachbarpunkt liegt schon ausserhalb der Kuppel
    if not InDome(X - 1.2, Y) or not InDome(X + 1.2, Y) or not InDome(X, Y - 1.2) then
      Blend(Result, White, 0.35);
  end;

  // 8. Kragen unten (flache Seite rechts)
  if (X >= 50) and (X <= 140) and (Y >= 141) and (Y <= 154) then
  begin
    Result := Off;
    Blend(Result, Led, 0.45 + 0.3 * Glow);
    if (Y < 142.2) or (Y > 152.8) or (X < 51.2) then
      Blend(Result, White, 0.3);
  end;
end;

{------------------------------------------------------------------------------
  RenderLed - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Farben umrechnen, Vorlage einpassen (Scale, OX, OY)
    2. Bild im passenden Pixelformat anlegen (Windows / Linux)
    3. Jedes Pixel 3 × 3-mal abtasten (Sample) und mitteln
    4. Bild an Bmp übergeben
    5. Beschriftung mit der Canvas darüberschreiben
------------------------------------------------------------------------------}
procedure RenderLed(Bmp: TBitmap; W, H: Integer; LedColor, Back: TColor;
  Glow: Double; const Labels: TLedLabels; LabelColor: TColor);
var
  Img: TLazIntfImage;                                    // Pixelbild, in das gerechnet wird
  Scale: Double;                                         // Vorlagen-Punkte pro Pixel
  OX, OY: Double;                                        // Versatz, damit die LED zentriert ist
  PX, PY, SX, SY: Integer;                               // Pixel und Unterabtastung
  Acc, C: TRGB;                                          // Summe der Proben, einzelne Probe
  BackC, LedC, OffC: TRGB;                               // Grundfarben
  Desc: TRawImageDescription;                            // Pixelformat des Bilds
  ImgH: HBITMAP;                                         // Handle des Bilds für die Übergabe an TBitmap
  MaskH: HBITMAP;                                        // Handle der Maske (wird nicht gebraucht)

  {----------------------------------------------------------------------------
    PX2
  ----------------------------------------------------------------------------
    Wandelt eine waagrechte Vorlagen-Koordinate in Pixel um.
  ----------------------------------------------------------------------------}
  function PX2(V: Double): Integer;
  begin
    Result := Round(OX + V / Scale);
  end;

  {----------------------------------------------------------------------------
    PY2
  ----------------------------------------------------------------------------
    Wandelt eine senkrechte Vorlagen-Koordinate in Pixel um.
  ----------------------------------------------------------------------------}
  function PY2(V: Double): Integer;
  begin
    Result := Round(OY + V / Scale);
  end;

begin
  // ----- 1. Farben und Massstab -----
  if (W < 10) or (H < 10) then
    Exit;                                                // zu klein
  BackC := ToRGB(Back);
  LedC := ToRGB(LedColor);
  OffC := ToRGB(RGBToColor($3A, $3F, $47));              // Kuppel ausgeschaltet

  // Vorlage so gross wie möglich einpassen, Seitenverhältnis bleibt
  Scale := Max(BASE_W / W, BASE_H / H);                  // die knappere Richtung bestimmt
  OX := (W - BASE_W / Scale) / 2;
  OY := (H - BASE_H / Scale) / 2;                        // mittig

  // ----- 2. Bild anlegen -----
  {$IFDEF WINDOWS}
  Img := TLazIntfImage.Create(0, 0);
  {$ELSE}
  // Linux (GTK2): Das Pixelformat muss zum Fenstersystem passen, sonst
  // scheitert CreateBitmaps ("Incompatible BitsPerPixel"). Darum das Bild
  // von einer 24-Bit-Bitmap holen und am Ende zurückschreiben.
  Bmp.PixelFormat := pf24bit;
  Bmp.SetSize(W, H);
  Img := Bmp.CreateIntfImage;
  {$ENDIF}
  try
    {$IFDEF WINDOWS}
    // 24 Bit ohne Alphakanal: Text, den GDI danach ins Bild schreibt, hätte
    // sonst Alpha 0 und wäre unter Windows unsichtbar
    Desc.Init_BPP24_B8G8R8_BIO_TTB(W, H);
    Img.DataDescription := Desc;
    {$ENDIF}
    // ----- 3. Jedes Pixel abtasten und mitteln -----
    for PY := 0 to H - 1 do
      for PX := 0 to W - 1 do
      begin
        Acc.R := 0; Acc.G := 0; Acc.B := 0;              // Summe leeren
        for SY := 0 to SS - 1 do
          for SX := 0 to SS - 1 do
          begin
            // Probe in der Mitte des Teilfelds, in Vorlagen-Koordinaten
            C := Sample(((PX + (SX + 0.5) / SS) - OX) * Scale,
                        ((PY + (SY + 0.5) / SS) - OY) * Scale,
                        BackC, LedC, OffC, Glow);
            Acc.R := Acc.R + C.R;
            Acc.G := Acc.G + C.G;
            Acc.B := Acc.B + C.B;
          end;
        Img.Colors[PX, PY] := FPColor(                   // Mittelwert, 16 Bit je Kanal
          Round(Acc.R / (SS * SS) * $FFFF),
          Round(Acc.G / (SS * SS) * $FFFF),
          Round(Acc.B / (SS * SS) * $FFFF));
      end;
    // ----- 4. An Bmp übergeben -----
    {$IFDEF WINDOWS}
    // ohne Maske: sonst zeichnet Windows Teile des Bilds (und die
    // Beschriftung) durchsichtig
    Img.CreateBitmaps(ImgH, MaskH, True);
    Bmp.Handle := ImgH;
    {$ELSE}
    Bmp.LoadFromIntfImage(Img);
    {$ENDIF}
  finally
    Img.Free;
  end;

  // ----- 5. Beschriftung -----
  with Bmp.Canvas do
  begin
    Brush.Style := bsClear;
    Font.Name := FONT_UI;
    Font.Color := LabelColor;
    Font.Height := -Max(9, Round(13 / Scale));           // mindestens 9 Pixel
    Font.Style := [fsBold];
    TextOut(PX2(74) - TextWidth(Labels.Anode), PY2(200) - TextHeight('A'), Labels.Anode);  // links vom Anodenbein
    TextOut(PX2(136), PY2(192) - TextHeight('A'), Labels.Cathode);  // rechts vom Kathodenbein
    Font.Style := [];
    Font.Height := -Max(8, Round(10.5 / Scale));
    TextOut(PX2(74) - TextWidth(Labels.AnodeHint), PY2(215) - TextHeight('A'), Labels.AnodeHint);
    TextOut(PX2(136), PY2(207) - TextHeight('A'), Labels.CathodeHint1);
    TextOut(PX2(136), PY2(220) - TextHeight('A'), Labels.CathodeHint2);
    // gestrichelte Linie zur flachen Seite und "flach"
    Pen.Color := LabelColor;
    Pen.Style := psDot;
    Pen.Width := 1;
    Line(PX2(146), PY2(147), PX2(168), PY2(147));
    Pen.Style := psSolid;
    Font.Height := -Max(8, Round(10 / Scale));
    TextOut(PX2(171), PY2(147) - TextHeight('f') div 2, Labels.Flat);
  end;
end;

end.
