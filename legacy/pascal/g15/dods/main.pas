(******************************************************************************
 * Day of Defeat:Source - Statsplugin for Logitech G15 Keyboards
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
 * Maniac @ 14.Aug.2008
 ******************************************************************************)

unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, LogitechG15, Registry, Inifiles, tlhelp32,
  StrUtils, Math,lcdg15,processlist;

type
  TForm1 = class(TForm)
    update: TTimer;
    logitech_Check: TTimer;
    procedure logitech_CheckTimer(Sender: TObject);
    procedure updateTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

  private
     procedure myCallbackConfigure();
     procedure myCallbackSoftButtons(dwButtons:integer);
  public
     procedure MyExceptionHandler(Sender : TObject; E : Exception );
     procedure LogParser(Logfile : String; MyName : String) ;
     procedure DisplayImage;
     procedure InitDisplayPositions;
  end;

CONST
  VERSION = '0.28.1';

var
  Form1: TForm1;
  ini : TInifile; // handler for settings.ini
  Offset : Integer; // Logfile offset
  SteamPath : String; // Path to Steam
  MyImage : TBitMap;   // temp space for image
  DLLlist : TStringList; // List of plugins
  LoadedDLLs : TStringList; // List of loaded plugins
  activedisplay : Integer; // Plugin which is shown on the Display (-1 no plugin)
  OLDCONDEBUG : String; // path to console.log
  MYSERVER, PUREMODE, MAP, MYCLASS : String; // Parser variables
  MYPLAYERS : String;                        // have to be global
  KILLS, DEATH, CAPTURE : Integer;           // to reset it
  KD : Real;                                 // using the softbuttons
  CHECK : Boolean;                           // var to check if display needs update
    G15lcd : TLcdG15;                        // Displayhandle
  extramessages : boolean;                   // wether to show extra output or not
  waiting : integer;                         // time to display extramessages
  changes : boolean;                         // check if something new is to display
  classpos,mappos,titlepos,statspos,statstitlepos : integer; // positions of output on display
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

// #############################################################################



TDLLOutput = function(): TCanvas; stdcall;
TDLLInit = function (apppath :Pchar; debugenable : boolean) :boolean; stdcall;
TDLLAction = function (line,playername : Pchar) : Pchar; stdcall;



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

// #############################################################################



//
//  functions to get windowhandle for "title"
//


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


// #############################################################################



//
//  Procedure to set the output formatting
//
procedure TForm1.InitDisplayPositions;
begin
    case ini.ReadInteger('Position','MAP',1) of

   0:   mappos := -1;
   1:   mappos := 7;
   2:   mappos := 16;
   3:   mappos := 26;
   4:   mappos := 35;

   end;

   case ini.ReadInteger('Position','TITLE',0) of

   0:   titlepos := -1;
   1:   titlepos := 7;
   2:   titlepos := 16;
   3:   titlepos := 26;
   4:   titlepos := 35;

   end;

   case ini.ReadInteger('Position','CLASS',2) of

   0:   classpos := -1;
   1:   classpos := 7;
   2:   classpos := 16;
   3:   classpos := 26;
   4:   classpos := 35;

   end;

   case ini.ReadInteger('Position','STATS',4) of

   0:   statspos := -1;
   1:   statspos := 7;
   2:   statspos := 16;
   3:   statspos := 26;
   4:   statspos := 35;

   end;

   case ini.ReadInteger('Position','STATSTITLE',3) of

   0:   statstitlepos := -1;
   1:   statstitlepos := 7;
   2:   statstitlepos := 16;
   3:   statstitlepos := 26;
   4:   statstitlepos := 35;
   end;
end;



// #############################################################################

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

// #############################################################################


//
// procedure to log actions for debugging purpose
//
procedure debug1(mymessage : string);
var strlst : TSTringlist;
    mytime : String;
begin
if (paramstr(1) = '-debug') then begin
        strlst := TStringList.Create;
        mytime := datetostr(now) + ' - ' + timetostr(now);
                if fileexists(extractfilepath(application.exename) + '\debug.log') then
                        strlst.LoadFromFile(extractfilepath(application.exename) + '\debug.log');
        strlst.Add(mytime + ' ' + mymessage) ;
        strlst.SaveToFile(extractfilepath(application.exename) + '\debug.log');
end;
end;


// #############################################################################


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

// #############################################################################

//
// procedure to find all installed plugins
//

