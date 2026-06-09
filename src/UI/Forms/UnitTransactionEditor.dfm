object TransactionEditForm: TTransactionEditForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1047#1072#1087#1080#1089#1100
  ClientHeight = 280
  ClientWidth = 400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object lblDate: TLabel
    Left = 16
    Top = 72
    Width = 25
    Height = 15
    Caption = #1044#1072#1090#1072
  end
  object lblSum: TLabel
    Left = 200
    Top = 72
    Width = 38
    Height = 15
    Caption = #1057#1091#1084#1084#1072
  end
  object lblCategory: TLabel
    Left = 16
    Top = 120
    Width = 56
    Height = 15
    Caption = #1050#1072#1090#1077#1075#1086#1088#1080#1103
  end
  object lblDescription: TLabel
    Left = 16
    Top = 168
    Width = 55
    Height = 15
    Caption = #1054#1087#1080#1089#1072#1085#1080#1077
  end
  object grpType: TGroupBox
    Left = 16
    Top = 16
    Width = 368
    Height = 57
    Caption = #1058#1080#1087
    TabOrder = 0
    object rbIncome: TRadioButton
      Left = 16
      Top = 20
      Width = 120
      Height = 17
      Caption = #1044#1086#1093#1086#1076
      Checked = True
      TabOrder = 0
      TabStop = True
      OnClick = TypeRadioClick
    end
    object rbExpense: TRadioButton
      Left = 200
      Top = 20
      Width = 120
      Height = 17
      Caption = #1056#1072#1089#1093#1086#1076
      TabOrder = 1
      OnClick = TypeRadioClick
    end
  end
  object dtpDate: TDateTimePicker
    Left = 16
    Top = 88
    Width = 120
    Height = 23
    Date = 45292.000000000000000000
    Time = 0.500000000000000000
    TabOrder = 1
  end
  object cmbCategory: TComboBox
    Left = 16
    Top = 136
    Width = 368
    Height = 23
    TabOrder = 2
  end
  object edtDescription: TEdit
    Left = 16
    Top = 184
    Width = 368
    Height = 23
    TabOrder = 3
  end
  object edtAmount: TEdit
    Left = 200
    Top = 88
    Width = 184
    Height = 23
    TabOrder = 4
  end
  object btnOK: TButton
    Left = 128
    Top = 232
    Width = 120
    Height = 30
    Caption = 'OK'
    Default = True
    TabOrder = 5
    OnClick = btnOKClick
  end
  object btnCancel: TButton
    Left = 264
    Top = 232
    Width = 120
    Height = 30
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    ModalResult = 2
    TabOrder = 6
  end
end
