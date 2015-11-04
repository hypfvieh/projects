(******************************************************************************
 * Counter-Strike:Source - Statsplugin for Logitech G15 Keyboards
 *
 * (c) copyright by Maniac 2007-2008
 *    
 *
 *  The program and the sourcecodes are provided as it is, no warranty!
 *  The author takes no responsabilty for any damage using this program
 *
 *  Everybody is allowed to use the sourcecodes for its own work. But please
 *  gimme a credit :)
 *  Respect the copyrights of the used libs and functions.
 *
 *
 *  the g15lcd.pas Unit is (c) 2006 smurfynet at users.sourceforge.net
 *  its published under GNU Public License.
 *
 *  parse function is (c)Johan Stokking (found at www.swissdelphicenter.ch)
 *
 *
 *  Thanks to:
 *
 *  smurfy -> For his great work, developing a G15 Unit for Delphi
 *  Johan Stokking -> For the great parse function, I used it many times!
 *  My Girlfriend -> That she doesnt kill me for wasting much time with this project
 *  Logitech -> For producing great Inputdevices :)
 *  Borland -> For their Delphi Personal Editions :D
 *
 *
 * Maniac @ 11.Jan.2008
 ******************************************************************************)



unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Graphics, Controls, Forms,
  Dialogs, StdCtrls, registry, ExtCtrls,strutils,lcdg15,tlhelp32,math,
  Classes,inifiles,processlist;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    update: TTimer;
    logitech_check: TTimer;
    loadplugins: TButton;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure updateTimer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure logitech_checkTimer(Sender: TObject);
    procedure loadpluginsClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
  LcdG15 : TLcdG15;
   procedure myCallbackConfigure();
   procedure myCallbackSoftButtons(dwButtons:integer);
    { Private declarations }
  public
 procedure MyExceptionHandler(Sender : TObject; E : Exception );

    { Public declarations }
  end;

CONST
  VERSION : String = '0.11.3';

var
  Form1: TForm1;
  OLDCONDEBUG : String;
  rsteam : TRegistry;
  rname : tregistry;
  ini : tinifile;
  steampath : String;
  myname,MYSERVER,MAP,MYPLAYERS,PUREMODE: String;
  KILLS,DEATH : Integer;
  connected : Boolean;
  OFFSET : Integer;
        KD : Real;
	debug : tstringlist;
	mytime : string;
   myaccount : string;
   loadeddlls : Tstringlist;
  activedisplay : integer;
   dlllist : TStringList;
   display : TBitmap;
   extramessages : boolean;
   waiting : integer;
   SteamWindowTitle : String = '';            // SteamWindow Title
implementation

uses md5, Unit2;

{$R *.dfm}

//
// that's all stuff I need to figure out the titel/handle of steam
//
type
  PFindWindowStruct = ^TFindWindowStruct;
  TFindWindowStruct = record
    Caption: string;
    ClassName: String;
    WindowHandle: THandle;
end;

TDLLOutput = function(): TCanvas; stdcall;
TDLLInit = function (apppath :Pchar; debugenable : boolean) :boolean; stdcall;
TDLLAction = function (line,playername : Pchar) : Pchar; stdcall;

// #############################################################################

  // Get PID from WindowHandle

function GetProcessNameFromWnd(Wnd: HWND): cardinal;
var
  PID: DWORD;
begin
  Result := 0;
  if IsWindow(Wnd) then  begin
    PID := INVALID_HANDLE_VALUE;
    GetWindowThreadProcessId(Wnd, @PID);
    Result := (PID);
  end;
end;

// #############################################################################
  // Get PID from ProcessName

function getPID(exeFileName: string): integer;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  Result := -1;
  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(ExeFileName))) then
    begin
      Result := FProcessEntry32.th32ProcessID;
    end;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

// DLL Loading/Unloading stuff

function CallDLLAction(hdll : thandle; functionname: string; line,playername : Pchar): Pchar;
var

  theFunction: TDLLAction;
  buf: array [0..144] of Char;
begin

  if hDLL <> 0 then
  begin
    try
      @theFunction := GetProcAddress(hDll, StrPCopy(buf, functionname));
      if @theFunction <> nil then
        Result := theFunction(line,playername)
      else
        raise Exception.Create('Could not load action function');
    finally
    end;
  end

end;

function CallDLLOutput(hdll : Thandle; functionname: string): TCanvas;
var
  theFunction: TDLLOutput;
  buf: array [0..144] of Char;
begin
  if hDLL <> 0 then
  begin
    try
      @theFunction := GetProcAddress(hDll, StrPCopy(buf, functionname));
      if @theFunction <> nil then
        Result := theFunction()
      else
        raise Exception.Create('Could not load output function');
    finally
    end;
  end

end;


function CallDLLInit(dllname, functionname: string; appPath: Pchar;  debugenable : boolean): boolean;
var
  hDLL: THandle;
  theFunction: TDLLInit;
  buf: array [0..144] of Char;
begin
  hDLL := LoadLibrary(StrPCopy(buf, dllname));
  if hDLL <> 0 then
  begin
    try
      @theFunction := GetProcAddress(hDll, StrPCopy(buf, functionname));
      if @theFunction <> nil then
        Result := theFunction(apppath,debugenable)
      else
         raise Exception.Create('Could not load init function');
    finally
      loadeddlls.add(inttostr(hdll) + '|' + extractfilename(dllname));
    end;
  end ;


