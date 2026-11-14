{==============================================================================
  uSkalierung - Windows-Skalierung (DPI): kein Fenster grösser als der Bildschirm
==============================================================================
  Zweck:     Sorgt dafür, dass bei 100 bis 200 % Windows-Skalierung jedes
             Fenster auf den freien Bildschirm passt (ohne Taskleiste).

  Problem:   Lazarus rechnet jedes Fenster nach dem Erzeugen von 96 dpi auf
             die Bildschirm-DPI um (auch Fenster aus CreateNew). Bei 150 %
             wird ein Fenster mit 724 Pixeln Höhe so 1086 Pixel hoch und
             passt auf einem 1920 × 1080-Bildschirm nicht mehr; bei 200 %
             nicht einmal die Mindestgrösse.

  Benutzung: Die Unit muss nur in der .lpr unter «uses» stehen. Sie meldet
             sich bei Screen an und begrenzt jedes Fenster, sobald es
             sichtbar wird, auf den freien Bildschirm. Die Mindestgrösse
             bleibt dabei immer kleiner als die Startgrösse.

  Regel für  Feste Pixel nur im Aufbau des Fensters (der wird danach
  eigenen    umgerechnet). Alles, was später gesetzt oder gezeichnet wird,
  Code:      mit Scale96ToForm umrechnen; nie Screen.PixelsPerInch im
             Konstruktor.

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  Kommentare ausführlicher; SkaliereDialog rechnet
                              auch die Schrift des Fensters selbst um
             2.0  29.10.2026  erste Fassung
==============================================================================}
unit uSkalierung;

{$mode objfpc}{$H+}

interface

uses
  Classes, Types, Forms, Controls, Graphics, LCLType, LCLIntf, Math;

{==============================================================================
  ÖFFENTLICHE FUNKTIONEN
==============================================================================}

{------------------------------------------------------------------------------
  StelleAufBildschirmDPI
------------------------------------------------------------------------------
  Für Fenster, deren Konstruktor durchgehend Scale96ToForm benutzt:
  direkt nach "inherited CreateNew" aufrufen. Danach rechnet
  Scale96ToForm wirklich auf die Bildschirm-DPI um (vorher stand das
  Fenster bis zum Ende des Konstruktors auf 96 dpi, Werte in eigenen
  Variablen wie Spaltenbreiten oder Bildlisten blieben dann bei 100 %).
------------------------------------------------------------------------------}
procedure StelleAufBildschirmDPI(F: TCustomForm);

{------------------------------------------------------------------------------
  SkaliereDialog
------------------------------------------------------------------------------
  Für Fenster, die nach "F := TForm.CreateNew(nil)" AUSSERHALB eines
  Konstruktors mit 96-dpi-Pixeln aufgebaut werden: Lazarus hat das leere
  Fenster schon beim Erzeugen umgerechnet, alles danach Gesetzte bliebe
  bei 100 %. Einmal nach dem Aufbau und vor ShowModal aufrufen. Rechnet
  Grösse, Mindestgrösse, alle Elemente und feste Schriftgrössen um.
------------------------------------------------------------------------------}
procedure SkaliereDialog(F: TCustomForm);

{------------------------------------------------------------------------------
  BegrenzeAufBildschirm
------------------------------------------------------------------------------
  Begrenzt ein Fenster auf den freien Bildschirm. Läuft automatisch beim
  Sichtbarwerden; von Hand nur nötig, wenn ein sichtbares Fenster im
  Code grösser gemacht wird (z. B. beim Wechsel der Ansicht).
------------------------------------------------------------------------------}
procedure BegrenzeAufBildschirm(F: TCustomForm);

implementation

{==============================================================================
  TYPEN UND VARIABLEN
==============================================================================}
type
  // Zugriff auf Font/ParentFont (in TControl geschützt)
  TControlZugriff = class(TControl);

  // Wächter: wird von Screen benachrichtigt, wenn ein Fenster sichtbar wird
  TSkalierungWaechter = class
    procedure FormSichtbar(Sender: TObject; Form: TCustomForm);
    procedure SpaeterPruefen(Data: PtrInt);
  end;

var
  Waechter: TSkalierungWaechter = nil;                   // der eine Wächter für alle Fenster

{==============================================================================
  FENSTER BEGRENZEN
==============================================================================}

{------------------------------------------------------------------------------
  FreierBereich
------------------------------------------------------------------------------
  Rückgabe:  freier Bereich (ohne Taskleiste) des Bildschirms, auf dem das
             Fenster liegt; noch ohne Handle der des Hauptfensters, sonst
             der Hauptbildschirm
------------------------------------------------------------------------------}
function FreierBereich(F: TCustomForm): TRect;
var
  M: TMonitor;                                           // Bildschirm des Fensters
