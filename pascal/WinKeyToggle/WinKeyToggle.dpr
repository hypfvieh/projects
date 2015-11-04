program WinKeyToggle;

uses
  Forms,
  Unit1 in 'Unit1.pas' {frm_main};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'WinKeyToogle';
  Application.CreateForm(Tfrm_main, frm_main);
  Application.ShowMainForm := False;
  Application.Run;
end.
