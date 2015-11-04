unit LogitechG15;


{


  VERSION:       1.0
  DATE:          26th November 2006		


  This is a VCL component written for the Logitech G15 Keyboard.
  It allows connection to the keyboard, the detection of keys pressed
  and the ability to send bitmap diaplays to the keyboard display.


  It is and extension of "lcdg15.pas", authored by smurfy.de


  Author of VCL Component:

	
  ThunderStruck @ www.g15formums.com


  VISIT: http://www.g15forums.com/forum/member.php?find=lastposter&t=2521


}





interface

uses
  // This component requires the following units...

  lcdg15, // The Logitech G15 keyboard LCD
  strutils, // String Utilities

  SysUtils,
  WinTypes,
  WinProcs,
  Messages,
  Classes,
  Graphics,
  Controls,
  forms,
  Dialogs,
  ExtCtrls,
  ComCtrls;


CONST                                

  // These are the system keycodes for the G15 multimedia keys
  G15_MediaKey_Previous   : Integer = 177;
  G15_MediaKey_Next       : Integer = 176;
  G15_MediaKey_Stop       : Integer = 178;
  G15_MediaKey_PlayPause  : Integer = 179;
  G15_MediaKey_VolumeUp   : Integer = 175;
  G15_MediaKey_VolumeDown : Integer = 174;
  G15_MediaKey_MuteToggle : Integer = 173;


  // These are the Key IDs of the G15 applet buttons
  G15_AppletKey_A : Integer = 1;
  G15_AppletKey_B : Integer = 2;
  G15_AppletKey_C : Integer = 4;
  G15_AppletKey_D : Integer = 8;


type


  TOnAppletKey = procedure(Sender : TObject; KeyCode : Integer ) of Object;

  TOnAppletKey_A = procedure(Sender : TObject ) of Object;
  TOnAppletKey_B = procedure(Sender : TObject ) of Object;
  TOnAppletKey_C = procedure(Sender : TObject ) of Object;
  TOnAppletKey_D = procedure(Sender : TObject ) of Object;

  TOnMediaNext = procedure(Sender : TObject ) of Object;
  TOnMediaPrevious = procedure(Sender : TObject ) of Object;
  TOnMediaPlayPause = procedure(Sender : TObject ) of Object;
  TOnMediaStop = procedure(Sender : TObject ) of Object;

  TOnVolumeWheelUp = procedure(Sender : TObject ) of Object;
  TOnVolumeWheelDown = procedure(Sender : TObject ) of Object;

  TOnConfigure = procedure(Sender : TObject ) of Object;

  // Define the Component
  TG15 = class(TComponent)
  private

    XWndHandle:HWnd;


    FConnected : Boolean;

    Fcaption : String;
    Fconfigurable : Boolean;

    // The image that is send to the G15
    FScreenCanvas : TImage;

    // Events
    FOnAppletKey : TOnAppletKey;
    FOnAppletKey_A : TOnAppletKey_A;
    FOnAppletKey_B : TOnAppletKey_B;
    FOnAppletKey_C : TOnAppletKey_C;
    FOnAppletKey_D : TOnAppletKey_D;

    FOnMediaNext : TOnMediaNext;
    FOnMediaPrevious : TOnMediaPrevious;
    FOnMediaPlayPause : TOnMediaPlayPause;
    FOnMediaStop : TOnMediaStop;

    FOnVolumeWheelUp : TOnVolumeWheelUp;
    FOnVolumeWheelDown : TOnVolumeWheelDown;

    FOnConfigure : TOnConfigure;

    ButtonEvent : Integer;

    LcdG15 : TLcdG15;
    tmrAppletButtons: TTimer;
    tmrMediaKeys : TTimer;

    procedure myCallbackSoftButtons(dwButtons:integer);
    procedure myCallbackConfigure();

    procedure tmrAppletButtonsTimer(Sender: TObject);
    procedure AppletButtonEvent( keyEvent : Integer );

    procedure tmrMediaKeysTimer(Sender: TObject);

  protected

    procedure G15Callback (var Msg : TMessage );

  public


    // Starts the G15, connects to the LCD
    function Start(): Boolean;
    // Sends the current image in ScreenCanvas to the LCD
    procedure SendToDisplay();overload;
    procedure SendToDisplay(priority:integer);overload;
    // Clears the LCD screen
    procedure ClearScreen();
    // Sets Application as foreground application on the LCD
    function SetAsLCDForegroundApp(foregroundYesNoFlag: integer):integer;
    // Enables/Disables hook of the volume wheel
    procedure CaptureVolumeWheel(enabled:boolean);

    // Writes menu text in the location above the 4 applet buttons
    procedure Menu_A( caption : String );
    procedure Menu_B( caption : String );
    procedure Menu_C( caption : String );
    procedure Menu_D( caption : String );

    procedure AppMessage(var Msg: TMsg; var Handled: Boolean);

  published


    // PROPERTIES ++++++++++++

    // The caption is the title that will identify the applet, when
    // toggling through the applets on the LCD
    property caption : String read Fcaption write Fcaption;

    property configurable : Boolean read Fconfigurable write Fconfigurable;
    
    property ScreenCanvas : TImage read FScreenCanvas write FScreenCanvas;

    // Constructor and Destroyer ++++++++++++++
    constructor Create (AOwner:TComponent); override;
    destructor Destroy; override;

    // EVENTS +++++++++++++++++

    // is raised when the state of any key changes
    property OnAppletKey :      TOnAppletKey      read FOnAppletKey       write FOnAppletKey;

    // These are raised when the applet keys are pressed
    property OnAppletKey_A :    TOnAppletKey_A    read FOnAppletKey_A     write FOnAppletKey_A;
    property OnAppletKey_B :    TOnAppletKey_B    read FOnAppletKey_B     write FOnAppletKey_B;
    property OnAppletKey_C :    TOnAppletKey_C    read FOnAppletKey_C     write FOnAppletKey_C;
    property OnAppletKey_D :    TOnAppletKey_D    read FOnAppletKey_D     write FOnAppletKey_D;

    // these are raised when any of the media keys on the G15 are pressed
    property OnMediaNext :      TOnMediaNext      read FOnMediaNext       write FOnMediaNext;
    property OnMediaPrevious :  TOnMediaPrevious  read FOnMediaPrevious   write FOnMediaPrevious;
    property OnMediaPlayPause : TOnMediaPlayPause read FOnMediaPlayPause  write FOnMediaPlayPause;
    property OnMediaStop :      TOnMediaStop      read FOnMediaStop       write FOnMediaStop;

    property OnVolumeWheelUp:   TOnVolumeWheelUp   read FOnVolumeWheelUp   write FOnVolumeWheelUp;
    property OnVolumeWheelDown: TOnVolumeWheelDown read FOnVolumeWheelDown write FOnVolumeWheelDown;

    // This event is raised when the user click "configure" for this applet
    // while in the G15 LCD control panel
    property OnConfigure :      TOnConfigure      read FOnConfigure       write FOnConfigure;

  end;

  
