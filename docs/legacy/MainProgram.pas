unit MainProgram;

interface

//Registry und About muss vorhanden sein
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ExtCtrls, StdCtrls, Buttons, JvBitBtn,
  JvRadioButton, JvComponent, JvTransLED, JvLabel, JvScrollingLabel,
  JvGroupBox, JvWaitingGradient, Registry, About, ShellAPI;

type
    TMainForm = class(TForm)
    JvWaitingGradient2: TJvWaitingGradient;
    JvGroupBox1: TJvGroupBox;
    GroupLed: TJvGroupBox;
    RadioGruen: TJvRadioButton;
    RadioRot: TJvRadioButton;
    RadioGelb: TJvRadioButton;
    RadioWeiss: TJvRadioButton;
    RadioBlau: TJvRadioButton;
    RadioInfrarot: TJvRadioButton;
    RadioStandart: TJvRadioButton;
    RadioManuell: TJvRadioButton;
    JvLabel3: TJvLabel;
    JvLabel4: TJvLabel;
    JvLabel5: TJvLabel;
    JvLabel6: TJvLabel;
    JvLabel1: TJvLabel;
    JvLabel2: TJvLabel;
    JvGroupBox3: TJvGroupBox;
    JvGroupBox4: TJvGroupBox;
    JvGroupBox5: TJvGroupBox;
    JvBitBtn1: TJvBitBtn;
    TxtBetriebsspannung: TEdit;
    TxtDurchlassspannung: TEdit;
    TxtBetriebsstrom: TEdit;
    LedGruen: TJvTransLED;
    LedRot: TJvTransLED;
    LedGelb: TJvTransLED;
    LedWeiss: TJvTransLED;
    LedBlau: TJvTransLED;
    LedInfrarot: TJvTransLED;
    TGruen: TTimer;
    TRot: TTimer;
    TGelb: TTimer;
    TWeiss: TTimer;
    TBlau: TTimer;
    TInfrarot: TTimer;
    JvScrollingLabel2: TJvScrollingLabel;
    MainMenu1: TMainMenu;
    About1: TMenuItem;
    InfoPdf: TMenuItem;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    GroupResultat: TJvGroupBox;
    Label6: TLabel;
    JvGroupBox2: TJvGroupBox;
    Label7: TLabel;
    txtUr: TEdit;
    JvGroupBox6: TJvGroupBox;
    Label8: TLabel;
    txtRVor: TEdit;
    JvGroupBox7: TJvGroupBox;
    Label9: TLabel;
    txtR: TEdit;
    JvGroupBox8: TJvGroupBox;
    Label10: TLabel;
    txtILed: TEdit;
    JvGroupBox9: TJvGroupBox;
    Label11: TLabel;
    txtPt: TEdit;
    JvGroupBox10: TJvGroupBox;
    Label12: TLabel;
    txtPr: TEdit;
    Label5: TLabel;
    Image1: TImage;
    SpeedButton1: TSpeedButton;
    Timer1: TTimer;
    berLEDResistance1: TMenuItem;
    N1: TMenuItem;
    Beenden1: TMenuItem;
    procedure TGruenTimer(Sender: TObject);
    procedure TRotTimer(Sender: TObject);
    procedure TGelbTimer(Sender: TObject);
    procedure TWeissTimer(Sender: TObject);
    procedure TBlauTimer(Sender: TObject);
    procedure TInfrarotTimer(Sender: TObject);
    procedure RadioStandartClick(Sender: TObject);
    procedure RadioManuellClick(Sender: TObject);
    procedure RadioGruenClick(Sender: TObject);
    procedure RadioRotClick(Sender: TObject);
    procedure RadioGelbClick(Sender: TObject);
    procedure RadioWeissClick(Sender: TObject);
    procedure RadioBlauClick(Sender: TObject);
    procedure RadioInfrarotClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure JvBitBtn1Click(Sender: TObject);
    procedure TxtBetriebsspannungKeyPress(Sender: TObject; var Key: Char);
    procedure TxtDurchlassspannungKeyPress(Sender: TObject; var Key: Char);
    procedure TxtBetriebsstromKeyPress(Sender: TObject; var Key: Char);
    procedure FormCreate(Sender: TObject);
    procedure Beenden1Click(Sender: TObject);
    procedure berLEDResistance1Click(Sender: TObject);
    procedure InfoPdfClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);



  private
    { Private declarations }

  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
  Count: Integer;

