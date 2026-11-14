{ Geglättete Schaltpläne: GDI und GTK2 zeichnen schräge Linien, Kreise und
  Pfeile ohne Kantenglättung (Treppenstufen). Darum wird die Grafik
  doppelt so gross in eine Bitmap gezeichnet und danach je 2 × 2 Punkte
  gemittelt verkleinert. Texte würden dabei unscharf; sie werden beim
  grossen Zeichnen nur gemerkt und danach in Originalgrösse scharf
  darübergelegt.

  Ablauf:
    if BeginSmooth(Ziel, R, Grund, Schlüssel, BigCanvas, BigRect) then
    begin
      Zeichnen(BigCanvas, BigRect, ...);
      EndSmooth;
    end;
  BeginSmooth liefert False, wenn nichts zu zeichnen ist oder das Bild mit
  demselben Schlüssel schon fertig im Speicher lag (dann ist es bereits
  gezeichnet). Der Schlüssel muss alles enthalten, was das Bild verändert;
  leer = nicht speichern. Gespeichert werden die zwei letzten Bilder, das
  reicht für eine blinkende LED (an/aus).

  Die Zeichenroutinen rufen für Text SmoothCapturing / SmoothAddText auf. }
unit uSmooth;

{$mode objfpc}{$H+}

interface

uses
  Types, Graphics;

{ Startet das gross Zeichnen für das Rechteck R auf Target (siehe oben). }
function BeginSmooth(Target: TCanvas; const R: TRect; Back: TColor; const Key: string;
  out BigCanvas: TCanvas; out BigRect: TRect): Boolean;

{ Verkleinert, kopiert auf das Ziel und zeichnet die gemerkten Texte. }
procedure EndSmooth;

{ True, solange gross gezeichnet wird (Texte dann nur merken). }
function SmoothCapturing: Boolean;

{ Text merken: AX = Ankerpunkt waagrecht, BaseY = Grundlinie (Pixel der
  grossen Bitmap), Align 0 = links, 1 = Mitte, 2 = rechts. Schrift wie
  gerade auf C eingestellt. }
procedure SmoothAddText(C: TCanvas; AX, BaseY: Integer; const T: string;
  Color: TColor; Align: Integer; Bold: Boolean);

{ Koordinate in Pixel runden. Beim Glätten so, dass ein gerader Strich mit
  der aktuellen Stiftbreite genau auf ganzen Bildpunkten des verkleinerten
  Bilds liegt; sonst würden waagrechte und senkrechte Leitungen unscharf. }
function SmoothCoord(V: Double): Integer;

{ Strichbreite in Pixel (V = gewünschte Breite in Pixeln der Zeichenfläche);
  beim Glätten ein Vielfaches der Vergrösserung, damit gerade Striche so
  dick bleiben wie ohne Glättung. }
function SmoothWidth(V: Double): Integer;

{ N Bildpunkte des fertigen Bilds in Pixel der Zeichenfläche (für feste
  Breiten wie den 1-Punkt-Rand eines Widerstands) }
function SmoothPx(N: Integer): Integer;

{ Schrifthöhe für TCanvas.Font.Height: V Pixel, aber mindestens MinPx
  Bildpunkte im fertigen Bild (beim Glätten mal Vergrösserung) }
function SmoothFontHeight(MinPx: Integer; V: Double): Integer;

{ Rechteck mit Rand wie TCanvas.Rectangle. GDI legt den Rand rechts und
  unten einen Pixel weiter innen; beim Glätten wird das ausgeglichen,
  sonst wären diese Kanten unscharf. }
procedure SmoothRectangle(C: TCanvas; L, T, R, B: Integer);

implementation

uses
  SysUtils, Math, IntfGraphics, uRichText;

const
  K = 2;  // Vergrösserung beim Zeichnen (2 × 2 Punkte werden gemittelt)

type
  { ein gemerkter Text }
  TSmoothText = record
    AX, BaseY: Integer;  // Anker und Grundlinie (grosse Bitmap)
    T: string;           // Text mit Auszeichnung
    Color: TColor;       // Farbe
    Align: Integer;      // Ausrichtung
    Bold: Boolean;       // fett
    FontName: string;    // Schriftart
    FontPx: Integer;     // Schrifthöhe in Pixeln des fertigen Bilds
  end;
  TSmoothTexts = array of TSmoothText;

  { ein fertiges Bild im Speicher }
  TSmoothCache = record
    Key: string;          // Schlüssel (leer = Platz frei)
    Bmp: TBitmap;         // verkleinerte Grafik
    Texts: TSmoothTexts;  // Texte dazu
  end;

var
  FTarget: TCanvas;      // eigentliche Zeichenfläche
  FRect: TRect;          // Zielrechteck darauf
  FKey: string;          // Schlüssel des laufenden Bilds
  FBig: TBitmap;         // gross gezeichnete Grafik
  FTexts: TSmoothTexts;  // gemerkte Texte
  FActive: Boolean;      // wird gerade gross gezeichnet
  FFontPx: Integer;      // zuletzt mit SmoothFontHeight verlangte Schrifthöhe (fertiges Bild)
  FCache: array[0..1] of TSmoothCache;  // die zwei letzten Bilder, [0] = neuestes

