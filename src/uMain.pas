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
  LCLType, Types, uESeries, uColorCode, uCalc, uBlink, uKsq, uSkalierung, uLang;

const
  { Programmversion für Titelleiste und Info }
  APP_VER = '2.4';

  { Ko-fi-Seite von Elospeed }
  KOFI_URL = 'https://ko-fi.com/elospeed';

type

  { TFormMain – das Hauptfenster }
  TFormMain = class(TForm)
    CheckDiode: TCheckBox;        // NE555: Diode über R2
    CheckSym: TCheckBox;          // Multivibrator: symmetrisch 1:1
    LabelSym: TLabel;
    ComboCircuit: TComboBox;      // Blinkschaltung: NE555 oder Multivibrator
    ComboKsq: TComboBox;          // Konstantstrom: LM317 oder zwei Transistoren
    EditU2: TEdit;                // Konstantstrom: Speisespannung bis (V)
    EditStrings: TEdit;           // Vorwiderstand: Stränge parallel
    LabelHeadSupply: TLabel;
    LabelStrings: TLabel;
    LabelStringsUnit: TLabel;
    LabelU2: TLabel;
    LabelU2Unit: TLabel;
    MenuModeK: TMenuItem;
    ComboConn: TComboBox;         // NE555: Anschluss der LED
    EditT1: TEdit;                // Zeitglied, erstes Feld (R1, R_B1 oder Frequenz)
    EditT2: TEdit;                // Zeitglied, zweites Feld (R2, R_B2 oder Tastgrad)
    EditT3: TEdit;                // Zeitglied, drittes Feld (C)
    LabelBlinkInfo: TLabel;       // Blinkschaltung: Takt unter der LED-Vorschau
    LabelConn: TLabel;
    LabelDiode: TLabel;
    LabelHeadLed: TLabel;
    LabelHeadTiming: TLabel;
    LabelT1: TLabel;
    LabelT1Unit: TLabel;
    LabelT2: TLabel;
    LabelT2Unit: TLabel;
    LabelT3: TLabel;
    LabelT3Unit: TLabel;
    MenuModeB: TMenuItem;
    MenuModeR: TMenuItem;
    MenuSepView: TMenuItem;
    PaintMode: TPaintBox;         // Umschalter «aus Bauteilen / aus Frequenz»
    PaintTabs: TPaintBox;         // Reiter «Vorwiderstand | Blinkschaltung | Konstantstrom»
    ComboColor: TComboBox;        // LED-Farbe
    ComboSeries: TComboBox;       // E-Reihe
    EditI: TEdit;                 // LED-Strom in mA
    EditN: TEdit;                 // Anzahl LEDs in Reihe
    EditU: TEdit;                 // Speisespannung in V
    EditUd: TEdit;                // Durchlassspannung in V
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
    MenuEdit: TMenuItem;
    MenuExit: TMenuItem;
    MenuFile: TMenuItem;
    MenuHelp: TMenuItem;
    MenuKofi: TMenuItem;
    MenuLedInfo: TMenuItem;
    MenuSepHelp: TMenuItem;
    MenuRechenweg: TMenuItem;
    MenuReset: TMenuItem;
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
    procedure BlinkInputChange(Sender: TObject);
    procedure CircuitChange(Sender: TObject);
    procedure KsqCircuitChange(Sender: TObject);
    procedure LabelDiodeClick(Sender: TObject);
    procedure LabelSymClick(Sender: TObject);
    procedure MenuModeClick(Sender: TObject);
    procedure PaintModeMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintModePaint(Sender: TObject);
    procedure PaintTabsMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintTabsPaint(Sender: TObject);
    procedure ComboColorChange(Sender: TObject);
    procedure ComboDrawItem(Control: TWinControl; Index: Integer; ARect: TRect;
      State: TOwnerDrawState);
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditKeyPress(Sender: TObject; var Key: Char);
    procedure EditMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure InputChange(Sender: TObject);
    procedure KofiClick(Sender: TObject);
    procedure PaintKofiPaint(Sender: TObject);
    procedure PaintKofiMouseEnter(Sender: TObject);
    procedure PaintKofiMouseLeave(Sender: TObject);
    procedure MenuAboutClick(Sender: TObject);
    procedure MenuLedInfoClick(Sender: TObject);
    procedure CopyClick(Sender: TObject);
    procedure CopyTimerTimer(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PaintRechenwegMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
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
    FBlinkStart: LongWord;   // Startzeit des Blinkens in ms (BlinkClockMs)
    FFineTimer: Boolean;     // feine Timer-Auflösung ist eingeschaltet
    FLedDirty: Boolean;      // LED-Bilder müssen neu gerechnet werden
    FKofiHover: Boolean;     // Maus ist über dem Ko-fi-Knopf
    FUpdating: Boolean;      // Eingaben werden gerade per Code gesetzt
    KofiCaptionShown: string; // Text des Ko-fi-Knopfs in der aktuellen Sprache
    FRechenwegOpen: Boolean; // Rechenweg aufgeklappt
    FCopyBtn: TRect;         // Knopf «Kopieren» in der Kopfzeile des Rechenwegs
    FCopied: Boolean;        // kurz «Kopiert» statt «Kopieren» anzeigen
    FCopyTimer: TTimer;      // stellt den Knopftext nach dem Kopieren zurück
    FMode: Integer;          // Reiter: 0 = Vorwiderstand, 1 = Blinkschaltung, 2 = Konstantstrom
    FReverse: Boolean;       // Blinkschaltung: aus Frequenz und Tastgrad rechnen
    FCircuitShown: TBlinkCircuit; // Schaltung, deren Werte in den Feldern stehen
    FReverseShown: Boolean;  // Richtung, deren Werte in den Feldern stehen
    FBTexts: array[TBlinkCircuit, Boolean, 0..2] of string; // gemerkte Feldinhalte
    FBInput: TBlinkInput;    // Eingaben der Blinkschaltung
    FBRes: TBlinkResult;     // Resultat der Blinkschaltung
    FBBands1: TBandArray;    // Farbringe Vorwiderstand LED 1
    FBBands2: TBandArray;    // Farbringe Vorwiderstand LED 2
    FOnLevel: Double;        // Helligkeit der leuchtenden LED (Dauerlicht bei schnellem Takt)
    FTabX: array[0..3] of Integer; // Grenzen der Reiter (für Mausklicks)
    FKInput: TKsqInput;      // Eingaben der Konstantstromquelle
    FKRes: TKsqResult;       // Resultat der Konstantstromquelle
    FKBands: TBandArray;     // Farbringe des Fühlerwiderstands
    FKBandsB: TBandArray;    // Farbringe von R_B (zwei Transistoren)
    MenuLang: TMenuItem;     // Ansicht → Sprache (zur Laufzeit erzeugt)
    MenuLangDe: TMenuItem;   // Sprache Deutsch
    MenuLangEn: TMenuItem;   // Sprache Englisch
    { Menü Ansicht → Sprache mit Deutsch und English anlegen }
    procedure SyncSymmetric;
    procedure SetFineTimer(AOn: Boolean);
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
    { Reiter wechseln: 0 = Vorwiderstand, 1 = Blinkschaltung, 2 = Konstantstrom }
    procedure SwitchMode(M: Integer; Save: Boolean);
    { Bedienelemente der linken Spalte je nach Reiter anordnen }
    procedure LayoutLeft;
    { Beschriftung und Einheiten der drei Zeitglied-Felder setzen }
    procedure UpdateTimingLabels;
    { Feldinhalte der Zeitglied-Felder merken bzw. für Schaltung und
      Richtung wieder einsetzen }
    procedure StoreTimingTexts;
    procedure LoadTimingTexts;
    { Blinkschaltung rechnen (läuft bei jeder Eingabe mit) }
    procedure RecalcBlink;
    { Fehlertext zur Blinkschaltung }
    function BlinkStatusText(S: TBlinkStatus): string;
    { Schritte des Rechenwegs der Blinkschaltung }
    function BlinkRechenwegLines: TStringArray;
    { Resultatkarten, Schaltplan und Zusammenfassung der Blinkschaltung }
    procedure PaintBlinkCards;
    procedure PaintBlinkSchematic;
    function BlinkSummary: string;
    { Hinweis-Kästchen und Text der Statuszeile für die Blinkschaltung }
    procedure BlinkStatus(out ChipText, Txt: string; out Sym: Integer; out Fore, Back: TColor);
    { Konstantstrom: rechnen, Fehlertext, Rechenweg, Karten, Schaltplan,
      Statuszeile und Zusammenfassung }
    procedure RecalcKsq;
    function KsqStatusText(S: TKsqStatus): string;
    function KsqRechenwegLines: TStringArray;
    procedure PaintKsqCards;
    procedure PaintKsqSchematic;
    procedure KsqStatus(out ChipText, Txt: string; out Sym: Integer; out Fore, Back: TColor);
    function KsqSummary: string;
    { Konstantstrom: Speisespannung als Bereich, z. B. "12 … 14,4 V" }
    function KsqVoltRange: string;
    { Konstantstrom: empfohlenes Bauteil mit Kühlkörper-Angabe }
    function KsqPartText: string;
    { Konstantstrom: Spannung der LEDs als Text, z. B. "2 × 3,2 V" }
    function KsqLedVolt: string;
    { Beschriftungen, die vom Reiter abhängen (Kopfzeile, «von» statt
      «Speisespannung», «LEDS») }
    procedure ModeCaptions;
    { Farbname der LED, z. B. "rot" }
    function LedColorName: string;
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
    { Erklärung der Zeichen im Rechenweg des aktuellen Reiters (mit Auszeichnung) }
    function RechenwegLegend: string;
    { Resultat, kompletter Rechenweg und Zeichen-Erklärung als einfacher Text }
    function CopyText: string;
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
  rsCopyBtn = 'Kopieren';
  rsCopiedBtn = 'Kopiert ✓';
  rsCopySteps = 'Rechenweg:';
  rsCopyLegend = 'Zeichen:';
  rsLegendR = 'U_B Speisespannung · U_F Durchlassspannung einer LED · U_R Spannung am Widerstand · R Vorwiderstand · I LED-Strom · P Leistung im Widerstand · R_t_h Wärmewiderstand';
  rsLegendRN = 'U_B Speisespannung · n LEDs in Reihe · U_F Durchlassspannung einer LED · U_R Spannung am Widerstand · R Vorwiderstand · I LED-Strom · P Leistung im Widerstand · R_t_h Wärmewiderstand';
  rsLegend555 = 'U_B Speisespannung · t_H Zeit Ausgang High · t_L Zeit Ausgang Low · f Frequenz · C Zeitkondensator · U_O_U_T Spannung am Ausgang · U_F Durchlassspannung · R Vorwiderstand · I LED-Strom';
  rsLegendMulti = 'U_B Speisespannung · U_F Durchlassspannung · t_1, t_2 Leuchtzeit LED 1 und 2 · k Zeitfaktor · R_B_1, R_B_2 Basiswiderstände · C Kondensator · I_B Basisstrom · I_C Kollektorstrom · β Stromverstärkung';
  rsLegendLM = 'U_B Speisespannung · U_L_E_D Spannung aller LEDs · R Fühlerwiderstand · I LED-Strom · P Leistung · U_m_i_n kleinste Speisespannung';
  rsLegendKT = 'U_B Speisespannung · U_L_E_D Spannung aller LEDs · R_S Fühlerwiderstand · R_B Basiswiderstand · U_B_E Basis-Emitter-Spannung · β Stromverstärkung · P Leistung · U_m_i_n kleinste Speisespannung';
  rsHintDatasheet = 'Hinweis: Durchlassspannung und Strom aus dem Datenblatt der verwendeten LED nehmen, die Vorgaben sind nur Richtwerte.';
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
  { Stränge parallel (Reiter Vorwiderstand) }
  rsLabelStrings = 'Stränge parallel';
  rsErrStrings = 'Bitte mindestens 1 Strang angeben (ganze Zahl).';
  rsSchemStrings = '× %d Stränge, je eigener R';
  rsCardCurrentSubStrings = 'je Strang; %d Stränge: gesamt %s';
  rsCardPowerSubStrings = 'je Widerstand (%d Stück)';
  rsStep3Strings = 'Tatsächlicher Strom: I = %s / %s = **%s** je Strang · %d Stränge: gesamt **%s**';
  rsStatusStrings = '(%d Stränge)';
  rsCopyStrings = 'Stränge parallel: %d, jeder mit eigenem Vorwiderstand; Strom gesamt %s';
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
  rsMenuFile = '&Datei';
  rsMenuExit = '&Beenden';
  rsMenuEdit = '&Bearbeiten';
  rsMenuReset = 'Eingaben &zurücksetzen';
  rsMenuView = '&Ansicht';
  rsMenuRechenweg = '&Rechenweg';
  rsMenuLang = '&Sprache (Language)';
  rsMenuHelp = '&Hilfe';
  rsMenuLedInfo = '&LED-Info (Die Leuchtdiode) …';
  rsMenuKofi = 'Einen Kaffee spendieren (Ko-fi) …';
  rsMenuAbout = 'Ü&ber LedPreResistor …';
  { Blinkschaltung }
  rsTabResistor = 'Vorwiderstand';
  rsTabBlink = 'Blinkschaltung';
  rsMenuModeR = '&Vorwiderstand';
  rsMenuModeB = 'Blink&schaltung';
  rsHeadCircuit = 'SCHALTUNG';
  rsHeadTiming = 'ZEITGLIED';
  rsHeadLed = 'LED AM AUSGANG';
  rsHeadLeds = 'LEDS';
  rsCircuit555 = 'NE555 (astabil)';
  rsCircuitMulti = 'Multivibrator (2 Transistoren)';
  rsModeParts = 'aus Bauteilen';
  rsModeFreq = 'aus Frequenz';
  rsModeTimes = 'aus Zeiten';
  rsLabelLed1 = 'LED 1 an';
  rsLabelLed2 = 'LED 2 an';
  rsErrBTimes = 'Bitte für LED 1 und LED 2 Zeiten grösser als 0 eingeben.';
  rsLabelFreq = 'Frequenz';
  rsLabelDuty = 'LED an';
  rsDiode = 'Diode über R2 (unter 50 % an)';
  rsSym = 'Symmetrisch 1:1 (gleich lang an)';
  rsLabelConn = 'Anschluss am Ausgang';
  rsConnGnd = 'nach Masse (leuchtet bei High)';
  rsConnVcc = 'nach +Ub (leuchtet bei Low)';
  rsConnBoth = 'beide (Wechselblinker)';
  rsLed1 = 'LED 1';
  rsLed2 = 'LED 2';
  rsBlinkInfo = '%s · an %s, aus %s';
  rsBlinkInfoMulti = '%s · LED 1: %s, LED 2: %s';
  rsBlinkInfoFast = '%s: zu schnell fürs Auge, wirkt wie Dauerlicht (%s hell)';
  rsBlinkInfoInvalid = 'blinkt, sobald die Werte stimmen';
  rsBlinkInfoSmooth = '%s · Vorschau gedimmt, zu schnell zum Anzeigen';
  rsBCardFreq = 'Blinkfrequenz';
  rsBCardFreqSub = 'Periode %s';
  rsBCardFreqSubAlt = 'Wechselblinker, Periode %s';
  rsBCardFreqFast = 'wirkt wie Dauerlicht';
  rsBCardTimes = 'LED an / aus';
  rsBCardTimesMulti = 'LED 1 / LED 2 an';
  rsBCardDuty = 'Tastgrad (LED an)';
  rsBCardDutySub = 'ohne Diode immer über 50 %';
  rsBCardDutySubDiode = 'mit Diode über R2';
  rsBCardDutySubVcc = 'LED leuchtet bei Low';
  rsBCardBase = 'Basisstrom';
  rsBCardBaseSub = '%s-fach übersteuert (β = %d)';
  rsBCardRv = 'Vorwiderstand (%s)';
  rsBCardRvSub = '%s · %s → %s';
  rsErrBR1 = 'Bitte R1 grösser als 0 eingeben.';
  rsErrBR2 = 'Bitte R2 grösser als 0 eingeben.';
  rsErrBRB1 = 'Bitte RB1 grösser als 0 eingeben.';
  rsErrBRB2 = 'Bitte RB2 grösser als 0 eingeben.';
  rsErrBC = 'Bitte einen Kondensator grösser als 0 eingeben.';
  rsErrBF = 'Bitte eine Frequenz grösser als 0 eingeben.';
  rsErrBDuty = 'Bitte für «LED an» einen Wert zwischen 0 und 100 % eingeben.';
  rsErrBDiode = 'Ohne Diode ist der Ausgang immer mehr als die Hälfte der Zeit High: Diode über R2 einschalten oder mehr als 50 % wählen.';
  rsErrBUTooLow = 'Die Speisespannung reicht nicht: am Ausgang bleibt %s, die LED braucht %s.';
  rsChipSupply = 'NE555: 4,5–16 V';
  rsWarnSupply = 'Speisespannung %s liegt ausserhalb 4,5–16 V: die CMOS-Version (TLC555, ICM7555) nehmen';
  rsChipBase = 'Basis −%s';
  rsWarnBase = 'Basis wird mit ca. −%s gesperrt, der BC547 verträgt 6 V: Diode 1N4148 vor jede Basis oder Ub senken';
  rsChipSat = 'Basisstrom knapp';
  rsWarnSat = 'Der Transistor schaltet nicht sicher durch: RB kleiner und dafür C grösser wählen';
  rsChipR1 = 'R1 unter 1 kΩ';
  rsWarnR1 = 'R1 sollte mindestens 1 kΩ haben, sonst wird der Entladetransistor (Pin 7) überlastet';
  rsChipOut = 'Ausgang über 200 mA';
  rsWarnOut = 'Mehr als 200 mA ist zu viel für den Ausgang des NE555: Transistor nachschalten';
  rsChipRHigh = 'R über 1 MΩ';
  rsWarnRHigh = 'Ein Zeitwiderstand über 1 MΩ: der Leckstrom des Elkos verfälscht die Zeit, lieber C grösser wählen';
  rsChipFast = 'über 50 Hz';
  rsWarnFast = 'Ab etwa 50 Hz sieht das Auge kein Flimmern mehr: die LED wirkt wie Dauerlicht mit weniger Helligkeit (PWM)';
  rsChipOk555 = 'NE555 passt';
  rsChipOkMulti = 'Transistoren schalten sicher';
  rsOkTolerance = 'Elkos haben oft ±20 % Toleranz: die echte Frequenz kann entsprechend abweichen';
  rsMoreHints = ' (+%d weitere)';
  rsBStep555High = 'Ausgang High (Laden über R1 + R2): t_H = ln 2 · (R1 + R2) · C = 0,693 × %s × %s = **%s**';
  rsBStep555HighD = 'Ausgang High (Laden über R1, Diode überbrückt R2): t_H = ln 2 · R1 · C = 0,693 × %s × %s = **%s**';
  rsBStep555Low = 'Ausgang Low (Entladen über R2): t_L = ln 2 · R2 · C = 0,693 × %s × %s = **%s**';
  rsBStep555Rev1 = 'Aus f und C: R1 + 2 · R2 = 1 / (ln 2 · f · C) = 1 / (0,693 × %s × %s) = **%s**';
  rsBStep555Rev1D = 'Aus f und C: R1 + R2 = 1 / (ln 2 · f · C) = 1 / (0,693 × %s × %s) = **%s**';
  rsBStep555Rev2 = 'Aufteilen für %s High: R1 = %s → **%s**, R2 = %s → **%s** (nächste %s-Werte)';
  rsBStepFreq = 'Frequenz: f = 1 / (t_H + t_L) = 1 / %s = **%s** · LED an: **%s**';
  rsBStepFreqRev = 'Mit den Normwerten: t_H = %s, t_L = %s → f = **%s** · LED an: **%s**';
  rsBStepOut = 'Ausgang High: U_O_U_T ≈ U_B − 1,7 V = %s − 1,7 V = **%s** (Spannungsabfall im NE555)';
  rsBStepOutVcc = 'LED nach +U_B: sie leuchtet, wenn der Ausgang Low ist (≈ 0,1 V); an LED und R bleiben %s − 0,1 V';
  rsBStepRv = 'Vorwiderstand: R = (%s − %s) / %s = %s → nächster %s-Wert darüber: **%s** → I = **%s**';
  rsBStepRvBoth = 'Vorwiderstände: LED 1 (nach Masse) **%s**, LED 2 (nach +U_B) **%s** → I = **%s** / **%s**';
  rsBStepMultiK = 'Sprung am Kollektor: ΔU = U_B − U_F − 0,2 V = **%s** → k = ln((U_B − 0,6 V + ΔU) / (U_B − 0,6 V)) = **%s**';
  rsBStepMultiT = 'LED 1 an (T2 gesperrt): t_1 = k · R_B_2 · C = %s × %s × %s = **%s** · LED 2 an: t_2 = k · R_B_1 · C = **%s**';
  rsBStepMultiRev = 'Aus t_1 = %s (LED 1) und t_2 = %s (LED 2): R_B_2 = t_1 / (k · C) = %s → **%s**, R_B_1 = t_2 / (k · C) = %s → **%s** (nächste %s-Werte)';
  rsBStepMultiF = 'Frequenz: f = 1 / (t_1 + t_2) = 1 / %s = **%s** · LED 1 an: **%s**';
  rsBStepMultiBase = 'Basisstrom: I_B = (U_B − 0,6 V) / R_B = %s / %s = **%s** → I_B · β / I_C = **%s-fach** (β = %d)';
  rsBStepMultiRv = 'Vorwiderstand: R = (U_B − U_F − 0,2 V) / I = %s / %s = %s → nächster %s-Wert darüber: **%s** → I = **%s**';
  rsBCopyTitle = 'LedPreResistor %s – Blinkschaltung (%s)';
  rsBCopyInput = 'Speisespannung %s, LED %s mit U_F = %s, Strom %s';
  rsBCopyParts = 'Bauteile: %s = %s, %s = %s, C = %s';
  rsBCopyTimes = 'LED an %s, aus %s, Frequenz %s, Tastgrad %s';
  rsBCopyRv = 'Vorwiderstand: %s';
  { Konstantstrom }
  rsTabKsq = 'Konstantstrom';
  rsMenuModeK = '&Konstantstrom';
  rsHeadSupply = 'SPEISESPANNUNG';
  rsLabelFrom = 'von';
  rsLabelTo = 'bis';
  rsKsqLM317 = 'LM317 (Regler, bis 1,5 A)';
  rsKsqTrans = '2 Transistoren (T1 nach Strom)';
  rsKCardR = 'Fühlerwiderstand (%s)';
  rsKCardRSub = '%s · %s (%s)';
  rsKCardI = 'LED-Strom';
  rsKCardISubL = 'berechnet %s → %s; bleibt von %s bis %s gleich';
  rsKCardISubLFix = 'berechnet %s → %s; bleibt auch bei schwankender Spannung gleich';
  rsKCardISubT = 'berechnet %s → %s; pro 10 °C wärmer ca. %s weniger';
  rsKCardLossL = 'Verlust im Regler';
  rsKCardLossT = 'Verlust in T1';
  rsKCardLossSubT = '%s; RB = %s';
  rsKCardNeed = 'Mindestspannung';
  rsKCardNeedSubL = '%s + 1,25 V + ca. 2 V Regler';
  rsKCardNeedSubT = '%s + 0,6 V + ca. 0,6 V an T1';
  rsKPartLM317L = 'LM317L (TO-92) reicht, ohne Kühlkörper';
  rsKPartLM317 = 'LM317 (TO-220) ohne Kühlkörper';
  rsKPartFree = '%s ohne Kühlkörper';
  rsKPartHeatsink = '%s mit Kühlkörper ≤ %s K/W';
  rsKPartTooHot = '%s: zu viel Verlust';
  rsKPartShortHeat = '%s + Kühlkörper ≤ %s K/W';
  rsKStepL1 = 'Der LM317 hält zwischen OUT und ADJ 1,25 V: R = 1,25 V / I = 1,25 V / %s = **%s** → nächster %s-Wert darüber: **%s**';
  rsKStepL2 = 'Tatsächlicher Strom: I = 1,25 V / %s = **%s** · Leistung am R: P = 1,25 V × %s = **%s** → %s';
  rsKStepL3 = 'Mindestspannung: U_m_i_n = %s + 1,25 V + ca. 2 V (Regler) = **%s** → Reserve bei %s: **%s**';
  rsKStepL4 = 'Verlust im Regler: P = (U_B − U_L_E_D − 1,25 V) · I = (%s − %s − 1,25 V) × %s = **%s** → **%s**';
  rsKStepL5 = 'Zum Vergleich ein Vorwiderstand: R = (%s − %s) / %s = %s; bei %s flösse **%s mehr** Strom, der LM317 hält ihn';
  rsKStepL5Fix = 'Aus ADJ fliessen zusätzlich ca. 50 µA durch die LEDs (vernachlässigbar). Der Strom bleibt auch bei schwankender Spannung gleich.';
  rsKStepT1 = 'T2 leitet ab ca. 0,6 V an R_S: R_S = 0,6 V / I = 0,6 V / %s = **%s** → nächster %s-Wert darüber: **%s**';
  rsKStepT2 = 'Tatsächlicher Strom: I = 0,6 V / %s = **%s** · Leistung an R_S: **%s** → %s · U_B_E sinkt um ca. 2 mV/K: pro 10 °C ca. %s weniger';
  rsKStepT3 = 'Basiswiderstand für %s (T1 %s braucht I / β = %s): R_B = (%s − 1,3 V) / %s = %s → Normwert darunter: **%s**';
  rsKStepT4 = 'Mindestspannung: U_m_i_n = %s + 0,6 V + ca. 0,6 V (T1) = **%s** → Reserve bei %s: **%s**';
  rsKStepT5 = 'Verlust in T1: P = (U_B − U_L_E_D − 0,6 V) · I = (%s − %s − 0,6 V) × %s = **%s** → **%s**';
  rsErrKUTooLow = 'Die Speisespannung (von) %s reicht nicht: die Schaltung braucht mindestens %s.';
  rsErrKCurrent = 'Mehr als 1,5 A schafft weder der LM317 noch der BD139: Strom kleiner wählen.';
  rsKChipOk = 'Konstantstrom passt';
  rsKOkRangeL = 'Mit Vorwiderstand: +%s Strom bei %s, mit dem LM317 bleibt er gleich';
  rsKOkRangeT = 'Mit Vorwiderstand: +%s Strom bei %s, hier nur ca. +%s';
  rsKOkFix = 'Tipp: bei «bis» die höchste Spannung eingeben (Auto z. B. 14,4 V)';
  rsKChipHeat = 'Kühlkörper nötig';
  rsKWarnHeat = '%s verheizt bis %s: Kühlkörper mit höchstens %s K/W, Kühlfahne liegt an %s (isoliert montieren)';
  rsKTabOut = 'OUT';
  rsKTabCollector = 'Kollektor';
  rsKChipTooHot = 'zu viel Verlust';
  rsKWarnTooHot = 'Bis %s Verlust ist zu viel: weniger Spannung, mehr LEDs in Reihe oder kleinerer Strom';
  rsKChipMinLoad = 'unter 10 mA';
  rsKWarnMinLoad = 'Unter ca. 10 mA regelt der LM317 nicht sicher (Mindestlaststrom): lieber die Schaltung mit 2 Transistoren';
  rsKChipVolt = 'Spannung zu hoch';
  rsKWarnVoltL = 'Mehr als 40 V zwischen IN und OUT verträgt der LM317 nicht: Spannung senken oder mehr LEDs in Reihe';
  rsKWarnVoltT = 'Mehr als 45 V an T1 verträgt der Transistor nicht: Spannung senken oder mehr LEDs in Reihe';
  rsKChipBase = 'RB wird warm';
  rsKWarnBase = 'T1 braucht viel Basisstrom: RB (%s) verheizt bis %s, %s nehmen – bei grossem Strom ist der LM317 einfacher';
  rsKChipRPower = 'Fühler-R über 1 W';
  rsKWarnRPower = 'Der Fühlerwiderstand verheizt %s: einen Leistungswiderstand (2–5 W) nehmen';
  rsKCopyTitle = 'LedPreResistor %s – Konstantstrom (%s)';
  rsKCopyR = 'Fühlerwiderstand: %s (%s, %s), berechnet %s';
  rsKCopyLoss = 'Verlust: %s → %s';
  rsKCopyNeed = 'Mindestspannung: %s';
  rsKCopyRB = 'Basiswiderstand RB: %s (%s)';
  rsAbout = 'LedPreResistor %s' + LineEnding + 'Vorwiderstand für LEDs berechnen.' + LineEnding + LineEnding +
    '© 2026 Elospeed – freie Software (MIT-Lizenz)' + LineEnding +
    'Neuauflage der Freeware «LED Pre-Resistor» von 2004.';

implementation

uses
  Math, Clipbrd, LCLIntf, Dialogs, IniFiles, uTheme, uFormat, uLedView, uSchematic, uRichText,
  uLedInfo, uKofiButton, uBlinkSchematic, uKsqSchematic, uSmooth{$IFDEF WINDOWS}, MMSystem{$ENDIF};

{$R *.lfm}

const
  { Kürzeste An- oder Aus-Zeit, die die Vorschau noch sauber blinken kann.
    Beim Blinken läuft der Timer mit feiner Auflösung (1 ms statt etwa
    16 ms) und meldet sich etwa alle 10 ms. Der Bildschirm zeigt bei 60 Hz
    ein Bild alle 16,7 ms, jede Phase kann darum um ein Bild länger oder
    kürzer erscheinen. Ab 50 ms (bei 50 % Tastgrad 10 Hz) fällt das kaum
    auf; bei kürzeren Phasen stockt das Blinken sichtbar (unter Windows
    ab etwa 12 Hz beobachtet). Kürzere Zeiten zeigt die Vorschau als
    gedimmtes Dauerlicht mit der Helligkeit des Tastgrads. }
  BLINK_ANIM_MIN_PHASE = 0.05;

{ Laufende Zeit in ms mit feiner Auflösung. GetTickCount64 springt unter
  Windows nur in Schritten von etwa 16 ms, timeGetTime ist bei
  eingeschalteter feiner Auflösung auf 1 ms genau. Gerechnet wird nur mit
  Differenzen in 32 Bit, darum stört der Überlauf nach 49 Tagen nicht. }
function BlinkClockMs: LongWord;
begin
  {$IFDEF WINDOWS}
  Result := timeGetTime;
  {$ELSE}
  Result := LongWord(GetTickCount64);
  {$ENDIF}
end;

const

  { Einstellung für den zuletzt gewählten Reiter }
  INI_SECTION_VIEW = 'Ansicht';
  INI_KEY_TAB = 'Reiter';
  INI_KEY_CIRCUIT = 'Schaltung';
  INI_KEY_KSQ = 'Konstantstrom';

{ Zahl aus der Einstellungsdatei lesen (Fehler: Vorgabe) }
function ReadViewSetting(const Key: string; Default: Integer): Integer;
var
  Ini: TIniFile;  // Einstellungen
begin
  Result := Default;
  try
    Ini := TIniFile.Create(IniFileName);
    try
      Result := Ini.ReadInteger(INI_SECTION_VIEW, Key, Default);
    finally
      Ini.Free;
    end;
  except
    Result := Default;
  end;
end;

{ Zahl in die Einstellungsdatei schreiben (Fehler werden still übergangen,
  z. B. bei einem schreibgeschützten Ordner) }
procedure WriteViewSetting(const Key: string; Value: Integer);
var
  Ini: TIniFile;  // Einstellungen
begin
  try
    ForceDirectories(ExtractFilePath(IniFileName));
    Ini := TIniFile.Create(IniFileName);
    try
      Ini.WriteInteger(INI_SECTION_VIEW, Key, Value);
    finally
      Ini.Free;
    end;
  except
  end;
end;

const
  { Vorgaben der Zeitglied-Felder je Schaltung und Richtung:
    vorwärts R1/R_B1 in kΩ, R2/R_B2 in kΩ, C in µF;
    rückwärts Frequenz in Hz, LED an in %, C in µF (NE555) bzw.
    Zeit LED 1 und LED 2 in s, C in µF (Multivibrator) }
  BLINK_DEFAULTS: array[TBlinkCircuit, Boolean, 0..2] of string = (
    (('1', '68', '10'), ('1', '55', '10')),
    (('33', '33', '22'), ('0,5', '0,5', '22')));

  { Normwerte für Pfeiltasten und Mausrad: E12 für Widerstände, E6 für Kondensatoren }
  E6_DIGITS: array[0..5] of Integer = (10, 15, 22, 33, 47, 68);

{ nächster Wert der Reihe (Ziffern Digits, zweistellig) über bzw. unter V }
function StepStd(V: Double; Up: Boolean; const Digits: array of Integer): Double;
var
  E, I: Integer;  // Zehnerpotenz und Index
  W: Double;      // Kandidat
begin
  if not (V > 0) then
    Exit(Digits[0] / 10);
  if Up then
  begin
    for E := Floor(Log10(V)) - 1 to Floor(Log10(V)) + 2 do
      for I := 0 to High(Digits) do
      begin
        W := Digits[I] * IntPower(10, E - 1);
        if W > V * (1 + 1e-9) then Exit(W);
      end;
  end
  else
    for E := Floor(Log10(V)) + 1 downto Floor(Log10(V)) - 2 do
      for I := High(Digits) downto 0 do
      begin
        W := Digits[I] * IntPower(10, E - 1);
        if W < V * (1 - 1e-9) then Exit(W);
      end;
  Result := V;
end;

{ Farbe C mit dem Hintergrund Back mischen (A = Anteil von C, 0..1) }
function MixColor(C, Back: TColor; A: Double): TColor;
var
  C1, C2: LongInt;  // RGB-Werte
begin
  C1 := ColorToRGB(C);
  C2 := ColorToRGB(Back);
  Result := RGBToColor(
    Round(Red(C1) * A + Red(C2) * (1 - A)),
    Round(Green(C1) * A + Green(C2) * (1 - A)),
    Round(Blue(C1) * A + Blue(C2) * (1 - A)));
end;

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
  FCopyTimer := TTimer.Create(Self);
  FCopyTimer.Enabled := False;
  FCopyTimer.Interval := 1500;
  FCopyTimer.OnTimer := @CopyTimerTimer;
  FOnLevel := 1.0;
  FBTexts := BLINK_DEFAULTS;
  FCircuitShown := bcNE555;
  FReverseShown := False;
  FUpdating := True;
  try
    FillCombos;
    ComboColor.ItemIndex := Ord(lcWhite);
    ComboSeries.ItemIndex := Ord(esE12);
    ComboCircuit.ItemIndex := EnsureRange(ReadViewSetting(INI_KEY_CIRCUIT, 0), 0, Ord(High(TBlinkCircuit)));
    ComboConn.ItemIndex := Ord(cnGnd);
    ComboKsq.ItemIndex := EnsureRange(ReadViewSetting(INI_KEY_KSQ, 0), 0, Ord(High(TKsqCircuit)));
    LoadTimingTexts;
  finally
    FUpdating := False;
  end;
  ApplyLanguage;
  ApplyTheme;
  UpdateRechenwegHeight;
  Recalc;
  // zuletzt gewählten Reiter wieder öffnen
  SwitchMode(EnsureRange(ReadViewSetting(INI_KEY_TAB, 0), 0, 2), False);
  OnShow := @FormShowPlatz;
  PanelLeft.OnResize := @PanelLeftResize;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  SetFineTimer(False);
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
      {$IFDEF WINDOWS}
      TEdit(C).Color := clrDeep;
      TEdit(C).Font.Color := clrTextBright;
      {$ELSE}
      // Linux (GTK2): Viele Themes (z. B. Yaru bei Ubuntu) zeichnen den
      // Feldhintergrund selbst und übergehen die eigene Farbe; helle Schrift
      // stünde dann weiss auf weiss. Darum dort Farben des Themes nehmen
      // (clDefault, nicht die helle Schrift des Fensters erben).
      TEdit(C).Font.Color := clDefault;
      {$ENDIF}
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
  LabelU2Unit.Font.Color := clrTextDim;
  LabelStringsUnit.Font.Color := clrTextDim;
  LabelHeadSupply.Font.Color := clrTextDim;
  LabelHeadSupply.Font.Size := 8;
  LabelHeadInputs.Font.Color := clrTextDim;
  LabelHeadPreview.Font.Color := clrTextDim;
  LabelHeadInputs.Font.Size := 8;
  LabelHeadPreview.Font.Size := 8;
  LabelHeadTiming.Font.Color := clrTextDim;
  LabelHeadTiming.Font.Size := 8;
  LabelHeadLed.Font.Color := clrTextDim;
  LabelHeadLed.Font.Size := 8;
  LabelT1Unit.Font.Color := clrTextDim;
  LabelT2Unit.Font.Color := clrTextDim;
  LabelT3Unit.Font.Color := clrTextDim;
  LabelBlinkInfo.Font.Color := clrTextSoft;
  LabelBlinkInfo.Font.Size := 8;
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
  Idx: array[0..5] of Integer;  // gewählte Einträge der sechs Listen
  BC: TBlinkCircuit;            // Schaltung
  BR: Boolean;                  // Richtung
  K: Integer;                   // Feld

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
  MenuFile.Caption := _(rsMenuFile);
  MenuExit.Caption := _(rsMenuExit);
  MenuEdit.Caption := _(rsMenuEdit);
  MenuReset.Caption := _(rsMenuReset);
  MenuView.Caption := _(rsMenuView);
  MenuRechenweg.Caption := _(rsMenuRechenweg);
  MenuLang.Caption := _(rsMenuLang);
  MenuHelp.Caption := _(rsMenuHelp);
  MenuLedInfo.Caption := _(rsMenuLedInfo);
  MenuKofi.Caption := _(rsMenuKofi);
  MenuAbout.Caption := _(rsMenuAbout);
  MenuModeR.Caption := _(rsMenuModeR);
  MenuModeB.Caption := _(rsMenuModeB);
  MenuModeK.Caption := _(rsMenuModeK);
  LabelStrings.Caption := _(rsLabelStrings);
  LabelStringsUnit.Caption := _(rsUnitN);
  LabelHeadSupply.Caption := _(rsHeadSupply);
  LabelU2.Caption := _(rsLabelTo);
  LabelHeadTiming.Caption := _(rsHeadTiming);
  LabelDiode.Caption := _(rsDiode);
  LabelSym.Caption := _(rsSym);
  LabelConn.Caption := _(rsLabelConn);
  UpdateTimingLabels;
  ModeCaptions;
  PaintTabs.Invalidate;
  PaintMode.Invalidate;
  MenuLangDe.Checked := LangCode <> 'en';
  MenuLangEn.Checked := LangCode = 'en';

  // Auswahllisten neu füllen, gewählte Einträge behalten
  FUpdating := True;
  try
    Idx[0] := ComboColor.ItemIndex;
    Idx[1] := ComboSeries.ItemIndex;
    Idx[3] := ComboCircuit.ItemIndex;
    Idx[4] := ComboConn.ItemIndex;
    Idx[5] := ComboKsq.ItemIndex;
    FillCombos;
    ComboColor.ItemIndex := Idx[0];
    ComboSeries.ItemIndex := Idx[1];
    ComboCircuit.ItemIndex := Idx[3];
    ComboConn.ItemIndex := Idx[4];
    ComboKsq.ItemIndex := Idx[5];
    if OldDec <> DisplayDecimal then
    begin
      SwapDecimal(EditU);
      SwapDecimal(EditUd);
      SwapDecimal(EditI);
      SwapDecimal(EditN);
      SwapDecimal(EditU2);
      SwapDecimal(EditT1);
      SwapDecimal(EditT2);
      SwapDecimal(EditT3);
      for BC := Low(TBlinkCircuit) to High(TBlinkCircuit) do
        for BR := False to True do
          for K := 0 to 2 do
            FBTexts[BC, BR, K] := StringReplace(FBTexts[BC, BR, K], OldDec, DisplayDecimal, [rfReplaceAll]);
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
  ComboCircuit.Items.Clear;
  ComboCircuit.Items.Add(_(rsCircuit555));
  ComboCircuit.Items.Add(_(rsCircuitMulti));
  ComboConn.Items.Clear;
  ComboConn.Items.Add(_(rsConnGnd));
  ComboConn.Items.Add(_(rsConnVcc));
  ComboConn.Items.Add(_(rsConnBoth));
  ComboKsq.Items.Clear;
  ComboKsq.Items.Add(_(rsKsqLM317));
  ComboKsq.Items.Add(_(rsKsqTrans));
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
    csInvalidStrings: Result := _(rsErrStrings);
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
  // Stränge parallel: ganze Zahl 1..100, sonst ungültig (-1)
  if ParseDecimal(EditStrings.Text, V) and (Frac(V) = 0) and (V >= 1) and (V <= 100) then
    FInput.Strings := Round(V)
  else
    FInput.Strings := -1;

  FRes := Calculate(FInput);
  if (FRes.Status <> csOk) or not ColorBands(FRes.Std, FInput.Series, FBands) then
    FBands := nil;

  RecalcBlink;
  RecalcKsq;

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
  if E.Tag < 0 then
  begin
    // Tag -1: Widerstand (E12), -2: Kondensator (E6) – zum nächsten Normwert
    if E.Tag = -2 then
      V := StepStd(V, Key = VK_UP, E6_DIGITS)
    else
      V := StepStd(V, Key = VK_UP, [10, 12, 15, 18, 22, 27, 33, 39, 47, 56, 68, 82]);
    E.Text := FormatNum(V, 3, 0);
    E.SelStart := Length(E.Text);
    Key := 0;
    Exit;
  end;
  Step := E.Tag / 1000;  // Tag = Schrittweite in Tausendsteln
  if ssShift in Shift then Step := Step * 10;
  if Key = VK_UP then V := V + Step else V := V - Step;
  if (E = EditN) or (E = EditStrings) then V := Max(1, V) else V := Max(0, V);
  E.Text := FormatNum(V, 2, 0);
  E.SelStart := Length(E.Text);
  Key := 0;
end;

{ Nur Ziffern und ein Dezimalzeichen zulassen. Punkt und Komma werden zum
  Dezimalzeichen der Sprache; die Anzahl LEDs nimmt nur Ziffern an.
  Steuerzeichen (Rücktaste, Kopieren, Einfügen) bleiben erlaubt. }
procedure TFormMain.EditKeyPress(Sender: TObject; var Key: Char);
var
  E: TEdit;  // Eingabefeld
begin
  if (Key < ' ') or (Key in ['0'..'9']) then Exit;
  E := Sender as TEdit;
  if (Key in [',', '.']) and (E <> EditN) and (E <> EditStrings) then
  begin
    // nur ein Dezimalzeichen; ein markiertes darf ersetzt werden
    if (Pos(DisplayDecimal, E.Text) = 0) or (Pos(DisplayDecimal, E.SelText) > 0) then
      Key := DisplayDecimal
    else
      Key := #0;
    Exit;
  end;
  Key := #0;
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
  RenderLed(FLedOn, PaintLed.Width, PaintLed.Height, LedGlowColor(CurrentLed), clrDeep, FOnLevel, L, clrTextSoft);
  RenderLed(FLedOff, PaintLed.Width, PaintLed.Height, LedGlowColor(CurrentLed), clrDeep, 0.0, L, clrTextSoft);
  FLedDirty := False;
end;

procedure TFormMain.PaintLedPaint(Sender: TObject);
var
  Y: Integer;  // Zeile der Frequenzanzeige
begin
  if FLedDirty or (FLedOn.Width <> PaintLed.Width) or (FLedOn.Height <> PaintLed.Height) then
    RenderLedBitmaps;
  if FLedLit or not TimerBlink.Enabled then
    PaintLed.Canvas.Draw(0, 0, FLedOn)
  else
    PaintLed.Canvas.Draw(0, 0, FLedOff);
  // Blinkschaltung: Frequenz gross oben links in der Vorschau
  if (FMode = 1) and (FBRes.Status = bsOk) then
    with PaintLed.Canvas do
    begin
      Brush.Style := bsClear;
      Font.Name := FONT_UI;
      Font.Style := [];
      Font.Size := 8;
      Font.Color := clrTextDim;
      TextOut(Px(8), Px(6), _(rsBCardFreq));
      Y := Px(6) + TextHeight('Ag');
      Font.Size := 14;
      Font.Style := [fsBold];
      Font.Color := clrAccent;
      TextOut(Px(8), Y, FormatFreq(FBRes.F));
      Font.Style := [];
    end;
end;

procedure TFormMain.PaintLedResize(Sender: TObject);
begin
  FLedDirty := True;
end;

procedure TFormMain.UpdateBlink;
var
  Level: Double;  // Helligkeit der leuchtenden LED
begin
  if FMode = 1 then
  begin
    // Blinkschaltung: Takt aus der Rechnung
    Level := 1.0;
    if FBRes.Status <> bsOk then
    begin
      TimerBlink.Enabled := False;
      LabelBlinkInfo.Caption := _(rsBlinkInfoInvalid);
    end
    else if bwTooFast in FBRes.Warnings then
    begin
      TimerBlink.Enabled := False;
      // Dauerlicht mit der mittleren Helligkeit
      Level := Max(0.15, FBRes.Duty1);
      LabelBlinkInfo.Caption := Format(_(rsBlinkInfoFast), [FormatFreq(FBRes.F), FormatPercent(FBRes.Duty1)]);
    end
    else if Min(FBRes.TOn1, FBRes.TOff1) < BLINK_ANIM_MIN_PHASE then
    begin
      // sichtbar blinkend, aber zu schnell für eine ruhige Anzeige
      TimerBlink.Enabled := False;
      Level := Max(0.15, FBRes.Duty1);
      LabelBlinkInfo.Caption := Format(_(rsBlinkInfoSmooth), [FormatFreq(FBRes.F)]);
    end
    else
    begin
      // Der Timer fragt oft nach und rechnet an/aus aus der Zeit seit dem
      // Start. So summieren sich Verspätungen einzelner Timer-Meldungen
      // nicht auf, der Takt bleibt gleichmässig.
      FBlinkStart := BlinkClockMs;
      TimerBlink.Interval := 10;
      TimerBlink.Enabled := True;
      SetFineTimer(True);
      if FBInput.Circuit = bcMulti then
        LabelBlinkInfo.Caption := Format(_(rsBlinkInfoMulti), [FormatFreq(FBRes.F),
          FormatSeconds(FBRes.TOn1), FormatSeconds(FBRes.TOff1)])
      else
        LabelBlinkInfo.Caption := Format(_(rsBlinkInfo), [FormatFreq(FBRes.F),
          FormatSeconds(FBRes.TOn1), FormatSeconds(FBRes.TOff1)]);
    end;
    if not SameValue(Level, FOnLevel) then
    begin
      FOnLevel := Level;
      FLedDirty := True;
    end;
    if not TimerBlink.Enabled then
      SetFineTimer(False);
    FLedLit := True;
    PaintLed.Invalidate;
    Exit;
  end;
  if not SameValue(FOnLevel, 1.0) then
  begin
    FOnLevel := 1.0;
    FLedDirty := True;
  end;
  // Vorwiderstand: LED leuchtet dauernd, geblinkt wird nur im Reiter Blinkschaltung
  TimerBlink.Enabled := False;
  SetFineTimer(False);
  FLedLit := True;
  PaintLed.Invalidate;
end;

{ Feine Timer-Auflösung (1 ms) nur während die Vorschau blinkt. Ohne sie
  kommen Timer-Meldungen unter Windows nur etwa alle 16 ms. }
procedure TFormMain.SetFineTimer(AOn: Boolean);
begin
  if AOn = FFineTimer then Exit;
  FFineTimer := AOn;
  {$IFDEF WINDOWS}
  if AOn then
    timeBeginPeriod(1)
  else
    timeEndPeriod(1);
  {$ENDIF}
end;

procedure TFormMain.TimerBlinkTimer(Sender: TObject);
var
  OnMs, PeriodMs: QWord;  // An-Zeit und Periode in ms
  Lit: Boolean;           // LED soll jetzt leuchten
begin
  if FMode <> 1 then
  begin
    TimerBlink.Enabled := False;
    SetFineTimer(False);
    Exit;
  end;
  OnMs := Max(1, Round(FBRes.TOn1 * 1000));
  PeriodMs := OnMs + Max(1, Round(FBRes.TOff1 * 1000));
  Lit := QWord(LongWord(BlinkClockMs - FBlinkStart)) mod PeriodMs < OnMs;
  if Lit = FLedLit then Exit;  // nur beim Umschalten neu zeichnen
  FLedLit := Lit;
  PaintSchematic.Invalidate;  // LEDs im Schaltplan blinken mit
  PaintLed.Invalidate;
end;

{ ---------- Schaltplan ---------- }

procedure TFormMain.PaintSchematicPaint(Sender: TObject);
var
  BC: TCanvas;           // Leinwand für das geglättete Zeichnen
  BR: TRect;             // Zeichenfläche darauf
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
  if FMode = 1 then
  begin
    PaintBlinkSchematic;
    Exit;
  end;
  if FMode = 2 then
  begin
    PaintKsqSchematic;
    Exit;
  end;
  LedName := LedColorName;
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
    if FRes.Strings > 1 then
      V.StringsText := Format(_(rsSchemStrings), [FRes.Strings]);
  end
  else
  begin
    V.RText := 'R = ' + Dash;
    V.URText := 'U_R = ' + Dash;
    V.IText := 'I = ' + Dash;
  end;
  InflateRect(R, -Px(20), -Px(20));
  if BeginSmooth(PaintSchematic.Canvas, R, clrDeep, '', BC, BR) then
  begin
    DrawSchematic(BC, BR, V, clrLine, clrLine, clrAccent, clrPanel);
    EndSmooth;
  end;
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
  if FMode = 1 then
  begin
    PaintBlinkCards;
    Exit;
  end;
  if FMode = 2 then
  begin
    PaintKsqCards;
    Exit;
  end;
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
        if Ok and (FRes.Strings > 1) then
          Card(_(rsCardCurrent), FormatMilliAmp(FRes.IAct),
            Format(_(rsCardCurrentSubStrings), [FRes.Strings, FormatMilliAmp(FRes.ITotal)]), clrTextBright)
        else if Ok then
          Card(_(rsCardCurrent), FormatMilliAmp(FRes.IAct),
            Format(_(rsCardCurrentSub), [FormatOhm(FRes.RCalc), FormatMilliAmp(FInput.I)]), clrTextBright)
        else
          Card(_(rsCardCurrent), '–', '', clrTextBright);
      2:
        if Ok and (FRes.Strings > 1) then
          Card(_(rsCardPower), FormatPower(FRes.PR), Format(_(rsCardPowerSubStrings), [FRes.Strings]), clrTextBright)
        else if Ok then
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
  if FRes.Strings > 1 then
    Result[2] := Format(_(rsStep3Strings), [FormatVolt(FRes.UR), FormatOhm(FRes.R), FormatMilliAmp(FRes.IAct),
      FRes.Strings, FormatMilliAmp(FRes.ITotal)])
  else
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

function TFormMain.RechenwegLegend: string;
begin
  if FMode = 1 then
  begin
    if FBRes.Status <> bsOk then Exit('');
    if FBInput.Circuit = bcMulti then Result := _(rsLegendMulti) else Result := _(rsLegend555);
  end
  else if FMode = 2 then
  begin
    if FKRes.Status <> ksOk then Exit('');
    if FKInput.Circuit = kcLM317 then Result := _(rsLegendLM) else Result := _(rsLegendKT);
  end
  else
  begin
    if FRes.Status <> csOk then Exit('');
    if FInput.N > 1 then Result := _(rsLegendRN) else Result := _(rsLegendR);
  end;
end;

function TFormMain.CopyText: string;
var
  SL: TStringList;   // Zeilen
  L: TStringArray;   // Schritte des Rechenwegs
  Legend: string;    // Zeichen-Erklärung
  Ok: Boolean;       // Rechnung gültig
  I: Integer;        // Zähler
begin
  if FMode = 1 then
  begin
    Result := BlinkSummary;
    L := BlinkRechenwegLines;
    Ok := FBRes.Status = bsOk;
  end
  else if FMode = 2 then
  begin
    Result := KsqSummary;
    L := KsqRechenwegLines;
    Ok := FKRes.Status = ksOk;
  end
  else
  begin
    Result := ResultSummary;
    L := RechenwegLines;
    Ok := FRes.Status = csOk;
  end;
  if not Ok then Exit;  // nur die Fehlermeldung
  SL := TStringList.Create;
  try
    SL.Text := Result;
    SL.Add('');
    SL.Add(_(rsCopySteps));
    for I := 0 to High(L) do
      SL.Add(IntToStr(I + 1) + '. ' + RichPlain(L[I]));
    Legend := RechenwegLegend;
    if Legend <> '' then
    begin
      SL.Add('');
      SL.Add(_(rsCopyLegend) + ' ' + RichPlain(Legend));
    end;
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

procedure TFormMain.UpdateRechenwegHeight;
var
  NeuH, Mehr: Integer;  // neue Höhe, zusätzlicher Platzbedarf
begin
  if FRechenwegOpen then
    NeuH := Px(178)  // fünf Schritte und die Zeichen-Erklärung
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
  // zu wenig Platz für LED-Vorschau oder Schaltplan (z. B. 200 % auf Full HD)
  if FRechenwegOpen and ((PaintLed.Height < Px(120)) or (PaintSchematic.Height < Px(180))) then
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
  Ok: Boolean;           // Rechnung gültig
  HintText: string;          // Hinweis zum Datenblatt
  HintX: Integer;        // frühester Anfang des Hinweises
  HintRight: Integer;    // rechter Rand des Hinweises (vor dem Knopf)
  BtnText: string;       // Beschriftung des Kopier-Knopfs
  BtnW: Integer;         // Breite des Kopier-Knopfs
  Legend: string;        // Zeichen-Erklärung
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
  // Hinweis rechts in der Kopfzeile, auch zugeklappt sichtbar: Vorgaben sind
  // nur Richtwerte. Schrift wird kleiner, wenn der Platz nicht reicht.
  HintX := R.Left + Px(24) + C.TextWidth(_(rsRechenweg)) + Px(24);
  // Knopf «Kopieren» ganz rechts (auch zugeklappt): kopiert Resultat und Rechenweg
  if FCopied then BtnText := _(rsCopiedBtn) else BtnText := _(rsCopyBtn);
  BtnW := Max(C.TextWidth(_(rsCopyBtn)), C.TextWidth(_(rsCopiedBtn))) + Px(20);
  FCopyBtn := Rect(R.Right - Px(8) - BtnW, R.Top + Px(4), R.Right - Px(8), R.Top + HeadH - Px(4));
  C.Brush.Style := bsSolid;
  C.Brush.Color := clrPanel;
  C.Pen.Color := clrBorder;
  C.RoundRect(FCopyBtn, Px(8), Px(8));
  C.Brush.Style := bsClear;
  if FCopied then C.Font.Color := clrOk else C.Font.Color := clrText;
  C.TextOut((FCopyBtn.Left + FCopyBtn.Right - C.TextWidth(BtnText)) div 2,
    (FCopyBtn.Top + FCopyBtn.Bottom - C.TextHeight('Ag')) div 2, BtnText);
  HintRight := FCopyBtn.Left - Px(14);
  HintText := _(rsHintDatasheet);
  C.Font.Color := clrTextSoft;
  while (C.Font.Size > 7) and (C.TextWidth(HintText) > HintRight - HintX) do
    C.Font.Size := C.Font.Size - 1;
  if C.TextWidth(HintText) <= HintRight - HintX then
    C.TextOut(HintRight - C.TextWidth(HintText),
      R.Top + (HeadH - C.TextHeight('Ag')) div 2, HintText);
  C.Font.Size := 9;
  C.Font.Color := clrText;
  if not FRechenwegOpen then Exit;
  C.Line(R.Left, R.Top + HeadH, R.Right, R.Top + HeadH);

  if FMode = 1 then
  begin
    L := BlinkRechenwegLines;
    Ok := FBRes.Status = bsOk;
  end
  else if FMode = 2 then
  begin
    L := KsqRechenwegLines;
    Ok := FKRes.Status = ksOk;
  end
  else
  begin
    L := RechenwegLines;
    Ok := FRes.Status = csOk;
  end;
  LineH := Px(23);
  Y := R.Top + HeadH + Px(6);
  for I := 0 to High(L) do
  begin
    if Ok then
    begin
      C.Font.Color := clrAccent;
      C.TextOut(R.Left + Px(14), Y, IntToStr(I + 1));
      DrawRich(C, R.Left + Px(40), Y, L[I], clrText, clrTextBright);
    end
    else
      DrawRich(C, R.Left + Px(14), Y, L[I], clrError, clrError);
    Inc(Y, LineH);
  end;
  // Erklärung der Zeichen: grau und kleiner, Schrift schrumpft, wenn der Platz fehlt
  Legend := RechenwegLegend;
  if Legend <> '' then
  begin
    C.Font.Size := 8;
    while (C.Font.Size > 7) and (RichWidth(C, Legend) > R.Right - R.Left - Px(54)) do
      C.Font.Size := C.Font.Size - 1;
    DrawRich(C, R.Left + Px(40), Y + Px(2), Legend, clrTextSoft, clrTextSoft);
    C.Font.Size := 9;
  end;
end;

procedure TFormMain.PaintRechenwegMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then Exit;
  // Klick auf den Knopf kopiert, sonst klappt die Kopfzeile auf oder zu
  if PtInRect(FCopyBtn, Point(X, Y)) then
    CopyClick(Sender)
  else if Y <= Px(28) then
    MenuRechenwegClick(Sender);
end;

procedure TFormMain.PaintRechenwegMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if (Y <= Px(28)) then
    PaintRechenweg.Cursor := crHandPoint
  else
    PaintRechenweg.Cursor := crDefault;
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
  if FMode = 1 then
    BlinkStatus(ChipText, Txt, Sym, Fore, Back)
  else if FMode = 2 then
    KsqStatus(ChipText, Txt, Sym, Fore, Back)
  else if FRes.Status <> csOk then
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
    if FRes.Strings > 1 then
      Txt := Txt + ' ' + Format(_(rsStatusStrings), [FRes.Strings]);
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
    if FRes.Strings > 1 then
      SL.Add(Format(_(rsCopyStrings), [FRes.Strings, FormatMilliAmp(FRes.ITotal)]));
    SL.Add(Format(_(rsCopyPower), [FormatPower(FRes.PR), FormatPower(FRes.PLed), FormatPower(FRes.PTotal)]));
    if FRes.RecommendedW > 0 then
      SL.Add(Format(_(rsCopyRating), [FormatRating(FRes.RecommendedW), FormatRating(RATING_REFERENCE),
        FormatPercent(FRes.Load)]));
    Result := TrimRight(SL.Text);
  finally
    SL.Free;
  end;
end;

procedure TFormMain.CopyClick(Sender: TObject);
begin
  Clipboard.AsText := CopyText;
  // kurz «Kopiert ✓» anzeigen
  FCopied := True;
  FCopyTimer.Enabled := False;
  FCopyTimer.Enabled := True;
  PaintRechenweg.Invalidate;
end;

procedure TFormMain.CopyTimerTimer(Sender: TObject);
begin
  FCopyTimer.Enabled := False;
  FCopied := False;
  PaintRechenweg.Invalidate;
end;

procedure TFormMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // Strg+Umschalt+C: wie der Knopf «Kopieren» im Rechenweg
  if (Key = VK_C) and (Shift = [ssCtrl, ssShift]) then
  begin
    CopyClick(Sender);
    Key := 0;
  end;
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
    EditStrings.Text := '1';
    EditU2.Text := FormatNum(14.4, 1, 1);
    ComboSeries.ItemIndex := Ord(esE12);
    // Blinkschaltung auf die Vorgaben
    FBTexts := BLINK_DEFAULTS;
    if FMode = 1 then
    begin
      // Reiter Blinkschaltung: rote LED mit 15 mA bei 9 V wie im Beispiel
      EditU.Text := '9';
      ComboColor.ItemIndex := Ord(lcRed);
      EditUd.Text := FormatNum(LED_DEFAULT_UD[lcRed], 2, 1);
      EditI.Text := '15';
    end;
    if FMode = 2 then
      EditN.Text := '2';  // Konstantstrom: zwei weisse LEDs im Auto wie im Beispiel
    CheckDiode.Checked := False;
    CheckSym.Checked := True;
    ComboConn.ItemIndex := Ord(cnGnd);
    LoadTimingTexts;
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

{ ---------- Blinkschaltung ---------- }

function TFormMain.LedColorName: string;
begin
  case CurrentLed of
    lcRed: Result := _(rsLedNameRed);
    lcYellow: Result := _(rsLedNameYellow);
    lcGreen: Result := _(rsLedNameGreen);
    lcBlue: Result := _(rsLedNameBlue);
    lcWhite: Result := _(rsLedNameWhite);
  else
    Result := _(rsLedNameInfrared);
  end;
end;

procedure TFormMain.SwitchMode(M: Integer; Save: Boolean);
begin
  FMode := M;
  MenuModeR.Checked := M = 0;
  MenuModeB.Checked := M = 1;
  MenuModeK.Checked := M = 2;
  LabelBlinkInfo.Visible := M = 1;
  // Platz unter der LED nur im Blinkmodus (Takt-Angabe)
  if M = 1 then
    PaintLed.BorderSpacing.Bottom := Px(36)
  else
    PaintLed.BorderSpacing.Bottom := 0;
  ModeCaptions;
  LayoutLeft;
  UpdateBlink;
  FLedDirty := True;
  PaintTabs.Invalidate;
  PaintLed.Invalidate;
  PaintSchematic.Invalidate;
  PaintCards.Invalidate;
  PaintRechenweg.Invalidate;
  PaintStatus.Invalidate;
  if Save then
    WriteViewSetting(INI_KEY_TAB, M);
end;

procedure TFormMain.LayoutLeft;
var
  Blink: Boolean;  // Reiter Blinkschaltung
  Ksq: Boolean;    // Reiter Konstantstrom
  Is555: Boolean;  // Schaltung NE555
  Y: Integer;      // laufende Zeile (96 dpi)
  Order: Integer;  // laufende Tab-Reihenfolge

  { Bedienelement an (X, Top) in 96-dpi-Punkten setzen; W = 0 behält die Breite }
  procedure Put(C: TControl; X, Top, W: Integer);
  begin
    if W > 0 then
      C.SetBounds(Px(X), Px(Top), Px(W), C.Height)
    else
      C.SetBounds(Px(X), Px(Top), C.Width, C.Height);
  end;

  { nächste Stelle in der Tab-Reihenfolge }
  procedure Tab(C: TWinControl);
  begin
    C.TabOrder := Order;
    Inc(Order);
  end;

begin
  Blink := FMode = 1;
  Ksq := FMode = 2;
  Is555 := ComboCircuit.ItemIndex <> Ord(bcMulti);
  PanelLeft.VertScrollBar.Position := 0;
  PanelLeft.DisableAlign;
  try
    // nur im Reiter Vorwiderstand
    LabelColor.Visible := FMode = 0;
    LabelStrings.Visible := FMode = 0;
    EditStrings.Visible := FMode = 0;
    LabelStringsUnit.Visible := FMode = 0;
    // Vorwiderstand und Konstantstrom
    LabelN.Visible := not Blink;
    EditN.Visible := not Blink;
    LabelNUnit.Visible := not Blink;
    // nur im Reiter Konstantstrom
    ComboKsq.Visible := Ksq;
    LabelHeadSupply.Visible := Ksq;
    LabelU2.Visible := Ksq;
    EditU2.Visible := Ksq;
    LabelU2Unit.Visible := Ksq;
    // nur im Reiter Blinkschaltung
    ComboCircuit.Visible := Blink;
    LabelHeadTiming.Visible := Blink;
    PaintMode.Visible := Blink;
    LabelT1.Visible := Blink;
    EditT1.Visible := Blink;
    LabelT1Unit.Visible := Blink;
    LabelT2.Visible := Blink;
    EditT2.Visible := Blink;
    LabelT2Unit.Visible := Blink;
    LabelT3.Visible := Blink;
    EditT3.Visible := Blink;
    LabelT3Unit.Visible := Blink;
    LabelHeadLed.Visible := Blink or Ksq;
    CheckDiode.Visible := Blink and Is555;
    LabelDiode.Visible := Blink and Is555;
    CheckSym.Visible := Blink and not Is555;
    LabelSym.Visible := Blink and not Is555;
    LabelConn.Visible := False;  // die Auswahl erklärt sich selbst
    ComboConn.Visible := Blink and Is555;

    Order := 0;
    Put(LabelHeadInputs, 16, 12, 0);
    if Ksq then
    begin
      // Schaltung, Speisespannung von … bis, LEDs
      Put(ComboKsq, 16, 30, 237);
      Put(LabelHeadSupply, 16, 64, 0);
      Put(LabelU, 16, 82, 0);
      Put(EditU, 16, 100, 92);
      Put(LabelUUnit, 112, 104, 0);
      Put(LabelU2, 140, 82, 0);
      Put(EditU2, 140, 100, 84);
      Put(LabelU2Unit, 228, 104, 0);
      Put(LabelHeadLed, 16, 134, 0);
      Put(ComboColor, 16, 152, 237);
      Put(LabelUd, 16, 186, 0);
      Put(EditUd, 16, 204, 92);
      Put(LabelUdUnit, 112, 208, 0);
      Put(LabelI, 140, 186, 0);
      Put(EditI, 140, 204, 84);
      Put(LabelIUnit, 228, 208, 0);
      Put(LabelSeries, 16, 238, 0);
      Put(ComboSeries, 16, 256, 113);
      Put(LabelN, 140, 238, 0);
      Put(EditN, 140, 256, 84);
      Put(LabelNUnit, 228, 260, 0);
      Y := 296;
      Tab(ComboKsq); Tab(EditU); Tab(EditU2); Tab(ComboColor); Tab(EditUd); Tab(EditI);
      Tab(ComboSeries); Tab(EditN);
    end
    else if not Blink then
    begin
      // Speisespannung und E-Reihe, LED, Anzahl in Reihe und Stränge parallel
      Put(LabelU, 16, 36, 0);
      Put(EditU, 16, 54, 92);
      Put(LabelUUnit, 112, 58, 0);
      Put(LabelSeries, 140, 36, 0);
      Put(ComboSeries, 140, 54, 113);
      Put(LabelColor, 16, 88, 0);
      Put(ComboColor, 16, 106, 237);
      Put(LabelUd, 16, 140, 0);
      Put(EditUd, 16, 158, 92);
      Put(LabelUdUnit, 112, 162, 0);
      Put(LabelI, 140, 140, 0);
      Put(EditI, 140, 158, 84);
      Put(LabelIUnit, 228, 162, 0);
      Put(LabelN, 16, 192, 0);
      Put(EditN, 16, 210, 92);
      Put(LabelNUnit, 112, 214, 0);
      Put(LabelStrings, 140, 192, 0);
      Put(EditStrings, 140, 210, 84);
      Put(LabelStringsUnit, 228, 214, 0);
      Y := 250;
      Tab(EditU); Tab(ComboSeries); Tab(ComboColor); Tab(EditUd); Tab(EditI); Tab(EditN); Tab(EditStrings);
    end
    else
    begin
      Put(ComboCircuit, 16, 30, 237);
      Put(LabelU, 16, 62, 0);
      Put(EditU, 16, 79, 92);
      Put(LabelUUnit, 112, 83, 0);
      Put(LabelSeries, 140, 62, 0);
      Put(ComboSeries, 140, 79, 113);
      Put(LabelHeadTiming, 16, 112, 0);
      Put(PaintMode, 16, 130, 237);
      Put(LabelT1, 16, 160, 0);
      Put(EditT1, 16, 177, 52);
      Put(LabelT1Unit, 71, 181, 0);
      Put(LabelT2, 98, 160, 0);
      Put(EditT2, 98, 177, 52);
      Put(LabelT2Unit, 153, 181, 0);
      Put(LabelT3, 180, 160, 0);
      Put(EditT3, 180, 177, 52);
      Put(LabelT3Unit, 235, 181, 0);
      Y := 208;
      Tab(ComboCircuit); Tab(EditU); Tab(ComboSeries); Tab(EditT1); Tab(EditT2); Tab(EditT3);
      if Is555 then
      begin
        Put(CheckDiode, 16, Y, 0);
        LabelDiode.AutoSize := False;  // feste Breite bis zum Rand, sonst wird der Text unter Umständen abgeschnitten
        Put(LabelDiode, 36, Y + 2, 217);
        Tab(CheckDiode);
        Inc(Y, 26);
      end
      else
      begin
        Put(CheckSym, 16, Y, 0);
        LabelSym.AutoSize := False;  // feste Breite bis zum Rand, sonst wird der Text unter Umständen abgeschnitten
        Put(LabelSym, 36, Y + 2, 217);
        Tab(CheckSym);
        Inc(Y, 26);
      end;
      // Kopf «LED AM AUSGANG» (NE555) bzw. «LEDS» (Multivibrator)
      Put(LabelHeadLed, 16, Y, 0);
      Put(ComboColor, 16, Y + 18, 237);
      Put(LabelUd, 16, Y + 48, 0);
      Put(EditUd, 16, Y + 65, 92);
      Put(LabelUdUnit, 112, Y + 69, 0);
      Put(LabelI, 140, Y + 48, 0);
      Put(EditI, 140, Y + 65, 84);
      Put(LabelIUnit, 228, Y + 69, 0);
      Tab(ComboColor); Tab(EditUd); Tab(EditI);
      Inc(Y, 96);
      if Is555 then
      begin
        Put(ComboConn, 16, Y, 237);
        Tab(ComboConn);
        Inc(Y, 32);
      end;
      Inc(Y, 4);
    end;
    Put(LabelHeadPreview, 16, Y, 0);
    Put(PanelPreview, 16, Y + 20, 237);
    Tab(PanelPreview);
  finally
    PanelLeft.EnableAlign;
  end;
  PanelLeftResize(PanelLeft);
end;

procedure TFormMain.UpdateTimingLabels;
var
  Is555: Boolean;  // Schaltung NE555
begin
  Is555 := ComboCircuit.ItemIndex <> Ord(bcMulti);
  if FReverse and not Is555 then
  begin
    LabelT1.Caption := _(rsLabelLed1);
    LabelT1Unit.Caption := 's';
    EditT1.Tag := 100;     // 0,1 s pro Schritt
    LabelT2.Caption := _(rsLabelLed2);
    LabelT2Unit.Caption := 's';
    EditT2.Tag := 100;
  end
  else if FReverse then
  begin
    LabelT1.Caption := _(rsLabelFreq);
    LabelT1Unit.Caption := 'Hz';
    EditT1.Tag := 100;     // 0,1 Hz pro Schritt
    LabelT2.Caption := _(rsLabelDuty);
    LabelT2Unit.Caption := '%';
    EditT2.Tag := 1000;    // 1 % pro Schritt
  end
  else
  begin
    if Is555 then
    begin
      LabelT1.Caption := 'R1';
      LabelT2.Caption := 'R2';
    end
    else
    begin
      LabelT1.Caption := 'RB1';
      LabelT2.Caption := 'RB2';
    end;
    LabelT1Unit.Caption := 'kΩ';
    LabelT2Unit.Caption := 'kΩ';
    EditT1.Tag := -1;      // E12-Werte
    EditT2.Tag := -1;
  end;
  LabelT3.Caption := 'C';
  LabelT3Unit.Caption := 'µF';
  EditT3.Tag := -2;        // E6-Werte
  if FMode = 2 then
    LabelHeadLed.Caption := _(rsHeadLeds)
  else if Is555 then
    LabelHeadLed.Caption := _(rsHeadLed)
  else
    LabelHeadLed.Caption := _(rsHeadLeds);
end;

procedure TFormMain.StoreTimingTexts;
begin
  FBTexts[FCircuitShown, FReverseShown, 0] := EditT1.Text;
  FBTexts[FCircuitShown, FReverseShown, 1] := EditT2.Text;
  FBTexts[FCircuitShown, FReverseShown, 2] := EditT3.Text;
end;

procedure TFormMain.LoadTimingTexts;
var
  Old: Boolean;  // vorheriger Zustand von FUpdating
begin
  if ComboCircuit.ItemIndex = Ord(bcMulti) then
    FCircuitShown := bcMulti
  else
    FCircuitShown := bcNE555;
  FReverseShown := FReverse;
  Old := FUpdating;
  FUpdating := True;
  try
    EditT1.Text := FBTexts[FCircuitShown, FReverseShown, 0];
    EditT2.Text := FBTexts[FCircuitShown, FReverseShown, 1];
    EditT3.Text := FBTexts[FCircuitShown, FReverseShown, 2];
  finally
    FUpdating := Old;
  end;
  UpdateTimingLabels;
  SyncSymmetric;
end;

{ Multivibrator symmetrisch (1:1): das zweite Feld folgt dem ersten,
  RB2 = RB1 bzw. Zeit LED 2 = Zeit LED 1. }
procedure TFormMain.SyncSymmetric;
var
  Sym: Boolean;  // symmetrisch eingestellt
  T: string;     // Text für das zweite Feld
  Old: Boolean;  // vorheriger Zustand von FUpdating
begin
  Sym := (ComboCircuit.ItemIndex = Ord(bcMulti)) and CheckSym.Checked;
  EditT2.Enabled := not Sym;
  if not Sym then Exit;
  T := EditT1.Text;
  if EditT2.Text = T then Exit;
  Old := FUpdating;
  FUpdating := True;
  try
    EditT2.Text := T;
  finally
    FUpdating := Old;
  end;
end;

procedure TFormMain.BlinkInputChange(Sender: TObject);
begin
  if FUpdating then Exit;
  SyncSymmetric;
  Recalc;
end;

procedure TFormMain.CircuitChange(Sender: TObject);
begin
  if FUpdating then Exit;
  StoreTimingTexts;
  LoadTimingTexts;
  LayoutLeft;
  Recalc;
  WriteViewSetting(INI_KEY_CIRCUIT, ComboCircuit.ItemIndex);
end;

procedure TFormMain.LabelDiodeClick(Sender: TObject);
begin
  CheckDiode.Checked := not CheckDiode.Checked;
end;

procedure TFormMain.LabelSymClick(Sender: TObject);
begin
  CheckSym.Checked := not CheckSym.Checked;
end;

procedure TFormMain.MenuModeClick(Sender: TObject);
begin
  SwitchMode((Sender as TMenuItem).Tag, True);
end;

procedure TFormMain.PaintTabsPaint(Sender: TObject);
var
  C: TCanvas;          // Zeichenfläche
  R: TRect;            // ganzer Bereich
  I, X, W: Integer;    // Reiter, Position, Breite
  T: string;           // Beschriftung
  TabTop: Integer;     // Oberkante der Reiter
begin
  C := PaintTabs.Canvas;
  R := PaintTabs.ClientRect;
  C.Brush.Color := clrWindow;
  C.FillRect(R);
  C.Font.Name := FONT_UI;
  C.Font.Size := 9;
  C.Font.Style := [];
  TabTop := R.Top + Px(6);
  X := R.Left + Px(16);
  FTabX[0] := X;
  // Linie unter den Reitern
  C.Pen.Color := clrBorder;
  C.Pen.Width := 1;
  C.Line(R.Left, R.Bottom - 1, R.Right, R.Bottom - 1);
  for I := 0 to 2 do
  begin
    case I of
      0: T := _(rsTabResistor);
      1: T := _(rsTabBlink);
    else
      T := _(rsTabKsq);
    end;
    W := C.TextWidth(T) + Px(32);
    if I = FMode then
    begin
      // aktiver Reiter: Fläche wie die linke Spalte, oben ein blauer Strich
      C.Brush.Color := clrPanel;
      C.Pen.Color := clrBorder;
      C.Rectangle(X, TabTop, X + W, R.Bottom);
      C.Brush.Color := clrAccent;
      C.FillRect(Types.Rect(X, TabTop, X + W, TabTop + Max(2, Px(2))));
      C.Font.Color := clrTextBright;
    end
    else
      C.Font.Color := clrTextSoft;
    C.Brush.Style := bsClear;
    C.TextOut(X + Px(16), TabTop + (R.Bottom - TabTop - C.TextHeight('Ag')) div 2, T);
    C.Brush.Style := bsSolid;
    Inc(X, W + Px(2));
    FTabX[I + 1] := X;
  end;
end;

procedure TFormMain.PaintTabsMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then Exit;
  if (X >= FTabX[0]) and (X < FTabX[1]) and (FMode <> 0) then
    SwitchMode(0, True)
  else if (X >= FTabX[1]) and (X < FTabX[2]) and (FMode <> 1) then
    SwitchMode(1, True)
  else if (X >= FTabX[2]) and (X < FTabX[3]) and (FMode <> 2) then
    SwitchMode(2, True);
end;

procedure TFormMain.PaintModePaint(Sender: TObject);
var
  C: TCanvas;   // Zeichenfläche
  R, H: TRect;  // ganzer Bereich und eine Hälfte
  I: Integer;   // Hälfte
  T: string;    // Beschriftung
begin
  C := PaintMode.Canvas;
  R := PaintMode.ClientRect;
  C.Font.Name := FONT_UI;
  C.Font.Size := 9;
  C.Font.Style := [];
  for I := 0 to 1 do
  begin
    if I = 0 then
    begin
      H := Types.Rect(R.Left, R.Top, (R.Left + R.Right) div 2, R.Bottom);
      T := _(rsModeParts);
    end
    else
    begin
      H := Types.Rect((R.Left + R.Right) div 2, R.Top, R.Right, R.Bottom);
      if ComboCircuit.ItemIndex = Ord(bcMulti) then
        T := _(rsModeTimes)
      else
        T := _(rsModeFreq);
    end;
    if (I = 1) = FReverse then
    begin
      C.Brush.Color := RGBToColor($1D, $4F, $86);
      C.Font.Color := clrTextBright;
    end
    else
    begin
      C.Brush.Color := clrDeep;
      C.Font.Color := clrTextSoft;
    end;
    C.FillRect(H);
    C.Brush.Style := bsClear;
    C.TextOut((H.Left + H.Right - C.TextWidth(T)) div 2,
      (H.Top + H.Bottom - C.TextHeight('Ag')) div 2, T);
    C.Brush.Style := bsSolid;
  end;
  C.Brush.Style := bsClear;
  C.Pen.Color := clrEditBorder;
  C.Pen.Width := 1;
  C.Rectangle(R);
  C.Brush.Style := bsSolid;
end;

procedure TFormMain.PaintModeMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Rev: Boolean;  // gewählte Richtung
begin
  if Button <> mbLeft then Exit;
  Rev := X >= PaintMode.Width div 2;
  if Rev = FReverse then Exit;
  StoreTimingTexts;
  FReverse := Rev;
  LoadTimingTexts;
  PaintMode.Invalidate;
  Recalc;
end;

procedure TFormMain.RecalcBlink;
var
  V: Double;       // umgewandelte Eingabe
  T1, T2: Double;  // Multivibrator: Zeiten von LED 1 und LED 2 in s
begin
  FBInput := Default(TBlinkInput);
  if ComboCircuit.ItemIndex = Ord(bcMulti) then
    FBInput.Circuit := bcMulti
  else
    FBInput.Circuit := bcNE555;
  FBInput.Reverse := FReverse;
  if FReverse and (FBInput.Circuit = bcMulti) then
  begin
    // Multivibrator: Zeiten von LED 1 und LED 2 in s, daraus f und Tastgrad
    if ParseDecimal(EditT1.Text, V) then T1 := V else T1 := 0;
    if ParseDecimal(EditT2.Text, V) then T2 := V else T2 := 0;
    if (T1 > 0) and (T2 > 0) then
    begin
      FBInput.F := 1 / (T1 + T2);
      FBInput.Duty := T1 / (T1 + T2);
    end;
  end
  else if FReverse then
  begin
    if ParseDecimal(EditT1.Text, V) then FBInput.F := V;
    if ParseDecimal(EditT2.Text, V) then FBInput.Duty := V / 100;
  end
  else
  begin
    if ParseDecimal(EditT1.Text, V) then FBInput.R1 := V * 1e3;
    if ParseDecimal(EditT2.Text, V) then FBInput.R2 := V * 1e3;
  end;
  if ParseDecimal(EditT3.Text, V) then FBInput.C := V * 1e-6;
  if FBInput.Circuit = bcNE555 then
  begin
    FBInput.Diode := CheckDiode.Checked;
    if ComboConn.ItemIndex >= 0 then
      FBInput.Conn := TLedConn(ComboConn.ItemIndex);
  end
  else
    FBInput.Conn := cnBoth;  // zwei LEDs im Wechsel
  FBInput.U := FInput.U;
  FBInput.Ud := FInput.Ud;
  FBInput.I := FInput.I;
  FBInput.Series := FInput.Series;

  FBRes := CalculateBlink(FBInput);
  FBBands1 := nil;
  FBBands2 := nil;
  if FBRes.Status = bsOk then
  begin
    if not ColorBands(FBRes.Led1.Std, FBInput.Series, FBBands1) then FBBands1 := nil;
    if FBRes.Led2.Used and not ColorBands(FBRes.Led2.Std, FBInput.Series, FBBands2) then
      FBBands2 := nil;
  end;
  if FMode = 1 then
    UpdateBlink;
end;

function TFormMain.BlinkStatusText(S: TBlinkStatus): string;
var
  Avail: Double;  // Spannung für LED und Vorwiderstand
begin
  case S of
    bsInvalidU: Result := _(rsErrU);
    bsInvalidUd: Result := _(rsErrUd);
    bsInvalidI: Result := _(rsErrI);
    bsInvalidR1:
      if FBInput.Circuit = bcMulti then Result := _(rsErrBRB1) else Result := _(rsErrBR1);
    bsInvalidR2:
      if FBInput.Circuit = bcMulti then Result := _(rsErrBRB2) else Result := _(rsErrBR2);
    bsInvalidC: Result := _(rsErrBC);
    bsInvalidF, bsInvalidDuty:
      if FBInput.Circuit = bcMulti then Result := _(rsErrBTimes)
      else if S = bsInvalidF then Result := _(rsErrBF)
      else Result := _(rsErrBDuty);
    bsDutyNeedsDiode: Result := _(rsErrBDiode);
    bsUTooLow:
      begin
        if FBInput.Circuit = bcMulti then
          Avail := FBInput.U - BJT_UCE_SAT
        else if FBInput.Conn = cnVcc then
          Avail := FBInput.U - NE555_LOW
        else
          Avail := FBInput.U - NE555_DROP_HIGH;
        Result := Format(_(rsErrBUTooLow), [FormatVolt(Max(0, Avail)), FormatVolt(FBInput.Ud)]);
      end;
    bsNoStdValue: Result := _(rsErrNoStd);
  else
    Result := '';
  end;
end;

{ Alles, was den Blink-Schaltplan verändert, als Text (Schlüssel für das
  Zwischenspeichern des geglätteten Bilds) }
function BlinkSchemKey(const V: TBlinkSchemValues; const Col: TBlinkSchemColors;
  Multi: Boolean): string;

  { Farbringe als Text }
  function BandsKey(const B: TBandArray): string;
  var
    I: Integer;  // Zähler
  begin
    Result := '';
    for I := 0 to High(B) do
      Result := Result + IntToStr(Ord(B[I])) + ',';
  end;

begin
  Result := Format('%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%s|%s',
    [V.UBText, V.R1Text, V.R2Text, V.CText, V.C2Text, V.RV1Text, V.RV2Text,
     V.Led1Text, V.Led2Text, V.UOutText, V.T1Text, V.T2Text,
     V.LedColor, Ord(V.Led1Lit), Ord(V.Led2Lit), Ord(V.Diode), Ord(V.Conn), Ord(V.Elko),
     Col.Line, Col.Text, Col.Accent, Col.Dim, Col.Body, Col.LedOff, Ord(Multi),
     BandsKey(V.Bands1), BandsKey(V.Bands2)]);
end;

procedure TFormMain.PaintBlinkSchematic;
var
  BC: TCanvas;           // Leinwand für das geglättete Zeichnen
  BR: TRect;             // Zeichenfläche darauf
  V: TBlinkSchemValues;   // Texte und Zustände
  Col: TBlinkSchemColors; // Farben
  R: TRect;               // Zeichenfläche
  Ok: Boolean;            // Resultat gültig
  Multi: Boolean;         // Multivibrator
  R1, R2: Double;         // anzuzeigende Zeitwiderstände
  Dash: string;           // Platzhalter

  { Wert oder Strich }
  function OhmOr(X: Double): string;
  begin
    if X > 0 then Result := FormatOhm(X) else Result := Dash;
  end;

begin
  Dash := '–';
  Ok := FBRes.Status = bsOk;
  Multi := FBInput.Circuit = bcMulti;
  V := Default(TBlinkSchemValues);
  if FBInput.U > 0 then V.UBText := 'U_B = ' + FormatVolt(FBInput.U) else V.UBText := 'U_B = ' + Dash;
  if Ok then
  begin
    R1 := FBRes.R1;
    R2 := FBRes.R2;
  end
  else
  begin
    R1 := FBInput.R1;
    R2 := FBInput.R2;
  end;
  if Multi then
  begin
    V.R1Text := 'R_B_1 = ' + OhmOr(R1);
    V.R2Text := 'R_B_2 = ' + OhmOr(R2);
    if FBInput.C > 0 then
    begin
      V.CText := 'C1 = ' + FormatCap(FBInput.C);
      V.C2Text := 'C2 = ' + FormatCap(FBInput.C);
    end
    else
    begin
      V.CText := 'C1 = ' + Dash;
      V.C2Text := 'C2 = ' + Dash;
    end;
    V.Led1Text := _(rsLed1);
    V.Led2Text := _(rsLed2);
    V.T1Text := 'T1 BC547';
    V.T2Text := 'T2 BC547';
  end
  else
  begin
    V.R1Text := 'R1 = ' + OhmOr(R1);
    V.R2Text := 'R2 = ' + OhmOr(R2);
    if FBInput.C > 0 then V.CText := 'C = ' + FormatCap(FBInput.C) else V.CText := 'C = ' + Dash;
    if FBInput.Conn = cnBoth then
    begin
      V.Led1Text := _(rsLed1);
      V.Led2Text := _(rsLed2);
    end
    else
      V.Led1Text := Format(_(rsSchemLed), [LedColorName]);
    if FBInput.Conn = cnVcc then
      V.UOutText := 'Low ≈ ' + FormatVolt(NE555_LOW)
    else if FBInput.U > 0 then
      V.UOutText := 'U_O_U_T ≈ ' + FormatVolt(FBInput.U - NE555_DROP_HIGH);
  end;
  if Ok then
  begin
    if Multi or (FBInput.Conn = cnBoth) then
    begin
      V.RV1Text := 'R_V_1 = ' + FormatOhm(FBRes.Led1.R);
      V.RV2Text := 'R_V_2 = ' + FormatOhm(FBRes.Led2.R);
    end
    else
      V.RV1Text := 'R_V = ' + FormatOhm(FBRes.Led1.R);
    V.Bands1 := FBBands1;
    V.Bands2 := FBBands2;
  end
  else if Multi or (FBInput.Conn = cnBoth) then
  begin
    V.RV1Text := 'R_V_1 = ' + Dash;
    V.RV2Text := 'R_V_2 = ' + Dash;
  end
  else
    V.RV1Text := 'R_V = ' + Dash;
  V.LedColor := LedGlowColor(CurrentLed);
  // blinkt die Vorschau, blinken die LEDs im Schaltplan im gleichen Takt
  if TimerBlink.Enabled then
  begin
    V.Led1Lit := FLedLit;
    V.Led2Lit := not FLedLit;
  end
  else
  begin
    V.Led1Lit := True;
    V.Led2Lit := True;
  end;
  V.Diode := FBInput.Diode;
  V.Conn := FBInput.Conn;
  V.Elko := FBInput.C >= 1e-6 * 0.999;

  Col.Line := clrLine;
  Col.Text := clrLine;
  Col.Accent := clrAccent;
  Col.Dim := clrTextDim;
  Col.Body := clrPanel;
  Col.LedOff := MixColor(V.LedColor, clrDeep, 0.22);

  R := PaintSchematic.ClientRect;
  InflateRect(R, -Px(16), -Px(16));
  // Schlüssel fürs Zwischenspeichern: beim Blinken wechseln nur zwei Bilder
  if not BeginSmooth(PaintSchematic.Canvas, R, clrDeep, BlinkSchemKey(V, Col, Multi), BC, BR) then Exit;
  if Multi then
    DrawSchematicMulti(BC, BR, V, Col)
  else
    DrawSchematic555(BC, BR, V, Col);
  EndSmooth;
end;

procedure TFormMain.PaintBlinkCards;
var
  C: TCanvas;          // Zeichenfläche
  Gap, W, X, I: Integer; // Abstand, Breite einer Karte, Position, Zähler
  R: TRect;            // aktuelle Karte
  Pad: Integer;        // Innenabstand
  Ok: Boolean;         // Resultat gültig
  Two: Boolean;        // zwei LEDs (Wechselblinker)
  T, V, Sub: string;   // Texte
  VC: TColor;          // Farbe des Werts
  P, Rating: Double;   // Leistung und Bauform
  WX, WY, WW, WH, PW: Integer; // Rechteck-Signal: Lage und Grösse, Periode
  K: Integer;          // Periode im Signal

  { Kartenrahmen, Titel, grosser Wert (passt sich der Breite an) und Untertext }
  procedure Card(const ATitle, AValue, ASub: string; AValueColor: TColor);
  var
    Y, Size: Integer; // laufende Zeile, Schriftgrösse
    H15: Integer;     // Zeilenhöhe bei voller Schriftgrösse
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
    C.Font.Style := [fsBold];
    C.Font.Color := AValueColor;
    Size := 15;
    C.Font.Size := Size;
    H15 := C.TextHeight('Ag');
    // langer Wert (z. B. zwei Zeiten): Schrift verkleinern, bis er passt
    while (Size > 9) and (C.TextWidth(AValue) > R.Right - R.Left - 2 * Pad) do
    begin
      Dec(Size);
      C.Font.Size := Size;
    end;
    // kleinere Schrift unten bündig mit der normalen Zeile
    C.TextOut(R.Left + Pad, Y + H15 - C.TextHeight('Ag'), AValue);
    Inc(Y, H15);
    C.Font.Size := 8;
    C.Font.Style := [];
    C.Font.Color := clrTextSoft;
    if ASub <> '' then
    begin
      TS := C.TextStyle;
      TS.Wordbreak := True;
      TS.SingleLine := False;
      TS.Clipping := True;
      C.TextRect(Types.Rect(R.Left + Pad, Y, R.Right - Pad, R.Bottom - Pad), R.Left + Pad, Y, ASub, TS);
    end;
  end;

  { zwei Zeiten mit gemeinsamer Einheit, z. B. "0,478 / 0,471 s" }
  function Pair(A, B: Double): string;
  begin
    if (A >= 0.1) and (B >= 0.1) then
      Result := FormatSig(A, 3) + ' / ' + FormatSig(B, 3) + ' s'
    else
      Result := FormatSeconds(A) + ' / ' + FormatSeconds(B);
  end;

begin
  C := PaintCards.Canvas;
  C.Brush.Color := clrWindow;
  C.FillRect(PaintCards.ClientRect);
  Gap := Px(8);
  Pad := Px(10);
  W := (PaintCards.Width - 3 * Gap) div 4;
  Ok := FBRes.Status = bsOk;
  Two := (FBInput.Circuit = bcMulti) or (FBInput.Conn = cnBoth);
  X := 0;
  for I := 0 to 3 do
  begin
    if I = 3 then
      R := Types.Rect(X, 0, PaintCards.Width, PaintCards.Height)
    else
      R := Types.Rect(X, 0, X + W, PaintCards.Height);
    C.ClipRect := R;
    C.Clipping := True;
    case I of
      0:
        if Ok then
        begin
          VC := clrTextBright;
          if Two then
            Sub := Format(_(rsBCardFreqSubAlt), [FormatSeconds(FBRes.T)])
          else
            Sub := Format(_(rsBCardFreqSub), [FormatSeconds(FBRes.T)]);
          if bwTooFast in FBRes.Warnings then
          begin
            VC := clrWarn;
            Sub := _(rsBCardFreqFast);
          end;
          Card(_(rsBCardFreq), FormatFreq(FBRes.F), Sub, VC);
        end
        else
          Card(_(rsBCardFreq), '–', '', clrTextBright);
      1:
        begin
          if FBInput.Circuit = bcMulti then T := _(rsBCardTimesMulti) else T := _(rsBCardTimes);
          if Ok then
          begin
            Card(T, Pair(FBRes.TOn1, FBRes.TOff1), '', clrTextBright);
            // Rechteck-Signal über zwei Perioden: hoch = LED 1 an
            WX := R.Left + Pad;
            WW := R.Right - R.Left - 2 * Pad;
            WH := Px(14);
            WY := R.Bottom - Pad;
            PW := WW div 2;
            if (PW > Px(8)) and (FBRes.Duty1 > 0) then
            begin
              C.Pen.Color := MixColor(LedGlowColor(CurrentLed), clrPanel, 0.85);
              C.Pen.Width := Max(1, Px(2) div 2 + 1);
              for K := 0 to 1 do
                C.PolyLine([Point(WX + K * PW, WY), Point(WX + K * PW, WY - WH),
                  Point(WX + K * PW + Round(PW * FBRes.Duty1), WY - WH),
                  Point(WX + K * PW + Round(PW * FBRes.Duty1), WY),
                  Point(WX + (K + 1) * PW, WY)]);
              C.Pen.Width := 1;
            end;
          end
          else
            Card(T, '–', '', clrTextBright);
        end;
      2:
        if FBInput.Circuit = bcMulti then
        begin
          if Ok then
          begin
            if bwNotSaturated in FBRes.Warnings then VC := clrWarn else VC := clrOk;
            Card(_(rsBCardBase), FormatMilliAmp(FBRes.IB),
              Format(_(rsBCardBaseSub), [FormatNum(FBRes.Overdrive, 1, 1), Round(BJT_BETA)]), VC);
          end
          else
            Card(_(rsBCardBase), '–', '', clrTextBright);
        end
        else if Ok then
        begin
          if FBInput.Conn = cnVcc then
            Sub := _(rsBCardDutySubVcc)
          else if FBInput.Diode then
            Sub := _(rsBCardDutySubDiode)
          else
            Sub := _(rsBCardDutySub);
          Card(_(rsBCardDuty), FormatPercent1(FBRes.Duty1), Sub, clrTextBright);
        end
        else
          Card(_(rsBCardDuty), '–', '', clrTextBright);
      3:
        begin
          T := Format(_(rsBCardRv), [SeriesName(FBInput.Series)]);
          if Ok then
          begin
            if FBRes.Led2.Used and not SameValue(FBRes.Led1.R, FBRes.Led2.R) then
              V := FormatOhm(FBRes.Led1.R) + ' / ' + FormatOhm(FBRes.Led2.R)
            else if FBRes.Led2.Used then
              V := '2 × ' + FormatOhm(FBRes.Led1.R)
            else
              V := FormatOhm(FBRes.Led1.R);
            P := Max(FBRes.Led1.P, FBRes.Led2.P);
            Rating := RecommendRating(P);
            if Rating > 0 then
              Sub := Format(_(rsBCardRvSub), [FormatMilliAmp(FBRes.Led1.IAct), FormatPower(FBRes.Led1.P),
                FormatRating(Rating)])
            else
              Sub := Format(_(rsBCardRvSub), [FormatMilliAmp(FBRes.Led1.IAct), FormatPower(FBRes.Led1.P),
                _(rsCardRatingNone)]);
            Card(T, V, Sub, clrTextBright);
          end
          else
            Card(T, '–', '', clrTextBright);
        end;
    end;
    C.Clipping := False;
    Inc(X, W + Gap);
  end;
end;

function TFormMain.BlinkRechenwegLines: TStringArray;
var
  Res: TBlinkResult;  // Abkürzung
  Inp: TBlinkInput;   // Abkürzung
  S, DHigh: Double;   // Summe der Widerstände rückwärts, High-Anteil
  Ser: string;        // Name der Normreihe
  Avail: Double;      // Spannung für LED und Vorwiderstand
begin
  Result := nil;
  Res := FBRes;
  Inp := FBInput;
  if Res.Status <> bsOk then
  begin
    SetLength(Result, 1);
    Result[0] := BlinkStatusText(Res.Status);
    Exit;
  end;
  Ser := SeriesName(Inp.Series);
  SetLength(Result, 5);
  if Inp.Circuit = bcNE555 then
  begin
    if Inp.Reverse then
    begin
      S := 1 / (Inp.F * Ln(2) * Inp.C);
      if Inp.Conn = cnVcc then DHigh := 1 - Inp.Duty else DHigh := Inp.Duty;
      if Inp.Diode then
        Result[0] := Format(_(rsBStep555Rev1D), [FormatFreq(Inp.F), FormatCap(Inp.C), FormatOhm(S)])
      else
        Result[0] := Format(_(rsBStep555Rev1), [FormatFreq(Inp.F), FormatCap(Inp.C), FormatOhm(S)]);
      Result[1] := Format(_(rsBStep555Rev2), [FormatPercent(DHigh), FormatOhm(Res.R1Calc), FormatOhm(Res.R1),
        FormatOhm(Res.R2Calc), FormatOhm(Res.R2), Ser]);
      Result[2] := Format(_(rsBStepFreqRev), [FormatSeconds(Res.THigh), FormatSeconds(Res.TLow),
        FormatFreq(Res.F), FormatPercent1(Res.Duty1)]);
    end
    else
    begin
      if Inp.Diode then
        Result[0] := Format(_(rsBStep555HighD), [FormatOhm(Res.R1), FormatCap(Res.C), FormatSeconds(Res.THigh)])
      else
        Result[0] := Format(_(rsBStep555High), [FormatOhm(Res.R1 + Res.R2), FormatCap(Res.C), FormatSeconds(Res.THigh)]);
      Result[1] := Format(_(rsBStep555Low), [FormatOhm(Res.R2), FormatCap(Res.C), FormatSeconds(Res.TLow)]);
      Result[2] := Format(_(rsBStepFreq), [FormatSeconds(Res.T), FormatFreq(Res.F), FormatPercent1(Res.Duty1)]);
    end;
    if Inp.Conn = cnVcc then
    begin
      Result[3] := Format(_(rsBStepOutVcc), [FormatVolt(Inp.U)]);
      Avail := Inp.U - NE555_LOW;
    end
    else
    begin
      Result[3] := Format(_(rsBStepOut), [FormatVolt(Inp.U), FormatVolt(Res.UOut)]);
      Avail := Res.UOut;
    end;
    if Inp.Conn = cnBoth then
      Result[4] := Format(_(rsBStepRvBoth), [FormatOhm(Res.Led1.R), FormatOhm(Res.Led2.R),
        FormatMilliAmp(Res.Led1.IAct), FormatMilliAmp(Res.Led2.IAct)])
    else
      Result[4] := Format(_(rsBStepRv), [FormatVolt(Avail), FormatVolt(Inp.Ud), FormatMilliAmp(Inp.I),
        FormatOhm(Res.Led1.RCalc), Ser, FormatOhm(Res.Led1.R), FormatMilliAmp(Res.Led1.IAct)]);
  end
  else
  begin
    Result[0] := Format(_(rsBStepMultiK), [FormatVolt(Res.DeltaU), FormatNum(Res.K, 3, 3)]);
    if Inp.Reverse then
      Result[1] := Format(_(rsBStepMultiRev), [FormatSeconds(Inp.Duty / Inp.F), FormatSeconds((1 - Inp.Duty) / Inp.F),
        FormatOhm(Res.R2Calc), FormatOhm(Res.R2), FormatOhm(Res.R1Calc), FormatOhm(Res.R1), Ser])
    else
      Result[1] := Format(_(rsBStepMultiT), [FormatNum(Res.K, 3, 3), FormatOhm(Res.R2), FormatCap(Res.C),
        FormatSeconds(Res.THigh), FormatSeconds(Res.TLow)]);
    Result[2] := Format(_(rsBStepMultiF), [FormatSeconds(Res.T), FormatFreq(Res.F), FormatPercent1(Res.Duty1)]);
    Result[3] := Format(_(rsBStepMultiBase), [FormatVolt(Inp.U - BJT_UBE), FormatOhm(Max(Res.R1, Res.R2)),
      FormatMilliAmp(Res.IB), FormatNum(Res.Overdrive, 1, 1), Round(BJT_BETA)]);
    Result[4] := Format(_(rsBStepMultiRv), [FormatVolt(Res.Led1.UR), FormatMilliAmp(Inp.I),
      FormatOhm(Res.Led1.RCalc), Ser, FormatOhm(Res.Led1.R), FormatMilliAmp(Res.Led1.IAct)]);
  end;
end;

procedure TFormMain.BlinkStatus(out ChipText, Txt: string; out Sym: Integer; out Fore, Back: TColor);
var
  Chips, Texts: array of string;  // Hinweise in der Reihenfolge ihrer Wichtigkeit

  { einen Hinweis anhängen }
  procedure Add(const AChip, AText: string);
  begin
    SetLength(Chips, Length(Chips) + 1);
    SetLength(Texts, Length(Texts) + 1);
    Chips[High(Chips)] := AChip;
    Texts[High(Texts)] := AText;
  end;

begin
  Chips := nil;
  Texts := nil;
  if FBRes.Status <> bsOk then
  begin
    ChipText := '';
    Sym := 2;
    Fore := clrError;
    Back := clrErrorBack;
    Txt := BlinkStatusText(FBRes.Status);
    Exit;
  end;
  if bwSupply555 in FBRes.Warnings then
    Add(_(rsChipSupply), Format(_(rsWarnSupply), [FormatVolt(FBInput.U)]));
  if bwBaseReverse in FBRes.Warnings then
    Add(Format(_(rsChipBase), [FormatVolt(FBRes.URev)]), Format(_(rsWarnBase), [FormatVolt(FBRes.URev)]));
  if bwNotSaturated in FBRes.Warnings then
    Add(_(rsChipSat), _(rsWarnSat));
  if bwR1Small in FBRes.Warnings then
    Add(_(rsChipR1), _(rsWarnR1));
  if bwOutCurrent in FBRes.Warnings then
    Add(_(rsChipOut), _(rsWarnOut));
  if bwRHigh in FBRes.Warnings then
    Add(_(rsChipRHigh), _(rsWarnRHigh));
  if bwTooFast in FBRes.Warnings then
    Add(_(rsChipFast), _(rsWarnFast));
  if Length(Chips) > 0 then
  begin
    ChipText := Chips[0];
    Txt := Texts[0];
    if Length(Chips) > 1 then
      Txt := Txt + Format(_(rsMoreHints), [Length(Chips) - 1]);
    Sym := 1;
    Fore := clrWarn;
    Back := clrWarnBack;
  end
  else
  begin
    if FBInput.Circuit = bcMulti then ChipText := _(rsChipOkMulti) else ChipText := _(rsChipOk555);
    Txt := _(rsOkTolerance);
    Sym := 0;
    Fore := clrOk;
    Back := clrOkBack;
  end;
end;

function TFormMain.BlinkSummary: string;
var
  SL: TStringList;   // Zeilen
  N1, N2: string;    // Namen der Zeitwiderstände
  Rv: string;        // Vorwiderstand(e)
begin
  if FBRes.Status <> bsOk then
    Exit(StringReplace(BlinkStatusText(FBRes.Status), '_', '', [rfReplaceAll]));
  SL := TStringList.Create;
  try
    SL.Add(Format(_(rsBCopyTitle), [APP_VER, ComboCircuit.Text]));
    SL.Add(StringReplace(Format(_(rsBCopyInput), [FormatVolt(FBInput.U), ComboColor.Text,
      FormatVolt(FBInput.Ud), FormatMilliAmp(FBInput.I)]), '_', '', [rfReplaceAll]));
    if FBInput.Circuit = bcMulti then
    begin
      N1 := 'RB1';
      N2 := 'RB2';
    end
    else
    begin
      N1 := 'R1';
      N2 := 'R2';
    end;
    SL.Add(Format(_(rsBCopyParts), [N1, FormatOhm(FBRes.R1), N2, FormatOhm(FBRes.R2), FormatCap(FBRes.C)]));
    SL.Add(Format(_(rsBCopyTimes), [FormatSeconds(FBRes.TOn1), FormatSeconds(FBRes.TOff1),
      FormatFreq(FBRes.F), FormatPercent1(FBRes.Duty1)]));
    Rv := FormatOhm(FBRes.Led1.R) + ' (' + BandNames(FBBands1, '-') + ')';
    if FBRes.Led2.Used then
      Rv := Rv + ', ' + FormatOhm(FBRes.Led2.R) + ' (' + BandNames(FBBands2, '-') + ')';
    SL.Add(Format(_(rsBCopyRv), [Rv]));
    Result := TrimRight(SL.Text);
  finally
    SL.Free;
  end;
end;

{ ---------- Konstantstrom ---------- }

{ Name des empfohlenen Bauteils }
function KsqPartName(P: TKsqPart): string;
begin
  case P of
    kpLM317L: Result := 'LM317L';
    kpLM317: Result := 'LM317';
    kpBC547: Result := 'BC547';
    kpBC337: Result := 'BC337';
  else
    Result := 'BD139';
  end;
end;

{ Leistungsbereich mit gemeinsamer Einheit, z. B. "80,0 … 124,1 mW" }
function FormatPowerRange(P1, P2: Double): string;
begin
  if Abs(P2 - P1) <= 0.005 * Max(Abs(P2), 1e-9) then
    Result := FormatPower(P2)
  else if P2 >= 1 then
    Result := FormatNum(P1, 2, 0) + ' … ' + FormatNum(P2, 2, 0) + ' W'
  else
    Result := FormatNum(P1 * 1000, 1, 1) + ' … ' + FormatNum(P2 * 1000, 1, 1) + ' mW';
end;

procedure TFormMain.ModeCaptions;
begin
  case FMode of
    1:
      begin
        LabelHeadInputs.Caption := _(rsHeadCircuit);
        LabelU.Caption := _(rsLabelU);
      end;
    2:
      begin
        LabelHeadInputs.Caption := _(rsHeadCircuit);
        LabelU.Caption := _(rsLabelFrom);
      end;
  else
    LabelHeadInputs.Caption := _(rsHeadInputs);
    LabelU.Caption := _(rsLabelU);
  end;
  UpdateTimingLabels;  // Kopf «LEDS» bzw. «LED AM AUSGANG»
end;

procedure TFormMain.KsqCircuitChange(Sender: TObject);
begin
  if FUpdating then Exit;
  Recalc;
  WriteViewSetting(INI_KEY_KSQ, ComboKsq.ItemIndex);
end;

procedure TFormMain.RecalcKsq;
var
  V: Double;  // umgewandelte Eingabe
begin
  FKInput := Default(TKsqInput);
  if ComboKsq.ItemIndex = Ord(kcTransistors) then
    FKInput.Circuit := kcTransistors
  else
    FKInput.Circuit := kcLM317;
  FKInput.UMin := FInput.U;
  // «bis» leer oder ungültig: feste Spannung (gleich wie «von»)
  if ParseDecimal(EditU2.Text, V) and (V > 0) then
    FKInput.UMax := V;
  FKInput.Ud := FInput.Ud;
  FKInput.I := FInput.I;
  FKInput.N := FInput.N;
  FKInput.Series := FInput.Series;
  FKRes := CalculateKsq(FKInput);
  FKBands := nil;
  FKBandsB := nil;
  if FKRes.Status = ksOk then
  begin
    if not ColorBands(FKRes.Std, FKInput.Series, FKBands) then FKBands := nil;
    if (FKInput.Circuit = kcTransistors) and not ColorBands(FKRes.RBStd, FKInput.Series, FKBandsB) then
      FKBandsB := nil;
  end;
end;

function TFormMain.KsqStatusText(S: TKsqStatus): string;
begin
  case S of
    ksInvalidU: Result := _(rsErrU);
    ksInvalidUd: Result := _(rsErrUd);
    ksInvalidI: Result := _(rsErrI);
    ksInvalidN: Result := _(rsErrN);
    ksTooMuchCurrent: Result := _(rsErrKCurrent);
    ksUTooLow: Result := Format(_(rsErrKUTooLow), [FormatVolt(FKRes.UMin), FormatVolt(FKRes.UNeed)]);
    ksNoStdValue: Result := _(rsErrNoStd);
  else
    Result := '';
  end;
end;

function TFormMain.KsqVoltRange: string;
begin
  if FKRes.UMax > FKRes.UMin then
    Result := FormatNum(FKRes.UMin, 2, 0) + ' … ' + FormatVolt(FKRes.UMax)
  else
    Result := FormatVolt(FKRes.UMin);
end;

function TFormMain.KsqLedVolt: string;
begin
  if FKInput.N > 1 then
    Result := IntToStr(FKInput.N) + ' × ' + FormatVolt(FKInput.Ud)
  else
    Result := FormatVolt(FKInput.Ud);
end;

function TFormMain.KsqPartText: string;
var
  N: string;  // Name des Bauteils
begin
  N := KsqPartName(FKRes.Part);
  if kwTooHot in FKRes.Warnings then
    Result := Format(_(rsKPartTooHot), [N])
  else if kwHeatsink in FKRes.Warnings then
    Result := Format(_(rsKPartHeatsink), [N, IntToStr(Floor(FKRes.HeatsinkRth))])
  else if FKRes.Part = kpLM317L then
    Result := _(rsKPartLM317L)
  else if FKRes.Part = kpLM317 then
    Result := _(rsKPartLM317)
  else
    Result := Format(_(rsKPartFree), [N]);
end;

function TFormMain.KsqRechenwegLines: TStringArray;
var
  Res: TKsqResult;   // Abkürzung
  Ser: string;       // Name der Normreihe
  RatingT: string;   // Bauform des Fühlerwiderstands
  Drift: Double;     // Stromänderung pro 10 °C (T2)
  PartShort: string; // empfohlenes Bauteil, kurz
begin
  Result := nil;
  Res := FKRes;
  if kwTooHot in Res.Warnings then
    PartShort := Format(_(rsKPartTooHot), [KsqPartName(Res.Part)])
  else if kwHeatsink in Res.Warnings then
    PartShort := Format(_(rsKPartShortHeat), [KsqPartName(Res.Part), IntToStr(Floor(Res.HeatsinkRth))])
  else
    PartShort := KsqPartName(Res.Part);
  if Res.Status <> ksOk then
  begin
    SetLength(Result, 1);
    Result[0] := KsqStatusText(Res.Status);
    Exit;
  end;
  Ser := SeriesName(FKInput.Series);
  if Res.RRating > 0 then RatingT := FormatRating(Res.RRating) else RatingT := _(rsCardRatingNone);
  SetLength(Result, 5);
  if FKInput.Circuit = kcLM317 then
  begin
    Result[0] := Format(_(rsKStepL1), [FormatMilliAmp(FKInput.I), FormatOhm(Res.RCalc), Ser, FormatOhm(Res.R)]);
    Result[1] := Format(_(rsKStepL2), [FormatOhm(Res.R), FormatMilliAmp(Res.IAct), FormatMilliAmp(Res.IAct),
      FormatPower(Res.PR), RatingT]);
    Result[2] := Format(_(rsKStepL3), [KsqLedVolt, FormatVolt(Res.UNeed), FormatVolt(Res.UMin), FormatVolt(Res.Reserve)]);
    Result[3] := Format(_(rsKStepL4), [KsqVoltRange, FormatVolt(Res.ULeds), FormatMilliAmp(Res.IAct),
      FormatPowerRange(Res.PLossMin, Res.PLossMax), PartShort]);
    if Res.UMax > Res.UMin then
      Result[4] := Format(_(rsKStepL5), [FormatVolt(Res.UMin), FormatVolt(Res.ULeds), FormatMilliAmp(FKInput.I),
        FormatOhm(Res.RvCalc), FormatVolt(Res.UMax), FormatPercent(Res.RvRise)])
    else
      Result[4] := _(rsKStepL5Fix);
  end
  else
  begin
    Drift := -KSQ_UBE_TC * 10 / KSQ_UBE_SENSE;
    Result[0] := Format(_(rsKStepT1), [FormatMilliAmp(FKInput.I), FormatOhm(Res.RCalc), Ser, FormatOhm(Res.R)]);
    Result[1] := Format(_(rsKStepT2), [FormatOhm(Res.R), FormatMilliAmp(Res.IAct), FormatPower(Res.PR), RatingT,
      FormatPercent(Drift)]);
    Result[2] := Format(_(rsKStepT3), [FormatMilliAmp(Res.IRB), KsqPartName(Res.Part), FormatMilliAmp(Res.IB1),
      FormatVolt(Res.UMin), FormatMilliAmp(Res.IRB), FormatOhm(Res.RBCalc), FormatOhm(Res.RB)]);
    Result[3] := Format(_(rsKStepT4), [KsqLedVolt, FormatVolt(Res.UNeed), FormatVolt(Res.UMin), FormatVolt(Res.Reserve)]);
    Result[4] := Format(_(rsKStepT5), [KsqVoltRange, FormatVolt(Res.ULeds), FormatMilliAmp(Res.IAct),
      FormatPowerRange(Res.PLossMin, Res.PLossMax), PartShort]);
  end;
end;

procedure TFormMain.PaintKsqSchematic;
var
  BC: TCanvas;           // Leinwand für das geglättete Zeichnen
  BR: TRect;             // Zeichenfläche darauf
  V: TKsqSchemValues;     // Texte und Werte
  Col: TBlinkSchemColors; // Farben
  R: TRect;               // Zeichenfläche
  Ok: Boolean;            // Resultat gültig
  Dash: string;           // Platzhalter
  LedName: string;        // Farbname der LED
begin
  Dash := '–';
  Ok := FKRes.Status = ksOk;
  LedName := LedColorName;
  V := Default(TKsqSchemValues);
  if FKRes.UMin > 0 then V.UBText := 'U_B = ' + KsqVoltRange else V.UBText := 'U_B = ' + Dash;
  if Ok and (FKRes.Part = kpLM317L) then V.ChipText := 'LM317L' else V.ChipText := 'LM317';
  V.RefText := 'U_R_E_F = 1,25 V';
  if LangCode = 'en' then V.RefText := 'U_R_E_F = 1.25 V';
  if FKInput.Circuit = kcLM317 then V.RText := 'R = ' else V.RText := 'R_S = ';
  if Ok then
  begin
    V.RText := V.RText + FormatOhm(FKRes.R);
    V.RSubText := 'I = ' + FormatMilliAmp(FKRes.IAct);
    V.RBText := 'R_B = ' + FormatOhm(FKRes.RB);
    V.T1Text := 'T1 ' + KsqPartName(FKRes.Part);
    V.Bands := FKBands;
    V.BandsB := FKBandsB;
  end
  else
  begin
    V.RText := V.RText + Dash;
    V.RSubText := 'I = ' + Dash;
    V.RBText := 'R_B = ' + Dash;
    V.T1Text := 'T1';
  end;
  V.T2Text := 'T2 BC547';
  if FKInput.N > 1 then
  begin
    V.LedText := Format(_(rsSchemLedN), [FKInput.N, LedName]);
    V.UFText := Format(_(rsSchemUFN), [FKInput.N, FormatVolt(FKInput.Ud)]);
  end
  else
  begin
    V.LedText := Format(_(rsSchemLed), [LedName]);
    V.UFText := Format(_(rsSchemUF), [FormatVolt(FKInput.Ud)]);
  end;
  V.TwoLeds := FKInput.N > 1;
  V.LedColor := LedGlowColor(CurrentLed);

  Col.Line := clrLine;
  Col.Text := clrLine;
  Col.Accent := clrAccent;
  Col.Dim := clrTextDim;
  Col.Body := clrPanel;
  Col.LedOff := MixColor(V.LedColor, clrDeep, 0.22);

  R := PaintSchematic.ClientRect;
  InflateRect(R, -Px(16), -Px(16));
  if not BeginSmooth(PaintSchematic.Canvas, R, clrDeep, '', BC, BR) then Exit;
  if FKInput.Circuit = kcLM317 then
    DrawSchematicLM317(BC, BR, V, Col)
  else
    DrawSchematicKsqT(BC, BR, V, Col);
  EndSmooth;
end;

procedure TFormMain.PaintKsqCards;
var
  C: TCanvas;          // Zeichenfläche
  Gap, W, X, I: Integer; // Abstand, Breite einer Karte, Position, Zähler
  R: TRect;            // aktuelle Karte
  Pad: Integer;        // Innenabstand
  Ok: Boolean;         // Resultat gültig
  LM: Boolean;         // Schaltung LM317
  T, Sub: string;      // Texte
  VC: TColor;          // Farbe des Werts
  TS: TTextStyle;      // Text mit Zeilenumbruch
  TH, SubTop: Integer; // Zeilenhöhe, Oberkante des Untertexts
  ResTop, ResBot: Integer; // Lage des gezeichneten Widerstands

  { Kartenrahmen, Titel, grosser Wert (passt sich der Breite an) und Untertext }
  procedure Card(const ATitle, AValue, ASub: string; AValueColor: TColor);
  var
    Y, Size: Integer; // laufende Zeile, Schriftgrösse
    H15: Integer;     // Zeilenhöhe bei voller Schriftgrösse
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
    C.Font.Style := [fsBold];
    C.Font.Color := AValueColor;
    Size := 15;
    C.Font.Size := Size;
    H15 := C.TextHeight('Ag');
    while (Size > 9) and (C.TextWidth(AValue) > R.Right - R.Left - 2 * Pad) do
    begin
      Dec(Size);
      C.Font.Size := Size;
    end;
    C.TextOut(R.Left + Pad, Y + H15 - C.TextHeight('Ag'), AValue);
    Inc(Y, H15);
    C.Font.Size := 8;
    C.Font.Style := [];
    C.Font.Color := clrTextSoft;
    if ASub <> '' then
    begin
      TS := C.TextStyle;
      TS.Wordbreak := True;
      TS.SingleLine := False;
      TS.Clipping := True;
      C.TextRect(Types.Rect(R.Left + Pad, Y, R.Right - Pad, R.Bottom - Pad), R.Left + Pad, Y, ASub, TS);
    end;
  end;

begin
  C := PaintCards.Canvas;
  C.Brush.Color := clrWindow;
  C.FillRect(PaintCards.ClientRect);
  Gap := Px(8);
  Pad := Px(10);
  W := (PaintCards.Width - 3 * Gap) div 4;
  Ok := FKRes.Status = ksOk;
  LM := FKInput.Circuit = kcLM317;
  X := 0;
  for I := 0 to 3 do
  begin
    if I = 3 then
      R := Types.Rect(X, 0, PaintCards.Width, PaintCards.Height)
    else
      R := Types.Rect(X, 0, X + W, PaintCards.Height);
    C.ClipRect := R;
    C.Clipping := True;
    case I of
      0:
        begin
          T := Format(_(rsKCardR), [SeriesName(FKInput.Series)]);
          if Ok then
          begin
            Card(T, FormatOhm(FKRes.R), '', clrTextBright);
            // Farbnamen und Bauform unten (bis zwei Zeilen), darüber der Widerstand
            if FKRes.RRating > 0 then
              Sub := Format(_(rsKCardRSub), [BandNames(FKBands, ' · '), FormatRating(FKRes.RRating), FormatPower(FKRes.PR)])
            else
              Sub := Format(_(rsKCardRSub), [BandNames(FKBands, ' · '), _(rsCardRatingNone), FormatPower(FKRes.PR)]);
            C.Font.Size := 8;
            C.Font.Style := [];
            C.Font.Color := clrTextSoft;
            TH := C.TextHeight('Ag');
            if C.TextWidth(Sub) > R.Right - R.Left - 2 * Pad then
              SubTop := R.Bottom - Pad - 2 * TH
            else
              SubTop := R.Bottom - Pad - TH;
            TS := C.TextStyle;
            TS.Wordbreak := True;
            TS.SingleLine := False;
            TS.Clipping := True;
            C.Brush.Style := bsClear;
            C.TextRect(Types.Rect(R.Left + Pad, SubTop, R.Right - Pad, R.Bottom - Pad), R.Left + Pad, SubTop, Sub, TS);
            ResBot := Min(R.Top + Px(80), SubTop - Px(4));
            ResTop := Max(R.Top + Px(58), ResBot - Px(24));
            if ResBot - ResTop >= Px(10) then
              DrawResistor(C, Types.Rect(R.Left + Pad, ResTop,
                R.Left + Pad + Min(Px(150), R.Right - R.Left - 2 * Pad), ResBot), FKBands);
          end
          else
            Card(T, '–', '', clrTextBright);
        end;
      1:
        if Ok then
        begin
          if not LM then
            Sub := Format(_(rsKCardISubT), [FormatOhm(FKRes.RCalc), FormatMilliAmp(FKInput.I),
              FormatPercent(-KSQ_UBE_TC * 10 / KSQ_UBE_SENSE)])
          else if FKRes.UMax > FKRes.UMin then
            Sub := Format(_(rsKCardISubL), [FormatOhm(FKRes.RCalc), FormatMilliAmp(FKInput.I),
              FormatVolt(FKRes.UMin), FormatVolt(FKRes.UMax)])
          else
            Sub := Format(_(rsKCardISubLFix), [FormatOhm(FKRes.RCalc), FormatMilliAmp(FKInput.I)]);
          Card(_(rsKCardI), FormatMilliAmp(FKRes.IAct), Sub, clrTextBright);
        end
        else
          Card(_(rsKCardI), '–', '', clrTextBright);
      2:
        begin
          if LM then T := _(rsKCardLossL) else T := _(rsKCardLossT);
          if Ok then
          begin
            if kwTooHot in FKRes.Warnings then VC := clrError
            else if kwHeatsink in FKRes.Warnings then VC := clrWarn
            else VC := clrOk;
            if LM then
              Sub := KsqPartText
            else
              Sub := Format(_(rsKCardLossSubT), [KsqPartText, FormatOhm(FKRes.RB)]);
            Card(T, FormatPowerRange(FKRes.PLossMin, FKRes.PLossMax), Sub, VC);
          end
          else
            Card(T, '–', '', clrTextBright);
        end;
      3:
        begin
          if LM then
            Sub := Format(_(rsKCardNeedSubL), [KsqLedVolt])
          else
            Sub := Format(_(rsKCardNeedSubT), [KsqLedVolt]);
          if Ok then
            Card(_(rsKCardNeed), FormatVolt(FKRes.UNeed), Sub, clrOk)
          else if FKRes.Status = ksUTooLow then
            Card(_(rsKCardNeed), FormatVolt(FKRes.UNeed), Sub, clrError)
          else
            Card(_(rsKCardNeed), '–', '', clrTextBright);
        end;
    end;
    C.Clipping := False;
    Inc(X, W + Gap);
  end;
end;

procedure TFormMain.KsqStatus(out ChipText, Txt: string; out Sym: Integer; out Fore, Back: TColor);
var
  Chips, Texts: array of string;  // Hinweise in der Reihenfolge ihrer Wichtigkeit
  Tab: string;                    // woran die Kühlfahne liegt

  { einen Hinweis anhängen }
  procedure Add(const AChip, AText: string);
  begin
    SetLength(Chips, Length(Chips) + 1);
    SetLength(Texts, Length(Texts) + 1);
    Chips[High(Chips)] := AChip;
    Texts[High(Texts)] := AText;
  end;

begin
  Chips := nil;
  Texts := nil;
  if FKRes.Status <> ksOk then
  begin
    ChipText := '';
    Sym := 2;
    Fore := clrError;
    Back := clrErrorBack;
    Txt := KsqStatusText(FKRes.Status);
    Exit;
  end;
  if kwTooHot in FKRes.Warnings then
    Add(_(rsKChipTooHot), Format(_(rsKWarnTooHot), [FormatPower(FKRes.PLossMax)]))
  else if kwHeatsink in FKRes.Warnings then
  begin
    if FKInput.Circuit = kcLM317 then Tab := _(rsKTabOut) else Tab := _(rsKTabCollector);
    Add(_(rsKChipHeat), Format(_(rsKWarnHeat), [KsqPartName(FKRes.Part), FormatPower(FKRes.PLossMax),
      IntToStr(Floor(FKRes.HeatsinkRth)), Tab]));
  end;
  if kwOverVoltage in FKRes.Warnings then
    if FKInput.Circuit = kcLM317 then
      Add(_(rsKChipVolt), _(rsKWarnVoltL))
    else
      Add(_(rsKChipVolt), _(rsKWarnVoltT));
  if kwMinLoad in FKRes.Warnings then
    Add(_(rsKChipMinLoad), _(rsKWarnMinLoad));
  if kwBaseHigh in FKRes.Warnings then
    if FKRes.RBRating > 0 then
      Add(_(rsKChipBase), Format(_(rsKWarnBase), [FormatOhm(FKRes.RB), FormatPower(FKRes.PRB), FormatRating(FKRes.RBRating)]))
    else
      Add(_(rsKChipBase), Format(_(rsKWarnBase), [FormatOhm(FKRes.RB), FormatPower(FKRes.PRB), _(rsCardRatingNone)]));
  if kwRPower in FKRes.Warnings then
    Add(_(rsKChipRPower), Format(_(rsKWarnRPower), [FormatPower(FKRes.PR)]));
  if Length(Chips) > 0 then
  begin
    ChipText := Chips[0];
    Txt := Texts[0];
    if Length(Chips) > 1 then
      Txt := Txt + Format(_(rsMoreHints), [Length(Chips) - 1]);
    Sym := 1;
    Fore := clrWarn;
    Back := clrWarnBack;
  end
  else
  begin
    ChipText := _(rsKChipOk);
    if FKRes.UMax <= FKRes.UMin then
      Txt := _(rsKOkFix)
    else if FKInput.Circuit = kcLM317 then
      Txt := Format(_(rsKOkRangeL), [FormatPercent(FKRes.RvRise), FormatVolt(FKRes.UMax)])
    else
      Txt := Format(_(rsKOkRangeT), [FormatPercent(FKRes.RvRise), FormatVolt(FKRes.UMax), FormatPercent1(FKRes.KsqRise)]);
    Sym := 0;
    Fore := clrOk;
    Back := clrOkBack;
  end;
end;

function TFormMain.KsqSummary: string;
var
  SL: TStringList;   // Zeilen
begin
  if FKRes.Status <> ksOk then
    Exit(StringReplace(KsqStatusText(FKRes.Status), '_', '', [rfReplaceAll]));
  SL := TStringList.Create;
  try
    SL.Add(Format(_(rsKCopyTitle), [APP_VER, ComboKsq.Text]));
    SL.Add(StringReplace(Format(_(rsCopyInput), [KsqVoltRange, FKInput.N, ComboColor.Text,
      FormatVolt(FKInput.Ud), FormatMilliAmp(FKInput.I)]), '_', '', [rfReplaceAll]));
    SL.Add(Format(_(rsKCopyR), [FormatOhm(FKRes.R), SeriesName(FKInput.Series), BandNames(FKBands, '-'),
      FormatOhm(FKRes.RCalc)]));
    SL.Add(Format(_(rsCopyCurrent), [FormatMilliAmp(FKRes.IAct)]));
    if FKInput.Circuit = kcTransistors then
      SL.Add(Format(_(rsKCopyRB), [FormatOhm(FKRes.RB), BandNames(FKBandsB, '-')]));
    SL.Add(Format(_(rsKCopyLoss), [FormatPowerRange(FKRes.PLossMin, FKRes.PLossMax), KsqPartText]));
    SL.Add(Format(_(rsKCopyNeed), [FormatVolt(FKRes.UNeed)]));
    Result := TrimRight(SL.Text);
  finally
    SL.Free;
  end;
end;

end.
