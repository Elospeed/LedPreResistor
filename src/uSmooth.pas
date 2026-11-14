{==============================================================================
  uSmooth - Schaltpläne und Symbole geglättet zeichnen
==============================================================================
  Zweck:     Windows (GDI) und Linux (GTK2) zeichnen schräge Linien, Kreise
             und Pfeile ohne Kantenglättung: Man sieht Treppenstufen. Diese
             Unit macht die Schaltpläne glatt.

  Idee:      Die Grafik wird doppelt so gross in ein Bild gezeichnet und
             danach verkleinert: je 2 × 2 Punkte werden zu einem gemittelt.
             Halb bedeckte Randpunkte bekommen so eine Mischfarbe, und die
             Kante wirkt glatt.
             Texte würden beim Verkleinern unscharf. Sie werden beim grossen
             Zeichnen nur gemerkt und danach in Originalgrösse scharf
             darübergeschrieben.

  Benutzung:
               if BeginSmooth(Ziel, R, Grund, Schlüssel, BigCanvas, BigRect) then
               begin
                 Zeichnen(BigCanvas, BigRect, ...);
                 EndSmooth;
               end;
             Die Zeichenroutinen fragen für Text SmoothCapturing ab und
             rufen dann SmoothAddText statt TextOut auf.

  Speicher:  Die zwei letzten fertigen Bilder bleiben gespeichert (Schlüssel
             = alles, was das Bild verändert). Das reicht für eine blinkende
             LED (an/aus), ohne jedes Mal neu zu rechnen.

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  neu: geglättetes Zeichnen
==============================================================================}
unit uSmooth;

{$mode objfpc}{$H+}

interface

uses
  Types, Graphics;

{==============================================================================
  ÖFFENTLICHE FUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  BeginSmooth
------------------------------------------------------------------------------
  Startet das vergrösserte Zeichnen für das Rechteck R auf Target.
  Parameter: Target    - eigentliche Zeichenfläche (z. B. PaintBox)
             R         - Zielrechteck darauf
             Back      - Hintergrundfarbe
             Key       - Schlüssel: alles, was das Bild verändert (Werte,
                         Farben, LED an/aus); leer = nicht speichern
             BigCanvas - (Rückgabe) hierauf zeichnen
             BigRect   - (Rückgabe) Rechteck auf BigCanvas (doppelt gross)
  Rückgabe:  True  = jetzt auf BigCanvas zeichnen und EndSmooth aufrufen
             False = nichts zu tun: Rechteck leer, oder das Bild lag schon
                     fertig im Speicher und ist bereits gezeichnet
------------------------------------------------------------------------------}
function BeginSmooth(Target: TCanvas; const R: TRect; Back: TColor; const Key: string;
  out BigCanvas: TCanvas; out BigRect: TRect): Boolean;

{------------------------------------------------------------------------------
  EndSmooth
------------------------------------------------------------------------------
  Beendet das vergrösserte Zeichnen: verkleinert das Bild, kopiert es auf
  das Ziel, schreibt die gemerkten Texte scharf darüber und speichert das
  Bild, wenn ein Schlüssel angegeben war.
------------------------------------------------------------------------------}
procedure EndSmooth;

{------------------------------------------------------------------------------
  SmoothCapturing
------------------------------------------------------------------------------
  Rückgabe:  True, solange vergrössert gezeichnet wird. Dann Texte nicht
             zeichnen, sondern mit SmoothAddText merken.
------------------------------------------------------------------------------}
function SmoothCapturing: Boolean;

{------------------------------------------------------------------------------
  SmoothAddText
------------------------------------------------------------------------------
  Merkt einen Text, der nach dem Verkleinern scharf gezeichnet wird.
  Parameter: C     - Leinwand; ihre Schriftart wird übernommen
             AX    - Ankerpunkt waagrecht (Pixel des grossen Bilds)
             BaseY - Grundlinie der Schrift (Pixel des grossen Bilds)
             T     - Text mit Auszeichnung (Tiefstellung mit «_»)
             Color - Farbe
             Align - 0 = links, 1 = Mitte, 2 = rechts am Ankerpunkt
             Bold  - fett
------------------------------------------------------------------------------}
procedure SmoothAddText(C: TCanvas; AX, BaseY: Integer; const T: string;
  Color: TColor; Align: Integer; Bold: Boolean);

