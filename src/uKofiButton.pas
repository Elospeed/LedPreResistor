{ Ko-fi-Knopf «Kaffee spendieren» – in allen Elospeed-Programmen gleich.
  Variante E (Wahl Speedy 29.10.2026): dunkle Pille, vorne das Symbol des
  Programms (16 px), rotes Herz, weisser fetter Text.
  Übernommen aus StemMaker (src/ustatusdraw.pas, KofiButtonWidth und
  DrawKofiButton), damit der Knopf überall genau gleich aussieht.
  Eigene Zeichnung, kein Ko-fi-Logo. Grössen gelten für 96 dpi und werden
  mit PPI umgerechnet. }
unit uKofiButton;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Types, Math, IntfGraphics, FPImage;

const
  { Farben (TColor = $00BBGGRR, Blau zuerst!) }
  CLR_KOFI           = TColor($005E5AFF);   // Ko-fi-Rot #FF5A5E (Herz)
  CLR_KOFI_FACE      = TColor($00262220);   // Pille auf hellem Grund  #202226
  CLR_KOFI_FACE_DARK = TColor($00302C2A);   // Pille auf dunklem Grund #2A2C30
  CLR_KOFI_HOVER     = TColor($00443F3C);   // Maus darüber            #3C3F44

{ Breite des Knopfs für den Text (Symbol + Herz + Text + Rand), in Pixel.
  Die Schrift der Leinwand muss schon gesetzt sein (fett). }
function KofiButtonWidth(C: TCanvas; const Text: string; PPI: Integer): Integer;

{ Zeichnet den Knopf: Hintergrund BackColor, darauf die dunkle Pille mit
  dem Programm-Symbol (AppIcon, meist Application.Icon; nil = ohne), rotem
  Herz und weissem Text, senkrecht mittig in R.
  Hover = True: Maus ist darüber, die Pille wird etwas heller. }
procedure DrawKofiButton(C: TCanvas; const R: TRect; const Text: string;
  Hover: Boolean; BackColor: TColor; PPI: Integer; AppIcon: TIcon = nil);

implementation

{ 96-dpi-Mass auf den Bildschirm umrechnen }
function ScalePx(V, PPI: Integer): Integer;
begin
  if PPI <= 0 then PPI := 96;
  Result := (V * PPI + 48) div 96;
end;

function KofiButtonWidth(C: TCanvas; const Text: string; PPI: Integer): Integer;
begin
  { 6 Rand links, 16 Symbol, 6 Abstand, 10 Herz, 6 Abstand, Text, 12 Rand rechts }
  Result := ScalePx(56, PPI) + C.TextWidth(Text);
end;

{ Ist die Farbe dunkel? (für die Wahl der Pillenfarbe) }
function IsDarkColor(Col: TColor): Boolean;
var
  RGB: LongInt;  // Farbe als echter RGB-Wert (keine Systemfarbe)
begin
  RGB := ColorToRGB(Col);
  Result := (Red(RGB) * 299 + Green(RGB) * 587 + Blue(RGB) * 114) div 1000 < 100;
end;

{ Pille und Herz geglättet zeichnen: GDI zeichnet Rundungen ohne
  Kantenglättung (treppig). Darum vierfach so gross zeichnen und dann
  je 4 x 4 Punkte zu einem mitteln.
    B      Rechteck der Pille auf C
    HeartX Mitte des Herzens (x, auf C), HeartY Mitte der Herzkreise
    D      Durchmesser der Herzkreise }
procedure DrawSmoothPill(C: TCanvas; const B: TRect; PillColor, BackColor: TColor;
  HeartX, HeartY, D: Integer);
const
  SS = 4;   // Vergrösserung beim Zeichnen
var
  Big, Small: TBitmap;              // gross gezeichnet, verkleinert
  BigImg, SmallImg: TLazIntfImage;  // Pixelzugriff auf beide
  W, H: Integer;                    // Grösse der Pille
  X, Y, I, J: Integer;              // Zählvariablen
  HX, HY, DD: Integer;              // Herz im grossen Bild
  R, G, Bl: Cardinal;               // Farbsummen beim Mitteln
  Px: TFPColor;                     // ein Bildpunkt
