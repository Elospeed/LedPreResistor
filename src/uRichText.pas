{==============================================================================
  uRichText - Text mit Fettdruck und tiefgestellten Zeichen
==============================================================================
  Zweck:     Schaltplan, Rechenweg und Zeichen-Erklärung brauchen Formeln
             wie «U_R = U_B − U_F = **8,8 V**». Diese Unit zeichnet solchen
             Text mit einer ganz einfachen Auszeichnung:
               **fett**  schaltet Fettdruck (und hellere Farbe) ein und aus
               _X        schreibt das nächste Zeichen tiefgestellt
                         (U_R -> U mit kleinem R)
             Mehrere tiefgestellte Zeichen: jedes mit eigenem _ (U_m_i_n).

  Technik:   Nur LCL-Canvas, keine Zusatzbibliothek. Der Text wird Zeichen
             für Zeichen abgelaufen (UTF-8, also auch Ω, µ, ×).

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  RichPlain für den Knopf «Kopieren»
             2.0  29.10.2026  erste Fassung
==============================================================================}
unit uRichText;

{$mode objfpc}{$H+}

interface

uses
  Graphics;                                              // TCanvas, TColor

{==============================================================================
  ÖFFENTLICHE FUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  DrawRich - Text mit Auszeichnung zeichnen
------------------------------------------------------------------------------
  Parameter: Canvas    - Zeichenfläche (Schrift ist schon eingestellt)
             X, Y      - Anfang links, Y = Oberkante der Zeile
             S         - Text mit ** und _
             Color     - Farbe für normalen Text
             BoldColor - Farbe für fetten Text (meist heller)
  Rückgabe:  Breite des gezeichneten Texts in Pixel
------------------------------------------------------------------------------}
function DrawRich(Canvas: TCanvas; X, Y: Integer; const S: string;
  Color, BoldColor: TColor): Integer;

{------------------------------------------------------------------------------
  RichWidth - Breite messen, ohne zu zeichnen
------------------------------------------------------------------------------
  Parameter: Canvas - Zeichenfläche mit der gewünschten Schrift
             S      - Text mit ** und _
  Rückgabe:  Breite in Pixel, die DrawRich brauchen würde (zum Ausrichten
             und zum Umbrechen der Zeichen-Erklärung)
------------------------------------------------------------------------------}
function RichWidth(Canvas: TCanvas; const S: string): Integer;

{------------------------------------------------------------------------------
  RichPlain - Text ohne Auszeichnung (für «Kopieren»)
------------------------------------------------------------------------------
  Parameter: S - Text mit ** und _
  Rückgabe:  einfacher Text: «**» fällt weg, «_X» wird zu «X»
             (Beispiel: «U_R = **8,8 V**» -> «UR = 8,8 V»)
------------------------------------------------------------------------------}
function RichPlain(const S: string): string;

implementation

uses
  LazUTF8;                                               // UTF8CodepointSize

{------------------------------------------------------------------------------
  WalkRich - gemeinsame Arbeit von DrawRich und RichWidth
------------------------------------------------------------------------------
  Läuft den Text Zeichen für Zeichen ab, misst jeden Abschnitt und zeichnet
  nur, wenn Paint = True ist. Normaler Text wird gesammelt (Run) und in
  einem Stück ausgegeben, das ist schneller und sieht sauberer aus als
  Zeichen für Zeichen.
  Parameter: wie DrawRich, dazu Paint (False = nur messen)
  Rückgabe:  Breite in Pixel
------------------------------------------------------------------------------}
function WalkRich(Canvas: TCanvas; X, Y: Integer; const S: string;
  Color, BoldColor: TColor; Paint: Boolean): Integer;