{------------------------------------------------------------------------------
  SmoothCoord
------------------------------------------------------------------------------
  Koordinate in Pixel runden. Beim Glätten so, dass ein gerader Strich mit
  der aktuellen Stiftbreite genau auf ganzen Bildpunkten des verkleinerten
  Bilds liegt; sonst würden waagrechte und senkrechte Leitungen unscharf.
------------------------------------------------------------------------------}
function SmoothCoord(V: Double): Integer;

{------------------------------------------------------------------------------
  SmoothWidth
------------------------------------------------------------------------------
  Strichbreite in Pixel (V = gewünschte Breite in Pixeln der Zeichenfläche);
  beim Glätten ein Vielfaches der Vergrösserung, damit gerade Striche so
  dick bleiben wie ohne Glättung.
------------------------------------------------------------------------------}
function SmoothWidth(V: Double): Integer;

{------------------------------------------------------------------------------
  SmoothPx
------------------------------------------------------------------------------
  N Bildpunkte des fertigen Bilds in Pixel der Zeichenfläche (für feste
  Breiten wie den 1-Punkt-Rand eines Widerstands)
------------------------------------------------------------------------------}
function SmoothPx(N: Integer): Integer;

{------------------------------------------------------------------------------
  SmoothFontHeight
------------------------------------------------------------------------------
  Schrifthöhe für TCanvas.Font.Height: V Pixel, aber mindestens MinPx
  Bildpunkte im fertigen Bild (beim Glätten mal Vergrösserung)
------------------------------------------------------------------------------}
function SmoothFontHeight(MinPx: Integer; V: Double): Integer;

{------------------------------------------------------------------------------
  SmoothRectangle
------------------------------------------------------------------------------
  Rechteck mit Rand wie TCanvas.Rectangle. GDI legt den Rand rechts und
  unten einen Pixel weiter innen; beim Glätten wird das ausgeglichen,
  sonst wären diese Kanten unscharf.
------------------------------------------------------------------------------}
procedure SmoothRectangle(C: TCanvas; L, T, R, B: Integer);

implementation

uses
  SysUtils, Math, IntfGraphics, uRichText;

{==============================================================================
  KONSTANTEN, TYPEN, VARIABLEN
==============================================================================}
const
  K = 2;                                                 // Vergrösserung beim Zeichnen (2 × 2 Punkte werden gemittelt)

type
  // ein gemerkter Text
  TSmoothText = record
    AX, BaseY: Integer;                                  // Anker und Grundlinie (grosse Bitmap)
    T: string;                                           // Text mit Auszeichnung
    Color: TColor;                                       // Farbe
    Align: Integer;                                      // Ausrichtung
    Bold: Boolean;                                       // fett
    FontName: string;                                    // Schriftart
    FontPx: Integer;                                     // Schrifthöhe in Pixeln des fertigen Bilds
  end;
  TSmoothTexts = array of TSmoothText;

  // ein fertiges Bild im Speicher
  TSmoothCache = record
    Key: string;                                         // Schlüssel (leer = Platz frei)
    Bmp: TBitmap;                                        // verkleinerte Grafik
    Texts: TSmoothTexts;                                 // Texte dazu
  end;

var
  FTarget: TCanvas;                                      // eigentliche Zeichenfläche
  FRect: TRect;                                          // Zielrechteck darauf
  FKey: string;                                          // Schlüssel des laufenden Bilds
  FBig: TBitmap;                                         // gross gezeichnete Grafik
  FTexts: TSmoothTexts;                                  // gemerkte Texte
  FActive: Boolean;                                      // wird gerade gross gezeichnet
  FFontPx: Integer;                                      // zuletzt mit SmoothFontHeight verlangte Schrifthöhe (fertiges Bild)
  FCache: array[0..1] of TSmoothCache;                   // die zwei letzten Bilder, [0] = neuestes