implementation

{$R *.dfm}
{$R info.RES} //Einbindung der Ressource Info.pdf

//--> Überprüfung ob Acrobat Reader installiert ist
function IsAcrobatInstalled: Boolean;
var reg: TRegistry;
begin
  Result := false;
  reg := TRegistry.Create(KEY_READ); 
  with reg do 
  begin
    try 
      RootKey := HKEY_CLASSES_ROOT; 
      if OpenKey('CLSID\{CA8A9780-280D-11CF-A24D-444553540000}', False) 
        then Result := true 
    finally 
      CloseKey; 
      Free 
    end 
  end 
end;
//<--

//--> Pfad des Temporären Ordners ermitteln
function GetTempDir: string;
var 
  Buffer: array[0..MAX_PATH] of Char; 
begin 
  GetTempPath(SizeOf(Buffer) - 1, Buffer);
  Result := StrPas(Buffer);
end;
//<--

//--> Info.pdf aus Anwendung extrahieren
function ExtractRes(ResType, ResName, ResNewName: string): Boolean;
var 
  Res: TResourceStream; 
begin 
  Result := False; 
  Res := TResourceStream.Create(Hinstance, Resname, PChar(ResType));
  try 
    Res.SavetoFile(ResNewName); 
    Result := True;
  finally
    Res.Free;
  end; 
end;
//<--

//--> Den nächsten Widerstand aus der E12-Reihe bestimmen
function R_E12(R: Real): Real;
var n: integer;
    f: real;
const E12: array[0..11] of Real = (1,1.2,1.5,1.8,2.2,2.7,3.3,3.9,4.7,5.6,6.8,8.2);
begin
  f:=1;
  repeat
    for n:=0 to 11 do if E12[n]*f>=R then begin result:=E12[n]*f; f:=0; break; end;
    f:=f*10;
  until f<1;
end;
//<--

{-----------------------------------------------------------------------------------
   Visualisierungsprozeduren LED's
 ----------------------------------------------------------------------------------}

procedure TMainForm.TGruenTimer(Sender: TObject);
begin
  if LedGruen.Color=clGreen then
    LedGruen.Color:=clLime
  else
    LedGruen.Color:=clGreen;
end;

procedure TMainForm.TRotTimer(Sender: TObject);
begin
  if LedRot.Color=clMaroon then
    LedRot.Color:=clRed
  else
    LedRot.Color:=clMaroon;
end;

procedure TMainForm.TGelbTimer(Sender: TObject);
begin
  if LedGelb.color=clOlive then
    LedGelb.Color:=clYellow
  else
    LedGelb.Color:=clOlive;
end;

procedure TMainForm.TWeissTimer(Sender: TObject);
begin
  if LedWeiss.color=clSilver then
    LedWeiss.Color:=clWhite
  else
    LedWeiss.Color:=clSilver;
end;

procedure TMainForm.TBlauTimer(Sender: TObject);
begin
  if LedBlau.color=clSkyBlue then
    LedBlau.Color:=clBlue
  else
    LedBlau.Color:=clSkyBlue;
end;

procedure TMainForm.TInfrarotTimer(Sender: TObject);
begin
  if LedInfrarot.color=clPurple then
    LedInfrarot.Color:=clFuchsia
  else
    LedInfrarot.Color:=clPurple;
end;



procedure TMainForm.RadioStandartClick(Sender: TObject);
begin
  With txtDurchlassspannung do begin
    ReadOnly:=true;
    BorderStyle:=bsNone;
    Clear;
  end;
  RadioGruen.Enabled:=true;
  RadioRot.Enabled:=true;
  RadioGelb.Enabled:=true;
  RadioBlau.Enabled:=true;
  RadioInfrarot.Enabled:=true;
  RadioWeiss.Enabled:=true;
