{ Hauptfenster von LedPreResistor (Entwurf A «Labor 2» mit LED-Vorschau).
  Verbindet Eingaben, Rechnung (uCalc) und Anzeige: Schaltplan, vier
  Resultatkarten, aufklappbarer Rechenweg und Statuszeile. Gerechnet wird
  live bei jeder Eingabe. Alle sichtbaren Texte stehen als resourcestring
  unten, damit sie später übersetzt werden können (src/lang). }
unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, ExtCtrls, Menus,
  LCLType, Types, uESeries, uColorCode, uCalc, uSkalierung, uLang;

const
  { Programmversion für Titelleiste und Info }
  APP_VER = '2.1';

  { Ko-fi-Seite von Elospeed }
  KOFI_URL = 'https://ko-fi.com/elospeed';

type

  { TFormMain – das Hauptfenster }
  TFormMain = class(TForm)
    CheckBlink: TCheckBox;        // LED blinken lassen
    ComboColor: TComboBox;        // LED-Farbe
    ComboFreq: TComboBox;         // Blinkfrequenz
    ComboSeries: TComboBox;       // E-Reihe
    EditI: TEdit;                 // LED-Strom in mA
    EditN: TEdit;                 // Anzahl LEDs in Reihe
    EditU: TEdit;                 // Speisespannung in V
    EditUd: TEdit;                // Durchlassspannung in V
    LabelBlink: TLabel;
    LabelColor: TLabel;
    LabelHeadInputs: TLabel;
    LabelHeadPreview: TLabel;
    LabelI: TLabel;
    LabelIUnit: TLabel;
    PaintKofi: TPaintBox;         // Ko-fi-Knopf «Kaffee spendieren» unten rechts
    LabelN: TLabel;
    LabelNUnit: TLabel;
    LabelSeries: TLabel;
    LabelU: TLabel;
    LabelUd: TLabel;
    LabelUdUnit: TLabel;
    LabelUUnit: TLabel;
    MainMenu: TMainMenu;
    MenuAbout: TMenuItem;
    MenuBlink: TMenuItem;
    MenuCopy: TMenuItem;
    MenuCopy2: TMenuItem;
    MenuEdit: TMenuItem;
    MenuExit: TMenuItem;
    MenuFile: TMenuItem;
    MenuHelp: TMenuItem;
    MenuKofi: TMenuItem;
    MenuLedInfo: TMenuItem;
    MenuSepHelp: TMenuItem;
    MenuRechenweg: TMenuItem;
    MenuReset: TMenuItem;
    MenuSep1: TMenuItem;
    MenuView: TMenuItem;
    PaintCards: TPaintBox;        // vier Resultatkarten
    PaintLed: TPaintBox;          // LED-Vorschau
    PaintRechenweg: TPaintBox;    // Rechenweg (Kopfzeile und Schritte)
    PaintSchematic: TPaintBox;    // Schaltplan
    PaintStatus: TPaintBox;       // Statuszeile
    PanelLeft: TScrollBox;  // rollt, wenn bei 200 % die Höhe nicht reicht
    PanelPreview: TPanel;
    PanelRechenweg: TPanel;
    PanelRight: TPanel;
    PanelStatus: TPanel;
    TimerBlink: TTimer;           // schaltet die LED beim Blinken um
    procedure BlinkChange(Sender: TObject);
    procedure ComboColorChange(Sender: TObject);
    procedure ComboDrawItem(Control: TWinControl; Index: Integer; ARect: TRect;
      State: TOwnerDrawState);
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure InputChange(Sender: TObject);
    procedure LabelBlinkClick(Sender: TObject);
    procedure KofiClick(Sender: TObject);
    procedure PaintKofiPaint(Sender: TObject);
    procedure PaintKofiMouseEnter(Sender: TObject);
    procedure PaintKofiMouseLeave(Sender: TObject);
    procedure MenuAboutClick(Sender: TObject);
    procedure MenuLedInfoClick(Sender: TObject);
    procedure MenuBlinkClick(Sender: TObject);
    procedure MenuCopyClick(Sender: TObject);
    procedure MenuExitClick(Sender: TObject);
    procedure MenuRechenwegClick(Sender: TObject);
    procedure MenuResetClick(Sender: TObject);
    procedure PaintCardsPaint(Sender: TObject);
    procedure PaintLedPaint(Sender: TObject);
    procedure PaintLedResize(Sender: TObject);
    procedure PaintRechenwegMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintRechenwegPaint(Sender: TObject);
    procedure PaintSchematicPaint(Sender: TObject);
    procedure PaintStatusPaint(Sender: TObject);
    procedure TimerBlinkTimer(Sender: TObject);
  private
    FInput: TCalcInput;      // aktuelle Eingaben (SI-Einheiten)
    FRes: TCalcResult;       // aktuelles Resultat
    FBands: TBandArray;      // Farbringe des Normwerts
    FLedOn: TBitmap;         // LED-Bild leuchtend (zwischengespeichert)
    FLedOff: TBitmap;        // LED-Bild aus (für das Blinken)
    FLedLit: Boolean;        // LED gerade an (beim Blinken wechselnd)
    FLedDirty: Boolean;      // LED-Bilder müssen neu gerechnet werden
    FKofiHover: Boolean;     // Maus ist über dem Ko-fi-Knopf
    FUpdating: Boolean;      // Eingaben werden gerade per Code gesetzt
    KofiCaptionShown: string; // Text des Ko-fi-Knopfs in der aktuellen Sprache
    FRechenwegOpen: Boolean; // Rechenweg aufgeklappt
    MenuLang: TMenuItem;     // Ansicht → Sprache (zur Laufzeit erzeugt)
    MenuLangDe: TMenuItem;   // Sprache Deutsch
    MenuLangEn: TMenuItem;   // Sprache Englisch
    { Menü Ansicht → Sprache mit Deutsch und English anlegen }
    procedure CreateLangMenu;
    { Klick auf eine Sprache im Menü (Tag 0 = Deutsch, 1 = Englisch) }
    procedure MenuLangClick(Sender: TObject);
    { alle Beschriftungen in der aktuellen Sprache setzen; Zahlen in den
      Eingabefeldern bekommen das passende Dezimalzeichen }
    procedure ApplyLanguage;
    { Farben und Schriften aus uTheme auf alle Bedienelemente anwenden }
    procedure ApplyTheme;
    { Auswahllisten mit den (übersetzbaren) Texten füllen }
    procedure FillCombos;
    { Eingaben lesen, rechnen und alles neu zeichnen }
    procedure Recalc;
    { Gewählte LED-Farbe }
    function CurrentLed: TLedColor;
    { LED-Bilder für die aktuelle Farbe und Grösse neu rechnen }
    procedure RenderLedBitmaps;
    { Blink-Timer je nach Häkchen und Frequenz einstellen }
    procedure UpdateBlink;
    { Höhe des Rechenweg-Bereichs je nach auf-/zugeklappt setzen }
    procedure UpdateRechenwegHeight;
    { beim ersten Anzeigen: zu wenig Platz für die LED-Vorschau prüfen }
    procedure FormShowPlatz(Sender: TObject);
    { LED-Vorschau füllt die linke Spalte bis unten; reicht die Höhe nicht,
      rollt die Spalte (Mindesthöhe der Vorschau) }
    procedure PanelLeftResize(Sender: TObject);
    { Rechenweg zuklappen, wenn das Fenster auf einen kleinen Bildschirm
      begrenzt wurde und die LED-Vorschau sonst verschwindet (200 %) }
    procedure RechenwegZuBeiPlatzmangel(Data: PtrInt);
    { Fehlertext zum Status der Rechnung }
    function StatusText(S: TCalcStatus): string;
    { Farbnamen der Ringe, z. B. "gelb · violett · braun · gold" }
    function BandNames(const B: TBandArray; const Sep: string): string;
    { Name der Normreihe, z. B. "E12" }
    function SeriesName(S: TESeries): string;
    { Schritte des Rechenwegs mit den aktuellen Zahlen }
    function RechenwegLines: TStringArray;
    { Zusammenfassung für die Zwischenablage }
    function ResultSummary: string;
    { Rechnet einen Wert aus 96-dpi-Pixeln auf die aktuelle Bildschirmskalierung um }
    function Px(V: Integer): Integer;
  end;