{==============================================================================
  INTERNE HILFSFUNKTIONEN UND ÖFFENTLICHE FUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  Present
------------------------------------------------------------------------------
  Zeichnet ein fertiges (verkleinertes) Bild und die Texte auf das Ziel.
  Parameter: C     - Zielleinwand
             R     - Zielrechteck
             Bmp   - verkleinertes Bild
             Texts - gemerkte Texte; ihre Lage gilt im grossen Bild und wird
                     durch K geteilt
------------------------------------------------------------------------------}
procedure Present(C: TCanvas; const R: TRect; Bmp: TBitmap; const Texts: TSmoothTexts);
var
  I: Integer;                                            // Zähler
  TW, TX, TY: Integer;                                   // Breite und Startpunkt eines Texts
  BY: Integer;                                           // Grundlinie in Zielpixeln
begin
  C.Draw(R.Left, R.Top, Bmp);                            // erst das Bild ...
  C.Brush.Style := bsClear;
  for I := 0 to High(Texts) do
    with Texts[I] do
    begin
      C.Font.Name := FontName;
      C.Font.Height := -FontPx;                          // ... dann jeder Text scharf
      if Bold then C.Font.Style := [fsBold] else C.Font.Style := [];
      TW := RichWidth(C, T);
      case Align of
        1: TX := R.Left + Round(AX / K) - TW div 2;
        2: TX := R.Left + Round(AX / K) - TW;
      else
        TX := R.Left + Round(AX / K);
      end;
      BY := R.Top + Round(BaseY / K);
      TY := BY - C.TextHeight('Ag') * 4 div 5;           // Grundlinie -> Oberkante
      DrawRich(C, TX, TY, T, Color, Color);
    end;
  C.Font.Style := [];
end;

{------------------------------------------------------------------------------
  BeginSmooth - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Leeres Rechteck: nichts tun
    2. Bild mit gleichem Schlüssel im Speicher? Dann nur zeigen und
       nach vorne tauschen (wird als neuestes behalten)
    3. Sonst grosses Bild anlegen und mit der Grundfarbe füllen
------------------------------------------------------------------------------}
function BeginSmooth(Target: TCanvas; const R: TRect; Back: TColor; const Key: string;
  out BigCanvas: TCanvas; out BigRect: TRect): Boolean;
var
  W, H: Integer;                                         // Grösse des Zielrechtecks
  I: Integer;                                            // Zähler
  Tmp: TSmoothCache;                                     // zum Tauschen
begin
  Result := False;
  BigCanvas := nil;
  BigRect := Types.Rect(0, 0, 0, 0);
  W := R.Right - R.Left;
  H := R.Bottom - R.Top;
  // ----- 1. Leeres Rechteck -----
  if (W <= 0) or (H <= 0) then Exit;
  // ----- 2. Im Speicher? -----
  FKey := '';
  if Key <> '' then
  begin
    FKey := Format('%s|%d|%d|%d', [Key, W, H, ColorToRGB(Back)]);  // Grösse und Grund gehören dazu
    for I := 0 to High(FCache) do
      if (FCache[I].Key = FKey) and Assigned(FCache[I].Bmp) then
      begin
        Present(Target, R, FCache[I].Bmp, FCache[I].Texts);
        if I > 0 then
        begin
          Tmp := FCache[0];
          FCache[0] := FCache[I];
          FCache[I] := Tmp;
        end;
        Exit;
      end;
  end;
  // ----- 3. Grosses Bild anlegen -----
  FTarget := Target;
  FRect := R;
  FBig := TBitmap.Create;
  FBig.PixelFormat := pf24bit;
  FBig.SetSize(W * K, H * K);
  // Systemfarben in echte Farben umrechnen, sonst bleibt der Grund schwarz
  FBig.Canvas.Brush.Style := bsSolid;
  FBig.Canvas.Brush.Color := ColorToRGB(Back);
  FBig.Canvas.FillRect(0, 0, W * K, H * K);
  FTexts := nil;
  FFontPx := 0;
  FActive := True;                                       // ab jetzt Texte nur merken
  BigCanvas := FBig.Canvas;
  BigRect := Types.Rect(0, 0, W * K, H * K);
  Result := True;