end;


function EnumWindowsProc(hWindow: hWnd; lParam: LongInt): boolean; stdcall;
var lpBuffer: PChar;
    WindowCaptionFound: boolean;
    ClassNameFound: boolean;
begin
  GetMem(lpBuffer, 255);
  result:=true;
  WindowCaptionFound:=false;
  ClassNameFound:=false;
  try
    if GetWindowText(hWindow, lpBuffer,255)>0 then
      if Pos(PFindWindowStruct(lParam).Caption, StrPas(lpBuffer))>0
      then WindowCaptionFound:=true;
    if PFindWindowStruct(lParam).ClassName='' then
      ClassNameFound:=true
      else if GetClassName(hWindow, lpBuffer, 255)>0 then
        if Pos(PFindWindowStruct(lParam).ClassName, StrPas(lpBuffer))>0
        then ClassNameFound:=true;
    if (WindowCaptionFound and ClassNameFound) then begin
      PFindWindowStruct(lParam).WindowHandle:=hWindow;
      result:=false;
    end;
  finally
    FreeMem(lpBuffer, sizeof(lpBuffer^));
  end;
end;

function NT_InternalGetWindowText(Wnd: HWND): string;
type
  TInternalGetWindowText = function(Wnd: HWND; lpString: PWideChar;
    nMaxCount: Integer): Integer;
  stdcall;
var
  hUserDll: THandle;
  InternalGetWindowText: TInternalGetWindowText;
  lpString: array[0..MAX_PATH] of WideChar; //Buffer for window caption
begin
  Result   := '';
  hUserDll := GetModuleHandle('user32.dll');
  if (hUserDll > 0) then
  begin @InternalGetWindowText := GetProcAddress(hUserDll, 'InternalGetWindowText');
    if Assigned(InternalGetWindowText) then
    begin
      InternalGetWindowText(Wnd, lpString, SizeOf(lpString));
      Result := string(lpString);
    end;
  end;
end;


function FindAWindow(WinCaption: string; WinClassName: string): THandle;
var WindowInfo: TFindWindowStruct;
begin
  with WindowInfo do begin
    caption := WinCaption;
    className := WinClassName;
    WindowHandle := 0;
    EnumWindows(@EnumWindowsProc, LongInt(@WindowInfo));
    result := WindowHandle;
  end;
end;


//
//
// procedure to create debug messages
//
//
procedure debug1(mymessage : string);
begin
if paramstr(1) = '-debug' then begin
 mytime := datetostr(now) + ' ' + timetostr(now) + ' ';
debug.Add(mytime +  mymessage);
try
      debug.SaveToFile(extractfilepath(application.exename) + 'debug.log');
finally
end;
end;
end;

//
// procedure to "ignore" unhandled exceptions
//
procedure TForm1.MyExceptionHandler(Sender : TObject; E : Exception );
begin
debug1('[EXCEPTION] ' + E.Message);
end;

//
// function to check if a application is running (checks for the exename)
//
function processExists(exeFileName: string): Boolean;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  Result := False;
  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(ExeFileName))) then
    begin
      Result := True;
    end;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

//
//
// Johan Stokkings great parse function, divides strings with an delimeter
//
//
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

//
// Handle Softbuttons
//
procedure TForm1.myCallbackSoftButtons(dwButtons:integer);
begin
// this is for statsreset (button on the right under the LCD)
if processexists('hl2.exe') then begin
   if dwbuttons = 8 then begin
    KILLS := 0;
    DEATH := 0;
    KD := 1;
    button4.click;
   end;
end;


 if dwbuttons = 1 then begin
   if activedisplay < loadeddlls.count -1 then   begin
   inc(activedisplay);
   button1.click;
   button4.click;
   end
   else begin
   activedisplay := -1;
   button4.click;
   end;

 end;


end;
//end;

//
// Handle Configuredialog request from LCDMON
//
procedure TForm1.myCallbackConfigure();
begin
// our nice config screen.. :D
loadeddlls.SaveToFile(extractfilepath(application.exename) + '\dlllist.lst');
form2.showmodal;
debug1('[CONFIG] Showing Configbox');
end;

//
// function to display player which has been killed with weapon
//
function youkilledweapon(text : string; name : string) : string;
var
    newtext : String;
    revtext : String;
    output : string;
    temp : string;
    i : integer;
    spaces : integer;
begin
newtext := stringreplace(text,name + ' killed ','',[rfreplaceall]);

spaces := 0;

for i := length(newtext) downto 0 do
        revtext := revtext + newtext[i];

for i := length(revtext) downto 0 do begin

        if spaces = 2 then begin
                output := output + revtext[i];
        end;


        if (spaces < 2) and (revtext[i] = ' ') then
                inc(spaces);

end;

temp := StringReplace(newtext, output, '',[rfReplaceAll]);
temp := temp+#143+StringReplace(output,'with ','',[rfreplaceall]);
delete(temp,length(temp)-1 ,1);
Result := temp;
end;


// ###########################################################################