var
  FormMain: TFormMain;  // die einzige Instanz des Hauptfensters

resourcestring
  rsCaption = 'LedPreResistor · Elospeed %s';
  rsLedRed = 'Rot';
  rsLedYellow = 'Gelb';
  rsLedGreen = 'Grün';
  rsLedBlue = 'Blau';
  rsLedWhite = 'Weiss';
  rsLedInfrared = 'Infrarot';
  rsLedNameRed = 'rot';
  rsLedNameYellow = 'gelb';
  rsLedNameGreen = 'grün';
  rsLedNameBlue = 'blau';
  rsLedNameWhite = 'weiss';
  rsLedNameInfrared = 'Infrarot';
  rsSeriesE12 = 'E12 (±10 %)';
  rsSeriesE24 = 'E24 (±5 %)';
  rsSeriesE96 = 'E96 (±1 %)';
  rsFreq = '%s Hz';
  rsAnode = 'Anode +';
  rsAnodeHint = 'langes Bein';
  rsCathode = 'Kathode −';
  rsCathodeHint1 = 'kurzes Bein,';
  rsCathodeHint2 = 'flache Seite';
  rsFlat = 'flach';
  rsBlack = 'schwarz';
  rsBrown = 'braun';
  rsRed = 'rot';
  rsOrange = 'orange';
  rsYellow = 'gelb';
  rsGreen = 'grün';
  rsBlue = 'blau';
  rsViolet = 'violett';
  rsGrey = 'grau';
  rsWhite = 'weiss';
  rsGold = 'gold';
  rsSilver = 'silber';
  rsSchemLed = 'LED %s';
  rsSchemLedN = '%d × LED %s';
  rsSchemUF = 'U_F = %s';
  rsSchemUFN = 'U_F = %d × %s';
  rsCardStd = 'Normwert (%s)';
  rsCardCurrent = 'Tatsächlicher Strom';
  rsCardCurrentSub = 'berechnet %s → %s';
  rsCardPower = 'Verlustleistung';
  rsCardPowerSub = 'am Widerstand';
  rsCardRating = 'Empfohlene Bauform';
  rsCardRatingSub = '%s wäre zu %s belastet';
  rsCardRatingSubOk = '%s zu %s belastet';
  rsCardRatingNone = '> 1 W';
  rsCardRatingNoneSub = 'zu viel für einen Vorwiderstand';
  rsRechenweg = 'Rechenweg';
  rsStep1 = 'Spannung am Widerstand: U_R = U_B − U_F = %s − %s = **%s**';
  rsStep1N = 'Spannung am Widerstand: U_R = U_B − n × U_F = %s − %d × %s = **%s**';
  rsKofi = 'Kaffee spendieren';
  rsStep2 = 'Idealer Widerstand: R = U_R / I = %s / %s A = **%s** → nächster %s-Wert darüber: **%s**';
  rsStep3 = 'Tatsächlicher Strom: I = %s / %s = **%s**';
  rsStep4 = 'Verlustleistung: P = U_R × I = %s × %s = **%s** → %s zu %s ausgelastet%s → **%s**';
  rsStep4Over50 = ' (> 50 %)';
  rsStep4None = 'Verlustleistung: P = U_R × I = %s × %s = **%s** → mehr als 0,5 W: **Konstantstromquelle oder grössere Bauform**';
  rsStep5 = 'Erwärmung (Schätzung): ΔT ≈ P × R_t_h = %s × %d °C/W ≈ **+%d °C** (bei %s)';
  rsStatusLoad = 'Auslastung %s';
  rsStatusWarn = '%s würde ca. +%d °C warm – %s empfohlen';
  rsStatusOk = '%s wird ca. +%d °C warm – reicht';
  rsStatusNone = '%s würde ca. +%d °C warm – Leistung zu gross für einen Vorwiderstand';
  rsStatusTotal = 'Gesamtleistung %s';
  rsErrU = 'Bitte eine Speisespannung grösser als 0 eingeben.';
  rsErrUd = 'Bitte eine Durchlassspannung grösser als 0 eingeben.';
  rsErrI = 'Bitte einen LED-Strom grösser als 0 eingeben.';
  rsErrN = 'Bitte mindestens 1 LED angeben (ganze Zahl).';
  rsErrUTooLow = 'Die Speisespannung (%s) muss grösser sein als %d × %s = %s.';
  rsErrNoStd = 'Kein Normwert gefunden.';
  rsCopyTitle = 'LedPreResistor %s – Vorwiderstand';
  rsCopyInput = 'Speisespannung %s, %d × LED %s mit U_F = %s, Strom %s';
  rsCopyStd = 'Vorwiderstand: %s (%s, %s), berechnet %s';
  rsCopyCurrent = 'Tatsächlicher Strom: %s';
  rsCopyPower = 'Leistung Widerstand: %s, LEDs: %s, gesamt: %s';
  rsCopyRating = 'Empfohlene Bauform: %s (%s zu %s ausgelastet)';
  rsLedInfoFailed = 'Die LED-Info konnte nicht geöffnet werden.';
  { Beschriftungen, die im Formular (uMain.lfm) deutsch stehen; sie werden
    in ApplyLanguage zur Laufzeit gesetzt }
  rsHeadInputs = 'EINGABEN';
  rsLabelU = 'Speisespannung';
  rsLabelColor = 'LED-Farbe';
  rsLabelUd = 'Durchlassspannung';
  rsLabelI = 'LED-Strom';
  rsLabelSeries = 'E-Reihe';
  rsLabelN = 'LEDs in Reihe';
  rsUnitN = 'Stk.';
  rsHeadPreview = 'LED-VORSCHAU';
  rsBlink = 'Blinken';
  rsMenuFile = '&Datei';
  rsMenuCopy = 'Resultat &kopieren';
  rsMenuExit = '&Beenden';
  rsMenuEdit = '&Bearbeiten';
  rsMenuReset = 'Eingaben &zurücksetzen';
  rsMenuView = '&Ansicht';
  rsMenuRechenweg = '&Rechenweg';
  rsMenuBlink = 'LED &blinken';
  rsMenuLang = '&Sprache (Language)';
  rsMenuHelp = '&Hilfe';
  rsMenuLedInfo = '&LED-Info (Die Leuchtdiode) …';
  rsMenuKofi = 'Einen Kaffee spendieren (Ko-fi) …';
  rsMenuAbout = 'Ü&ber LedPreResistor …';
  rsAbout = 'LedPreResistor %s' + LineEnding + 'Vorwiderstand für LEDs berechnen.' + LineEnding + LineEnding +
    '© 2026 Elospeed – freie Software (MIT-Lizenz)' + LineEnding +
    'Neuauflage der Freeware «LED Pre-Resistor» von 2004.';

