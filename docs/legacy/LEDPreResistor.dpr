program LEDPreResistor;

uses
  Forms,
  MainProgram in 'MainProgram.pas' {MainForm},
  About in 'About.pas' {FormAbout};

{$R *.res}


begin
  Application.Initialize;
  Application.Title := 'LED Pre-Resistor';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TFormAbout, FormAbout);
  Application.Run;
end.