end;

procedure TMainForm.RadioManuellClick(Sender: TObject);
begin
  txtDurchlassspannung.ReadOnly:=false;
  txtDurchlassspannung.BorderStyle:=bsSingle;
  txtDurchlassspannung.Clear;
  TRot.Enabled:=false;
  LedRot.color:=clMaroon;
  TGelb.Enabled:=false;
  LedGelb.Color:=clOlive;
  TInfrarot.Enabled:=false;
  LedInfrarot.Color:=clPurple;
  TBlau.Enabled:=false;
  LedBlau.Color:=clSkyBlue;
  TWeiss.Enabled:=false;
  LedWeiss.Color:=clSilver;
  TGruen.Enabled:=false;
  LedGruen.Color:=clGreen;
  txtDurchlassspannung.SetFocus;
  RadioGruen.Enabled:=false;
  RadioRot.Enabled:=false;
  RadioGelb.Enabled:=false;
  RadioBlau.Enabled:=false;
  RadioInfrarot.Enabled:=false;
  RadioWeiss.Enabled:=false;
  RadioGruen.Checked:=false;
  RadioGelb.Checked:=false;
  RadioBlau.Checked:=false;
  RadioInfrarot.Checked:=false;
  RadioWeiss.Checked:=false;
end;

procedure TMainForm.RadioGruenClick(Sender: TObject);
begin
  TRot.Enabled:=false;
  LedRot.color:=clMaroon;
  TGelb.Enabled:=false;
  LedGelb.Color:=clOlive;
  TInfrarot.Enabled:=false;
  LedInfrarot.Color:=clPurple;
  TBlau.Enabled:=false;
  LedBlau.Color:=clSkyBlue;
  TWeiss.Enabled:=false;
  LedWeiss.Color:=clSilver;
  TGruen.Enabled:=false;
  LedGruen.Color:=clGreen;
  txtDurchlassspannung.Text:='2.1';
  TGruen.Enabled:=true;
end;

procedure TMainForm.RadioRotClick(Sender: TObject);
begin
  TRot.Enabled:=false;
  LedRot.color:=clMaroon;
  TGelb.Enabled:=false;
  LedGelb.Color:=clOlive;
  TInfrarot.Enabled:=false;
  LedInfrarot.Color:=clPurple;
  TBlau.Enabled:=false;
  LedBlau.Color:=clSkyBlue;
  TWeiss.Enabled:=false;
  LedWeiss.Color:=clSilver;
  TGruen.Enabled:=false;
  LedGruen.Color:=clGreen;
  txtDurchlassspannung.Text:='1.6';
  TRot.Enabled:=true;
end;

procedure TMainForm.RadioGelbClick(Sender: TObject);
begin
  TRot.Enabled:=false;
  LedRot.color:=clMaroon;
  TGelb.Enabled:=false;
  LedGelb.Color:=clOlive;
  TInfrarot.Enabled:=false;
  LedInfrarot.Color:=clPurple;
  TBlau.Enabled:=false;
  LedBlau.Color:=clSkyBlue;
  TWeiss.Enabled:=false;
  LedWeiss.Color:=clSilver;
  TGruen.Enabled:=false;
  LedGruen.Color:=clGreen;
  txtDurchlassspannung.Text:='2.2';
  TGelb.Enabled:=true;
end;

procedure TMainForm.RadioWeissClick(Sender: TObject);
begin
  TRot.Enabled:=false;
  LedRot.color:=clMaroon;
  TGelb.Enabled:=false;
  LedGelb.Color:=clOlive;
  TInfrarot.Enabled:=false;
  LedInfrarot.Color:=clPurple;
  TBlau.Enabled:=false;
  LedBlau.Color:=clSkyBlue;
  TWeiss.Enabled:=false;
  LedWeiss.Color:=clSilver;
  TGruen.Enabled:=false;
  LedGruen.Color:=clGreen;
  txtDurchlassspannung.Text:='4.0';
  TWeiss.Enabled:=true;
