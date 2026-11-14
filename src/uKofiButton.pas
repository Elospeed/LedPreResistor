{==============================================================================
  uKofiButton - Ko-fi-Knopf «Kaffee spendieren»
==============================================================================
  Zweck:     Zeichnet den Spendenknopf unten rechts in der Fusszeile. Er sieht
             in allen Elospeed-Programmen gleich aus.

  Aussehen:  Variante E (gewählt am 29.10.2026): dunkle Pille, vorne das
             Symbol des Programms (16 px), rotes Herz, weisser fetter Text.
             Eigene Zeichnung, kein Ko-fi-Logo (keine Lizenzfrage).

  Technik:   Die runde Pille und das Herz werden vierfach so gross gezeichnet
             und dann verkleinert (je 4 × 4 Punkte gemittelt). So werden die
             Rundungen glatt statt treppig.
             Alle Masse gelten für 96 dpi (100 %) und werden mit PPI auf die
             Bildschirm-Skalierung umgerechnet.

  Herkunft:  Übernommen aus StemMaker (src/ustatusdraw.pas, KofiButtonWidth
             und DrawKofiButton), damit der Knopf überall genau gleich ist.

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  Kommentare ausführlicher
             2.0  29.10.2026  erste Fassung (aus StemMaker übernommen)
==============================================================================}
unit uKofiButton;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Types, Math, IntfGraphics, FPImage;

{==============================================================================
  KONSTANTEN
==============================================================================}
const
  // Farben. Achtung: TColor ist $00BBGGRR, also Blau zuerst!
  CLR_KOFI           = TColor($005E5AFF);                // Ko-fi-Rot #FF5A5E (Herz)
  CLR_KOFI_FACE      = TColor($00262220);                // Pille auf hellem Grund  #202226
  CLR_KOFI_FACE_DARK = TColor($00302C2A);                // Pille auf dunklem Grund #2A2C30
  CLR_KOFI_HOVER     = TColor($00443F3C);                // Maus darüber            #3C3F44

{==============================================================================
  ÖFFENTLICHE FUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  KofiButtonWidth
------------------------------------------------------------------------------
  Parameter: C    - Leinwand; ihre Schrift muss schon gesetzt sein (fett)
             Text - Beschriftung, z. B. «Kaffee spendieren»
             PPI  - Bildschirm-Auflösung (96 = 100 %)
  Rückgabe:  Breite des ganzen Knopfs in Pixel
             (Rand + Symbol + Herz + Text + Rand)
------------------------------------------------------------------------------}
function KofiButtonWidth(C: TCanvas; const Text: string; PPI: Integer): Integer;

{------------------------------------------------------------------------------
  DrawKofiButton
------------------------------------------------------------------------------
  Zeichnet den Knopf senkrecht mittig in R: Hintergrund, darauf die
  dunkle Pille mit Programm-Symbol, rotem Herz und weissem Text.

  Parameter: C         - Leinwand, auf die gezeichnet wird
             R         - Platz für den Knopf (Breite aus KofiButtonWidth)
             Text      - Beschriftung
             Hover     - True: Maus ist darüber, Pille etwas heller
             BackColor - Farbe des Untergrunds (Fusszeile)
             PPI       - Bildschirm-Auflösung (96 = 100 %)
             AppIcon   - Programm-Symbol, meist Application.Icon;
                         nil = ohne Symbol
------------------------------------------------------------------------------}
procedure DrawKofiButton(C: TCanvas; const R: TRect; const Text: string;
  Hover: Boolean; BackColor: TColor; PPI: Integer; AppIcon: TIcon = nil);

implementation

{==============================================================================
  HILFSFUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  ScalePx
------------------------------------------------------------------------------
  Rechnet ein Mass für 96 dpi auf den Bildschirm um.
  Parameter: V   - Mass in Pixel bei 100 %
             PPI - Bildschirm-Auflösung; 0 oder weniger gilt als 96
  Rückgabe:  Mass in Bildschirm-Pixeln, gerundet
             (Beispiel: 16 px bei 144 dpi = 24 px)
------------------------------------------------------------------------------}
function ScalePx(V, PPI: Integer): Integer;
begin
  if PPI <= 0 then PPI := 96;                            // Schutz vor fehlender Angabe
  Result := (V * PPI + 48) div 96;                       // +48 = runden statt abschneiden
