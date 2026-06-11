unit UnitTransactionEditor;

interface

uses
  System.Classes,
  Winapi.Windows,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  Finance.Types,
  Finance.Strings;

type
  TTransactionEditForm = class(TForm)
    grpType: TGroupBox;
    rbIncome: TRadioButton;
    rbExpense: TRadioButton;
    dtpDate: TDateTimePicker;
    lblDate: TLabel;
    lblCategory: TLabel;
    cmbCategory: TComboBox;
    lblDescription: TLabel;
    edtDescription: TEdit;
    lblSum: TLabel;
    edtAmount: TEdit;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure TypeRadioClick(Sender: TObject);
  private
    FResult: TTransactionRec;
    function GetCategoryValue: string;
    procedure RefillCategories(const SelectName: string);
    procedure LoadFromRec(const ARec: TTransactionRec);
    procedure SaveToRec(var ARec: TTransactionRec);
  public
    function Execute(var ARec: TTransactionRec; AEdit: Boolean): Boolean;
  end;

var
  TransactionEditForm: TTransactionEditForm;

implementation

uses
  System.SysUtils,
  System.UITypes,
  Vcl.Dialogs,
  Finance.DateUtils,
  Finance.Categories;

{$R *.dfm}

function TTransactionEditForm.GetCategoryValue: string;
begin
  if (cmbCategory.ItemIndex >= 0) and
    (cmbCategory.ItemIndex < cmbCategory.Items.Count) then
    Result := Trim(cmbCategory.Items[cmbCategory.ItemIndex])
  else
  begin
    Result := Trim(cmbCategory.Text);
    if Result = '' then
      raise Exception.Create(TX_ERR_CATEGORY_REQUIRED);
  end;
end;

procedure TTransactionEditForm.RefillCategories(const SelectName: string);
var
  S: string;
  I, J: Integer;
begin
  cmbCategory.Items.Clear;
  if rbIncome.Checked then
    FillIncomeCategories(cmbCategory.Items)
  else
    FillExpenseCategories(cmbCategory.Items);
  if cmbCategory.Items.Count = 0 then
    Exit;
  S := Trim(SelectName);
  J := -1;
  if S <> '' then
    for I := 0 to cmbCategory.Items.Count - 1 do
      if SameText(Trim(cmbCategory.Items[I]), S) then
      begin
        J := I;
        Break;
      end;
  if J >= 0 then
  begin
    cmbCategory.Style := csDropDownList;
    cmbCategory.ItemIndex := J;
  end
  else if S <> '' then
  begin
    cmbCategory.Style := csDropDown;
    cmbCategory.ItemIndex := -1;
    cmbCategory.Text := S;
  end
  else
  begin
    cmbCategory.Style := csDropDownList;
    cmbCategory.ItemIndex := 0;
  end;
end;

procedure TTransactionEditForm.FormCreate(Sender: TObject);
begin
{$IF Declared(stNever)}
  ShowInTaskbar := stNever;
{$IFEND}
  Caption := TX_FORM_CAPTION;
  grpType.Caption := TX_GROUP_TYPE;
  rbIncome.Caption := TX_TYPE_INCOME;
  rbExpense.Caption := TX_TYPE_EXPENSE;
  lblDate.Caption := TX_LABEL_DATE;
  lblSum.Caption := TX_LABEL_SUM;
  lblCategory.Caption := TX_LABEL_CATEGORY;
  lblDescription.Caption := TX_LABEL_DESCRIPTION;
  btnCancel.Caption := TX_BTN_CANCEL;
  CategoriesLoad;
  cmbCategory.Style := csDropDownList;
  dtpDate.Date := Date;
  rbIncome.Checked := True;
  rbExpense.Checked := False;
  RefillCategories('');
end;

procedure TTransactionEditForm.TypeRadioClick(Sender: TObject);
begin
  RefillCategories('');
end;

procedure TTransactionEditForm.LoadFromRec(const ARec: TTransactionRec);
var
  S: string;
  Dt: TDateTime;
begin
  S := Trim(ARec.DateStr);
  if (S <> '') and TryParseRuDate(S, Dt) then
    dtpDate.Date := Dt
  else
    dtpDate.Date := Date;

  if ARec.IsIncome then
  begin
    rbIncome.Checked := True;
    rbExpense.Checked := False;
  end
  else
  begin
    rbExpense.Checked := True;
    rbIncome.Checked := False;
  end;

  RefillCategories(ARec.Category);

  edtDescription.Text := ARec.Description;
  edtAmount.Text := FormatFloat(AMOUNT_FORMAT, ARec.Amount);
end;

procedure TTransactionEditForm.SaveToRec(var ARec: TTransactionRec);
var
  FS: TFormatSettings;
  Amt: Double;
  S: string;
  KeepId, KeepAccountId: Int64;
begin
  KeepId := ARec.Id;
  KeepAccountId := ARec.AccountId;
  ARec := Default(TTransactionRec);
  ARec.Id := KeepId;
  ARec.AccountId := KeepAccountId;
  S := FormatDateTime('dd.mm.yyyy', dtpDate.Date);
  ARec.DateStr := S;

  ARec.IsIncome := rbIncome.Checked;

  ARec.Category := GetCategoryValue;

  ARec.Description := Trim(edtDescription.Text);

  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';
  S := StringReplace(Trim(edtAmount.Text), ',', '.', [rfReplaceAll]);
  if not TryStrToFloat(S, Amt, FS) then
    raise Exception.Create(TX_ERR_AMOUNT_INVALID);
  if Amt <= 0 then
    raise Exception.Create(TX_ERR_AMOUNT_POSITIVE);
  ARec.Amount := Amt;
end;

function TTransactionEditForm.Execute(var ARec: TTransactionRec;
  AEdit: Boolean): Boolean;
begin
  if AEdit then
  begin
    FResult := ARec;
    LoadFromRec(ARec);
  end
  else
  begin
    FResult := Default(TTransactionRec);
    dtpDate.Date := Date;
    rbIncome.Checked := True;
    rbExpense.Checked := False;
    RefillCategories('');
    edtDescription.Text := '';
    edtAmount.Text := '';
  end;
  Result := ShowModal = mrOK;
  if Result then
    ARec := FResult;
end;

procedure TTransactionEditForm.btnOKClick(Sender: TObject);
begin
  try
    SaveToRec(FResult);
    EnsureUserCategory(FResult.IsIncome, FResult.Category);
  except
    on E: Exception do
    begin
      MessageDlg(E.Message, mtWarning, [mbOK], 0);
      Exit;
    end;
  end;
  ModalResult := mrOK;
end;

end.