implementation

uses
  Math, Clipbrd, LCLIntf, Dialogs, uTheme, uFormat, uLedView, uSchematic, uRichText, uLedInfo, uKofiButton;

{$R *.lfm}

const
  { Blinkfrequenzen in Hz für die Auswahlliste }
  FREQS: array[0..3] of Double = (0.5, 1, 2, 5);

function TFormMain.Px(V: Integer): Integer;
begin
  Result := Scale96ToForm(V);
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  // Sprache vor allen Beschriftungen laden (INI, sonst Sprache von Windows)
  LangLoad(LangStartCode);
  CreateLangMenu;
  FLedOn := TBitmap.Create;
  FLedOff := TBitmap.Create;
  FLedLit := True;
  FLedDirty := True;
  FRechenwegOpen := True;
  FUpdating := True;
  try
    FillCombos;
    ComboColor.ItemIndex := Ord(lcWhite);
    ComboSeries.ItemIndex := Ord(esE12);
    ComboFreq.ItemIndex := 1;  // 1 Hz
  finally
    FUpdating := False;
  end;
  ApplyLanguage;
  ApplyTheme;
  UpdateRechenwegHeight;
  Recalc;
  OnShow := @FormShowPlatz;
  PanelLeft.OnResize := @PanelLeftResize;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  FLedOn.Free;
  FLedOff.Free;
end;

procedure TFormMain.ApplyTheme;
var
  I: Integer;   // Zähler über die Bedienelemente der linken Spalte
  C: TControl;  // aktuelles Bedienelement
begin
  Color := clrWindow;
  Font.Name := FONT_UI;
  Font.Color := clrText;
  PanelLeft.Color := clrPanel;
  PanelRight.Color := clrWindow;
  PanelRechenweg.Color := clrWindow;
  PanelStatus.Color := clrBar;
  PanelPreview.Color := clrDeep;

  for I := 0 to PanelLeft.ControlCount - 1 do
  begin
    C := PanelLeft.Controls[I];
    if C is TEdit then
    begin
      TEdit(C).Color := clrDeep;
      TEdit(C).Font.Color := clrTextBright;
      TEdit(C).Font.Name := FONT_MONO;
      TEdit(C).Font.Size := 10;
    end
    else if C is TComboBox then
    begin
      TComboBox(C).Color := clrDeep;
      TComboBox(C).Font.Color := clrTextBright;
    end
    else if C is TLabel then
      TLabel(C).Font.Color := clrText;
  end;
  // Einheiten und Überschriften gedämpft
  LabelUUnit.Font.Color := clrTextDim;
  LabelUdUnit.Font.Color := clrTextDim;
  LabelIUnit.Font.Color := clrTextDim;
  LabelNUnit.Font.Color := clrTextDim;
  LabelHeadInputs.Font.Color := clrTextDim;
  LabelHeadPreview.Font.Color := clrTextDim;
  LabelHeadInputs.Font.Size := 8;
  LabelHeadPreview.Font.Size := 8;
  LabelBlink.Font.Color := clrText;
  ComboFreq.Color := clrDeep;
  ComboFreq.Font.Color := clrTextBright;
  // Breite des Ko-fi-Links: Herz + Text + Rand
  PaintKofi.Canvas.Font.Name := FONT_UI;
  PaintKofi.Canvas.Font.Size := 9;
  PaintKofi.Canvas.Font.Style := [fsBold];
  { das Fenster steht hier noch auf 96 dpi und wird danach umgerechnet:
    darum mit 96 dpi messen, nicht mit Screen.PixelsPerInch (sonst ist der
    Rand bei 150 % doppelt skaliert) }
  PaintKofi.Width := KofiButtonWidth(PaintKofi.Canvas, _(rsKofi), PixelsPerInch);
end;

procedure TFormMain.CreateLangMenu;

  { einen Eintrag der Sprachliste anlegen }
  function AddItem(const ACaption: string; ATag: Integer): TMenuItem;
  begin
    Result := TMenuItem.Create(Self);
    Result.Caption := ACaption;   // Sprachnamen bleiben unübersetzt
    Result.Tag := ATag;
    Result.RadioItem := True;
    Result.GroupIndex := 1;
    Result.OnClick := @MenuLangClick;
    MenuLang.Add(Result);
  end;

begin
  MenuLang := TMenuItem.Create(Self);
  MenuView.Add(MenuLang);
  MenuLangDe := AddItem('Deutsch', 0);
  MenuLangEn := AddItem('English', 1);
end;

procedure TFormMain.MenuLangClick(Sender: TObject);
var
  Code: string;  // gewählte Sprache
begin
  if (Sender as TMenuItem).Tag = 1 then Code := 'en' else Code := 'de';
  if Code = LangCode then Exit;
  LangLoad(Code);
  LangSaveChoice(Code);
  ApplyLanguage;
end;

procedure TFormMain.ApplyLanguage;
var
  OldKofi: string;  // Ko-fi-Text vor dem Wechsel (für die Breite)
  OldDec: Char;     // Dezimalzeichen vor dem Wechsel
  Idx: array[0..2] of Integer;  // gewählte Einträge der drei Listen

  { Dezimalzeichen in einem Eingabefeld tauschen }
  procedure SwapDecimal(E: TEdit);
  begin
    E.Text := StringReplace(E.Text, OldDec, DisplayDecimal, [rfReplaceAll]);
  end;