end;

{------------------------------------------------------------------------------
  SmoothCapturing - siehe Interface
------------------------------------------------------------------------------}
function SmoothCapturing: Boolean;
begin
  Result := FActive;
end;

{------------------------------------------------------------------------------
  SmoothAddText - siehe Interface
------------------------------------------------------------------------------}
procedure SmoothAddText(C: TCanvas; AX, BaseY: Integer; const T: string;
  Color: TColor; Align: Integer; Bold: Boolean);
var
  N: Integer;                                            // neuer Eintrag
begin
  N := Length(FTexts);
  SetLength(FTexts, N + 1);
  FTexts[N].AX := AX;
  FTexts[N].BaseY := BaseY;
  FTexts[N].T := T;
  FTexts[N].Color := Color;
  FTexts[N].Align := Align;
  FTexts[N].Bold := Bold;
  FTexts[N].FontName := C.Font.Name;
  // Die Höhe nicht von C.Font zurücklesen: TFont rechnet über Punkte und
  // rundet, die Schrift würde je nach Skalierung kleiner als ohne Glättung.
  if FFontPx > 0 then
    FTexts[N].FontPx := FFontPx
  else
    FTexts[N].FontPx := Max(1, Round(Abs(C.Font.Height) / K));
end;

{------------------------------------------------------------------------------
  SmoothCoord - siehe Interface
------------------------------------------------------------------------------
  Beispiel: K = 2, Stift 4 Pixel breit (Half = 2), V = 101 ergibt 102:
  der Strich deckt 100 ... 103 ab = genau die Bildpunkte 50 und 51.
------------------------------------------------------------------------------}
function SmoothCoord(V: Double): Integer;
var
  Half: Integer;                                         // halbe Stiftbreite
begin
  if not FActive then
    Exit(Round(V));                                      // ohne Glättung: einfach runden
  // Ein Stift der Breite PW deckt x - PW div 2 .. x + PW - PW div 2 - 1 ab;
  // der Anfang soll auf einem Vielfachen von K liegen.
  Half := FBig.Canvas.Pen.Width div 2;
  Result := K * Round((V - Half) / K) + Half;
end;

{------------------------------------------------------------------------------
  SmoothWidth - siehe Interface
------------------------------------------------------------------------------}
function SmoothWidth(V: Double): Integer;
begin
  if FActive then
    Result := K * Max(1, Round(V / K))                   // Vielfaches von K
  else
    Result := Max(1, Round(V));
end;

{------------------------------------------------------------------------------
  SmoothPx - siehe Interface
------------------------------------------------------------------------------}
function SmoothPx(N: Integer): Integer;
begin
  if FActive then Result := N * K else Result := N;
end;

{------------------------------------------------------------------------------
  SmoothFontHeight - siehe Interface
------------------------------------------------------------------------------}
function SmoothFontHeight(MinPx: Integer; V: Double): Integer;
begin
  if FActive then
  begin
    FFontPx := Max(MinPx, Round(V / K));
    Result := -FFontPx * K;
  end
  else
    Result := -Max(MinPx, Round(V));
end;

{------------------------------------------------------------------------------
  SmoothRectangle - siehe Interface
------------------------------------------------------------------------------}
procedure SmoothRectangle(C: TCanvas; L, T, R, B: Integer);
begin
  if FActive then
    C.Rectangle(L, T, R + 1, B + 1)                      // GDI-Versatz ausgleichen
  else
    C.Rectangle(L, T, R, B);
end;

