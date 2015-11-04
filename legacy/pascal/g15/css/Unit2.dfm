object Form2: TForm2
  Left = 713
  Top = 122
  BorderStyle = bsDialog
  Caption = 'Configure Plugins'
  ClientHeight = 370
  ClientWidth = 203
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 97
    Height = 13
    Caption = 'Plugins to Configure:'
  end
  object Label2: TLabel
    Left = 8
    Top = 272
    Width = 187
    Height = 13
    Caption = 'Time to show extre messages (in msec):'
  end
  object ListBox1: TListBox
    Left = 8
    Top = 24
    Width = 185
    Height = 169
    ItemHeight = 13
    TabOrder = 0
    OnDblClick = ListBox1DblClick
  end
  object Button1: TButton
    Left = 120
    Top = 200
    Width = 75
    Height = 25
    Caption = 'Close'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 8
    Top = 200
    Width = 97
    Height = 25
    Caption = 'Configure Plugin'
    Enabled = False
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 24
    Top = 336
    Width = 153
    Height = 25
    Caption = 'About DOD:S Statsplugin'
    TabOrder = 3
    OnClick = Button3Click
  end
  object extram: TCheckBox
    Left = 16
    Top = 240
    Width = 177
    Height = 17
    Caption = 'Show extra death/kill messages'
    TabOrder = 4
    OnClick = extramClick
  end
  object mytime: TSpinEdit
    Left = 64
    Top = 296
    Width = 73
    Height = 22
    Enabled = False
    MaxValue = 15000
    MinValue = 1
    TabOrder = 5
    Value = 1500
    OnChange = mytimeChange
  end
end