end;

{------------------------------------------------------------------------------
  KofiButtonWidth - siehe Interface
------------------------------------------------------------------------------}
function KofiButtonWidth(C: TCanvas; const Text: string; PPI: Integer): Integer;
begin
  // 6 Rand links + 16 Symbol + 6 Abstand + 10 Herz + 6 Abstand
  // + Text + 12 Rand rechts = 56 Pixel plus Textbreite
  Result := ScalePx(56, PPI) + C.TextWidth(Text);
end;

{------------------------------------------------------------------------------
  IsDarkColor
------------------------------------------------------------------------------
  Prüft, ob eine Farbe dunkel ist. Danach richtet sich die Pillenfarbe.
  Parameter: Col - beliebige Farbe, auch Systemfarbe wie clBtnFace
  Rückgabe:  True, wenn die Helligkeit unter 100 (von 255) liegt.
             Helligkeit = 0,299 Rot + 0,587 Grün + 0,114 Blau
             (so empfindet das Auge die drei Grundfarben)
------------------------------------------------------------------------------}
function IsDarkColor(Col: TColor): Boolean;
var
  RGB: LongInt;                                          // Farbe als echter RGB-Wert (keine Systemfarbe)
begin
  RGB := ColorToRGB(Col);                                // Systemfarbe -> echte Farbe
  Result := (Red(RGB) * 299 + Green(RGB) * 587 + Blue(RGB) * 114) div 1000 < 100;
end;

{------------------------------------------------------------------------------
  DrawSmoothPill
------------------------------------------------------------------------------
  Zeichnet Pille und Herz mit glatten Rändern. Windows (GDI) zeichnet
  Rundungen ohne Kantenglättung, also treppig. Darum wird alles vierfach
  so gross gezeichnet und dann je 4 × 4 Punkte zu einem gemittelt.

  Parameter: C         - Leinwand, auf die das Ergebnis kommt
             B         - Rechteck der Pille auf C
             PillColor - Farbe der Pille
             BackColor - Farbe des Untergrunds (für die Ecken)
             HeartX    - Mitte des Herzens waagrecht (auf C)
             HeartY    - Mitte der beiden Herzkreise senkrecht (auf C)
             D         - Durchmesser der Herzkreise

  Ablauf:
    1. Grosses Bild anlegen, Grund füllen, Pille als abgerundetes Rechteck
    2. Herz aus zwei Kreisen und einem Dreieck darauf zeichnen
    3. Je 4 × 4 Punkte zu einem mitteln (verkleinern)
    4. Kleines Bild auf die Leinwand kopieren
------------------------------------------------------------------------------}
procedure DrawSmoothPill(C: TCanvas; const B: TRect; PillColor, BackColor: TColor;
  HeartX, HeartY, D: Integer);
const
  SS = 4;                                                // Vergrösserung beim Zeichnen
var
  Big, Small: TBitmap;                                   // gross gezeichnet, verkleinert
  BigImg, SmallImg: TLazIntfImage;                       // Pixelzugriff auf beide
  W, H: Integer;                                         // Grösse der Pille
  X, Y, I, J: Integer;                                   // Zählvariablen
  HX, HY, DD: Integer;                                   // Herz im grossen Bild
  R, G, Bl: Cardinal;                                    // Farbsummen beim Mitteln
  Px: TFPColor;                                          // ein Bildpunkt
