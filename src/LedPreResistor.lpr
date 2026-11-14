{==============================================================================
  LedPreResistor - Projektdatei (Hauptprogramm)
==============================================================================
  Zweck:     Startet Elospeed LedPreResistor. Das Programm rechnet für eine
             oder mehrere LEDs den Vorwiderstand, Blinkschaltungen und
             Konstantstromquellen.

  Aufbau:    Die ganze Arbeit steckt in uMain (Hauptfenster). Diese Datei
             erzeugt nur das Fenster und startet die Programmschleife.

  Lizenz:    MIT (siehe LICENSE im Hauptordner)

  Autor:     Elospeed
  Versionen: 2.4  14.11.2026  Kommentare ausführlicher
             2.0  29.10.2026  erste Fassung
==============================================================================}
program LedPreResistor;

{$mode objfpc}{$H+}

uses
  Interfaces,                                            // LCL-Anbindung an das Fenstersystem (Win32/Win64, GTK2)
  Forms,                                                 // Application, Fenster
  uSkalierung,                                           // jedes Fenster auf den freien Bildschirm begrenzen (DPI)
  uMain;                                                 // Hauptfenster

{$R *.res}                                               // Symbol, Versionsangaben, LED-Info, Übersetzung

begin
  RequireDerivedFormResource := True;                    // Fenster aus der .lfm laden
  Application.Title := 'Elospeed LedPreResistor';        // Name in der Taskleiste
  Application.Scaled := True;                            // Windows-Skalierung (DPI) beachten
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);           // Hauptfenster erzeugen
  Application.Run;                                       // Programmschleife bis zum Schliessen
end.