procedure Register;


implementation


{===============================================================================

      IMPLEMENTATION

===============================================================================}


// registers the G15 component
procedure Register;
begin
  RegisterComponents( 'Logitech G15', [ TG15 ] );
end;

procedure TG15.Menu_A( caption : String );
begin
  caption := leftstr( caption,4 );
  FScreenCanvas.Canvas.TextOut(0,36,caption);
end;

procedure TG15.Menu_B( caption : String );
begin
  caption := leftstr( caption,4);
  FScreenCanvas.Canvas.TextOut(35,36,caption);
end;

procedure TG15.Menu_C( caption : String );
begin
  caption := leftstr( caption,4);
  FScreenCanvas.Canvas.TextOut(95,36,caption);
end;

procedure TG15.Menu_D( caption : String );
begin
  caption := leftstr( caption,4);
  FScreenCanvas.Canvas.TextOut(130,36,caption);
end;

procedure TG15.SendToDisplay();
begin
  SendToDisplay(128);
end;

procedure TG15.SendToDisplay(priority:integer);
begin
  if FConnected then
    LcdG15.SendToDisplay(priority);
end;

procedure TG15.ClearScreen();
begin
  with FScreenCanvas, canvas do
  begin
    brush.color:=clwhite;
    canvas.Rectangle( -1, -1, 164, 44 );
  end;
end;

function TG15.SetAsLCDForegroundApp(foregroundYesNoFlag: integer):integer;
begin
  result := 0;
  if FConnected then
    result := LcdG15.SetAsLCDForegroundApp(foregroundYesNoFlag);
end;

procedure TG15.CaptureVolumeWheel(enabled: Boolean);
begin
  HOOK_VOLWHEEL( enabled );
end;

procedure TG15.myCallbackSoftButtons(dwButtons:integer);
begin
  ButtonEvent := dwButtons;
  tmrAppletButtons.Enabled := false;
  tmrAppletButtons.Enabled := true;
end;

procedure TG15.tmrAppletButtonsTimer(Sender: TObject);
begin
  tmrAppletButtons.Enabled := false;
  AppletButtonEvent( ButtonEvent );
