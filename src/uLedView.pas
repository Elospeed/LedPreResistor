{ Realistische 5-mm-LED für die LED-Vorschau, nach Entwurf A «Labor 2».
  Ohne Zusatzbibliothek: Das Bild wird Pixel für Pixel in ein TLazIntfImage
  gerechnet (mit 3×3-Kantenglättung und echter Transparenz für den
  Leuchtschein) und danach als TBitmap angezeigt. Die Beschriftung
  (Anode/Kathode/flach) zeichnet die LCL-Canvas darüber.
  Alle Masse beziehen sich auf eine Vorlage von 200 × 250 Punkten. }
unit uLedView;

{$mode objfpc}{$H+}

interface

uses
  Graphics;

type
  { Texte der Beschriftung (übersetzbar, darum von aussen übergeben) }
  TLedLabels = record
    Anode: string;      // z. B. "Anode +"
    AnodeHint: string;  // z. B. "langes Bein"
    Cathode: string;    // z. B. "Kathode −"
    CathodeHint1: string; // z. B. "kurzes Bein,"
    CathodeHint2: string; // z. B. "flache Seite"
    Flat: string;       // z. B. "flach"
  end;

{ Zeichnet die LED in Bmp (Grösse W × H, Hintergrund Back).
  LedColor = Leuchtfarbe, Glow = Helligkeit 0 (aus) bis 1 (voll). }
procedure RenderLed(Bmp: TBitmap; W, H: Integer; LedColor, Back: TColor;
  Glow: Double; const Labels: TLedLabels; LabelColor: TColor);

implementation

uses
  Math, IntfGraphics, GraphType, FPImage, LCLType, LCLIntf;

const
  BASE_W = 200;   // Breite der Vorlage
  BASE_H = 250;   // Höhe der Vorlage
  SS = 3;         // Unterabtastung je Achse (3 × 3 Proben pro Pixel)

type
  { Farbe mit Kanälen 0..1 für die Mischrechnung }
  TRGB = record
    R, G, B: Double;
  end;

{ Wandelt eine TColor in TRGB (0..1) }
function ToRGB(C: TColor): TRGB;
begin
  C := ColorToRGB(C);
  Result.R := Red(C) / 255;
  Result.G := Green(C) / 255;
  Result.B := Blue(C) / 255;
end;

{ Mischt Farbe C mit Deckkraft A (0..1) über Grund P }
procedure Blend(var P: TRGB; const C: TRGB; A: Double);
begin
  if A <= 0 then Exit;
  if A > 1 then A := 1;
  P.R := P.R + (C.R - P.R) * A;
  P.G := P.G + (C.G - P.G) * A;
  P.B := P.B + (C.B - P.B) * A;
end;

{ Lineare Interpolation zwischen drei Stützstellen (0, M, 1) }
function Ramp3(T, V0, M, VM, V1: Double): Double;
begin
  if T <= 0 then Exit(V0);
  if T >= 1 then Exit(V1);
  if T < M then
    Result := V0 + (VM - V0) * (T / M)
  else
    Result := VM + (V1 - VM) * ((T - M) / (1 - M));
end;

{ Abstand des Punkts (PX, PY) zur Strecke (AX, AY)-(BX, BY) }
function SegDist(PX, PY, AX, AY, BX, BY: Double): Double;
var
  DX, DY, T: Double;  // Richtung der Strecke und Projektion
begin
  DX := BX - AX;
  DY := BY - AY;
  T := ((PX - AX) * DX + (PY - AY) * DY) / (DX * DX + DY * DY);
  T := EnsureRange(T, 0, 1);
  Result := Hypot(PX - (AX + T * DX), PY - (AY + T * DY));
end;

{ Liegt (X, Y) im Kuppelkörper? Rechteck 60..140 × 72..141 mit Halbkreis
  (Mitte 100/72, Radius 40) oben drauf. }
function InDome(X, Y: Double): Boolean;
begin
  if (X < 60) or (X > 140) or (Y > 141) then
    Exit(False);
  if Y >= 72 then
    Exit(True);
  Result := Sqr(X - 100) + Sqr(Y - 72) <= 1600;
end;

{ Liegt (X, Y) im Kathoden-Träger (der grössere Metallteil in der LED)? }
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