var
  I: Integer;                                            // Position im Text (Bytes)
  Bold: Boolean;                                         // Fettdruck gerade aktiv
  Sub: Boolean;                                          // nächstes Zeichen tiefgestellt
  Ch: string;                                            // aktuelles Zeichen (UTF-8, 1–4 Bytes)
  ChLen: Integer;                                        // Länge des Zeichens in Bytes
  BaseSize: Integer;                                     // ursprüngliche Schriftgrösse
  BaseStyle: TFontStyles;                                // ursprünglicher Schriftstil
  StartX: Integer;                                       // Startposition für die Breitenberechnung
  Run: string;                                           // gesammelter Text gleichen Stils
  BaseH: Integer;                                        // Zeilenhöhe der Grundschrift

  // Gibt den gesammelten Text (Run) im aktuellen Stil aus und rückt X weiter
  procedure Flush;
  begin
    if Run = '' then
      Exit;
    if Bold then
    begin
      Canvas.Font.Style := BaseStyle + [fsBold];
      Canvas.Font.Color := BoldColor;
    end
    else
    begin
      Canvas.Font.Style := BaseStyle;
      Canvas.Font.Color := Color;
    end;
    if Paint then
      Canvas.TextOut(X, Y, Run);
    Inc(X, Canvas.TextWidth(Run));
    Run := '';
  end;

begin
  StartX := X;
  BaseSize := Canvas.Font.Size;
  BaseStyle := Canvas.Font.Style;
  BaseH := Canvas.TextHeight('Ag');
  Bold := False;
  Sub := False;
  Run := '';
  Canvas.Brush.Style := bsClear;
  I := 1;
  while I <= Length(S) do
  begin
    // «**»: Fettdruck umschalten
    if (S[I] = '*') and (I < Length(S)) and (S[I + 1] = '*') then
    begin
      Flush;
      Bold := not Bold;
      Inc(I, 2);
      Continue;
    end;
    // «_»: das nächste Zeichen tiefstellen
    if (S[I] = '_') and (I < Length(S)) then
    begin
      Flush;
      Sub := True;
      Inc(I);
      Continue;
    end;
    // ein ganzes UTF-8-Zeichen lesen (Ω, µ, × haben 2 Bytes)
    ChLen := UTF8CodepointSize(@S[I]);
    Ch := Copy(S, I, ChLen);
    Inc(I, ChLen);
    if Sub then
    begin
      // tiefgestelltes Zeichen: kleinere Schrift, nach unten versetzt
      Canvas.Font.Size := Round(BaseSize * 0.72);
      if Bold then Canvas.Font.Style := BaseStyle + [fsBold] else Canvas.Font.Style := BaseStyle;
      Canvas.Font.Color := Color;
      if Paint then
        Canvas.TextOut(X, Y + BaseH - Canvas.TextHeight('Ag') + BaseH div 6, Ch);
      Inc(X, Canvas.TextWidth(Ch) + 1);
      Canvas.Font.Size := BaseSize;
      Sub := False;
    end
    else
      Run := Run + Ch;                                   // normales Zeichen sammeln
  end;
  Flush;                                                 // Rest ausgeben
  // Schrift wie vorher hinterlassen
  Canvas.Font.Style := BaseStyle;
  Canvas.Font.Color := Color;
  Result := X - StartX;
end;

{------------------------------------------------------------------------------
  DrawRich - siehe Interface
------------------------------------------------------------------------------}
function DrawRich(Canvas: TCanvas; X, Y: Integer; const S: string;
  Color, BoldColor: TColor): Integer;
begin
  Result := WalkRich(Canvas, X, Y, S, Color, BoldColor, True);
end;

{------------------------------------------------------------------------------
  RichWidth - siehe Interface
------------------------------------------------------------------------------}
function RichWidth(Canvas: TCanvas; const S: string): Integer;
begin
  Result := WalkRich(Canvas, 0, 0, S, clBlack, clBlack, False);
end;

{------------------------------------------------------------------------------
  RichPlain - siehe Interface
------------------------------------------------------------------------------}
function RichPlain(const S: string): string;
var
  I: Integer;                                            // Position im Text (Bytes)
begin
  Result := '';
  I := 1;
  while I <= Length(S) do
  begin
    if (S[I] = '*') and (I < Length(S)) and (S[I + 1] = '*') then
      Inc(I, 2)                                          // «**» überspringen
    else if (S[I] = '_') and (I < Length(S)) then
      Inc(I)                                             // «_» weglassen, Zeichen bleibt
    else
    begin
      Result := Result + S[I];
      Inc(I);
    end;
  end;
end;

end.
