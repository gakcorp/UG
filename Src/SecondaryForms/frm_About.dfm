object frmAbout: TfrmAbout
  Left = 268
  Top = 257
  BorderStyle = bsDialog
  Caption = 'About'
  ClientHeight = 266
  ClientWidth = 336
  Color = clWhite
  ParentFont = True
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 0
    Top = 232
    Width = 336
    Height = 3
    Align = alBottom
    Shape = bsTopLine
  end
  object lblVersionCatpion: TLabel
    Left = 16
    Top = 128
    Width = 39
    Height = 13
    Alignment = taRightJustify
    Caption = 'Version:'
  end
  object lblProgramName: TLabel
    Left = 0
    Top = 0
    Width = 336
    Height = 33
    Align = alCustom
    Alignment = taCenter
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'UIS.GIS'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    Layout = tlCenter
  end
  object lblVersion: TLabel
    Left = 130
    Top = 128
    Width = 198
    Height = 13
    AutoSize = False
  end
  object lblWebSite: TLabel
    Left = 99
    Top = 70
    Width = 229
    Height = 13
    Cursor = crHandPoint
    Align = alCustom
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsUnderline]
    ParentFont = False
    OnClick = lblWebSiteClick
  end
  object lblCopyright: TLabel
    Left = 99
    Top = 39
    Width = 229
    Height = 33
    Align = alCustom
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    WordWrap = True
  end
  object lblLicense: TLabel
    Left = 8
    Top = 89
    Width = 320
    Height = 39
    Align = alCustom
    Anchors = [akLeft, akTop, akRight]
    Caption = 
      'All rights to the software owned by UIS LTD. Using functional by' +
      ' subscription.'
    WordWrap = True
  end
  object lblCompiler: TLabel
    Left = 16
    Top = 176
    Width = 45
    Height = 13
    Caption = 'Compiler:'
    Enabled = False
    Visible = False
  end
  object lblTimeStamp: TLabel
    Left = 16
    Top = 144
    Width = 51
    Height = 13
    Caption = 'Build date:'
  end
  object lblBuildInfo: TLabel
    Left = 8
    Top = 157
    Width = 47
    Height = 13
    Caption = 'Build info:'
    Enabled = False
    Visible = False
  end
  object lblBuildTimeValue: TLabel
    Left = 130
    Top = 144
    Width = 198
    Height = 13
    AutoSize = False
  end
  object lblBuildInfoValue: TLabel
    Left = 130
    Top = 160
    Width = 198
    Height = 13
    AutoSize = False
  end
  object lblCompilerValue: TLabel
    Left = 130
    Top = 176
    Width = 198
    Height = 13
    AutoSize = False
  end
  object lblSources: TLabel
    Left = 16
    Top = 192
    Width = 42
    Height = 13
    Caption = 'Sources:'
    Enabled = False
    Visible = False
  end
  object lblRequires: TLabel
    Left = 16
    Top = 208
    Width = 46
    Height = 13
    Caption = 'Requires:'
    Enabled = False
    Visible = False
  end
  object lblSourcesValue: TLabel
    Left = 130
    Top = 192
    Width = 198
    Height = 13
    Cursor = crHandPoint
    AutoSize = False
    Color = clWindow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsUnderline]
    ParentColor = False
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    OnClick = lblSourcesValueClick
  end
  object lblRequiresValue: TLabel
    Left = 130
    Top = 208
    Width = 198
    Height = 13
    Cursor = crHandPoint
    AutoSize = False
    Color = clWindow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsUnderline]
    ParentColor = False
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    OnClick = lblRequiresValueClick
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 235
    Width = 336
    Height = 31
    Align = alBottom
    BevelOuter = bvNone
    Padding.Bottom = 2
    ParentColor = True
    TabOrder = 0
    object btnClose: TButton
      Left = 86
      Top = 3
      Width = 130
      Height = 25
      Align = alCustom
      Anchors = [akRight, akBottom]
      Cancel = True
      Caption = 'Close'
      TabOrder = 0
      OnClick = btnCloseClick
    end
    object btnLicense: TButton
      Left = 8
      Top = 2
      Width = 130
      Height = 25
      Align = alCustom
      Anchors = [akLeft, akBottom]
      Caption = 'License'
      Enabled = False
      TabOrder = 1
      Visible = False
      OnClick = btnLicenseClick
    end
  end
  object imgLogo: TImage32
    Left = 16
    Top = 8
    Width = 64
    Height = 64
    Margins.Bottom = 5
    Align = alCustom
    Bitmap.DrawMode = dmBlend
    Bitmap.ResamplerClassName = 'TNearestResampler'
    BitmapAlign = baTopLeft
    Scale = 1.000000000000000000
    ScaleMode = smResize
    TabOrder = 1
  end
end
