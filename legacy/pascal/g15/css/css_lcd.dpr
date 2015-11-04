program css_lcd;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  lcdg15 in 'lcdg15.pas',
  Unit2 in 'Unit2.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'CS:S Statsplugin';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