begin
  M := nil;
  if F.HandleAllocated then
    M := Screen.MonitorFromRect(F.BoundsRect, mdNearest)
  else if (Application.MainForm <> nil) and Application.MainForm.HandleAllocated then
    M := Application.MainForm.Monitor;
  if M = nil then
    M := Screen.PrimaryMonitor;
  if M <> nil then
    Result := M.WorkareaRect
  else
    Result := Screen.WorkAreaRect;
end;

{------------------------------------------------------------------------------
  BegrenzeAufBildschirm - siehe Interface
------------------------------------------------------------------------------
  Ablauf:
    1. Freien Bereich und Rahmengrösse bestimmen
    2. Mindestgrösse und Grösse auf den Platz begrenzen
    3. Mindestgrösse kleiner als die Grösse halten
    4. Fenster, das über den Rand ragt, zurückschieben
------------------------------------------------------------------------------}
procedure BegrenzeAufBildschirm(F: TCustomForm);
var
  R, WR: TRect;                                          // freier Bereich, Fenster mit Rahmen
  MaxB, MaxH: Integer;                                   // grösste erlaubte Breite und Höhe
  RandB, RandH: Integer;                                 // Rahmen und Titelleiste ausserhalb von Width/Height
begin
  // ----- 1. Platz und Rahmen -----
  if (F = nil) or (F.Parent <> nil) or (F.WindowState <> wsNormal) then Exit;  // nur freie, normale Fenster
  R := FreierBereich(F);
  // Width/Height sind bei der LCL ohne Titelleiste und Rahmen gerechnet.
  // Deren echte Grösse vom Fenster messen (geschätzte Werte waren bei
  // 150-200 % ein paar Pixel zu klein, das Fenster lag unter der Taskleiste)
  RandB := F.Scale96ToForm(16);                          // Schätzung, falls Messung fehlt
  RandH := F.Scale96ToForm(48);
  if F.HandleAllocated and (LCLIntf.GetWindowRect(F.Handle, WR) <> 0) then
  begin
    if WR.Right - WR.Left - F.Width > 0 then
      RandB := WR.Right - WR.Left - F.Width;
    if WR.Bottom - WR.Top - F.Height > 0 then
      RandH := WR.Bottom - WR.Top - F.Height;
  end;
  // ein paar Pixel Reserve: der Live-Test zeigte bei 150-175 % noch 3-4 px
  // Überstand (Rahmen nicht ganz in GetWindowRect enthalten)
  Inc(RandH, F.Scale96ToForm(4));
  MaxB := R.Right - R.Left - RandB;
  MaxH := R.Bottom - R.Top - RandH;
  if (MaxB < 200) or (MaxH < 150) then Exit;             // Unsinn gemessen: nichts ändern

  // ----- 2. Auf den Platz begrenzen -----
  if F.Constraints.MinWidth > MaxB then
    F.Constraints.MinWidth := MaxB;
  if F.Constraints.MinHeight > MaxH then
    F.Constraints.MinHeight := MaxH;

  if F.Width > MaxB then
    F.Width := MaxB;
  if F.Height > MaxH then
    F.Height := MaxH;

  // ----- 3. Mindestgrösse kleiner als die Startgrösse -----
  // sonst lässt sich ein verkleinertes Fenster nicht mehr kleiner ziehen
  if (F.BorderStyle in [bsSizeable, bsSizeToolWin]) then
  begin
    if F.Constraints.MinWidth >= F.Width then
      F.Constraints.MinWidth := Max(0, F.Width - F.Scale96ToForm(40));
    if F.Constraints.MinHeight >= F.Height then
      F.Constraints.MinHeight := Max(0, F.Height - F.Scale96ToForm(40));
  end;

  // ----- 4. Fenster, das unten oder rechts über den Rand ragt, zurückschieben -----
  if F.Left + F.Width + RandB > R.Right then F.Left := Max(R.Left, R.Right - F.Width - RandB);
  if F.Top + F.Height + RandH > R.Bottom then
    F.Top := Max(R.Top, R.Bottom - F.Height - RandH);
  if F.Left < R.Left then F.Left := R.Left;
  if F.Top < R.Top then F.Top := R.Top;
end;

{------------------------------------------------------------------------------
  StelleAufBildschirmDPI - siehe Interface
------------------------------------------------------------------------------}
procedure StelleAufBildschirmDPI(F: TCustomForm);
begin
  if F.PixelsPerInch <> Screen.PixelsPerInch then
    F.AutoAdjustLayout(lapAutoAdjustForDPI, F.PixelsPerInch, Screen.PixelsPerInch, 0, 0);