begin
  W := B.Right - B.Left;
  H := B.Bottom - B.Top;
  if (W <= 0) or (H <= 0) then Exit;
  Big := TBitmap.Create;
  Small := TBitmap.Create;
  BigImg := nil;
  SmallImg := nil;
  try
    // ----- 1. Grosses Bild mit Pille -----
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
      // ----- 2. Herz aus zwei Kreisen und einem Dreieck -----
      // (gezeichnet statt Zeichen ♥, das nicht jede Schrift hat)
      HX := (HeartX - B.Left) * SS;
      HY := (HeartY - B.Top) * SS;
      DD := D * SS;
      Brush.Color := CLR_KOFI;
      Pen.Color := CLR_KOFI;
      Ellipse(HX - DD, HY - DD div 2, HX + SS, HY + DD div 2 + SS);  // linker Bogen
      Ellipse(HX, HY - DD div 2, HX + DD + SS, HY + DD div 2 + SS);  // rechter Bogen
      Polygon([Point(HX - DD + SS div 2, HY + SS), Point(HX + DD + SS div 2, HY + SS),
        Point(HX + SS div 2, HY + DD + SS)]);            // Spitze unten
    end;

    // ----- 3. Verkleinern: je SS × SS Punkte mitteln -----
    BigImg := Big.CreateIntfImage;
    Small.PixelFormat := pf24bit;
    Small.SetSize(W, H);
    SmallImg := Small.CreateIntfImage;
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        R := 0; G := 0; Bl := 0;                         // Summen leeren
        for J := 0 to SS - 1 do
          for I := 0 to SS - 1 do
          begin
            Px := BigImg.Colors[X * SS + I, Y * SS + J];
            Inc(R, Px.Red); Inc(G, Px.Green); Inc(Bl, Px.Blue);
          end;
        Px.Red := R div (SS * SS);                       // Mittelwert der 16 Punkte
        Px.Green := G div (SS * SS);
        Px.Blue := Bl div (SS * SS);
        Px.Alpha := alphaOpaque;
        SmallImg.Colors[X, Y] := Px;
      end;
    // ----- 4. Auf die Leinwand -----
    Small.LoadFromIntfImage(SmallImg);
    C.Draw(B.Left, B.Top, Small);
  finally
    SmallImg.Free;
    BigImg.Free;
    Small.Free;
    Big.Free;
  end;
end;

{------------------------------------------------------------------------------
  DrawKofiButton - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Hintergrund füllen
    2. Höhe und Farbe der Pille bestimmen
    3. Pille mit Herz geglättet zeichnen
    4. Programm-Symbol vorne einsetzen
    5. Text weiss daneben schreiben
------------------------------------------------------------------------------}
procedure DrawKofiButton(C: TCanvas; const R: TRect; const Text: string;
  Hover: Boolean; BackColor: TColor; PPI: Integer; AppIcon: TIcon);
var
  B, IR: TRect;                                          // der Knopf selbst, das Symbol
  H: Integer;                                            // Höhe der Pille
  HX, HY, D: Integer;                                    // Mitte und Kreisdurchmesser des Herzens
  X, S: Integer;                                         // linker Rand des Symbols, Symbolgrösse
  Col: TColor;                                           // Farbe der Pille
begin
  // ----- 1. Hintergrund -----
  // clDefault (Panel ohne eigene Farbe) wäre in der Bitmap schwarz
  if (BackColor = clDefault) or (BackColor = clNone) then
    BackColor := clBtnFace;
  BackColor := ColorToRGB(BackColor);
  C.Brush.Style := bsSolid;
  C.Brush.Color := BackColor;
  C.FillRect(R);

  // ----- 2. Pille: so hoch wie die Schrift plus Luft, ganz runde Enden -----
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

  // ----- 3. Lage von Symbol und Herz, Pille zeichnen -----
  X := B.Left + ScalePx(7, PPI);                         // Symbol 7 px vom linken Rand
  S := ScalePx(16, PPI);                                 // Symbol 16 × 16 px
  D := ScalePx(5, PPI);                                  // Herzkreise 5 px
  HX := X + S + ScalePx(6, PPI) + D;
  HY := (B.Top + B.Bottom) div 2 - ScalePx(2, PPI);
  DrawSmoothPill(C, B, Col, BackColor, HX, HY, D);

  // ----- 4. Vorne das Symbol des Programms (16 px bei 100 %) -----
  if (AppIcon <> nil) and not AppIcon.Empty then
  begin
    AppIcon.Current := AppIcon.GetBestIndexForSize(Size(S, S));  // passende Bildgrösse wählen
    IR := Rect(X, (B.Top + B.Bottom - S) div 2, X + S, (B.Top + B.Bottom - S) div 2 + S);
    C.StretchDraw(IR, AppIcon);
  end;

  // ----- 5. Text weiss -----
  C.Brush.Style := bsClear;                              // Text ohne eigenen Hintergrund
  C.Font.Color := clWhite;
  C.TextOut(HX + D + ScalePx(6, PPI), (B.Top + B.Bottom - C.TextHeight('Ag')) div 2, Text);
end;

end.
