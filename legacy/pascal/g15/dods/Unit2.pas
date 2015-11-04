unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,inifiles, Spin, ComCtrls;

type
  TForm2 = class(TForm)
    Button3: TButton;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Label1: TLabel;
    ListBox1: TListBox;
    Button2: TButton;
    TabSheet2: TTabSheet;
    extram: TCheckBox;
    Label2: TLabel;
    mytime: TSpinEdit;
    Button1: TButton;
    TabSheet3: TTabSheet;
    formatting: TListBox;
    Button4: TButton;
    procedure ListBox1DblClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure extramClick(Sender: TObject);
    procedure mytimeChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure formattingDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure formattingDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure Button4Click(Sender: TObject);
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

uses main;

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
'(c)copyright by Maniac 2007-2009' +#10#13+
'No Warranty!'  +#10#13+ #10#13+
'More Stuff will follow' +#10#13+ '' +#10#13+ 'Special Thanks to: XxXFaNtA', 
mtInformation, [mbOK], 0);

end;

procedure TForm2.Button4Click(Sender: TObject);
begin

ini.WriteInteger('Position','MAP',formatting.Items.IndexOf('Map: dod_sample'));
ini.WriteInteger('Position','CLASS',formatting.Items.IndexOf('Class: Sample Class'));
ini.WriteInteger('Position','TITLE',formatting.Items.IndexOf('DOD: Source - Statsplugin'));
ini.WriteInteger('Position','STATSTITLE',formatting.Items.IndexOf('Score | Kills | Death | K/D'));
ini.WriteInteger('Position','STATS',formatting.items.IndexOf('    0    |   0   |      0     |   1  '));

Form1.InitDisplayPositions;

end;

procedure TForm2.FormShow(Sender: TObject);
var i : integer;
    j : integer;
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

      formatting.clear;
      formatting.items.Add('DOD: Source - Statsplugin');
      formatting.items.Add('Map: dod_sample');
      formatting.items.Add('Class: Sample Class');
      formatting.items.Add('Score | Kills | Death | K/D');
      formatting.items.Add('    0    |   0   |      0     |   1  ');



      for j := 0 to formatting.items.Count - 1 do begin

        if formatting.items.Strings[j] = 'Map: dod_sample' then
          formatting.Items.Move(j,ini.readinteger('Position','MAP',1));

        if formatting.items.strings[j] = 'Class: Sample Class' then
          formatting.items.move(j,ini.ReadInteger('Position','CLASS',2));

        if formatting.Items.Strings[j] = 'DOD: Source - Statsplugin' then
          formatting.items.move(j,ini.ReadInteger('Position','TITLE',0));

        if formatting.Items.strings[j] = '    0    |   0   |      0     |   1  ' then
          formatting.items.move(j,ini.readinteger('Position','STATS',4));

        if formatting.items.strings[j] = 'Score | Kills | Death | K/D' then
          formatting.Items.Move(j,ini.ReadInteger('Position','STATSTITLE',3));
      end;
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

procedure TForm2.formattingDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  iTemp: Integer;
  ptTemp: TPoint;
  szTemp: string;
begin
  { change the x,y coordinates into a TPoint record }
  ptTemp.x := x;
  ptTemp.y := y;

  { Use a while loop instead of a for loop due to items possible being removed
   from listboxes this prevents an out of bounds exception }
  iTemp := 0;
   while iTemp <= TListBox(Source).Items.Count-1 do
  begin
    { look for the selected items as these are the ones we wish to move }
    if TListBox(Source).selected[iTemp] then
    begin
      { use a with as to make code easier to read }
      with Sender as TListBox do
      begin
      { need to use a temporary variable as when the item is deleted the
        indexing will change }
        szTemp := TListBox(Source).Items[iTemp];

        { delete the item that is being dragged  }
        TListBox(Source).Items.Delete(iTemp);

      { insert the item into the correct position in the listbox that it
       was dropped on }
        Items.Insert(itemAtPos(ptTemp, True), szTemp);
      end;
    end;
    Inc(iTemp);
  end;
end;                                                                                            
procedure TForm2.formattingDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
Accept := Sender is TListBox;
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