//
// function to show who has been killed by player with weapon
//
function deathbyweapon(text : string; name : string) : string;
var temp : string;
begin
temp := stringreplace(text,' killed ' + name + ' with ',#143,[rfreplaceall]);
delete(temp,length(temp), 1);
Result := temp;

end;

// ############################################################################


//
// function to calculate the output position of text on display (to center text)
//
function textposition(text : string) : integer;
const ImageWidth = 156;
      LetterSize = 6;
var   x : integer;
      y : Integer;
      z : Integer;
      letters : integer;
begin

letters := length(text);
x := letters * LetterSize;
y := ImageWidth - x;
z := y div 2;

Result := z;


end;




procedure TForm1.Button1Click(Sender: TObject);
var i : integer;
    strlst : TStringList;
    MyFile : TFilestream;
    Buff : Pchar;
    changes : boolean;
    dlls : integer;
    newstr : string;
    mystr : string;
    mytext : string;
    index : integer;
begin
// That was the biggest part of work
// this is the parser for the logfiles
// atm it supports: MAP, KILLS, DEATH
// it would be nice if it could show the Team I belong to
// but the logfile dont say which team I have.
// Only if I've captured something, and thats to late -.-
   changes := false;
   strlst := TStringList.Create;
   debug.add(mytime + '[PARSER] Creating Stringlist for console.log');
   debug.add(mytime + '[PARSER] Checking if console.log is existing (checking ' + OLDCONDEBUG + ')');
// first we need to check if hl2 is running and a logfile exists
        
 if (fileexists(OLDCONDEBUG)) and (processexists('hl2.exe')) then begin
 //  debug1('[PARSER] Console.log found, creating copy');
   debug1('[PARSER] Loading Copy to strlst');
// set filemode (method to open file, default is exclusive), since we share the file

   // try to catch exception if there is one (prevent "bong" sound and minimize of CSS)
   try
   // with hl2 we need to set sharemode;
   MyFile := TFilestream.Create(OLDCONDEBUG,fmOpenRead or fmShareDenyNone);
   debug1('[PARSER] Checking for Offset mistakes (Prevent out of index error)');

   if OFFSET > MyFile.Size then begin
      OFFSET := MyFile.Size;
      debug1('[CONSOLE.LOG] Console.log manipulation found, resetting OFFSET ');
       if fileexists(extractfilepath(application.exename)+'\logo.bmp') then begin
      display.LoadFromFile(extractfilepath(application.exename)+'\logo.bmp');
          display.Canvas.Font.Name := 'LinuxConsole6x10';
         display.Canvas.Font.Size := 6;
         display.Canvas.TextOut(37,22,'Version: ' + VERSION);
      if connected then begin
         LcdG15.LcdCanvas := display.canvas;
         LcdG15.SendToDisplay(128);
      end;
      end;
   end;
    MyFile.Seek(OFFSET,sofrombeginning);
    strlst.LoadFromStream(myFile);
   for i := 0 to strlst.Count -1 do begin
      if strlst.Strings[i] <> '' then begin
           Buff:= PChar(strlst.Strings[i]);

            if (parse(' ',strlst.strings[i],2) = 'to') and (parse(' ',strlst.strings[i],1) = 'Connected') then begin
            
            MYSERVER := parse(' ',strlst.Strings[i],3);
            end;

            if (parse(':',strlst.Strings[i],1) = 'Players') and (parse(' ',strlst.Strings[i],3) = '/') then begin
              MYPLAYERS := parse(':',strlst.Strings[i],2);
            end;

            if ((SearchBuf(Buff,length(buff),0,0,'Got pure server whitelist:') <> nil) and (SearchBuf(Buff,length(buff),0,0,'sv_pure') <> nil)) then begin

                    PUREMODE := parse('=',strlst.Strings[i],2);
                    PUREMODE := StringReplace(PUREMODE,' ','',[rfReplaceAll]);
                    PUREMODE := StringReplace(PUREMODE,'.','',[rfReplaceAll]);
                    if PUREMODE = '0' then
                    PUREMODE := '(0) Allowed'
                    else if PUREMODE = '1' then
                    PUREMODE := '(1) Restricted'
                    else if PUREMODE = '2' then
                    PUREMODE := '(2) Forbidden'
                    else
                    PUREMODE := 'Unknown';

                    button3.Click;
            end;
          for dlls := 0 to loadeddlls.Count -1 do begin
              debug1('[PARSER] Calling DLL: ' + parse('|',loadeddlls.strings[dlls],2));
              CallDLLAction(strtoint(parse('|',loadeddlls.Strings[dlls],1)),'plugin_action',Pchar(strlst.strings[i]),Pchar(myname));
          end;

         if SearchBuf(Buff,length(buff),0,0,myname + ' killed') <> nil then begin
            KILLS := KILLS + 1;
            if (DEATH <> 0) then
            KD := KILLS / DEATH
            else
            KD := KILLS / 1;
                if extramessages = true then begin
                 display.Canvas.Brush.Color := clwhite;
                 // oversize the rectangle, so that we dont see the top/bottom border
                 display.Canvas.Rectangle(0,-1,161,44);
                // set the font color to black, coz we dont know whats systemdefault is
                display.Canvas.Font.Color := clblack;
                display.Canvas.Font.Name := 'LinuxConsole6x10';

                display.Canvas.Font.Size := 9;
                display.Canvas.MoveTo(159,0);
                display.Canvas.LineTo(159,43);
                // now write the stuff to canvas...
                display.Canvas.TextOut(textposition('You'),0,'You');

                display.Canvas.TextOut(textposition('killed'),10,'killed');

                newstr := '';
                mystr := youkilledweapon(strlst.strings[i],myname);
                mytext := parse(#143,mystr,1);
                if length(mytext) >= 26 then begin
                index := length(mytext) - 26;

                delete(mytext,26,index+1);
                newstr := mytext;

                end
                else
                  newstr := myText;

                display.Canvas.TextOut(textposition(newstr),21,utf8toansi(newstr));
               ini.WriteInteger('Settings', 'offset',myfile.Position);
               // mystr := parse(#143,newstr,2parse(' ','with bar',2);
                display.Canvas.TextOut(textposition('with ' + ini.readstring('weapons',parse(#143,mystr,2),parse(#143,mystr,2))),32,'with ' + utf8toansi(ansiuppercase(ini.readstring('weapons',parse(#143,mystr,2),parse(#143,mystr,2)))));
                lcdg15.SendToDisplay(128);
            //    Application.ProcessMessages;
                sleep(waiting);


            end;
            changes := true;
	         debug1('[PARSER] Adding Kill and calculating k/d');
         end;

         if SearchBuf(Buff, length(Buff), 0, 0, 'killed '+myname + ' with') <> nil then begin
            DEATH := DEATH + 1;
            if (DEATH <> 0) then
            KD := KILLS / DEATH
            else
            KD := KILLS / 1;
             if extramessages = true then begin
                 display.Canvas.Brush.Color := clwhite;
                 // oversize the rectangle, so that we dont see the top/bottom border
                 display.Canvas.Rectangle(0,-1,161,44);
                // set the font color to black, coz we dont know whats systemdefault is
                display.Canvas.Font.Color := clblack;
                display.Canvas.Font.Name := 'LinuxConsole6x10';

                display.Canvas.Font.Size := 9;
                display.Canvas.MoveTo(159,0);
                display.Canvas.LineTo(159,43);
                // now write the stuff to canvas...
                display.Canvas.TextOut(textposition('You were'),0,'You were');

                display.Canvas.TextOut(textposition('killed by'),10,'killed by');

                newstr := '';
                mystr := deathbyweapon(strlst.strings[i],myname);
                mytext := parse(#143,mystr,1);
                if length(mytext) >= 26 then begin
                index := length(mytext) - 26;

                delete(mytext,26,index+1);
                newstr := mytext;

                end
                else
                  newstr := myText;

                display.Canvas.TextOut(textposition(newstr),21,utf8toansi(newstr));
                ini.WriteInteger('Settings', 'offset',myfile.Position);
               // mystr := parse(#143,newstr,2parse(' ','with bar',2);
                display.Canvas.TextOut(textposition('with ' + ini.readstring('weapons',parse(#143,mystr,2),parse(#143,mystr,2))),32,'with ' + utf8toansi(ansiuppercase(ini.ReadString('weapons',parse(#143,mystr,2),parse(#143,mystr,2)))));
                Lcdg15.SendToDisplay(128);
            //    Application.ProcessMessages;
               sleep(waiting);
                end;
            changes := true;
            debug1('[PARSER]Adding death and calculatng k/d');
         end;

         if SearchBuf(Buff,length(Buff), 0, 0, myname + ' suicided.') <> nil then begin
            changes := true;
            KILLS := KILLS -1;
            DEATH := DEATH +1;
            if (DEATH <> 0) then
            KD := KILLS / DEATH
            else
            KD := KILLS / 1;
             if extramessages = true then begin
                 display.Canvas.Brush.Color := clwhite;
                 // oversize the rectangle, so that we dont see the top/bottom border
                 display.Canvas.Rectangle(0,-1,161,44);
                // set the font color to black, coz we dont know whats systemdefault is
                display.Canvas.Font.Color := clblack;
                display.Canvas.Font.Name := 'LinuxConsole6x10';

                display.Canvas.Font.Size := 9;
                display.Canvas.MoveTo(159,0);
                display.Canvas.LineTo(159,43);
                // now write the stuff to canvas...
                display.Canvas.TextOut(textposition('You'),0,'You');

                display.Canvas.TextOut(textposition('killed'),10,'killed');
                display.Canvas.TextOut(textposition('yourself!'),21,'yourself!');
                ini.WriteInteger('Settings', 'offset',myfile.Position);
                LcdG15.SendToDisplay(128);
//                application.ProcessMessages;
               sleep(waiting);


                end;
	         debug1('[PARSER] Detected Suicide, recalculating kills, death and k/d');
         end;

           if SearchBuf(Buff,length(Buff), 0, 0, myname + ' died.') <> nil then begin

            DEATH := DEATH +1;
            if (DEATH <> 0) then
            KD := KILLS / DEATH
            else
            KD := KILLS / 1;
	    debug1('[PARSER] Detected Suicide, recalculating kills, death and k/d');
               if extramessages = true then begin
                 display.Canvas.Brush.Color := clwhite;
                 // oversize the rectangle, so that we dont see the top/bottom border
                 display.Canvas.Rectangle(0,-1,161,44);
                // set the font color to black, coz we dont know whats systemdefault is
                display.Canvas.Font.Color := clblack;
                display.Canvas.Font.Name := 'LinuxConsole6x10';

                display.Canvas.Font.Size := 9;
                display.Canvas.MoveTo(159,0);
                display.Canvas.LineTo(159,43);
                // now write the stuff to canvas...
                display.Canvas.TextOut(textposition('You'),0,'You');

                display.Canvas.TextOut(textposition('killed'),10,'killed');
                display.Canvas.TextOut(textposition('yourself!'),21,'yourself!');
                ini.WriteInteger('Settings', 'offset',myfile.Position);
                LcdG15.SendToDisplay(128);
          //    application.ProcessMessages       ;
                sleep(waiting);
            changes := false;


                end;
            changes := true;
         end;

         if parse(' ',strlst.Strings[i],1) = 'Map:' then begin
               KILLS := 0;
               DEATH := 0;
               KD := 1;
               MAP := utf8toansi(parse(' ',strlst.Strings[i],2));
               changes := true;
	       debug1('[PARSER] Resetting stats, changing map');
         end;

         if SearchBuf(Buff,length(buff),0,0, 'Steam config directory:') <> nil then begin
             display.LoadFromFile(extractfilepath(application.exename) + 'loading.bmp');
             if connected then begin
               LcdG15.LcdCanvas := display.canvas;
               LcdG15.SendToDisplay(128);
             end;
             debug1('[PARSER] Waiting for Information, to show');
         end;
      end;

   end;
   finally
    end;

// OFFSET is needed to only parse the new part of the file not the old stuff again
 debug1('[PARSER] Changeing last line counter for console.log');
 debug1('[PARSER] Path is: ' + OLDCONDEBUG);
  OFFSET := MyFile.Position;
// end;
 end
// show default picture if there is no css running
 else if not processexists('hl2.exe') then begin
 debug1('[PARSER] CSS is not running. Showing default logo');
 if fileexists(extractfilepath(application.exename)+'\logo.bmp') then begin
      display.LoadFromFile(extractfilepath(application.exename)+'\logo.bmp');
          display.Canvas.Font.Name := 'LinuxConsole6x10';
         display.Canvas.Font.Size := 6;
         display.Canvas.TextOut(37,22,'Version: ' + VERSION);
      if connected then begin
         LcdG15.LcdCanvas := display.canvas;
         LcdG15.SendToDisplay(128);
      end;
   end;
 end;
 strlst.Free;
 if assigned(MyFile) then 
 MyFile.Free;
 if changes then
 button6.click;

 debug1('[PARSER] Checking if hl2.exe is running (parser)');
 if not (processexists('hl2.exe')) and (OFFSET <> 0) then begin
 debug1('[PARSER] Setting new OFFSET');
 // this is just to know which lines we already check last time
 ini.WriteInteger('Settings','offset',OFFSET);
 end;

end;

procedure TForm1.FormCreate(Sender: TObject);
var
  hwndOwner: HWnd;
  Sem: THandle;
begin
// register LCD font
AddFontResource(PChar(ExtractFilePath(ParamStr(0)) + 'LinuxConsole6x10.fon'));


activedisplay := -1;
debug := tstringlist.create;
loadeddlls := tstringlist.create;
display := TBitmap.create;
display.Height := 43;
display.Width := 160;
mytime := datetostr(now) + ' ' + timetostr(now) + ' ';
debug1('[FORM CREATE] Debugger startet');
debug1('[FORM CREATE] Starting Version: ' + VERSION );
Application.OnException := MyExceptionHandler;
// This is to prevent the program to run more the once
 debug1('[FORM CREATE] Checking for running instances');
 Sem := CreateSemaphore(nil, 0, 1, 'UPG - CS:S Statsplugin');
  if ((Sem <> 0) and (GetLastError = ERROR_ALREADY_EXISTS)) then
  begin
    CloseHandle(Sem);
    MessageDlg('Programm already running', mtWarning,
      [mbOk], 0);
      debug1('[FORM CREATE] Programm already running, exiting now');
    Halt;
  end;


// this is to hide our programm from taskbar and taskmanager
debug1('[FORM CREATE] Sending program to background');
   hwndOwner := GetWindow(Handle, GW_OWNER);
   ShowWindow(hwndOwner, SW_HIDE);
   ShowWindowAsync(hwndOwner, SW_HIDE);
   ShowWindowAsync(Self.Handle, SW_HIDE);


form1.DesktopFont := false;
end;

procedure TForm1.Button2Click(Sender: TObject);
var 
    steamname : tregistry;  
begin
// Here I try to get the playername from registry
debug1('[NAME DETECT] trying to get player name');
steamname := tregistry.create;
steamname.RootKey := HKEY_CURRENT_USER;
steamname.OpenKeyReadOnly('\Software\Valve\Steam');
myname := steamname.ReadString('LastGameNameUsed');
debug1('[NAME DETECT] Found the following name: ' + myname);
steamname.free;


end;



procedure TForm1.Button4Click(Sender: TObject);
var i : integer;
begin
debug1('[IMG DISP] Creating Displayimage');
debug1('[IMG DISP] Plugin No. ' + inttostr(activedisplay));

 if activedisplay = -1 then begin
  display.Canvas.Brush.Color := clwhite;
  // oversize the rectangle, so that we dont see the top/bottom border
  display.Canvas.Rectangle(0,-1,161,44);
  // set the font color to black, coz we dont know whats systemdefault is
  display.Canvas.Font.Color := clblack;
  display.Canvas.Font.Name := 'LinuxConsole6x10';

  display.Canvas.Font.Size := 6;
  // a line on the left and on the right
  display.Canvas.MoveTo(159,0);
  display.Canvas.LineTo(159,43);
  // now write the stuff to canvas...
  display.Canvas.TextOut(3,-1,'CS:S - Statsplugin');
  display.Canvas.TextOut(3,7,'IP: ' + MYSERVER);
  display.Canvas.TextOut(3,16,'Map: ' + MAP);
  display.Canvas.TextOut(3,26,'Kills');
  display.Canvas.TextOut(35,26,'|');
  display.Canvas.TextOut(43,26,'Death');
  display.Canvas.TextOut(75,26,'|');
  display.Canvas.TextOut(83,26,'K/D');
//  display.Canvas.TextOut(115,26,'|');
//  display.Canvas.TextOut(124,26,'K/D');

  // Some checks for display formatting purpose
  if KILLS < 100 then begin
     display.Canvas.TextOut(15,35,inttostr(KILLS));
  end
  else begin
     display.Canvas.TextOut(8,35,inttostr(KILLS));
  end;

  display.Canvas.TextOut(35,35,'|');

  if DEATH < 100 then begin
    display.Canvas.TextOut(53,35,inttostr(DEATH));
  end
  else begin
    display.Canvas.TextOut(45,35,inttostr(DEATH));
  end;

  display.Canvas.TextOut(75,35,'|');

  if KD > 10 then begin
    display.Canvas.TextOut(93,35,floattostr(roundto(KD,-2)));
  end
  else begin
    display.Canvas.TextOut(86,35,floattostr(roundto(KD,-2)));
  end;

   debug1('[IMG DISP] Showing image');
// ...and show it on the display
   LcdG15.LcdCanvas := display.canvas;
   LcdG15.SendToDisplay(128);

 end
 else begin

  for i := 0 to loadeddlls.count -1  do begin

   if i = activedisplay then begin
     LcdG15.LcdCanvas := CallDllOutput(strtoint(parse('|',loadeddlls.strings[i],1)),'plugin_output');
     LcdG15.SendToDisplay(128);
   end;
  end;


 end;



end;

procedure TForm1.Button5Click(Sender: TObject);
begin
// register our application to the LCD Manager
debug1('[REGISTER] Registering programm to lcd manager');
LcdG15 := TLcdG15.Create('UPG - Counter-Strike:Source - Statsplugin',false,false,true);
// To check if configure button in the LCD Manager is clicked (I only show the copyright stuff)
LCDG15.OnConfigure := myCallbackConfigure;
LCDG15.OnSoftButtons := myCallbackSoftButtons;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
// reset our display connection, if we close our applications
if (LcdG15 <> nil) then
 LcdG15.Destroy;

RemoveFontResource(PChar(ExtractFilePath(ParamStr(0)) + 'LinuxConsole6x10.fon'));
debug1('[DESTROY] Resetting display. Removing Font. Exiting');

end;

procedure TForm1.Button6Click(Sender: TObject);
begin
// so do we need to connect first, or just send our canvas stuff?
debug1('[DISPLAY] Checking if display is connected');
if connected then begin
debug1('[DISPLAY] Display is connected');
button4.Click;
end
else begin
debug1('[DISPLAY] Display was not connected');
button5.click;
button4.Click;
connected := true;
end;


end;



procedure TForm1.updateTimer(Sender: TObject);
var     TheWindowHandle: THandle;
        ppid : integer;
        ProcPath : String;
begin
// here we get the steam username
if processexists('steam.exe') then begin
   TheWindowHandle:=FindAWindow('STEAM -', '');
      if TheWindowHandle=0 then  begin
         debug1('[TIMER] Hmm, no Steam found (searched: STEAM -)');
         TheWindowHandle := FindAWindow('Steam —', '');
      end;
      if TheWindowHandle = 0 then begin
        debug1('[TIMER] Hmm, no Steam, too (searched: Steam —)');
        TheWindowHandle := FindAWindow('Steam', '');
      end;
      if TheWindowHandle = 0 then
        debug1('[TIMER] Hmm, still no Steam found (searched: Steam)')
      else begin
          // check if windowhandle is steam
          ppid := GetProcessNameFromWnd(TheWindowHandle);
          debug1('[TIMER] Got ' + inttostr(ppid) + ' as pid');
          if ppid = getPID('steam.exe') then begin
             SteamWindowTitle := NT_InternalGetWindowText(TheWindowHandle);
             debug1('[TIMER] Windowtitle is: ' + SteamWindowTitle);
          end
          else begin
            if SteamWindowTitle <> '' then begin
              debug1('[TIMER] Got another (wrong) window with steam in title, ignoring!');
            end
            else begin
              debug1('[TIMER] Got a window with steam in title which has not the steam PID, thats great');
            end;
            
          end;
 // New Way of Getting active Steam-Account
         ProcPath := GetProcPath('hl2.exe');
         if ProcPath <> '' then begin

            debug1('[TIMER-PATH] Current Steam-Windowstitle: ' + SteamWindowTitle);
            debug1('[TIMER-PATH] Steam Path is: ' + steampath);
            debug1('[TIMER-PATH] Current HL2.exe Path: ' + ProcPath);

            MyAccount := GetAccountName(ProcPath,steampath);
            debug1('[TIMER-PATH] Got this Accountname: ' + MyAccount);

 (*        debug1('[TIMER-PATH] Current Windowstitle: ' + SteamWindowTitle);
         debug1('[TIMER-PATH] Username will be: ' + trim(parse(' ',SteamWindowTitle,2)));
         if (myaccount <> trim(parse(' ',SteamWindowTitle,2))) and (trim(parse(' ',SteamWindowTitle,2)) <> '-') then  begin
            myaccount := trim(parse(' ',SteamWindowTitle,2));
         end
         else begin
            myaccount := trim(parse(' ',SteamWindowTitle,3));
         end;  *)
                     // Setting console.log path
            debug1('[TIMER-PATH] got ' + myaccount + ' as username');
            if fileexists(steampath + '\steamapps\' + myaccount + '\counter-strike source\cstrike\console.log') then begin
               OLDCONDEBUG :=  steampath + '\steamapps\' + myaccount + '\counter-strike source\cstrike\console.log';
               debug1('[TIMER] Console.log -> ' + OLDCONDEBUG);
            end
            // this is need for steamnames with special characters, e.g. asterisk. In this case steam
            // generates a 128 Bit MD5 Hash, so we have to do the same, but we don't check for
            // special characters. We just try the MD5 hash, if the first try hasn't found something
            else if fileexists(steampath + '\steamapps\' + MD5DigestToStr(MD5string(lowercase(myaccount))) + '\counter-strike source\cstrike\console.log') then begin
               OLDCONDEBUG := steampath + '\steamapps\' + MD5DigestToStr(MD5string(lowercase(myaccount))) + '\counter-strike source\cstrike\console.log';
               debug1('[TIMER] Found Console.log in MD5 Path -> ' + OLDCONDEBUG);
            end
            else
               debug1('[TIMER] Console.log not found');

         
          end;
         end;
       
end
else if (processexists('steam.exe') = false) or (processexists('hl2.exe') = false) then begin
debug1('[TIMER-PATH] No Steam.exe found!/HL2 not running');
if fileexists(extractfilepath(application.exename)+'\logo.bmp') then begin
      display.LoadFromFile(extractfilepath(application.exename)+'\logo.bmp');
          display.Canvas.Font.Name := 'LinuxConsole6x10';
         display.Canvas.Font.Size := 6;
         display.Canvas.TextOut(37,22,'Version: ' + VERSION);
      if connected then begin
         LcdG15.LcdCanvas := display.canvas;
         LcdG15.SendToDisplay(128);
      end;
   end;
end;




// to get the newest stats
// only when CSS is running

   debug1('[TIMER] checking for hl2.exe');
   if processexists('hl2.exe') then begin
      debug1('[TIMER] hl.exe is running');
      button2.click;            // get playername from config.cfg
      button1.click;            // create stats

   end
   else begin
         debug1('[TIMER] hl2.exe was not running');
         button2.Click;
         button1.click;


   end;






end;

procedure TForm1.FormShow(Sender: TObject);
var Buff : Pchar;
begin


debug1('[StartUp] Setting default values');
// Set Startvalues for stats
   KILLS := 0;
   DEATH := 0;
   OFFSET := 0;
   MYSERVER := 'Unknown';
   MAP := 'Unknown';

// Create Display Handle
   LcdG15 := nil;

   rname := tregistry.create;
   rname.rootkey := HKEY_CURRENT_USER;
   rname.OpenKey('\Software\Valve\Steam',false);

   loadplugins.Click;
   steampath := stringreplace(rname.ReadString('SteamPath'),'/','\',[rfReplaceAll]);
   debug1('[ACC DETECT] Got: ' + steampath);

// Create and Open RegKey, to check if we know TF2 Path
   ini := tinifile.Create(extractfilepath(application.exename) + '\settings.ini');
   debug1('[StartUp] Getting Registry entry');
   if ini.ValueExists('Settings','offset') then  begin
      Offset := ini.ReadInteger('settings','offset',0);
      debug1('[StartUp] INI offset found: ' + inttostr(offset));
   end
   else
        Offset := 0;
   if ini.ValueExists('Settings','extramessages') then begin
        if ini.readinteger('settings','extramessages',0) = 1 then begin
        extramessages := true;
        debug1('[StartUp] Extramessages enabled')
        end
        else begin
        extramessages := falsE;
        debug1('[StartUp] Extramessages disabled');
        end;
   end
   else begin
        extramessages := false;
        debug1('[StartUp] Extramessages disabled');
   end;

   if ini.ValueExists('settings','messagetime') then begin
        waiting := ini.ReadInteger('settings','messagetime',2000);
        debug1('[StartUp] Message display time: ' + inttostr(waiting));
   end
   else begin
        waiting := 2000;
        debug1('[StartUp] Message display time reset to 2000');
   end;
        

// we need a fix to check if lcdmon.exe and lgdcore.exe is running before we
// try to setup our program
debug1('[StartUp] Running lcdmon/lgdcore checker');

// now we need to check if condebug is set, if it isnt, we set it


debug1('[CSS PARAM] Trying to get CSS Parameter');
rsteam := tregistry.create;
rsteam.RootKey := HKEY_CURRENT_USER;
rsteam.OpenKey('\Software\Valve\Steam\Apps\240',false) ;
Buff := PChar(rsteam.ReadString('LaunchOptions'));
if SearchBuf(Buff,length(buff),0,0,'-condebug') <> nil then begin
   debug1('[CSS PARAM] -condebug already set');
end
else begin
        debug1('[CSS PARAM] No -condebug set, setting it');
        rsteam.WriteString('LaunchOptions',rsteam.ReadString('LaunchOptions') + ' -condebug');
        rsteam.Free;
end;

end;


procedure TForm1.logitech_checkTimer(Sender: TObject);
begin
   if (processexists('lcdmon.exe')) then begin
      debug1('[LCDMON/LGDCORE] Got the Logitech stuff running, starting display setup');
// For beauty purpose we display a default picture
      debug1('[StartUp] Showing default logo');
      if not connected then begin
         button5.Click;
         LcdG15.Cleardisplay;
         if fileexists(extractfilepath(application.exename)+'\logo.bmp') then begin
         display.LoadFromFile(extractfilepath(application.exename)+'\logo.bmp');
         display.Canvas.Font.Name := 'LinuxConsole6x10';
         display.Canvas.Font.Size := 6;
         display.Canvas.TextOut(37,22,'Version: ' + VERSION);
         end;
         LcdG15.LcdCanvas := display.canvas;
         LcdG15.SendToDisplay(128);
         connected := true;
      end;
   debug1('[LCDMON/LGDCORE] Now that we have the logitech stuff running, we can stopp searching for it');
   logitech_check.Enabled := false;
   debug1('[LCDMON/LGDCORE] Starting default parser');
   update.Enabled := true;
   end;

   if paramstr(1) = '-debug' then  begin
      mytime := datetostr(now) + ' ' + timetostr(now) + ' ';
      debug.SaveToFile(extractfilepath(application.exename) + 'debug.log');
   end;
   debug1('[LCDMON/LGDCORE] Logitech stuff not running, retrying in 3 seconds');

end;

procedure TForm1.loadpluginsClick(Sender: TObject);
var srSearch : TSearchRec;
    i : integer;
begin
// get list of installed plugins (all dlls in plugins directory)
Dlllist := TStringlist.create;
 if FindFirst(extractfilepath(application.exename) + '\plugins\*.dll', 0, srSearch) = 0 then
      repeat
        if  (srSearch.Name <> '.') and
          (srSearch.Name <> '..') then
        begin
          DLLlist.Add(srSearch.Name);
          debug1('[PLUGIN LOADER] Found: ' + srsearch.name);
        end;
      until (FindNext(srSearch) <> 0);
    FindClose(srSearch);
// if you have them all, then start init to load it
    for i := 0 to dlllist.count -1 do begin
        if paramstr(1) = '-debug' then begin
        CallDLLInit(extractfilepath(application.exename) + '\plugins\' + dlllist.strings[i],'plugin_init',Pchar(extractfilepath(application.exename)),true);
        debug1('[PLUGIN LOADER] Loaded: ' + dlllist.Strings[i]);
        end
        else begin
        CallDLLInit(extractfilepath(application.exename) + '\plugins\' + dlllist.strings[i],'plugin_init',Pchar(extractfilepath(application.exename)),false);
        debug1('[PLUGIN LOADER] Loaded: ' + dlllist.Strings[i] + ' without debug (nobody will see this message)');
        end;
    end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
debug1('[PLYR CONNECT IMG DISP] Creating Displayimage');
debug1('[PLYR CÒNNECT IMG DISP] Plugin No. ' + inttostr(activedisplay));

  display.Canvas.Brush.Color := clwhite;
  // oversize the rectangle, so that we dont see the top/bottom border
  display.Canvas.Rectangle(0,-1,161,44);
  // set the font color to black, coz we dont know whats systemdefault is
  display.Canvas.Font.Color := clblack;
  display.Canvas.Font.Name := 'LinuxConsole6x10';

  display.Canvas.Font.Size := 6;
  // a line on the left and on the right
  display.Canvas.MoveTo(159,0);
  display.Canvas.LineTo(159,43);
  // now write the stuff to canvas...
  display.Canvas.TextOut(3,-1,'CS:S - Statsplugin');
  display.Canvas.TextOut(3,7,'IP: ' + MYSERVER);
  display.Canvas.TextOut(3,16,'Map: ' + MAP);
  display.Canvas.TextOut(3,26,'Players: '+ MYPLAYERS);
  display.Canvas.TextOut(3,35,'Pure Mode: '+ PUREMODE);


    debug1('[PLY CONNECT IMG DISP] Showing image');
// ...and show it on the display
 if not connected then
 button5.click
 else begin
   LcdG15.LcdCanvas := display.canvas;
   LcdG15.SendToDisplay(128);
 end;


end;
end.
