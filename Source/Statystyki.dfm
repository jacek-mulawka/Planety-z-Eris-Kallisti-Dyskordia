object Statystyki_Form: TStatystyki_Form
  Left = 0
  Top = 0
  Caption = 'Statystyki'
  ClientHeight = 337
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Zwycięstwo_Label: TLabel
    Left = 0
    Top = 0
    Width = 635
    Height = 19
    Align = alTop
    Alignment = taCenter
    Caption = 'Zwyci'#281'stwo Przegrana'
    Color = clBtnFace
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
    ExplicitWidth = 184
  end
  object Statystyki_Image: TImage
    Left = 0
    Top = 19
    Width = 635
    Height = 275
    Align = alClient
    PopupMenu = Statystyki_PopupMenu
    ExplicitLeft = 185
    ExplicitTop = 125
    ExplicitWidth = 105
    ExplicitHeight = 105
  end
  object Poziomy_Splitter: TSplitter
    Left = 0
    Top = 294
    Width = 635
    Height = 8
    Cursor = crVSplit
    Align = alBottom
    OnMoved = FormResize
    ExplicitTop = 296
  end
  object Przyciski_Panel: TPanel
    Left = 0
    Top = 302
    Width = 635
    Height = 35
    Align = alBottom
    TabOrder = 0
    object Następna_Misja_Button: TButton
      Left = 10
      Top = 5
      Width = 75
      Height = 25
      Hint = 'Nast'#281'pna misja.'#13#10#13#10'<N'#228'chste Mission.>'#13#10#13#10'<Next mission.>'
      Caption = '>'
      ModalResult = 12
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
    end
    object Pauza_Button: TButton
      Left = 250
      Top = 5
      Width = 75
      Height = 25
      Caption = 'Pauza'
      ModalResult = 8
      ParentShowHint = False
      ShowHint = False
      TabOrder = 2
    end
    object Rozegraj_Misję_Jeszcze_Raz_Button: TButton
      Left = 340
      Top = 5
      Width = 75
      Height = 25
      Hint = 
        'Rozegraj misj'#281' jeszcze raz.'#13#10#13#10'<Spiele die Mission erneut.>'#13#10#13#10'<' +
        'Play the mission again.>'
      Caption = 'Jeszcze raz'
      ModalResult = 4
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
    end
    object Stop_Button: TButton
      Left = 430
      Top = 5
      Width = 75
      Height = 25
      Caption = 'Stop'
      ModalResult = 3
      ParentShowHint = False
      ShowHint = False
      TabOrder = 4
    end
    object Kontynuuj_Button: TButton
      Left = 125
      Top = 5
      Width = 75
      Height = 25
      Hint = 
        'Kontynuuj aktualn'#261' misj'#281'.'#13#10#13#10'<Setzen Sie Ihre aktuelle Mission f' +
        'ort.>'#13#10#13#10'<Continue your current mission.>'
      Caption = 'Kontynuuj'
      ModalResult = 11
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
    end
    object Pomoc_BitBtn: TBitBtn
      Left = 530
      Top = 5
      Width = 50
      Height = 25
      Hint = 'Pomoc.'#13#10#13#10'<Hilfe.>'#13#10#13#10'<Help.>'
      Glyph.Data = {
        DE010000424DDE01000000000000760000002800000024000000120000000100
        0400000000006801000000000000000000001000000000000000000000000000
        80000080000000808000800000008000800080800000C0C0C000808080000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333336633
        3333333333333FF3333333330000333333364463333333333333388F33333333
        00003333333E66433333333333338F38F3333333000033333333E66333333333
        33338FF8F3333333000033333333333333333333333338833333333300003333
        3333446333333333333333FF3333333300003333333666433333333333333888
        F333333300003333333E66433333333333338F38F333333300003333333E6664
        3333333333338F38F3333333000033333333E6664333333333338F338F333333
        0000333333333E6664333333333338F338F3333300003333344333E666433333
        333F338F338F3333000033336664333E664333333388F338F338F33300003333
        E66644466643333338F38FFF8338F333000033333E6666666663333338F33888
        3338F3330000333333EE666666333333338FF33333383333000033333333EEEE
        E333333333388FFFFF8333330000333333333333333333333333388888333333
        0000}
      NumGlyphs = 2
      ParentShowHint = False
      ShowHint = True
      TabOrder = 5
      OnClick = Pomoc_BitBtnClick
    end
  end
  object Odświeżanie_Timer: TTimer
    Enabled = False
    Interval = 500
    OnTimer = Odświeżanie_TimerTimer
    Left = 50
    Top = 35
  end
  object Statystyki_PopupMenu: TPopupMenu
    Left = 55
    Top = 115
    object Wykres_Liniowy_MenuItem: TMenuItem
      AutoCheck = True
      Caption = 'Wykres liniowy'
      Checked = True
      OnClick = FormResize
    end
    object Wykres_Słupkowy_MenuItem: TMenuItem
      AutoCheck = True
      Caption = 'Wykres s'#322'upkowy'
      OnClick = FormResize
    end
  end
end