end;

procedure TMainForm.RadioBlauClick(Sender: TObject);
begin
  TRot.Enabled:=false;
  LedRot.color:=clMaroon;
  TGelb.Enabled:=false;
  LedGelb.Color:=clOlive;
  TInfrarot.Enabled:=false;
  LedInfrarot.Color:=clPurple;
  TBlau.Enabled:=false;
  LedBlau.Color:=clSkyBlue;
  TWeiss.Enabled:=false;
  LedWeiss.Color:=clSilver;
  TGruen.Enabled:=false;
  LedGruen.Color:=clGreen;
  txtDurchlassspannung.Text:='2.9';
  TBlau.Enabled:=true;
end;

procedure TMainForm.RadioInfrarotClick(Sender: TObject);
begin
  TRot.Enabled:=false;
  LedRot.color:=clMaroon;
  TGelb.Enabled:=false;
  LedGelb.Color:=clOlive;
  TInfrarot.Enabled:=false;
  LedInfrarot.Color:=clPurple;
  TBlau.Enabled:=false;
  LedBlau.Color:=clSkyBlue;
  TWeiss.Enabled:=false;
  LedWeiss.Color:=clSilver;
  TGruen.Enabled:=false;
  LedGruen.Color:=clGreen;
  txtDurchlassspannung.Text:='1.5';
  TInfrarot.Enabled:=true;
end;
{===================================================================================
 ===================================================================================}

//--> Blinken des errechneten Widerstandswerts
procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  if txtR.Font.Style=[] then
    txtR.Font.Style:=[fsbold]
  else
    txtR.Font.Style:=[];
  if Count=20 then
    begin
      txtR.Font.Style:=[];
      timer1.Enabled:=false;
      Count:=0;
    end
  else
    inc(count);
end;
//<--

{-----------------------------------------------------------------------------------
   Berechnungsroutine
 ----------------------------------------------------------------------------------}

procedure TMainForm.JvBitBtn1Click(Sender: TObject);
var
U,Ud,ILed,Ur,RVor,R,Pr,Pt,ILedResultierend,PLed: real;
begin
Count:=0;
 Try
 //--> Werteingabe Check
   If txtBetriebsspannung.text='' Then Begin MessageDlg('Betriebsspannung angeben !',mtInformation,[mbOk],0); Exit End;
   U:=StrToFloat(txtBetriebsspannung.Text);
   If U=0 Then Begin MessageDlg('Betriebsspannung angeben !',mtInformation,[mbOk],0); Exit End;

   If txtDurchlassspannung.Text='' Then Begin MessageDlg('Durchlassspannung angeben !',mtInformation,[mbOk],0); Exit End;
   Ud:=StrToFloat(txtDurchlassspannung.Text);
   If Ud=0 Then Begin MessageDlg('Durchlassspannung angeben !',mtInformation,[mbOk],0); Exit End;

   If txtBetriebsstrom.Text='' Then Begin MessageDlg('LED Betriebsstrom angeben !',mtInformation,[mbOk],0); Exit End;
   ILed:=StrToFloat(txtBetriebsstrom.Text);
   If ILed=0 Then Begin MessageDlg('LED Betriebsstrom angeben !',mtInformation,[mbOk],0); Exit End;

   If U <= Ud Then Begin MessageDlg('Betriebsspannung U kann nicht kleiner als die Durchlassspannung Ud der LED sein !',mtInformation,[mbOk],0); Exit End;
 //<-- Werteingabe Check

 //--> Berechnung
   Ur := U-Ud;
   txtUr.Text:=FloatToStr(Ur);

   ILed := ILed * 0.001;
   RVor := Ur / ILed;
   txtRVor.Text:=FloatToStr(RVor);

   R:=R_E12(RVor);
   txtR.Text:=FloatToStr(R);

   ILedResultierend:=Ur / R * 1000;
   txtILed.Text:=FloatToStr(ILedResultierend);

   Pr:=Ur * ILedResultierend ;
   txtPr.Text:=FloatToStr(Pr);

   PLed:=Ud * ILedResultierend;
   Pt:=PLed + Pr;
   txtPt.Text:=FloatToStr(Pt);
 //<-- Berechnung

   Timer1.Enabled:=true; // Blinken des errechneten Widerstandswerts