begin
  // Zahlen: Komma auf Deutsch, Punkt auf Englisch; Prozent mit/ohne Leerschlag
  OldDec := DisplayDecimal;
  if LangCode = 'en' then
  begin
    DisplayDecimal := '.';
    PercentSpace := '';
  end
  else
  begin
    DisplayDecimal := ',';
    PercentSpace := ' ';
  end;
  OldKofi := KofiCaptionShown;
  KofiCaptionShown := _(rsKofi);

  Caption := Format(_(rsCaption), [APP_VER]);
  LabelHeadInputs.Caption := _(rsHeadInputs);
  LabelU.Caption := _(rsLabelU);
  LabelColor.Caption := _(rsLabelColor);
  LabelUd.Caption := _(rsLabelUd);
  LabelI.Caption := _(rsLabelI);
  LabelSeries.Caption := _(rsLabelSeries);
  LabelN.Caption := _(rsLabelN);
  LabelNUnit.Caption := _(rsUnitN);
  LabelHeadPreview.Caption := _(rsHeadPreview);
  LabelBlink.Caption := _(rsBlink);
  MenuFile.Caption := _(rsMenuFile);
  MenuCopy.Caption := _(rsMenuCopy);
  MenuCopy2.Caption := _(rsMenuCopy);
  MenuExit.Caption := _(rsMenuExit);
  MenuEdit.Caption := _(rsMenuEdit);
  MenuReset.Caption := _(rsMenuReset);
  MenuView.Caption := _(rsMenuView);
  MenuRechenweg.Caption := _(rsMenuRechenweg);
  MenuBlink.Caption := _(rsMenuBlink);
  MenuLang.Caption := _(rsMenuLang);
  MenuHelp.Caption := _(rsMenuHelp);
  MenuLedInfo.Caption := _(rsMenuLedInfo);
  MenuKofi.Caption := _(rsMenuKofi);
  MenuAbout.Caption := _(rsMenuAbout);
  MenuLangDe.Checked := LangCode <> 'en';
  MenuLangEn.Checked := LangCode = 'en';

  // Auswahllisten neu füllen, gewählte Einträge behalten
  FUpdating := True;
  try
    Idx[0] := ComboColor.ItemIndex;
    Idx[1] := ComboSeries.ItemIndex;
    Idx[2] := ComboFreq.ItemIndex;
    FillCombos;
    ComboColor.ItemIndex := Idx[0];
    ComboSeries.ItemIndex := Idx[1];
    ComboFreq.ItemIndex := Idx[2];
    if OldDec <> DisplayDecimal then
    begin
      SwapDecimal(EditU);
      SwapDecimal(EditUd);
      SwapDecimal(EditI);
      SwapDecimal(EditN);
    end;
  finally
    FUpdating := False;
  end;

  { Ko-fi-Knopf: nur beim Wechsel zur Laufzeit um den Unterschied der
    Textbreite anpassen. Beim Start setzt ApplyTheme die Breite (dort
    noch vor der DPI-Umrechnung). So wird nichts doppelt skaliert. }
  if (OldKofi <> '') and (OldKofi <> KofiCaptionShown) then
  begin
    PaintKofi.Canvas.Font.Name := FONT_UI;
    PaintKofi.Canvas.Font.Size := 9;
    PaintKofi.Canvas.Font.Style := [fsBold];
    PaintKofi.Width := PaintKofi.Width + PaintKofi.Canvas.TextWidth(KofiCaptionShown)
      - PaintKofi.Canvas.TextWidth(OldKofi);
    PaintKofi.Invalidate;
  end;

  FLedDirty := True;  // Beschriftung der LED (Anode/Kathode)
  PaintLed.Invalidate;
  ComboColor.Invalidate;
  Recalc;
end;

procedure TFormMain.FillCombos;
var
  F: Double;  // Frequenz
begin
  ComboColor.Items.Clear;
  ComboColor.Items.Add(_(rsLedRed));
  ComboColor.Items.Add(_(rsLedYellow));
  ComboColor.Items.Add(_(rsLedGreen));
  ComboColor.Items.Add(_(rsLedBlue));
  ComboColor.Items.Add(_(rsLedWhite));
  ComboColor.Items.Add(_(rsLedInfrared));
  ComboSeries.Items.Clear;
  ComboSeries.Items.Add(_(rsSeriesE12));
  ComboSeries.Items.Add(_(rsSeriesE24));
  ComboSeries.Items.Add(_(rsSeriesE96));
  ComboFreq.Items.Clear;
  for F in FREQS do
    ComboFreq.Items.Add(Format(_(rsFreq), [FormatNum(F, 1, 0)]));
end;

function TFormMain.CurrentLed: TLedColor;
begin
  if ComboColor.ItemIndex < 0 then
    Result := lcWhite
  else
    Result := TLedColor(ComboColor.ItemIndex);
end;

function TFormMain.SeriesName(S: TESeries): string;
begin
  case S of
    esE12: Result := 'E12';
    esE24: Result := 'E24';
  else
    Result := 'E96';
  end;
end;

function TFormMain.BandNames(const B: TBandArray; const Sep: string): string;
var
  I: Integer;   // Ring-Zähler
  N: string;    // Name eines Rings
begin
  Result := '';
  for I := 0 to High(B) do
  begin
    case B[I] of
      bcBlack: N := _(rsBlack);
      bcBrown: N := _(rsBrown);
      bcRed: N := _(rsRed);
      bcOrange: N := _(rsOrange);
      bcYellow: N := _(rsYellow);
      bcGreen: N := _(rsGreen);
      bcBlue: N := _(rsBlue);
      bcViolet: N := _(rsViolet);
      bcGrey: N := _(rsGrey);
      bcWhite: N := _(rsWhite);
      bcGold: N := _(rsGold);
    else
      N := _(rsSilver);
    end;
    if I > 0 then
      Result := Result + Sep;
    Result := Result + N;
  end;
end;

function TFormMain.StatusText(S: TCalcStatus): string;
begin
  case S of
    csInvalidU: Result := _(rsErrU);
    csInvalidUd: Result := _(rsErrUd);
    csInvalidI: Result := _(rsErrI);
    csInvalidN: Result := _(rsErrN);
    csUTooLow: Result := Format(_(rsErrUTooLow), [FormatVolt(FInput.U), FInput.N,
      FormatVolt(FInput.Ud), FormatVolt(FInput.N * FInput.Ud)]);
    csNoStdValue: Result := _(rsErrNoStd);
  else
    Result := '';
  end;
end;

procedure TFormMain.Recalc;
var
  V: Double;  // umgewandelte Eingabe
begin
  if FUpdating then Exit;
  FInput := Default(TCalcInput);
  if ParseDecimal(EditU.Text, V) then FInput.U := V;
  if ParseDecimal(EditUd.Text, V) then FInput.Ud := V;
  if ParseDecimal(EditI.Text, V) then FInput.I := V / 1000;
  // Anzahl nur als ganze Zahl gültig
  if ParseDecimal(EditN.Text, V) and (Frac(V) = 0) and (V >= 1) and (V <= 1000) then
    FInput.N := Round(V)
  else
    FInput.N := 0;
  if ComboSeries.ItemIndex >= 0 then
    FInput.Series := TESeries(ComboSeries.ItemIndex);
  FInput.RatingW := RATING_REFERENCE;

  FRes := Calculate(FInput);
  if (FRes.Status <> csOk) or not ColorBands(FRes.Std, FInput.Series, FBands) then
    FBands := nil;

  PaintSchematic.Invalidate;
  PaintCards.Invalidate;
  PaintRechenweg.Invalidate;
  PaintStatus.Invalidate;
end;

procedure TFormMain.InputChange(Sender: TObject);
begin
  Recalc;
end;

procedure TFormMain.ComboColorChange(Sender: TObject);
begin
  if FUpdating then Exit;
  // Vorgabe der Durchlassspannung für die gewählte Farbe übernehmen
  FUpdating := True;
  try
    EditUd.Text := FormatNum(LED_DEFAULT_UD[CurrentLed], 2, 1);
  finally
    FUpdating := False;
  end;
  FLedDirty := True;
  PaintLed.Invalidate;
  ComboColor.Invalidate;
  Recalc;
end;