procedure LoadPlugins;
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


// #############################################################################


//
// procedure to "ignore" unhandled exceptions
//
procedure TForm1.MyExceptionHandler(Sender : TObject; E : Exception );
var mytime : String;
begin
debug1('[EXCEPTION] ' + E.Message);

mytime := datetostr(now) + ' ' + timetostr(now) + ' ';
end;

// #############################################################################


//
// function to get the Playername from Registry
//
function getPlayerName() : String;
var
    steamname : tregistry;
begin
debug1('[NAME DETECT] trying to get player name');
steamname := tregistry.create;
steamname.RootKey := HKEY_CURRENT_USER;
steamname.OpenKeyReadOnly('\Software\Valve\Steam');
Result := steamname.ReadString('LastGameNameUsed');
debug1('[NAME DETECT] Found the following name: ' + result);
steamname.free;
end;




// #############################################################################

//
// Logparser
//

procedure TForm1.LogParser(Logfile : String; MyName : String) ;
var i,j : integer;
    strlst : TStringList;
    MyFile : TFilestream;
    Buff : Pchar;
    spaces : integer;
    dlls : integer;

    newstr : utf8string;
    mytext : string;
    mystr : string;
    index : integer;

begin
// That was the biggest part of work
// this is the parser for the logfiles
// atm it supports: MAP, CLASS, KILLS, DEATH, CAPTURE
// it would be nice if it could show the Team I belong to
// but the logfile dont say which team I have.
// Only if I've captured something, and thats to late -.-
   debug1('[PARSER] Creating temp Image');

   changes := falsE;
   debug1('[PARSER] Creating Stringlist for console.log');
   strlst := TStringList.Create;
   debug1('[PARSER] Checking if console.log is existing');

   // first we need to check if hl2 is running and a logfile exists
 if (fileexists(Logfile)) and (processexists('hl2.exe')) then begin
   debug1('[PARSER] Loading Copy to strlst');
   // set filemode (method to open file, default is exclusive), since we share the file
   // try to catch exception if there is one (prevent "bong" sound and minimize of dod:S)
   try
   // with hl2 we need to set sharemode;
   MyFile := TFilestream.Create(LogFile,fmOpenRead or fmShareDenyNone);
   debug1('[PARSER] Checking for Offset mistakes (Prevent out of index error)');

   if OFFSET > MyFile.Size then begin
      OFFSET := MyFile.Size;
      debug1('[CONSOLE.LOG] Console.log manipulation found, resetting OFFSET ');
       if fileexists(extractfilepath(application.exename)+'\logo.bmp') then begin
         MyImage.LoadFromFile(extractfilepath(application.exename)+'\logo.bmp');
         MyImage.Canvas.Font.Name := 'LinuxConsole6x10';
         MyImage.Canvas.Font.Size := 6;
         MyImage.Canvas.TextOut(37,22,'Version: ' + VERSION);
         changes := true;
      end;
   end;
    MyFile.Seek(OFFSET,sofrombeginning);
    strlst.LoadFromStream(myFile);
   for i := 0 to strlst.Count -1 do begin
      if strlst.Strings[i] <> '' then begin
           Buff:= PChar(strlst.Strings[i]);
           if (parse(' ',strlst.strings[i],2) = 'to') and (parse(' ',strlst.strings[i],1) = 'Connected') then begin
             changes := true;
            MYSERVER := parse(' ',strlst.Strings[i],3);

            end;

            if (parse(':',strlst.Strings[i],1) = 'Players') and (parse(' ',strlst.Strings[i],3) = '/') then begin
              changes := true;
              MYPLAYERS := parse(':',strlst.Strings[i],2);

            end;

            if ((SearchBuf(Buff,length(buff),0,0,'Got pure server whitelist:') <> nil) and (SearchBuf(Buff,length(buff),0,0,'sv_pure') <> nil)) then begin
                    changes := true;
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
	         debug1('[PARSER] Adding Kill and calculating k/d');
                  if extramessages = true then begin
                 MyImage.Canvas.Brush.Color := clwhite;
                 // oversize the rectangle, so that we dont see the top/bottom border
                 MyImage.Canvas.Rectangle(0,-1,161,44);
                // set the font color to black, coz we dont know whats systemdefault is
                MyImage.Canvas.Font.Color := clblack;
                MyImage.Canvas.Font.Name := 'LinuxConsole6x10';

                MyImage.Canvas.Font.Size := 9;
                MyImage.Canvas.MoveTo(159,0);
                MyImage.Canvas.LineTo(159,43);
                // now write the stuff to canvas...
                MyImage.Canvas.TextOut(textposition('You'),0,'You');

                MyImage.Canvas.TextOut(textposition('killed'),10,'killed');

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

                MyImage.Canvas.TextOut(textposition(newstr),21,(newstr));
               ini.WriteInteger('Settings', 'offset',myfile.Position);
               // mystr := parse(#143,newstr,2parse(' ','with bar',2);
                MyImage.Canvas.TextOut(textposition('with ' + ini.readstring('weapons',parse(#143,mystr,2),parse(#143,mystr,2))),32,'with ' + utf8toansi(ansiuppercase(ini.readstring('weapons',parse(#143,mystr,2),parse(#143,mystr,2)))));
                g15lcd.SendToDisplay(128);
            //    Application.ProcessMessages;
                sleep(waiting);


            end;
                 changes := true;
         end;

         if SearchBuf(Buff, length(Buff), 0, 0, 'killed '+myname + ' with') <> nil then begin
            DEATH := DEATH + 1;
            if (DEATH <> 0) then
            KD := KILLS / DEATH
            else
            KD := KILLS / 1;
            debug1('[PARSER]Adding death and calculatng k/d');

            if extramessages = true then begin
                 MyImage.Canvas.Brush.Color := clwhite;
                 // oversize the rectangle, so that we dont see the top/bottom border
                 MyImage.Canvas.Rectangle(0,-1,161,44);
                // set the font color to black, coz we dont know whats systemdefault is
                MyImage.Canvas.Font.Color := clblack;
                MyImage.Canvas.Font.Name := 'LinuxConsole6x10';

                MyImage.Canvas.Font.Size := 9;
                MyImage.Canvas.MoveTo(159,0);
                MyImage.Canvas.LineTo(159,43);
                // now write the stuff to canvas...
                MyImage.Canvas.TextOut(textposition('You were'),0,'You were');

                MyImage.Canvas.TextOut(textposition('killed by'),10,'killed by');

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

                MyImage.Canvas.TextOut(textposition(newstr),21,(newstr));
                ini.WriteInteger('Settings', 'offset',myfile.Position);
               // mystr := parse(#143,newstr,2parse(' ','with bar',2);
                MyImage.Canvas.TextOut(textposition('with ' + ini.readstring('weapons',parse(#143,mystr,2),parse(#143,mystr,2))),32,'with ' + utf8toansi(ansiuppercase(ini.ReadString('weapons',parse(#143,mystr,2),parse(#143,mystr,2)))));
                g15lcd.SendToDisplay(128);
            //    Application.ProcessMessages;
               sleep(waiting);


            end;
            changes := true;
         end;

         if (SearchBuf(Buff,length(Buff), 0, 0, myname) <> nil) and (SearchBuf(Buff,length(Buff), 0, 0, 'captured') <> nil) then begin
            CAPTURE := CAPTURE +1;
	    debug1('[PARSER] Adding capture');
            changes := true;
         end;

         if SearchBuf(Buff,length(Buff), 0, 0, myname + ' suicided.') <> nil then begin

            DEATH := DEATH +1;
            if (DEATH <> 0) then
            KD := KILLS / DEATH
            else
            KD := KILLS / 1;
	    debug1('[PARSER] Detected Suicide, recalculating kills, death and k/d');
             if extramessages = true then begin
                 MyImage.Canvas.Brush.Color := clwhite;
                 // oversize the rectangle, so that we dont see the top/bottom border
                 MyImage.Canvas.Rectangle(0,-1,161,44);
                // set the font color to black, coz we dont know whats systemdefault is
                MyImage.Canvas.Font.Color := clblack;
                MyImage.Canvas.Font.Name := 'LinuxConsole6x10';

                MyImage.Canvas.Font.Size := 9;
                MyImage.Canvas.MoveTo(159,0);
                MyImage.Canvas.LineTo(159,43);
                // now write the stuff to canvas...
                MyImage.Canvas.TextOut(textposition('You'),0,'You');

                MyImage.Canvas.TextOut(textposition('killed'),10,'killed');
                MyImage.Canvas.TextOut(textposition('yourself!'),21,'yourself!');
                ini.WriteInteger('Settings', 'offset',myfile.Position);
                g15lcd.SendToDisplay(128);
//                application.ProcessMessages;
               sleep(waiting);


                end;
            changes := true;
         end;

            if SearchBuf(Buff,length(Buff), 0, 0, myname + ' died.') <> nil then begin

            DEATH := DEATH +1;
            if (DEATH <> 0) then
            KD := KILLS / DEATH
            else
            KD := KILLS / 1;
	    debug1('[PARSER] Detected Suicide, recalculating kills, death and k/d');
               if extramessages = true then begin
                 MyImage.Canvas.Brush.Color := clwhite;
                 // oversize the rectangle, so that we dont see the top/bottom border
                 MyImage.Canvas.Rectangle(0,-1,161,44);
                // set the font color to black, coz we dont know whats systemdefault is
                MyImage.Canvas.Font.Color := clblack;
                MyImage.Canvas.Font.Name := 'LinuxConsole6x10';

                MyImage.Canvas.Font.Size := 9;
                MyImage.Canvas.MoveTo(159,0);
                MyImage.Canvas.LineTo(159,43);
                // now write the stuff to canvas...
                MyImage.Canvas.TextOut(textposition('You'),0,'You');

                MyImage.Canvas.TextOut(textposition('killed'),10,'killed');
                MyImage.Canvas.TextOut(textposition('yourself!'),21,'yourself!');
                ini.WriteInteger('Settings', 'offset',myfile.Position);
                g15lcd.SendToDisplay(128);
          //    application.ProcessMessages       ;
                sleep(waiting);
            changes := false;


                end;
            changes := true;
         end;


         if (strlst.Strings[i][1] = '*') and (strlst.Strings[i][2] <> '*') and (SearchBuf(Buff,length(Buff), 0, 0, 'suicided.') = nil) and (SearchBuf(Buff,length(Buff), 0, 0, 'killed' ) = nil)
	 and (SearchBuf(Buff,length(Buff), 0, 0, 'teammate' ) = nil) and (SearchBuf(Buff,length(Buff), 0, 0, 'joined' ) = nil) and (SearchBuf(Buff,length(Buff), 0, 0, ':' ) = nil)then begin
         // we need this stuff for the spaces in the string
         // because the string changes with steam language settings
         // since we cant figure out the string for all languages (e.g. russian, chinese)
         // we need to get the class like this

            spaces := 0;
            for j := 0 to length(strlst.Strings[i]) do begin
               if strlst.Strings[i][j] = ' ' then  begin
                  spaces := spaces +1;
               end;
            end;
            debug1('[PARSER]{CLASS} Found ' + inttostr(spaces) + ' spaces');
         // this is just for the case we get an string with a * in front like
         // *You will respawn when you have selected a class
         // As far as I can see this and the Class string is the only default string
         // starting with an asterisk
            if spaces +1 < 7 then begin
               MYCLASS := utf8toansi(parse(' ',strlst.Strings[i],spaces +1));
         // quick & dirty workaround for Machine Gunner Class (only English version afaik)
               if MYCLASS = 'Gunner' then
                 MYCLASS := 'Machine Gunner';
	            debug1('[PARSER] Setting Class');
            end;
            changes := true;
         end;

         if parse(' ',strlst.Strings[i],1) = 'Map:' then begin
               KILLS := 0;
               DEATH := 0;
               CAPTURE := 0;
               KD := 1;
               MYCLASS := 'None Selected';
               MAP := utf8toansi(parse(' ',strlst.Strings[i],2));
	       debug1('[PARSER] Resetting stats, changing map');
               changes := true;
         end;


      end;

   end;
   finally
    end;

// OFFSET is needed to only parse the new part of the file not the old stuff again
 debug1('[PARSER] Changeing last line counter for console.log');
 debug1('[PARSER] Path is: ' + LogFile);
  OFFSET := MyFile.Position;
  ini.WriteInteger('Settings', 'offset',OFFSET);
//  ini.UpdateFile;
 end;

 strlst.Free;
if assigned(MyFile) then
 MyFile.Free;

 // Here we format the image and get it back as result

 DisplayImage;


end;


procedure TForm1.DisplayImage;
var i : integer;
begin
  

 debug1('[PARSER] Creating Displayimage');
debug1('[PARSER] Plugin No. ' + inttostr(activedisplay));
if (processexists('hl2.exe')) and (processexists('steam.exe')) then begin
 if activedisplay = -1 then begin
  MyImage.Canvas.Brush.Color := clwhite;
  // oversize the rectangle, so that we dont see the top/bottom border
  MyImage.Canvas.Rectangle(0,-1,161,44);
  // set the font color to black, coz we dont know whats systemdefault is
  MyImage.Canvas.Font.Color := clblack;
  MyImage.Canvas.Font.Name := 'LinuxConsole6x10';

  MyImage.Canvas.Font.Size := 6;
  // a line on the left and on the right
  MyImage.Canvas.MoveTo(159,0);
  MyImage.Canvas.LineTo(159,43);
  // now write the stuff to canvas...
  MyImage.Canvas.TextOut(3,titlepos,'DOD: Source - Statsplugin');
  MyImage.Canvas.TextOut(3,classpos,'Class: ' + MYCLASS);
  MyImage.Canvas.TextOut(3,mappos,'Map: ' + MAP);
  MyImage.Canvas.TextOut(3,statstitlepos,'Score');
  MyImage.Canvas.TextOut(35,statstitlepos,'|');
  MyImage.Canvas.TextOut(43,statstitlepos,'Kills');
  MyImage.Canvas.TextOut(75,statstitlepos,'|');
  MyImage.Canvas.TextOut(83,statstitlepos,'Death');
  MyImage.Canvas.TextOut(115,statstitlepos,'|');
  MyImage.Canvas.TextOut(124,statstitlepos,'K/D');

  // Some checks for MyImage formatting purpose
  if CAPTURE < 100 then begin
     MyImage.Canvas.TextOut(15,statspos,inttostr(CAPTURE));
  end
  else begin
     MyImage.Canvas.TextOut(8,statspos,inttostr(CAPTURE));
  end;

  MyImage.Canvas.TextOut(35,statspos,'|');

  if KILLS < 100 then begin
    MyImage.Canvas.TextOut(53,statspos,inttostr(KILLS));
  end
  else begin
    MyImage.Canvas.TextOut(45,statspos,inttostr(KILLS));
  end;

  MyImage.Canvas.TextOut(75,statspos,'|');

  if DEATH < 100 then begin
    MyImage.Canvas.TextOut(93,statspos,inttostr(DEATH));
  end
  else begin
    MyImage.Canvas.TextOut(86,statspos,inttostr(DEATH));
  end;

  MyImage.Canvas.TextOut(115,statspos,'|');

  if KD > 10 then begin
    MyImage.Canvas.TextOut(124,statspos,floattostr(roundto(KD,-2)));
  end
  else begin
    MyImage.Canvas.TextOut(130,statspos,floattostr(roundto(KD,-2)));
  end;
end;

// show default picture if there is no dod:s running

   debug1('[FORMAT] Image done, putting it into result');



 end
 else begin

  for i := 0 to loadeddlls.count -1  do begin

   if i = activedisplay then begin

    g15lcd.LcdCanvas := CallDllOutput(strtoint(parse('|',loadeddlls.strings[i],1)),'plugin_output');
     g15lcd.SendToDisplay(128);

   end;
  end;


 end;


  if not processexists('hl2.exe') then begin
 debug1('[PARSER] DOD:S is not running. Showing default logo');
 if fileexists(extractfilepath(application.exename)+'\logo.bmp') then begin
      MyImage.LoadFromFile(extractfilepath(application.exename)+'\logo.bmp');
      MyImage.Canvas.Font.Name := 'LinuxConsole6x10';
      MyImage.Canvas.Font.Size := 6;
      MyImage.Canvas.TextOut(37,22,'Version: ' + VERSION);
      changes := true;
   end;
 end;


 if changes then begin
 ini.WriteInteger('Settings', 'offset',offset);
    g15lcd.SendToDisplay(128);
    changes := false;
    end;





end;

// #############################################################################

//
// Callback function for softbuttons
//

procedure TForm1.myCallbackSoftButtons(dwButtons:integer);
begin
        if dwButtons = 8 then begin
        if (activedisplay < loadeddlls.count) and (loadeddlls.Count > 0) then   begin
                 inc(activedisplay);
                 LogParser(OLDCONDEBUG,GetPlayerName);

        end
                else begin
                activedisplay := -1;
                LogParser(OLDCONDEBUG,GetPlayerName);

        end;
        end;

        if dwButtons = 1 then begin
         if processexists('hl2.exe') then begin
            update.Enabled := false;
            KILLS := 0;
            DEATH := 0;
            CAPTURE := 0;
            KD := 1;
            changes := true;
            DisplayImage;
            update.Enabled := true;
//            LogParser(OLDCONDEBUG,GetPlayerName);
          

         end;

        end;
end;

// #############################################################################

//
// Callback function for configure-button in lcdmon
//

procedure TForm1.myCallbackConfigure();
begin
loadeddlls.SaveToFile(extractfilepath(application.exename) + '\dlllist.lst');
form2.showmodal;
debug1('[CONFIG] Showing Configbox');
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
end;


// #############################################################################

//
// Timer to check if lcdmon is running
//
procedure TForm1.logitech_CheckTimer(Sender: TObject);
begin

 if (processexists('lcdmon.exe')) then begin

      debug1('[LCDMON/LGDCORE] Got the Logitech stuff running, starting display setup');
// For beauty purpose we display a default picture
      debug1('[StartUp] Showing default logo');
         if fileexists(extractfilepath(application.exename)+'\logo.bmp') then begin
         // register our application to the LCD Manager
        debug1('[REGISTER] Registering programm to lcd manager');
        G15Lcd := TLcdG15.Create('Day of Defeat: Source - Statsplugin',false,false,true);
        // To check if configure button in the LCD Manager is clicked
        G15lcd.OnConfigure := myCallbackConfigure;
        G15lcd.OnSoftButtons := myCallbackSoftButtons;
        g15lcd.LcdCanvas := MyImage.Canvas;
        LogParser(OLDCONDEBUG,GetPlayerName);

         end;
   debug1('[LCDMON/LGDCORE] Now that we have the logitech stuff running, we can stopp searching for it');
   logitech_check.Enabled := false;
   debug1('[LCDMON/LGDCORE] Starting default parser');
   update.Enabled := true;
   end
   else begin
        debug1('[LCDMON/LGDCORE] Logitech stuff not running, retrying in 3 seconds');
   end;


end;

// #############################################################################

//
// Timer for parsing the logfile
//
procedure TForm1.updateTimer(Sender: TObject);
var     TheWindowHandle: THandle;
        myaccount : String;
        ppid : integer;
        ProcPath : String;
begin
// here we get the steam username
if (processexists('steam.exe')) and (processexists('hl2.exe')) then begin
// Check if there is a correct steam window
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
              exit;
            end
            else begin
              debug1('[TIMER] Got a window with steam in title which has not the steam PID, thats great');
              exit;
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
// this is the old stuff, doesnt work with SteamUI Update 2010

            //debug1('[TIMER-PATH] Username will be: ' + trim(parse(' ',SteamWindowTitle,2)));
 (*           if (myaccount <> trim(parse(' ',SteamWindowTitle,2))) and (trim(parse(' ',SteamWindowTitle,2)) <> '-') then  begin
              myaccount := trim(parse(' ',SteamWindowTitle,2));
            end
            else begin
              myaccount := trim(parse(' ',SteamWindowTitle,3));
            end;  *)


                     // Setting console.log path
            if fileexists(steampath + '\steamapps\' + myaccount + '\Day of Defeat Source\dod\console.log') then begin
               OLDCONDEBUG :=  steampath + '\steamapps\' + myaccount + '\Day of Defeat Source\dod\console.log';
               debug1('[TIMER] Console.log -> ' + OLDCONDEBUG);
            end
            // this is need for steamnames with special characters, e.g. asterisk. In this case steam
            // generates a 128 Bit MD5 Hash, so we have to do the same, but we don't check for
            // special characters. We just try the MD5 hash, if the first try without hasn't find something
            else if fileexists(steampath + '\steamapps\' + MD5DigestToStr(MD5string(lowercase(myaccount))) + '\Day of Defeat Source\dod\console.log') then begin
               OLDCONDEBUG := steampath + '\steamapps\' + MD5DigestToStr(MD5string(lowercase(myaccount))) + '\Day of Defeat Source\dod\console.log';
               debug1('[TIMER] Found Console.log in MD5 Path -> ' + OLDCONDEBUG);
            end
            else
               debug1('[TIMER] Console.log not found');



         end;

     end;
end
else if not processexists('steam.exe') then begin
debug1('[TIMER] Steam.exe not found');
if not CHECK then begin
if fileexists(extractfilepath(application.exename)+'\logo.bmp') then begin
        CHECK := true;
        LogParser(OLDCONDEBUG,GetPlayerName);
end;
end;

end;

if not processexists('hl2.exe') then begin
debug1('[TIMER] hl2.exe not found');
if not CHECK then begin
if fileexists(extractfilepath(application.exename)+'\logo.bmp') then begin
        CHECK := TRUE;
        LogParser(OLDCONDEBUG,GetPlayerName);
end;
end;
end;
// to get the newest stats
// only when dod is running

   debug1('[TIMER] checking for hl2.exe');
   if processexists('hl2.exe') then begin
      debug1('[TIMER] hl.exe is running');
      CHECK := FALSE;
      LogParser(OLDCONDEBUG,GetPlayerName);

   end  ;



end;

// ############################################################################

//
// Form creation, initialisation of some variables
//
procedure TForm1.FormCreate(Sender: TObject);
var
  Sem: THandle;
  hwndOwner: HWnd;
begin
// register LCD font
AddFontResource(PChar(ExtractFilePath(ParamStr(0)) + 'LinuxConsole6x10.fon'));



activedisplay := -1;
loadeddlls := tstringlist.create;
debug1('[FORM CREATE] Debugger startet');
debug1('[FORM CREATE] Starting Version: ' + VERSION );
Application.OnException := MyExceptionHandler;
// This is to prevent the program to run more the once
 debug1('[FORM CREATE] Checking for running instances');
 Sem := CreateSemaphore(nil, 0, 1, 'UPG - DOD:S Statsplugin');
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

// ############################################################################

//
// form show, get some stuff from registry
//
procedure TForm1.FormShow(Sender: TObject);
var Buff : Pchar;
    rname,rsteam : TRegistry;
begin


 debug1('[PARSER] Setting default Values for KILL, DEATH, KD, MAP, CLASS, PUREMODE');
   KILLS := 0;
   DEATH := 0;
   CAPTURE := 0;
   MYCLASS := 'None Selected';
   MAP := 'Unknown';
   PUREMODE := 'Unknown';
   CHECK := FALSE;
   changes := true;
   g15lcd := nil;
   MyImage := TBitmap.Create;
   MyImage.Height := 43;
   MyImage.Width := 160;

   

 // Get steampath
   rname := tregistry.create;
   rname.rootkey := HKEY_CURRENT_USER;
   rname.OpenKey('\Software\Valve\Steam',false);
    
  loadplugins ;
   steampath := stringreplace(rname.ReadString('SteamPath'),'/','\',[rfReplaceAll]);
   debug1('[ACC DETECT] Got: ' + steampath);

   ini := tinifile.Create(extractfilepath(application.exename) + 'settings.ini');
   debug1('[StartUp] Getting Offset from INI '+(extractfilepath(application.exename) + 'settings.ini') + ')');
   if ini.ValueExists('Settings','offset') then  begin
      Offset := ini.ReadInteger('settings','offset',0);
      debug1('[StartUp] INI offset found: ' + inttostr(offset));
   end
   else
        OFFSET := 0;
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



 InitDisplayPositions;
// we need a fix to check if lcdmon.exe and lgdcore.exe is running before we
// try to setup our program
debug1('[StartUp] Running lcdmon/lgdcore checker');

// now we need to check if condebug is set, if it isnt, we set it


debug1('[DOD PARAM] Trying to get DOD:S Parameter');
rsteam := tregistry.create;
rsteam.RootKey := HKEY_CURRENT_USER;
rsteam.OpenKey('\Software\Valve\Steam\Apps\300',false) ;
Buff := PChar(rsteam.ReadString('LaunchOptions'));
if SearchBuf(Buff,length(buff),0,0,'-condebug') <> nil then begin
   debug1('[DOD PARAM] -condebug already set');
end
else begin
        debug1('[DOD PARAM] No -condebug set, setting it');
        rsteam.WriteString('LaunchOptions',rsteam.ReadString('LaunchOptions') + ' -condebug');
        rsteam.Free;
end;



end;

// #############################################################################

//
// form destroy, end of program, so free some variables
//

procedure TForm1.FormDestroy(Sender: TObject);
begin
if (G15lcd <> nil) then
 G15Lcd.Destroy;

RemoveFontResource(PChar(ExtractFilePath(ParamStr(0)) + 'LinuxConsole6x10.fon'));
debug1('[DESTROY] Resetting display. Removing Font. Exiting');
end;



end.
