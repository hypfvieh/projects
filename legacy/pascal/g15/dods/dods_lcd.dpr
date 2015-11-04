program dods_lcd;

uses
  Forms,
  main in 'main.pas' {Form1},
  Unit2 in 'Unit2.pas' {Form2},
  processlist in 'processlist.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Day of Defeat: Source Statsplugin';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