end;

{------------------------------------------------------------------------------
  SkaliereSchriften
------------------------------------------------------------------------------
  Rechnet feste Schriftgrössen eines Elements und aller Elemente darin von
  96 dpi auf PPI um (ruft sich für Unterelemente selbst auf).
  Parameter: C   - Element
             PPI - Bildschirm-Auflösung
------------------------------------------------------------------------------}
procedure SkaliereSchriften(C: TControl; PPI: Integer);
var
  I: Integer;                                            // Zähler für Unterelemente
begin
  // feste Schriftgrössen (Font.Height := -17) sind 96-dpi-Pixel
  with TControlZugriff(C) do
    if not ParentFont and (Font.Height <> 0) then
      Font.Height := MulDiv(Font.Height, PPI, 96);
  if C is TWinControl then
    for I := 0 to TWinControl(C).ControlCount - 1 do
      SkaliereSchriften(TWinControl(C).Controls[I], PPI);
end;

{------------------------------------------------------------------------------
  SkaliereDialog - siehe Interface
------------------------------------------------------------------------------}
procedure SkaliereDialog(F: TCustomForm);
var
  PPI: Integer;                                          // Bildschirm-Auflösung
  I: Integer;                                            // Zähler
begin
  PPI := F.PixelsPerInch;
  if PPI = 96 then Exit;                                 // 100 %: nichts umzurechnen
  F.DisableAutoSizing;
  try
    // Schrift des Fensters selbst: Knöpfe und Labels ohne eigene Schrift erben sie
    if F.Font.Height <> 0 then
      F.Font.Height := MulDiv(F.Font.Height, PPI, 96);
    for I := 0 to F.ControlCount - 1 do
      SkaliereSchriften(F.Controls[I], PPI);
    for I := 0 to F.ControlCount - 1 do
      F.Controls[I].AutoAdjustLayout(lapAutoAdjustForDPI, 96, PPI, 0, 0);
    F.Constraints.AutoAdjustLayout(PPI / 96, PPI / 96);
    F.SetBounds(F.Left, F.Top, MulDiv(F.Width, PPI, 96), MulDiv(F.Height, PPI, 96));
  finally
    F.EnableAutoSizing;
  end;
end;

{------------------------------------------------------------------------------
  FormSichtbar
------------------------------------------------------------------------------
  Wird von Screen aufgerufen, wenn ein Fenster sichtbar oder unsichtbar
  wird. Begrenzt sichtbare Fenster sofort und nochmals etwas später.
------------------------------------------------------------------------------}
procedure TSkalierungWaechter.FormSichtbar(Sender: TObject; Form: TCustomForm);
begin
  if (Form <> nil) and Form.Visible then
  begin
    BegrenzeAufBildschirm(Form);
    // nochmals, wenn das Fenster fertig angezeigt ist: Ausrichtung und
    // OnShow können es danach noch ein paar Pixel höher machen
    // (LedPreResistor bei 150 %: 4 px unter der Taskleiste)
    Application.QueueAsyncCall(@SpaeterPruefen, PtrInt(Form));
  end;
end;

{------------------------------------------------------------------------------
  SpaeterPruefen
------------------------------------------------------------------------------
  Zweite Prüfung, wenn das Fenster fertig angezeigt ist.
  Parameter: Data - das Fenster als Zahl (so verlangt es QueueAsyncCall)
------------------------------------------------------------------------------}
procedure TSkalierungWaechter.SpaeterPruefen(Data: PtrInt);
var
  I: Integer;                                            // Zähler über alle Fenster
begin
  // nur, wenn es das Fenster noch gibt
  for I := 0 to Screen.CustomFormCount - 1 do
    if PtrInt(Screen.CustomForms[I]) = Data then
    begin
      if Screen.CustomForms[I].Visible then
        BegrenzeAufBildschirm(Screen.CustomForms[I]);
      Exit;
    end;
end;

{==============================================================================
  ANMELDEN UND ABMELDEN
==============================================================================}
initialization
  Waechter := TSkalierungWaechter.Create;
  Screen.AddHandlerFormVisibleChanged(@Waechter.FormSichtbar);

finalization
  if Application <> nil then
    Application.RemoveAsyncCalls(Waechter);
  if Screen <> nil then
    Screen.RemoveHandlerFormVisibleChanged(@Waechter.FormSichtbar);
  Waechter.Free;

end.
