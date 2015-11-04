unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,inifiles, Spin;

type
  TForm2 = class(TForm)
    ListBox1: TListBox;
    Label1: TLabel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    extram: TCheckBox;
    Label2: TLabel;
    mytime: TSpinEdit;
    procedure ListBox1DblClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure extramClick(Sender: TObject);
    procedure mytimeChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
   dlllist : Tstringlist;
   ini : tinifile;
implementation

{$R *.dfm}

type
TDLLConfig = function(): Boolean; stdcall;



function Parse(Char, S: string; Count: Integer): string;
var
  I: Integer;
  T: string;
begin
  if S[Length(S)] <> Char then
    S := S + Char;
  for I := 1 to Count do
  begin
    T := Copy(S, 0, Pos(Char, S) - 1);
    S := Copy(S, Pos(Char, S) + 1, Length(S));
  end;
  Result := T;
end;



function CallDLLConfig(hdll : Thandle; functionname: string): Boolean;
var
  theFunction: TDLLConfig;
  buf: array [0..144] of Char;
begin
  if hDLL <> 0 then
  begin
    try
      @theFunction := GetProcAddress(hDll, StrPCopy(buf, functionname));
      if @theFunction <> nil then
        Result := theFunction()
      else
        raise Exception.Create('Could not load config function');
    finally
    end;
  end

end;

procedure TForm2.ListBox1DblClick(Sender: TObject);
begin
button2.click;
end;

procedure TForm2.Button1Click(Sender: TObject);
begin
deletefile(extractfilepath(application.exename) + '\dlllist.lst');
form2.Close;
end;

procedure TForm2.Button2Click(Sender: TObject);
var i : integer;
begin

for i := 0 to listbox1.Items.Count -1 do begin
    if listbox1.Selected[i] then begin
       CallDLLConfig(strtoint(parse('|',dlllist.strings[i],1)),'plugin_config');
    end;
end;
end;

procedure TForm2.Button3Click(Sender: TObject);
begin
MessageDlg('Day of Defeat: Source - Statsplugin' +#10#13+
'(c)copyright by Maniac 2007-2008' +#10#13+
'No Warranty!'  +#10#13+ #10#13+
'More Stuff will follow' +#10#13+ '' +#10#13+ 'Special Thanks to: XxXFaNtA', 
mtWarning, [mbOK], 0);

end;

procedure TForm2.FormShow(Sender: TObject);
var i : integer;
begin
     dlllist := tstringlist.create;
             if fileexists(extractfilepath(application.exename) + '\dlllist.lst') then begin
                button2.enabled := true;
                dlllist.LoadFromFile(extractfilepath(application.exename) + '\dlllist.lst');

                for i := 0 to dlllist.Count -1 do begin
                    listbox1.items.add(parse('|',dlllist.Strings[i],2));
                end;
             end;
     ini := tinifile.Create(extractfilepath(application.exename) + 'settings.ini');
     if ini.ReadInteger('settings','extramessages',0)  = 1 then
        extram.Checked := true;

     if ini.ReadInteger('settings','messagetime',0) <> 0 then
        mytime.Value := ini.ReadInteger('settings','messagetime',0);
end;

procedure TForm2.extramClick(Sender: TObject);
begin
if extram.Checked = true then begin
mytime.Enabled := true;
ini.WriteInteger('Settings','extramessages',1);

end
else if extram.checked = false then begin
mytime.Enabled := false;
ini.WriteInteger('Settings','extramessages',0);

end;
end;

procedure TForm2.mytimeChange(Sender: TObject);
begin
ini.WriteInteger('Settings','messagetime',mytime.Value);
end;

procedure TForm2.FormDestroy(Sender: TObject);
begin
deletefile(extractfilepath(application.exename) + '\dlllist.lst');
form2.Close;
end;

end.