{------------------------------------------------------------------------------
  Downscale
------------------------------------------------------------------------------
  Verkleinert das grosse Bild auf Zielgrösse: je 2 × 2 Punkte werden
  gemittelt. Beide Bilder haben dasselbe Pixelformat; jedes Byte
  (Farbkanal) wird für sich gemittelt, darum ist die Reihenfolge der
  Kanäle (RGB oder BGR, Windows oder Linux) egal.
  Parameter: Big  - grosses Bild (W·K × H·K)
             W, H - Zielgrösse
  Rückgabe:  neues, verkleinertes Bild (Aufrufer gibt es frei)
------------------------------------------------------------------------------}
function Downscale(Big: TBitmap; W, H: Integer): TBitmap;
var
  BigImg, SmallImg: TLazIntfImage;                       // Pixelzugriff
  BPP: Integer;                                          // Bytes pro Punkt
  X, Y, Ch: Integer;                                     // Zähler
  A, B, Dst: PByte;                                      // obere und untere Quellzeile, Ziel
begin
  Result := TBitmap.Create;
  BigImg := Big.CreateIntfImage;
  SmallImg := nil;
  try
    BPP := BigImg.DataDescription.BitsPerPixel div 8;
    SmallImg := TLazIntfImage.Create(0, 0);
    SmallImg.DataDescription := BigImg.DataDescription;
    SmallImg.SetSize(W, H);
    if (BPP < 1) or (BigImg.DataDescription.BitsPerPixel mod 8 <> 0) then
    begin
      // unbekanntes Format: ohne Mitteln übernehmen
      for Y := 0 to H - 1 do
        for X := 0 to W - 1 do
          SmallImg.Colors[X, Y] := BigImg.Colors[X * K, Y * K];
    end
    else
      for Y := 0 to H - 1 do
      begin
        A := BigImg.GetDataLineStart(Y * K);
        B := BigImg.GetDataLineStart(Y * K + 1);
        Dst := SmallImg.GetDataLineStart(Y);
        for X := 0 to W - 1 do
        begin
          for Ch := 0 to BPP - 1 do
          begin
            // Mittel aus 4 Punkten: links/rechts, obere/untere Zeile
            Dst^ := Byte((Cardinal(A[0]) + A[BPP] + B[0] + B[BPP] + 2) shr 2);
            Inc(A);
            Inc(B);
            Inc(Dst);
          end;
          Inc(A, BPP);                                   // zweiten Punkt überspringen
          Inc(B, BPP);
        end;
      end;
    Result.LoadFromIntfImage(SmallImg);
  finally
    SmallImg.Free;
    BigImg.Free;
  end;
end;

{------------------------------------------------------------------------------
  EndSmooth - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Verkleinern
    2. Bild und Texte auf das Ziel zeichnen
    3. Mit Schlüssel: als neuestes Bild merken, das älteste fällt weg
------------------------------------------------------------------------------}
procedure EndSmooth;
var
  Small: TBitmap;                                        // verkleinerte Grafik
begin
  if not FActive then Exit;
  FActive := False;
  Small := nil;
  try
    Small := Downscale(FBig, FRect.Right - FRect.Left, FRect.Bottom - FRect.Top);
    Present(FTarget, FRect, Small, FTexts);
    if FKey <> '' then
    begin
      // als neuestes Bild merken, das älteste fällt weg
      FCache[1].Bmp.Free;
      FCache[1] := FCache[0];
      FCache[0].Key := FKey;
      FCache[0].Bmp := Small;
      FCache[0].Texts := FTexts;
      Small := nil;
    end;
  finally
    Small.Free;
    FreeAndNil(FBig);
    FTexts := nil;
  end;
end;

{------------------------------------------------------------------------------
  FreeCache
------------------------------------------------------------------------------
  Gibt die gespeicherten Bilder frei (beim Programmende).
------------------------------------------------------------------------------}
procedure FreeCache;
var
  I: Integer;                                            // Zähler
begin
  for I := 0 to High(FCache) do
    FreeAndNil(FCache[I].Bmp);
end;

finalization
  FreeCache;
end.
