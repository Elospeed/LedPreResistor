program ProjectAbout;

uses
  Forms,
  About in 'About.pas' {FormAbout};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormAbout, FormAbout);
  Application.Run;
end.