end;

procedure TG15.tmrMediaKeysTimer(Sender: TObject);
begin
  if Odd(GetAsyncKeyState( G15_MediaKey_Previous )) then
    if assigned( OnMediaPrevious ) then
      FOnMediaPrevious( Self );

  if Odd(GetAsyncKeyState( G15_MediaKey_Next )) then
    if assigned( OnMediaNext ) then
      FOnMediaNext( Self );

  if Odd(GetAsyncKeyState( G15_MediaKey_PlayPause )) then
    if assigned( OnMediaPlayPause ) then
      FOnMediaPlayPause( Self );

  if Odd(GetAsyncKeyState( G15_MediaKey_Stop )) then
    if assigned( OnMediaStop ) then
      FOnMediaStop( Self );
end;

procedure TG15.AppletButtonEvent( keyEvent : Integer );
begin

  if Assigned( OnAppletKey ) then
    FOnAppletKey( Self, keyEvent );

   //buttonCurrent := keyEvent;

   case keyevent of


    0:  begin
          // All keys up
        end;
    1:  begin
          // Key A down
          if Assigned( OnAppletKey_A ) then
            FOnAppletKey_A( Self );
        end;
    2:  begin
          // Key B down
          if assigned( OnAppletKey_B ) then
            FOnAppletKey_B( Self );
        end;
    4:  begin
          // Key C down
          if assigned( OnAppletKey_C ) then
            FOnAppletKey_C( Self );
        end;
    8:  begin
          // Key D Down
          if assigned( OnAppletKey_D ) then
            FOnAppletKey_D( Self );
        end;


    3:  begin
          //Key A & B down...';
        end;
    5:  begin
          //Key A & C down...';
        end;
    9:  begin
          //Key A & D down...';
        end;


    6:  begin
          //'Key B & C down...';
        end;
    10: begin
          //'Key B & D down...';
        end;
    12:  begin
          //'Key C & D down...';
        end;

   end;


end;

procedure TG15.myCallbackConfigure();
begin
  if assigned( OnConfigure ) then
    FOnConfigure( Self );
end;

function TG15.Start(): Boolean;
begin

  result := false;

    if Assigned( FScreenCanvas ) then
    begin

    try
      LcdG15 := nil;
      lcdG15 := TLCDG15.Create( Fcaption, false, false, configurable );
      LCDG15.OnSoftButtons := myCallbackSoftButtons;
      LCDG15.OnConfigure := myCallbackConfigure; // only works if you set on the createmethod as last param true!
      LcdG15.ClearDisplay;
      LcdG15.LcdCanvas := FScreenCanvas.Canvas;
      LcdG15.SendToDisplay(128);
      //result := true;

      tmrAppletButtons := TTimer.Create( Self );
      result := true;
      tmrAppletButtons.OnTimer := tmrAppletButtonsTimer;
      tmrAppletButtons.Enabled := false;
      tmrAppletButtons.Interval := 10;

      tmrMediaKeys := TTimer.Create( Self );
      tmrMediaKeys.OnTimer := tmrMediaKeysTimer;
      tmrMediaKeys.Enabled := true;
      tmrMediaKeys.Interval := 10;

//      FScreenCanvas.Canvas.Brush.Color := clwhite;
//      FScreenCanvas.Canvas.Font.Color := clblack;
//      FScreenCanvas.Canvas.Font.Name := 'terminal';
//      FScreenCanvas.Canvas.Font.Size := 8;

      FConnected := true;

      // NEW !!!!!!!!!!!!!!!!!!!!!!
      Application.OnMessage := AppMessage;

    except
      result := false;
    end;


  end else
    Showmessage( 'You must first assign a TImage to the G15''s ScreenCanvas property.' );

end;

constructor TG15.Create (AOwner:TComponent);
begin
  inherited Create (AOwner);
    XWndHandle := AllocateHWnd ( G15Callback );
  Fcaption := '(Logitech G15 Applet)';
  FConnected := false;
end;

destructor TG15.Destroy;
begin
  if XWndHandle <> 0 then
    DeAllocateHwnd (XWndHandle);
  inherited;
end;

procedure TG15.G15Callback(var Msg:TMessage);
begin

end;

procedure TG15.AppMessage(var Msg: TMsg; var Handled: Boolean);
begin
  with Msg do if (message=(WM_APP+666)) and ( wParam=13 ) then
  begin
      // Vol Wheel
      case Msg.lParam of
        174 : OnVolumeWheelDown(Application);
        175 : OnVolumeWheelUp(Application);
      end;
    Handled:=True;
  end;
end;

end.
