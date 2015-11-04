object Form2: TForm2
  Left = 713
  Top = 122
  BorderStyle = bsDialog
  Caption = 'Configure Plugins'
  ClientHeight = 405
  ClientWidth = 298
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
  object Button3: TButton
    Left = 64
    Top = 343
    Width = 153
    Height = 25
    Caption = 'About TF2 Statsplugin'
    TabOrder = 0
    OnClick = Button3Click
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 8
    Width = 289
    Height = 329
    ActivePage = TabSheet1
    TabOrder = 1
    object TabSheet1: TTabSheet
      Caption = 'Configure Plugins'
      object Label1: TLabel
        Left = 8
        Top = 8
        Width = 97
        Height = 13
        Caption = 'Plugins to Configure:'
      end
      object ListBox1: TListBox
        Left = 8
        Top = 27
        Width = 270
        Height = 214
        ItemHeight = 13
        TabOrder = 0
        OnDblClick = ListBox1DblClick
      end
      object Button2: TButton
        Left = 91
        Top = 253
        Width = 97
        Height = 25
        Caption = 'Configure Plugin'
        Enabled = False
        TabOrder = 1
        OnClick = Button2Click
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Output Formatting'
      ImageIndex = 2
      object formatting: TListBox
        Left = 8
        Top = 8
        Width = 265
        Height = 129
        DragMode = dmAutomatic
        ItemHeight = 13
        TabOrder = 0
        OnDragDrop = formattingDragDrop
        OnDragOver = formattingDragOver
      end
      object Button4: TButton
        Left = 97
        Top = 143
        Width = 75
        Height = 25
        Caption = 'Save'
        TabOrder = 1
        OnClick = Button4Click
      end
    end
  end
  object Button1: TButton
    Left = 101
    Top = 374
    Width = 75
    Height = 25
    Caption = 'Close'
    TabOrder = 2
    OnClick = Button1Click
  end
end
