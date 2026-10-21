{ Elospeed LedPreResistor 2.0 – Projektdatei.
  Berechnet den Vorwiderstand für eine oder mehrere LEDs.
  Lizenz: MIT (siehe LICENSE im Hauptordner). }
program LedPreResistor;

{$mode objfpc}{$H+}

uses
  Interfaces, // LCL-Anbindung an das Fenstersystem (unter Windows: Win32/Win64)
  Forms,
  uMain;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title := 'Elospeed LedPreResistor';
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
