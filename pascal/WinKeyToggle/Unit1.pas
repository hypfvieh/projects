(****************************************************************************
 *                              WinKeyToggle                                *
 *                    (c) copyright 2011 by Maniac                          *
 *                        http://www.case-of.org                            *
 *                                                                          *
 *  This software is provided as it is, no warrenty!!                       *
 *  This code is licenced under WTFPL. You find the exact terms below.      *
 *                                                                          *
 *  hooks.pas (c) copyright by Jens Borrisholt                              *
 *  hooks.pas is licensed under GPLv2, please the the unit-header           *
 *            for more information!                                         *
 *                                                                          *
 *  Windows, the Windows Logo are (c) copyright by Microsoft                *
 *                                                                          *
 * ======================================================================== *
 *            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE                   *
 *                   Version 2, December 2004                               *
 *                                                                          *
 *    Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>                      *
 *                                                                          *
 *  Everyone is permitted to copy and distribute verbatim or modified       *
 *  copies of this license document, and changing it is allowed as long     *
 *  as the name is changed.                                                 *
 *                                                                          *
 *           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE                    *
 *  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION         *
 *                                                                          *
 *    0. You just DO WHAT THE FUCK YOU WANT TO.                             *
 *                                                                          *
 *                                                                          *
 ****************************************************************************)
unit Unit1;

interface

uses
 Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, hooks, StdCtrls, ImgList, ExtCtrls, Menus;

type
  Tfrm_main = class(TForm)
    btn_on: TButton;
    btn_off: TButton;
    tray: TTrayIcon;
    imglst: TImageList;
    btn_about: TButton;
    pm_main: TPopupMenu;
    pmi_on: TMenuItem;
    pmi_off: TMenuItem;
    N1: TMenuItem;
    pmi_exit: TMenuItem;
    N2: TMenuItem;
    pmi_about: TMenuItem;
    ballon_hint: TBalloonHint;
    procedure btn_onClick(Sender: TObject);
    procedure btn_offClick(Sender: TObject);
    procedure btn_aboutClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure pmi_aboutClick(Sender: TObject);
    procedure pmi_onClick(Sender: TObject);
    procedure pmi_offClick(Sender: TObject);
    procedure pmi_exitClick(Sender: TObject);
  private
    { Private-Deklarationen }
     KeyboardHook: TLowLevelKeyboardHook;
     procedure KeyboardHookPREExecute(Hook: THook; var Hookmsg: THookMsg);
     procedure WmHotkey(var Msg: TMessage); message WM_HOTKEY;
     procedure ToggleOnOff;
  public
    { Public-Deklarationen }
  end;

CONST
 MYVERSION = '1.0';

var
  frm_main: Tfrm_main;
  KeysOn : boolean = true;

implementation
  uses Math;
{$R *.dfm}

procedure Tfrm_main.ToggleOnOff;
begin
  if pmi_off.Enabled then
    pmi_off.Click
  else
    pmi_on.Click;
end;

procedure Tfrm_main.WmHotkey(var Msg: TMessage);
begin
  if (Msg.WParam = 1) then
  begin
    ToggleOnOff;
  end;
end;

procedure Tfrm_main.FormCreate(Sender: TObject);
begin
  RegisterHotKey(Handle,1,MOD_CONTROL or MOD_ALT,VK_END);

  KeyboardHook := TLowLevelKeyboardHook.Create;
  KeyboardHook.OnPreExecute := KeyboardHookPREExecute;
  KeyboardHook.Active := True;

  tray.IconIndex := 1;
  tray.hint := 'WinKeyToogle'+#13#10'Windows Keys Enabled';
end;

procedure Tfrm_main.KeyboardHookPREExecute(Hook: THook; var Hookmsg: THookMsg);
var
  P : pKBDLLHOOKSTRUCT;
begin
  P := Pointer(Hookmsg.LParam);
  if ((P^.flags = 1) or (P^.flags = 129)) then begin
    if ((P^.vkCode = VK_LWIN) or (P^.vkCode = VK_RWIN) or (P^.vkCode = VK_APPS)) then  begin
        Hookmsg.Result := IfThen(keyson, 1, 0)
    end
    else
      Hookmsg.Result := 0;
  end;
end;

procedure Tfrm_main.btn_onClick(Sender: TObject);
begin
  KeysOn := False;

  tray.IconIndex := 1;
  tray.BalloonHint := 'Windows Keys Enabled';
  tray.Hint := 'WinKeyToogle'+#13#10'Windows Keys Enabled';
  tray.ShowBalloonHint;
end;

procedure Tfrm_main.pmi_offClick(Sender: TObject);
begin
  btn_off.Click;
  pmi_on.Enabled := true;
  pmi_off.Enabled := false;
end;

procedure Tfrm_main.pmi_onClick(Sender: TObject);
begin
  btn_on.Click;
  pmi_on.Enabled := false;
  pmi_off.Enabled := true;
end;

procedure Tfrm_main.pmi_aboutClick(Sender: TObject);
begin
  btn_about.Click;
end;

procedure Tfrm_main.pmi_exitClick(Sender: TObject);
begin
  btn_on.Click;
  close;
end;

procedure Tfrm_main.btn_aboutClick(Sender: TObject);
begin
  Showmessage('WinKeyToggle - Version ' + MYVERSION + #13#10 +
              '(c) copyright by Maniac' + #13#10 +
              'http://www.case-of.org' + #13#10 +
              '' + #13#10+
              'This software is licenced under WTFPL' + #13#10 +
              'Full license available here : http://sam.zoy.org/wtfpl/COPYING');
end;

procedure Tfrm_main.btn_offClick(Sender: TObject);
begin
  Keyson := true;
  tray.IconIndex := 0;
  tray.BalloonHint := 'Windows Keys Disabled';
  tray.Hint := 'WinKeyToogle'+#13#10'Windows Keys Disabled';
  tray.ShowBalloonHint;
end;

end.
