{ Hauptfenster von LedPreResistor.
  Verbindet später Eingaben, Rechnung (uCalc) und Anzeige. Im Moment nur das
  leere Fenster im dunklen Design, damit der automatische Build von Anfang an
  eine lauffähige EXE erzeugt. }
unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls;

const
  { Programmversion für Titelleiste und About-Fenster }
  APP_VER = '2.0';

type

  { TFormMain – das Hauptfenster }
  TFormMain = class(TForm)
    LabelTitel: TLabel;    // Programmname oben links
    LabelHinweis: TLabel;  // Platzhalter-Text, solange das Fenster leer ist
    procedure FormCreate(Sender: TObject);
  end;

var
  FormMain: TFormMain;  // die einzige Instanz des Hauptfensters

implementation

{$R *.lfm}

{ Wird beim Erzeugen des Fensters aufgerufen: setzt Titel und Grundfarben.
  Die Farben kommen später zentral aus uTheme. }
procedure TFormMain.FormCreate(Sender: TObject);
begin
  Caption := 'LedPreResistor · Elospeed ' + APP_VER;
  Color := $0018140F;               // Hintergrund #0F1418 (TColor ist BGR)
  LabelTitel.Font.Color := $00F0EBE6;   // Text #E6EBF0
  LabelHinweis.Font.Color := $00A4998E; // Nebentext #8E99A4
end;

end.