begin
  W := B.Right - B.Left;
  H := B.Bottom - B.Top;
  if (W <= 0) or (H <= 0) then Exit;
  Big := TBitmap.Create;
  Small := TBitmap.Create;
  BigImg := nil;
  SmallImg := nil;
  try
    Big.PixelFormat := pf24bit;
    Big.SetSize(W * SS, H * SS);
    with Big.Canvas do
    begin
      // Systemfarben in echte Farben umrechnen, sonst bleibt der Grund schwarz
      Brush.Color := ColorToRGB(BackColor);
      FillRect(0, 0, W * SS, H * SS);
      Brush.Color := PillColor;
      Pen.Color := PillColor;
      RoundRect(0, 0, W * SS, H * SS, H * SS, H * SS);
      // Herz aus zwei Kreisen und einem Dreieck (nicht jede Schrift hat ♥)
      HX := (HeartX - B.Left) * SS;
      HY := (HeartY - B.Top) * SS;
      DD := D * SS;
      Brush.Color := CLR_KOFI;
      Pen.Color := CLR_KOFI;
      Ellipse(HX - DD, HY - DD div 2, HX + SS, HY + DD div 2 + SS);
      Ellipse(HX, HY - DD div 2, HX + DD + SS, HY + DD div 2 + SS);
      Polygon([Point(HX - DD + SS div 2, HY + SS), Point(HX + DD + SS div 2, HY + SS),
        Point(HX + SS div 2, HY + DD + SS)]);
    end;

    BigImg := Big.CreateIntfImage;
    Small.PixelFormat := pf24bit;
    Small.SetSize(W, H);
    SmallImg := Small.CreateIntfImage;
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        R := 0; G := 0; Bl := 0;
        for J := 0 to SS - 1 do
          for I := 0 to SS - 1 do
          begin
            Px := BigImg.Colors[X * SS + I, Y * SS + J];
            Inc(R, Px.Red); Inc(G, Px.Green); Inc(Bl, Px.Blue);
          end;
        Px.Red := R div (SS * SS);
        Px.Green := G div (SS * SS);
        Px.Blue := Bl div (SS * SS);
        Px.Alpha := alphaOpaque;
        SmallImg.Colors[X, Y] := Px;
      end;
    Small.LoadFromIntfImage(SmallImg);
    C.Draw(B.Left, B.Top, Small);
  finally
    SmallImg.Free;
    BigImg.Free;
    Small.Free;
    Big.Free;
  end;
end;

procedure DrawKofiButton(C: TCanvas; const R: TRect; const Text: string;
  Hover: Boolean; BackColor: TColor; PPI: Integer; AppIcon: TIcon);
var
  B, IR: TRect;     // der Knopf selbst, das Symbol
  H: Integer;       // Höhe der Pille
  HX, HY, D: Integer; // Mitte und Kreisdurchmesser des Herzens
  X, S: Integer;    // linker Rand des Symbols, Symbolgrösse
  Col: TColor;      // Farbe der Pille
begin
  // clDefault (Panel ohne eigene Farbe) wäre in der Bitmap schwarz
  if (BackColor = clDefault) or (BackColor = clNone) then
    BackColor := clBtnFace;
  BackColor := ColorToRGB(BackColor);
  C.Brush.Style := bsSolid;
  C.Brush.Color := BackColor;
  C.FillRect(R);

  // Pille: so hoch wie die Schrift plus etwas Luft, ganz runde Enden
  H := Min(R.Bottom - R.Top - ScalePx(2, PPI),
    Max(C.TextHeight('Ag') + ScalePx(8, PPI), ScalePx(22, PPI)));
  B := Rect(R.Left, (R.Top + R.Bottom - H) div 2, R.Right, 0);
  B.Bottom := B.Top + H;
  if Hover then
    Col := CLR_KOFI_HOVER
  else if IsDarkColor(BackColor) then
    Col := CLR_KOFI_FACE_DARK
  else
    Col := CLR_KOFI_FACE;

  // Lage von Symbol und Herz
  X := B.Left + ScalePx(7, PPI);
  S := ScalePx(16, PPI);
  D := ScalePx(5, PPI);
  HX := X + S + ScalePx(6, PPI) + D;
  HY := (B.Top + B.Bottom) div 2 - ScalePx(2, PPI);
  DrawSmoothPill(C, B, Col, BackColor, HX, HY, D);

  // vorne das Symbol des Programms (16 px bei 100 %)
  if (AppIcon <> nil) and not AppIcon.Empty then
  begin
    AppIcon.Current := AppIcon.GetBestIndexForSize(Size(S, S));
    IR := Rect(X, (B.Top + B.Bottom - S) div 2, X + S, (B.Top + B.Bottom - S) div 2 + S);
    C.StretchDraw(IR, AppIcon);
  end;

  // Text weiss
  C.Brush.Style := bsClear;
  C.Font.Color := clWhite;
  C.TextOut(HX + D + ScalePx(6, PPI), (B.Top + B.Bottom - C.TextHeight('Ag')) div 2, Text);
end;

end.