{ Berechnet die Farbe eines Abtastpunkts (in Vorlagen-Koordinaten) }
function Sample(X, Y: Double; const Back, Led, Off: TRGB; Glow: Double): TRGB;
const
  Leg: TRGB = (R: $B9 / 255; G: $C0 / 255; B: $C8 / 255);
  Anvil: TRGB = (R: $9A / 255; G: $A2 / 255; B: $AB / 255);
  PostC: TRGB = (R: $8A / 255; G: $92 / 255; B: $9B / 255);
  White: TRGB = (R: 1; G: 1; B: 1);
  Grey: TRGB = (R: $55 / 255; G: $55 / 255; B: $55 / 255);
var
  D, T, A: Double;  // Abstand, Gradientposition, Deckkraft
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

    // feiner heller Rand
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

procedure RenderLed(Bmp: TBitmap; W, H: Integer; LedColor, Back: TColor;
  Glow: Double; const Labels: TLedLabels; LabelColor: TColor);
var
  Img: TLazIntfImage;   // Pixelbild, in das gerechnet wird
  Scale: Double;        // Vorlagen-Punkte pro Pixel
  OX, OY: Double;       // Versatz, damit die LED zentriert ist
  PX, PY, SX, SY: Integer; // Pixel und Unterabtastung
  Acc, C: TRGB;         // Summe der Proben, einzelne Probe
  BackC, LedC, OffC: TRGB; // Grundfarben
  Desc: TRawImageDescription; // Pixelformat des Bilds
  ImgH: HBITMAP;        // Handles für die Übergabe an TBitmap
  MaskH: HBITMAP;

  { Wandelt Vorlagen-Koordinaten in Pixel }
  function PX2(V: Double): Integer;
  begin
    Result := Round(OX + V / Scale);
  end;

  function PY2(V: Double): Integer;
  begin
    Result := Round(OY + V / Scale);
  end;

begin
  if (W < 10) or (H < 10) then
    Exit;
  BackC := ToRGB(Back);
  LedC := ToRGB(LedColor);
  OffC := ToRGB(RGBToColor($3A, $3F, $47));

  // Vorlage so gross wie möglich einpassen, Seitenverhältnis bleibt
  Scale := Max(BASE_W / W, BASE_H / H);
  OX := (W - BASE_W / Scale) / 2;
  OY := (H - BASE_H / Scale) / 2;

  Img := TLazIntfImage.Create(0, 0);
  try
    // 24 Bit ohne Alphakanal: Text, den GDI danach ins Bild schreibt, hätte
    // sonst Alpha 0 und wäre unter Windows unsichtbar
    Desc.Init_BPP24_B8G8R8_BIO_TTB(W, H);
    Img.DataDescription := Desc;
    for PY := 0 to H - 1 do
      for PX := 0 to W - 1 do
      begin
        Acc.R := 0; Acc.G := 0; Acc.B := 0;
        for SY := 0 to SS - 1 do
          for SX := 0 to SS - 1 do
          begin
            C := Sample(((PX + (SX + 0.5) / SS) - OX) * Scale,
                        ((PY + (SY + 0.5) / SS) - OY) * Scale,
                        BackC, LedC, OffC, Glow);
            Acc.R := Acc.R + C.R;
            Acc.G := Acc.G + C.G;
            Acc.B := Acc.B + C.B;
          end;
        Img.Colors[PX, PY] := FPColor(
          Round(Acc.R / (SS * SS) * $FFFF),
          Round(Acc.G / (SS * SS) * $FFFF),
          Round(Acc.B / (SS * SS) * $FFFF));
      end;
    // ohne Maske: sonst zeichnet Windows Teile des Bilds (und die
    // Beschriftung) durchsichtig
    Img.CreateBitmaps(ImgH, MaskH, True);
    Bmp.Handle := ImgH;
  finally
    Img.Free;
  end;

  // Beschriftung
  with Bmp.Canvas do
  begin
    Brush.Style := bsClear;
    Font.Name := 'Segoe UI';
    Font.Color := LabelColor;
    Font.Height := -Max(9, Round(13 / Scale));
    Font.Style := [fsBold];
    TextOut(PX2(74) - TextWidth(Labels.Anode), PY2(200) - TextHeight('A'), Labels.Anode);
    TextOut(PX2(136), PY2(192) - TextHeight('A'), Labels.Cathode);
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