procedure TFormMain.ComboDrawItem(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  Cb: TComboBox;   // die Liste, die gezeichnet wird
  X, D: Integer;   // Textposition und Durchmesser des Farbpunkts
begin
  Cb := Control as TComboBox;
  with Cb.Canvas do
  begin
    if odSelected in State then
      Brush.Color := clrBorder
    else
      Brush.Color := clrDeep;
    FillRect(ARect);
    X := ARect.Left + Px(6);
    // Farbpunkt vor jeder LED-Farbe
    if (Cb = ComboColor) and (Index >= 0) then
    begin
      D := Px(10);
      Brush.Color := LedGlowColor(TLedColor(Index));
      Pen.Color := clrEditBorder;
      Ellipse(X, (ARect.Top + ARect.Bottom - D) div 2, X + D, (ARect.Top + ARect.Bottom + D) div 2);
      Inc(X, D + Px(6));
    end;
    Brush.Style := bsClear;
    Font.Color := clrTextBright;
    if Index >= 0 then
      TextOut(X, (ARect.Top + ARect.Bottom - TextHeight('Ag')) div 2, Cb.Items[Index]);
    Brush.Style := bsSolid;
  end;
end;

procedure TFormMain.EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  E: TEdit;       // Eingabefeld
  V, Step: Double; // Wert und Schrittweite
begin
  if not (Key in [VK_UP, VK_DOWN]) then Exit;
  E := Sender as TEdit;
  if not ParseDecimal(E.Text, V) then V := 0;
  Step := E.Tag / 1000;  // Tag = Schrittweite in Tausendsteln
  if ssShift in Shift then Step := Step * 10;
  if Key = VK_UP then V := V + Step else V := V - Step;
  if E = EditN then V := Max(1, V) else V := Max(0, V);
  E.Text := FormatNum(V, 2, 0);
  E.SelStart := Length(E.Text);
  Key := 0;
end;

procedure TFormMain.EditMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  K: Word;  // simulierte Pfeiltaste
begin
  if WheelDelta > 0 then K := VK_UP else K := VK_DOWN;
  EditKeyDown(Sender, K, Shift);
  Handled := True;
end;

{ ---------- LED-Vorschau ---------- }

procedure TFormMain.RenderLedBitmaps;
var
  L: TLedLabels;  // Beschriftung
begin
  L.Anode := _(rsAnode);
  L.AnodeHint := _(rsAnodeHint);
  L.Cathode := _(rsCathode);
  L.CathodeHint1 := _(rsCathodeHint1);
  L.CathodeHint2 := _(rsCathodeHint2);
  L.Flat := _(rsFlat);
  RenderLed(FLedOn, PaintLed.Width, PaintLed.Height, LedGlowColor(CurrentLed), clrDeep, 1.0, L, clrTextSoft);
  RenderLed(FLedOff, PaintLed.Width, PaintLed.Height, LedGlowColor(CurrentLed), clrDeep, 0.0, L, clrTextSoft);
  FLedDirty := False;
end;

procedure TFormMain.PaintLedPaint(Sender: TObject);
begin
  if FLedDirty or (FLedOn.Width <> PaintLed.Width) or (FLedOn.Height <> PaintLed.Height) then
    RenderLedBitmaps;
  if FLedLit or not TimerBlink.Enabled then
    PaintLed.Canvas.Draw(0, 0, FLedOn)
  else
    PaintLed.Canvas.Draw(0, 0, FLedOff);
end;

procedure TFormMain.PaintLedResize(Sender: TObject);
begin
  FLedDirty := True;
end;

procedure TFormMain.UpdateBlink;
var
  F: Double;  // Frequenz in Hz
begin
  if (ComboFreq.ItemIndex >= 0) and (ComboFreq.ItemIndex <= High(FREQS)) then
    F := FREQS[ComboFreq.ItemIndex]
  else
    F := 1;
  // eine Periode = an + aus, darum halbe Periodendauer
  TimerBlink.Interval := Round(500 / F);
  TimerBlink.Enabled := CheckBlink.Checked;
  MenuBlink.Checked := CheckBlink.Checked;
  FLedLit := True;
  PaintLed.Invalidate;
end;

procedure TFormMain.BlinkChange(Sender: TObject);
begin
  UpdateBlink;
end;

procedure TFormMain.LabelBlinkClick(Sender: TObject);
begin
  CheckBlink.Checked := not CheckBlink.Checked;
end;

procedure TFormMain.MenuBlinkClick(Sender: TObject);
begin
  CheckBlink.Checked := not CheckBlink.Checked;
end;

procedure TFormMain.TimerBlinkTimer(Sender: TObject);
begin
  FLedLit := not FLedLit;
  PaintLed.Invalidate;
end;

{ ---------- Schaltplan ---------- }

procedure TFormMain.PaintSchematicPaint(Sender: TObject);
var
  V: TSchematicValues;  // Texte und Farben für den Schaltplan
  R: TRect;             // Zeichenfläche
  LedName: string;      // Farbname der LED im Text
  Dash: string;         // Platzhalter bei ungültigen Eingaben
begin
  R := PaintSchematic.ClientRect;
  with PaintSchematic.Canvas do
  begin
    Brush.Color := clrDeep;
    Pen.Color := clrBorder;
    Pen.Width := 1;
    Rectangle(R);
  end;
  case CurrentLed of
    lcRed: LedName := _(rsLedNameRed);
    lcYellow: LedName := _(rsLedNameYellow);
    lcGreen: LedName := _(rsLedNameGreen);
    lcBlue: LedName := _(rsLedNameBlue);
    lcWhite: LedName := _(rsLedNameWhite);
  else
    LedName := _(rsLedNameInfrared);
  end;
  Dash := '–';
  V := Default(TSchematicValues);
  V.LedColor := LedGlowColor(CurrentLed);
  if FInput.U > 0 then V.UBText := 'U_B = ' + FormatVolt(FInput.U) else V.UBText := 'U_B = ' + Dash;
  if FInput.N > 1 then
  begin
    V.LedText := Format(_(rsSchemLedN), [FInput.N, LedName]);
    V.UFText := Format(_(rsSchemUFN), [FInput.N, FormatVolt(FInput.Ud)]);
  end
  else
  begin
    V.LedText := Format(_(rsSchemLed), [LedName]);
    V.UFText := Format(_(rsSchemUF), [FormatVolt(FInput.Ud)]);
  end;
  if FRes.Status = csOk then
  begin
    V.RText := 'R = ' + FormatOhm(FRes.R);
    V.URText := 'U_R = ' + FormatVolt(FRes.UR);
    V.IText := 'I = ' + FormatMilliAmp(FRes.IAct);
    V.Bands := FBands;
  end
  else
  begin
    V.RText := 'R = ' + Dash;
    V.URText := 'U_R = ' + Dash;
    V.IText := 'I = ' + Dash;
  end;
  InflateRect(R, -Px(20), -Px(20));
  DrawSchematic(PaintSchematic.Canvas, R, V, clrLine, clrLine, clrAccent, clrPanel);
end;

{ ---------- Resultatkarten ---------- }

procedure TFormMain.PaintCardsPaint(Sender: TObject);
var
  C: TCanvas;          // Zeichenfläche
  Gap, W, X: Integer;  // Abstand, Gesamtbreite, laufende Position
  CW: array[0..3] of Integer; // Breite der Karten
  I: Integer;          // Kartenzähler
  R: TRect;            // aktuelle Karte
  Pad: Integer;        // Innenabstand
  ValueColor: TColor;  // Farbe des Hauptwerts
  Lvl: TLoadLevel;     // Bewertung der Referenz-Bauform
  BarR: TRect;         // Balken der Auslastung
  Ok: Boolean;         // Resultat gültig
  Ringe: string;       // Farbnamen der Ringe
  K: Integer;          // Trennstelle für zwei Zeilen

  { Kartenrahmen, Titel, grosser Wert und Untertext }
  procedure Card(const ATitle, AValue, ASub: string; AValueColor: TColor);
  var
    Y: Integer;       // laufende Zeile
    TS: TTextStyle;   // Textausrichtung mit Zeilenumbruch
  begin
    C.Brush.Style := bsSolid;
    C.Brush.Color := clrPanel;
    C.Pen.Color := clrBorder;
    C.Pen.Width := 1;
    C.Rectangle(R);
    C.Brush.Style := bsClear;
    Y := R.Top + Pad;
    C.Font.Name := FONT_UI;
    C.Font.Size := 8;
    C.Font.Style := [];
    C.Font.Color := clrTextDim;
    C.TextOut(R.Left + Pad, Y, ATitle);
    Inc(Y, C.TextHeight('Ag') + Px(2));
    C.Font.Size := 15;
    C.Font.Style := [fsBold];
    C.Font.Color := AValueColor;
    C.TextOut(R.Left + Pad, Y, AValue);
    Inc(Y, C.TextHeight('Ag'));
    C.Font.Size := 8;
    C.Font.Style := [];
    C.Font.Color := clrTextSoft;
    if ASub <> '' then
    begin
      // Untertext darf auf zwei Zeilen umbrechen
      TS := C.TextStyle;
      TS.Wordbreak := True;
      TS.SingleLine := False;
      TS.Clipping := True;
      C.TextRect(Types.Rect(R.Left + Pad, Y, R.Right - Pad, R.Bottom - Pad - Px(8)), R.Left + Pad, Y, ASub, TS);
    end;
  end;

begin
  C := PaintCards.Canvas;
  C.Brush.Color := clrWindow;
  C.FillRect(PaintCards.ClientRect);
  Gap := Px(8);
  Pad := Px(10);
  W := PaintCards.Width - 3 * Gap;
  // Verhältnis 1,15 : 1 : 1 : 1 wie im Entwurf
  CW[0] := Round(W * 1.15 / 4.15);
  CW[1] := (W - CW[0]) div 3;
  CW[2] := CW[1];
  CW[3] := W - CW[0] - 2 * CW[1];
  Ok := FRes.Status = csOk;
  X := 0;
  for I := 0 to 3 do
  begin
    R := Types.Rect(X, 0, X + CW[I], PaintCards.Height);
    { nichts über den Kartenrand hinaus zeichnen (schmales Fenster, 150 %) }
    C.ClipRect := R;
    C.Clipping := True;
    case I of
      0:
        if Ok then
        begin
          Card(Format(_(rsCardStd), [SeriesName(FInput.Series)]), FormatOhm(FRes.R), '', clrTextBright);
          // Widerstand mit Farbringen und Farbnamen darunter
          C.Font.Size := 8;
          C.Font.Color := clrTextSoft;
          C.Brush.Style := bsClear;
          Ringe := BandNames(FBands, ' · ');
          K := 0;
          if C.TextWidth(Ringe) > R.Right - R.Left - 2 * Pad then
          begin
            // zu schmal: nach dem zweiten Ring umbrechen
            K := Pos(' · ', Ringe);
            K := Pos(' · ', Ringe, K + 1);
            if K = 0 then K := Pos(' · ', Ringe);
          end;
          // Oberkante der Farbnamen (eine oder zwei Zeilen)
          if K > 0 then
            BarR.Top := R.Bottom - Pad - 2 * C.TextHeight('Ag')
          else
            BarR.Top := R.Bottom - Pad - C.TextHeight('Ag');
          // Widerstand mit Farbringen, nie über den Farbnamen
          BarR.Bottom := Min(R.Top + Px(80), BarR.Top - Px(4));
          // und nie über dem Wert: dann lieber flacher zeichnen
          BarR.Left := Max(R.Top + Px(58), BarR.Bottom - Px(24));  // hier: Oberkante des Widerstands
          if BarR.Bottom - BarR.Left >= Px(10) then
            DrawResistor(C, Types.Rect(R.Left + Pad, BarR.Left,
              R.Left + Pad + Min(Px(150), R.Right - R.Left - 2 * Pad), BarR.Bottom), FBands);
          C.Font.Size := 8;
          C.Font.Color := clrTextSoft;
          C.Brush.Style := bsClear;
          if K = 0 then
            C.TextOut(R.Left + Pad, BarR.Top, Ringe)
          else
          begin
            C.TextOut(R.Left + Pad, BarR.Top, Copy(Ringe, 1, K - 1));
            C.TextOut(R.Left + Pad, BarR.Top + C.TextHeight('Ag'), Copy(Ringe, K + Length(' · '), MaxInt));
          end;
        end
        else
          Card(Format(_(rsCardStd), [SeriesName(FInput.Series)]), '–', '', clrTextBright);
      1:
        if Ok then
          Card(_(rsCardCurrent), FormatMilliAmp(FRes.IAct),
            Format(_(rsCardCurrentSub), [FormatOhm(FRes.RCalc), FormatMilliAmp(FInput.I)]), clrTextBright)
        else
          Card(_(rsCardCurrent), '–', '', clrTextBright);
      2:
        if Ok then
          Card(_(rsCardPower), FormatPower(FRes.PR), _(rsCardPowerSub), clrTextBright)
        else
          Card(_(rsCardPower), '–', '', clrTextBright);
      3:
        if Ok then
        begin
          Lvl := LoadLevelOf(FRes.Load);
          if FRes.RecommendedW = 0 then
            Card(_(rsCardRating), _(rsCardRatingNone), _(rsCardRatingNoneSub), clrError)
          else
          begin
            case Lvl of
              llOk: ValueColor := clrOk;
              llWarning: ValueColor := clrWarn;
            else
              ValueColor := clrError;
            end;
            if Lvl = llOk then
              Card(_(rsCardRating), FormatRating(FRes.RecommendedW),
                Format(_(rsCardRatingSubOk), [FormatRating(RATING_REFERENCE), FormatPercent(FRes.Load)]), ValueColor)
            else
              Card(_(rsCardRating), FormatRating(FRes.RecommendedW),
                Format(_(rsCardRatingSub), [FormatRating(RATING_REFERENCE), FormatPercent(FRes.Load)]), ValueColor);
          end;
          // Balken: Auslastung der ¼-W-Bauform, Markierung bei 50 %
          BarR := Types.Rect(R.Left + Pad, R.Bottom - Pad - Px(6), R.Right - Pad, R.Bottom - Pad);
          C.Brush.Style := bsSolid;
          C.Brush.Color := clrDeep;
          C.FillRect(BarR);
          case Lvl of
            llOk: C.Brush.Color := clrOk;
            llWarning: C.Brush.Color := clrWarn;
          else
            C.Brush.Color := clrError;
          end;
          C.FillRect(Types.Rect(BarR.Left, BarR.Top,
            BarR.Left + Round((BarR.Right - BarR.Left) * Min(1, FRes.Load)), BarR.Bottom));
          C.Pen.Color := clrTextDim;
          C.Line((BarR.Left + BarR.Right) div 2, BarR.Top - Px(2), (BarR.Left + BarR.Right) div 2, BarR.Bottom + Px(2));
        end
        else
          Card(_(rsCardRating), '–', '', clrTextBright);
    end;
    C.Clipping := False;
    Inc(X, CW[I] + Gap);
  end;
end;

{ ---------- Rechenweg ---------- }

function TFormMain.RechenwegLines: TStringArray;
var
  Over: string;  // Zusatz "(> 50 %)"
begin
  Result := nil;
  if FRes.Status <> csOk then
  begin
    SetLength(Result, 1);
    Result[0] := StatusText(FRes.Status);
    Exit;
  end;
  SetLength(Result, 5);
  if FInput.N > 1 then
    Result[0] := Format(_(rsStep1N), [FormatVolt(FInput.U), FInput.N, FormatVolt(FInput.Ud), FormatVolt(FRes.UR)])
  else
    Result[0] := Format(_(rsStep1), [FormatVolt(FInput.U), FormatVolt(FInput.Ud), FormatVolt(FRes.UR)]);
  Result[1] := Format(_(rsStep2), [FormatVolt(FRes.UR), FormatNum(FInput.I, 4, 3),
    FormatOhm(FRes.RCalc), SeriesName(FInput.Series), FormatOhm(FRes.R)]);
  Result[2] := Format(_(rsStep3), [FormatVolt(FRes.UR), FormatOhm(FRes.R), FormatMilliAmp(FRes.IAct)]);
  if FRes.Load > LOAD_WARN then Over := _(rsStep4Over50) else Over := '';
  if FRes.RecommendedW = 0 then
    Result[3] := Format(_(rsStep4None), [FormatVolt(FRes.UR), FormatMilliAmp(FRes.IAct), FormatPower(FRes.PR)])
  else
    Result[3] := Format(_(rsStep4), [FormatVolt(FRes.UR), FormatMilliAmp(FRes.IAct), FormatPower(FRes.PR),
      FormatRating(RATING_REFERENCE), FormatPercent(FRes.Load), Over, FormatRating(FRes.RecommendedW)]);
  Result[4] := Format(_(rsStep5), [FormatPower(FRes.PR), Round(RTH_QUARTER_WATT),
    Round(FRes.TempRise), FormatRating(RATING_REFERENCE)]);
end;

procedure TFormMain.UpdateRechenwegHeight;
var
  NeuH, Mehr: Integer;  // neue Höhe, zusätzlicher Platzbedarf
begin
  if FRechenwegOpen then
    NeuH := Px(158)
  else
    NeuH := Px(30);
  Mehr := NeuH - PanelRechenweg.Height;
  { Unterkante behalten und nach oben wachsen: nur Height setzen schiebt
    das Feld unter die Statuszeile (alBottom ordnet nach Top) }
  PanelRechenweg.SetBounds(PanelRechenweg.Left, PanelRechenweg.Top - Mehr,
    PanelRechenweg.Width, NeuH);
  { Die Fensterhöhe bleibt gleich: der Rechenweg nimmt den Platz von
    Schaltplan und LED-Vorschau (die linke Spalte rollt, wenn es eng wird).
    Ein Mitwachsen des Fensters lief mit Mindesthöhe und Bildschirmgrenze
    bei 150-200 % aus dem Ruder (Live-Test 30.10.) }
  MenuRechenweg.Checked := FRechenwegOpen;
end;

procedure TFormMain.PanelLeftResize(Sender: TObject);
begin
  PanelPreview.Height := Max(PanelPreview.Constraints.MinHeight,
    PanelLeft.ClientHeight - PanelPreview.Top - Px(8));
end;

procedure TFormMain.FormShowPlatz(Sender: TObject);
begin
  OnShow := nil;
  { erst nach dem Anzeigen: dann ist das Fenster schon auf den Bildschirm
    begrenzt (uSkalierung) und die Höhen stimmen }
  Application.QueueAsyncCall(@RechenwegZuBeiPlatzmangel, 0);
end;

procedure TFormMain.RechenwegZuBeiPlatzmangel(Data: PtrInt);
begin
  if FRechenwegOpen and (PaintLed.Height < Px(120)) then
  begin
    FRechenwegOpen := False;
    UpdateRechenwegHeight;
    PaintRechenweg.Invalidate;
  end;
end;

procedure TFormMain.PaintRechenwegPaint(Sender: TObject);
var
  C: TCanvas;            // Zeichenfläche
  R: TRect;              // ganzer Bereich
  HeadH, LineH: Integer; // Höhe Kopfzeile und Textzeile
  L: TStringArray;       // Schritte
  I, Y: Integer;         // Zähler und Zeile
  Mid: Integer;          // Mitte der Kopfzeile
begin
  C := PaintRechenweg.Canvas;
  R := PaintRechenweg.ClientRect;
  C.Brush.Color := RGBToColor($1A, $1D, $22);
  C.Pen.Color := clrBorder;
  C.Rectangle(R);
  C.Font.Name := FONT_UI;
  C.Font.Size := 9;
  C.Font.Style := [];
  HeadH := Px(28);
  // kleines Dreieck (auf = nach unten, zu = nach rechts) selbst zeichnen,
  // nicht jede Schrift hat die Pfeilzeichen
  C.Brush.Color := clrText;
  C.Pen.Color := clrText;
  Mid := R.Top + HeadH div 2;
  if FRechenwegOpen then
    C.Polygon([Point(R.Left + Px(10), Mid - Px(3)), Point(R.Left + Px(18), Mid - Px(3)), Point(R.Left + Px(14), Mid + Px(2))])
  else
    C.Polygon([Point(R.Left + Px(12), Mid - Px(4)), Point(R.Left + Px(17), Mid), Point(R.Left + Px(12), Mid + Px(4))]);
  C.Brush.Style := bsClear;
  C.Font.Color := clrText;
  C.TextOut(R.Left + Px(24), R.Top + (HeadH - C.TextHeight('Ag')) div 2, _(rsRechenweg));
  if not FRechenwegOpen then Exit;
  C.Line(R.Left, R.Top + HeadH, R.Right, R.Top + HeadH);

  L := RechenwegLines;
  LineH := Px(23);
  Y := R.Top + HeadH + Px(6);
  for I := 0 to High(L) do
  begin
    if FRes.Status = csOk then
    begin
      C.Font.Color := clrAccent;
      C.TextOut(R.Left + Px(14), Y, IntToStr(I + 1));
      DrawRich(C, R.Left + Px(40), Y, L[I], clrText, clrTextBright);
    end
    else
      DrawRich(C, R.Left + Px(14), Y, L[I], clrError, clrError);
    Inc(Y, LineH);
  end;
end;

procedure TFormMain.PaintRechenwegMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  // Klick auf die Kopfzeile klappt auf oder zu
  if (Button = mbLeft) and (Y <= Px(28)) then
    MenuRechenwegClick(Sender);
end;

procedure TFormMain.MenuRechenwegClick(Sender: TObject);
begin
  FRechenwegOpen := not FRechenwegOpen;
  UpdateRechenwegHeight;
  PaintRechenweg.Invalidate;
end;

{ ---------- Statuszeile ---------- }

procedure TFormMain.PaintStatusPaint(Sender: TObject);
var
  C: TCanvas;       // Zeichenfläche
  R, Chip: TRect;   // Bereich und Hinweis-Kästchen
  ChipText, Txt: string; // Texte
  Fore, Back: TColor;    // Farben des Kästchens
  Lvl: TLoadLevel;  // Bewertung
  X: Integer;       // laufende Position
  Sym: Integer;    // Symbol: 0 = Haken, 1 = Warndreieck, 2 = Kreuz
  IconW: Integer;   // Platz für das Symbol
  IX, IY: Integer;  // Lage des Symbols
begin
  C := PaintStatus.Canvas;
  R := PaintStatus.ClientRect;
  C.Brush.Color := clrBar;
  C.FillRect(R);
  C.Pen.Color := clrBorder;
  C.Line(R.Left, R.Top, R.Right, R.Top);
  C.Font.Name := FONT_UI;
  C.Font.Size := 9;
  C.Font.Style := [];
  X := R.Left + Px(10);
  if FRes.Status <> csOk then
  begin
    ChipText := '';
    Sym := 2;
    Fore := clrError;
    Back := clrErrorBack;
    Txt := StatusText(FRes.Status);
  end
  else
  begin
    Lvl := LoadLevelOf(FRes.Load);
    case Lvl of
      llOk: begin Fore := clrOk; Back := clrOkBack; Sym := 0; end;
      llWarning: begin Fore := clrWarn; Back := clrWarnBack; Sym := 1; end;
    else
      begin Fore := clrError; Back := clrErrorBack; Sym := 1; end;
    end;
    ChipText := Format(_(rsStatusLoad), [FormatPercent(FRes.Load)]);
    if FRes.RecommendedW = 0 then
      Txt := Format(_(rsStatusNone), [FormatRating(RATING_REFERENCE), Round(FRes.TempRise)])
    else if Lvl = llOk then
      Txt := Format(_(rsStatusOk), [FormatRating(RATING_REFERENCE), Round(FRes.TempRise)])
    else
      Txt := Format(_(rsStatusWarn), [FormatRating(RATING_REFERENCE), Round(FRes.TempRise),
        FormatRating(FRes.RecommendedW)]);
    Txt := Txt + '   ·   ' + Format(_(rsStatusTotal), [FormatPower(FRes.PTotal)]);
  end;
  // Hinweis-Kästchen mit selbst gezeichnetem Symbol (Haken, Warndreieck, Kreuz)
  IconW := Px(14);
  Chip := Types.Rect(X, R.Top + Px(4), X + IconW + C.TextWidth(ChipText) + Px(14), R.Bottom - Px(3));
  C.Brush.Color := Back;
  C.Pen.Color := Fore;
  C.Pen.Width := 1;
  C.Rectangle(Chip);
  IX := Chip.Left + Px(5);
  IY := (Chip.Top + Chip.Bottom) div 2;
  C.Pen.Width := Max(1, Px(2));
  case Sym of
    0: C.PolyLine([Point(IX, IY), Point(IX + Px(3), IY + Px(3)), Point(IX + Px(9), IY - Px(4))]);
    1: begin
         C.Brush.Color := Fore;
         C.Pen.Width := 1;
         C.Polygon([Point(IX + Px(5), IY - Px(6)), Point(IX + Px(10), IY + Px(5)), Point(IX, IY + Px(5))]);
         C.Pen.Color := Back;
         C.Line(IX + Px(5), IY - Px(2), IX + Px(5), IY + Px(2));
         C.Line(IX + Px(5), IY + Px(3), IX + Px(5), IY + Px(4));
       end;
  else
    begin
      C.Line(IX, IY - Px(4), IX + Px(8), IY + Px(4));
      C.Line(IX, IY + Px(4), IX + Px(8), IY - Px(4));
    end;
  end;
  C.Pen.Width := 1;
  C.Brush.Style := bsClear;
  C.Font.Color := Fore;
  C.TextOut(Chip.Left + Px(6) + IconW, (Chip.Top + Chip.Bottom - C.TextHeight('Ag')) div 2, ChipText);
  C.Font.Color := clrText;
  C.TextOut(Chip.Right + Px(10), (R.Top + R.Bottom - C.TextHeight('Ag')) div 2, Txt);
end;

procedure TFormMain.KofiClick(Sender: TObject);
begin
  OpenURL(KOFI_URL);
end;

{ Ko-fi-Knopf unten rechts, Elospeed-Standard (gezeichnet in uKofiButton) }
procedure TFormMain.PaintKofiPaint(Sender: TObject);
var
  R: TRect;  // Bereich des Knopfs
begin
  R := PaintKofi.ClientRect;
  PaintKofi.Canvas.Font.Name := FONT_UI;
  PaintKofi.Canvas.Font.Size := 9;
  PaintKofi.Canvas.Font.Style := [fsBold];
  DrawKofiButton(PaintKofi.Canvas, R, _(rsKofi), FKofiHover, clrBar,
    Screen.PixelsPerInch, Application.Icon);
  // Trennlinie oben wie bei der übrigen Statuszeile
  PaintKofi.Canvas.Pen.Color := clrBorder;
  PaintKofi.Canvas.Line(R.Left, R.Top, R.Right, R.Top);
end;

procedure TFormMain.PaintKofiMouseEnter(Sender: TObject);
begin
  FKofiHover := True;
  PaintKofi.Invalidate;
end;

procedure TFormMain.PaintKofiMouseLeave(Sender: TObject);
begin
  FKofiHover := False;
  PaintKofi.Invalidate;
end;

{ ---------- Menü ---------- }

function TFormMain.ResultSummary: string;
var
  LedName: string;  // Farbname
  SL: TStringList;  // Zeilen
begin
  Result := '';
  if FRes.Status <> csOk then
    Exit(StatusText(FRes.Status));
  LedName := ComboColor.Text;
  SL := TStringList.Create;
  try
    SL.Add(Format(_(rsCopyTitle), [APP_VER]));
    SL.Add(StringReplace(Format(_(rsCopyInput), [FormatVolt(FInput.U), FInput.N, LedName,
      FormatVolt(FInput.Ud), FormatMilliAmp(FInput.I)]), '_', '', [rfReplaceAll]));
    SL.Add(Format(_(rsCopyStd), [FormatOhm(FRes.R), SeriesName(FInput.Series),
      BandNames(FBands, '-'), FormatOhm(FRes.RCalc)]));
    SL.Add(Format(_(rsCopyCurrent), [FormatMilliAmp(FRes.IAct)]));
    SL.Add(Format(_(rsCopyPower), [FormatPower(FRes.PR), FormatPower(FRes.PLed), FormatPower(FRes.PTotal)]));
    if FRes.RecommendedW > 0 then
      SL.Add(Format(_(rsCopyRating), [FormatRating(FRes.RecommendedW), FormatRating(RATING_REFERENCE),
        FormatPercent(FRes.Load)]));
    Result := TrimRight(SL.Text);
  finally
    SL.Free;
  end;
end;

procedure TFormMain.MenuCopyClick(Sender: TObject);
begin
  Clipboard.AsText := ResultSummary;
end;

procedure TFormMain.MenuExitClick(Sender: TObject);
begin
  Close;
end;

procedure TFormMain.MenuResetClick(Sender: TObject);
begin
  FUpdating := True;
  try
    EditU.Text := '12';
    ComboColor.ItemIndex := Ord(lcWhite);
    EditUd.Text := FormatNum(LED_DEFAULT_UD[lcWhite], 2, 1);
    EditI.Text := '20';
    EditN.Text := '1';
    ComboSeries.ItemIndex := Ord(esE12);
  finally
    FUpdating := False;
  end;
  FLedDirty := True;
  PaintLed.Invalidate;
  Recalc;
end;

procedure TFormMain.MenuAboutClick(Sender: TObject);
begin
  MessageDlg(Format(_(rsAbout), [APP_VER]), mtInformation, [mbOK], 0);
end;

procedure TFormMain.MenuLedInfoClick(Sender: TObject);
begin
  if not ShowLedInfo then
    MessageDlg(_(rsLedInfoFailed), mtError, [mbOK], 0);
end;

end.