{ Bild und Texte auf das Ziel zeichnen }
procedure Present(C: TCanvas; const R: TRect; Bmp: TBitmap; const Texts: TSmoothTexts);
var
  I: Integer;           // Zähler
  TW, TX, TY: Integer;  // Breite und Startpunkt eines Texts
  BY: Integer;          // Grundlinie in Zielpixeln
begin
  C.Draw(R.Left, R.Top, Bmp);
  C.Brush.Style := bsClear;
  for I := 0 to High(Texts) do
    with Texts[I] do
    begin
      C.Font.Name := FontName;
      C.Font.Height := -FontPx;
      if Bold then C.Font.Style := [fsBold] else C.Font.Style := [];
      TW := RichWidth(C, T);
      case Align of
        1: TX := R.Left + Round(AX / K) - TW div 2;
        2: TX := R.Left + Round(AX / K) - TW;
      else
        TX := R.Left + Round(AX / K);
      end;
      BY := R.Top + Round(BaseY / K);
      TY := BY - C.TextHeight('Ag') * 4 div 5;
      DrawRich(C, TX, TY, T, Color, Color);
    end;
  C.Font.Style := [];
end;

function BeginSmooth(Target: TCanvas; const R: TRect; Back: TColor; const Key: string;
  out BigCanvas: TCanvas; out BigRect: TRect): Boolean;
var
  W, H: Integer;          // Grösse des Zielrechtecks
  I: Integer;             // Zähler
  Tmp: TSmoothCache;      // zum Tauschen
begin
  Result := False;
  BigCanvas := nil;
  BigRect := Types.Rect(0, 0, 0, 0);
  W := R.Right - R.Left;
  H := R.Bottom - R.Top;
  if (W <= 0) or (H <= 0) then Exit;
  FKey := '';
  if Key <> '' then
  begin
    FKey := Format('%s|%d|%d|%d', [Key, W, H, ColorToRGB(Back)]);
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
  FActive := True;
  BigCanvas := FBig.Canvas;
  BigRect := Types.Rect(0, 0, W * K, H * K);
  Result := True;
end;

function SmoothCapturing: Boolean;
begin
  Result := FActive;
end;

procedure SmoothAddText(C: TCanvas; AX, BaseY: Integer; const T: string;
  Color: TColor; Align: Integer; Bold: Boolean);
var
  N: Integer;  // neuer Eintrag
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

function SmoothCoord(V: Double): Integer;
var
  Half: Integer;  // halbe Stiftbreite
begin
  if not FActive then
    Exit(Round(V));
  // Ein Stift der Breite PW deckt x - PW div 2 .. x + PW - PW div 2 - 1 ab;
  // der Anfang soll auf einem Vielfachen von K liegen.
  Half := FBig.Canvas.Pen.Width div 2;
  Result := K * Round((V - Half) / K) + Half;
end;

function SmoothWidth(V: Double): Integer;
begin
  if FActive then
    Result := K * Max(1, Round(V / K))
  else
    Result := Max(1, Round(V));
end;

function SmoothPx(N: Integer): Integer;
begin
  if FActive then Result := N * K else Result := N;
end;

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

procedure SmoothRectangle(C: TCanvas; L, T, R, B: Integer);
begin
  if FActive then
    C.Rectangle(L, T, R + 1, B + 1)
  else
    C.Rectangle(L, T, R, B);
end;

{ Grosse Bitmap auf Zielgrösse mitteln. Beide Bilder haben dasselbe
  Pixelformat; jedes Byte (Farbkanal) wird für sich gemittelt, darum ist
  die Reihenfolge der Kanäle egal. }
function Downscale(Big: TBitmap; W, H: Integer): TBitmap;
var
  BigImg, SmallImg: TLazIntfImage;  // Pixelzugriff
  BPP: Integer;                     // Bytes pro Punkt
  X, Y, Ch: Integer;                // Zähler
  A, B, Dst: PByte;                 // obere und untere Quellzeile, Ziel
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
            Dst^ := Byte((Cardinal(A[0]) + A[BPP] + B[0] + B[BPP] + 2) shr 2);
            Inc(A);
            Inc(B);
            Inc(Dst);
          end;
          Inc(A, BPP);
          Inc(B, BPP);
        end;
      end;
    Result.LoadFromIntfImage(SmallImg);
  finally
    SmallImg.Free;
    BigImg.Free;
  end;
end;

procedure EndSmooth;
var
  Small: TBitmap;  // verkleinerte Grafik
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

procedure FreeCache;
var
  I: Integer;  // Zähler
begin
  for I := 0 to High(FCache) do
    FreeAndNil(FCache[I].Bmp);
end;

finalization
  FreeCache;
end.
