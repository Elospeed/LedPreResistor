unit About;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, JvScrollText, StdCtrls, JvGIF, ExtCtrls, JvGradient, ShellApi, JclFileUtils;


type
  TFormAbout = class(TForm)
    JvGradient1: TJvGradient;
    JvScrollText1: TJvScrollText;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    LabelToolName: TLabel;
    LabelCopyright: TLabel;
    Label3: TLabel;
    LabelVersion: TLabel;
    Label5: TLabel;
    LabelAutor: TLabel;
    LabelOriginalDateiName: TLabel;
    Label4: TLabel;
    Label6: TLabel;
    procedure OKClick(Sender: TObject);
    procedure Label1MouseLeave(Sender: TObject);
    procedure Label1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Label2MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Label2MouseLeave(Sender: TObject);
    procedure Label2Click(Sender: TObject);
    procedure Label1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }

  end;

var
  FormAbout: TFormAbout;
  ProduktName, Produktversion, OriginalDateiName: string;

implementation

{$R *.dfm}

procedure GetProductVersion(FileName: string);
var fi: TJclFileVersionInfo;
begin
  fi:=TJclFileVersionInfo.Create(FileName);
  try
    ProduktName:=fi.ProductName;
    Produktversion:=fi.FileVersion;
    OriginalDateiName:=fi.OriginalFilename;
  finally
    fi.free;
  end;
end;



procedure TFormAbout.OKClick(Sender: TObject);
begin
FormAbout.Visible:=False;
end;

procedure TFormAbout.Label1MouseLeave(Sender: TObject);
begin
Label1.Font.Color:=clWhite; Label1.Font.Style:=[fsBold];
end;

procedure TFormAbout.Label1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
Label1.Font.Color:=clBlue; Label1.Font.Style:=[fsBold,fsUnderline];
end;

procedure TFormAbout.Label2MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
Label2.Font.Size:=18;
Label2.Font.Style:=[fsBold];
end;

procedure TFormAbout.Label2MouseLeave(Sender: TObject);
begin
Label2.Font.Size:=14;
Label2.Font.Style:=[];
end;

procedure TFormAbout.Label2Click(Sender: TObject);
begin
FormAbout.Hide;
end;

procedure TFormAbout.Label1Click(Sender: TObject);
begin
ShellExecute(0, 'open', '[Webseite entfernt]', nil, nil, SW_SHOW);
//shellExecute(Application.Handle,'open', PChar('[Link entfernt]'), nil,nil,sw_ShowNormal);
end;




procedure TFormAbout.FormCreate(Sender: TObject);
var
AktuellDatum : TDateTime;
Jahr, Monat, Tag : Word;

begin
  GetProductVersion(application.ExeName);
  AktuellDatum:=Now;
  DecodeDate(AktuellDatum, Jahr, Monat, Tag);

  LabelToolName.Caption:= ProduktName;
  LabelCopyright.Caption:= 'Copyright © 2001 - ' + IntToStr(Jahr) + ' SpeedJohn Electronics';
  LabelVersion.Caption:= 'Version : ' + Produktversion;
  LabelOriginalDateiName.Caption:= 'Original-Dateiname: ' + OriginalDateiName;
end;

end.