// Unbekannter Fehler !!
 except
   MessageDlg('Unbekannter Fehler ! Überprüfe die Eingaben !!',mtInformation,[mbOk],0); Exit;
 end
end;
{===================================================================================
 ===================================================================================}

{-----------------------------------------------------------------------------------
  Div. Textfeld Eingabebeschränkungen
 ----------------------------------------------------------------------------------}

procedure TMainForm.TxtBetriebsspannungKeyPress(Sender: TObject;
var Key: Char);
begin
  if Key = #13 then Key := #0 else if not (Key in [#8,#46,#48 .. #57]) then Key:= #0
end;

procedure TMainForm.TxtDurchlassspannungKeyPress(Sender: TObject;
var Key: Char);
begin
  if Key = #13 then Key := #0 else if not (Key in [#8,#46,#48 .. #57]) then Key:= #0
end;

procedure TMainForm.TxtBetriebsstromKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then Key := #0 else if not (Key in [#8,#46,#48 .. #57]) then Key:= #0
end;
{===================================================================================
 ===================================================================================}

{-----------------------------------------------------------------------------------
  Initialisierungs und Beendungsroutinen
 ----------------------------------------------------------------------------------}

 procedure TMainForm.FormCreate(Sender: TObject);
begin
  Count:=0; //In Timer1 verwendet - Blinken des Ergebnisses
end;

procedure TMainForm.Beenden1Click(Sender: TObject);
begin
  Application.Terminate;
end;
{===================================================================================
 ===================================================================================}

{-----------------------------------------------------------------------------------
  Form Über LedPreResistor
 ----------------------------------------------------------------------------------}

 procedure TMainForm.berLEDResistance1Click(Sender: TObject);
begin
  FormAbout.Show;
end;
{===================================================================================
 ===================================================================================}

{-----------------------------------------------------------------------------------
  Info-PDF laden...
 ----------------------------------------------------------------------------------}
procedure TMainForm.InfoPdfClick(Sender: TObject);
//--> Überprüfung ob Acrobat Reader installiert ist..
begin
  If IsAcrobatInstalled = False Then
    Begin
      MessageDlg('Adobe Acrobat Reader ist auf Ihrem Computer nicht installiert.' + chr(10) + chr(13) + 'Bitte laden sie den Adobe Acrobat Reader vom Internet herunter und versuchen Sie es erneut.' + chr(10) + chr(13) + 'Alternativ können Sie das Dokument auch auf "[Webseite entfernt]" online lesen.' , mtError, [mbOk], 0);
      Exit;
    end;
//<--

//--> Überprüfung ob Info.pdf im Temp Verzeichnis vorhanden ist
  If FileExists(GetTempDir + 'Info.pdf') Then
    Begin
    ShellExecute (Handle, nil, Pchar(GetTempDir +'info.pdf'), nil, nil, SW_MAXIMIZE);
    Exit;
    end;
//<--

//--> Info.pdf laden
  ExtractRes('PDFFILE', 'INFOFILE', GetTempDir + 'Info.pdf');
  if not FileExists(GetTempDir + 'Info.pdf') then
    Begin
      showmessage('Das extrahieren des PDF-Dokuments ist fehlgeschlagen !');
      Exit;
    end;
  ShellExecute (Handle, nil, PChar(GetTempDir +'info.pdf'), nil, nil, SW_MAXIMIZE);
end;
//<--

//--> Aufruf Routine Info-Pdf (Info Button klick !)
procedure TMainForm.SpeedButton1Click(Sender: TObject);
begin
  InfoPdf.Click;
end;
//<--
{===================================================================================
 ===================================================================================}

end.

