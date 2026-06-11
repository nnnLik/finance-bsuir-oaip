unit UnitSettings;

interface

uses
  System.Classes, System.SysUtils, System.UITypes, Vcl.Forms, Vcl.Controls,
  Vcl.StdCtrls, Finance.Types,
  Vcl.ExtCtrls, Vcl.Graphics;

type
  TSettingsPageForm = class(TForm)
  private
    FOnDataChanged: TNotifyEvent;
    pnlTop: TPanel;
    lblTitle: TLabel;
    btnExportCsv: TButton;
    btnImportCsv: TButton;
    lblAccounts: TLabel;
    cmbAccounts: TComboBox;
    lblNewAccount: TLabel;
    edtNewAccount: TEdit;
    btnAddAccount: TButton;
    btnDeleteAccount: TButton;
    lblIncome: TLabel;
    cmbIncome: TComboBox;
    btnAddIncome: TButton;
    btnDeleteIncome: TButton;
    lblExpense: TLabel;
    cmbExpense: TComboBox;
    btnAddExpense: TButton;
    btnDeleteExpense: TButton;
    FCurrentAccountId: Int64;
    FAccounts: TAccountArray;
    procedure BtnExportCsvClick(Sender: TObject);
    procedure BtnImportCsvClick(Sender: TObject);
    procedure BtnAddAccountClick(Sender: TObject);
    procedure BtnDeleteAccountClick(Sender: TObject);
    procedure BtnAddIncomeClick(Sender: TObject);
    procedure BtnDeleteIncomeClick(Sender: TObject);
    procedure BtnAddExpenseClick(Sender: TObject);
    procedure BtnDeleteExpenseClick(Sender: TObject);
    procedure RefreshDataLists;
    procedure SetCurrentAccountId(const Value: Int64);
    procedure NotifyDataChanged;
  public
    constructor Create(AOwner: TComponent); override;
    property CurrentAccountId: Int64 read FCurrentAccountId
      write SetCurrentAccountId;
    property OnDataChanged: TNotifyEvent read FOnDataChanged
      write FOnDataChanged;
  end;

implementation

uses
  Vcl.Dialogs, Finance.Repository, Finance.Strings;

function ComboBoxValue(const Combo: TComboBox): string;
begin
  if (Combo.ItemIndex >= 0) and (Combo.ItemIndex < Combo.Items.Count) then
    Result := Trim(Combo.Items[Combo.ItemIndex])
  else
    Result := Trim(Combo.Text);
end;

constructor TSettingsPageForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BorderStyle := bsNone;
  Align := alClient;
  Visible := False;

  pnlTop := TPanel.Create(Self);
  pnlTop.Parent := Self;
  pnlTop.Align := alTop;
  pnlTop.Height := 420;
  pnlTop.BevelOuter := bvNone;

  lblTitle := TLabel.Create(Self);
  lblTitle.Parent := pnlTop;
  lblTitle.Left := 20;
  lblTitle.Top := 16;
  lblTitle.Caption := SETTINGS_TITLE;
  lblTitle.Font.Size := 13;
  lblTitle.Font.Style := [fsBold];

  btnExportCsv := TButton.Create(Self);
  btnExportCsv.Parent := pnlTop;
  btnExportCsv.Left := 20;
  btnExportCsv.Top := 56;
  btnExportCsv.Width := 170;
  btnExportCsv.Caption := SETTINGS_BTN_EXPORT;
  btnExportCsv.OnClick := BtnExportCsvClick;

  btnImportCsv := TButton.Create(Self);
  btnImportCsv.Parent := pnlTop;
  btnImportCsv.Left := 210;
  btnImportCsv.Top := 56;
  btnImportCsv.Width := 170;
  btnImportCsv.Caption := SETTINGS_BTN_IMPORT;
  btnImportCsv.OnClick := BtnImportCsvClick;

  lblAccounts := TLabel.Create(Self);
  lblAccounts.Parent := pnlTop;
  lblAccounts.Left := 20;
  lblAccounts.Top := 100;
  lblAccounts.Caption := SETTINGS_ACCOUNTS_TITLE;

  cmbAccounts := TComboBox.Create(Self);
  cmbAccounts.Parent := pnlTop;
  cmbAccounts.Left := 20;
  cmbAccounts.Top := 124;
  cmbAccounts.Width := 260;
  cmbAccounts.Style := csDropDownList;

  lblNewAccount := TLabel.Create(Self);
  lblNewAccount.Parent := pnlTop;
  lblNewAccount.Left := 20;
  lblNewAccount.Top := 156;
  lblNewAccount.Caption := SETTINGS_NEW_ACCOUNT_TITLE;

  edtNewAccount := TEdit.Create(Self);
  edtNewAccount.Parent := pnlTop;
  edtNewAccount.Left := 20;
  edtNewAccount.Top := 180;
  edtNewAccount.Width := 260;

  btnAddAccount := TButton.Create(Self);
  btnAddAccount.Parent := pnlTop;
  btnAddAccount.Left := 290;
  btnAddAccount.Top := 178;
  btnAddAccount.Width := 120;
  btnAddAccount.Caption := SETTINGS_BTN_ADD_ACCOUNT;
  btnAddAccount.OnClick := BtnAddAccountClick;

  btnDeleteAccount := TButton.Create(Self);
  btnDeleteAccount.Parent := pnlTop;
  btnDeleteAccount.Left := 420;
  btnDeleteAccount.Top := 122;
  btnDeleteAccount.Width := 120;
  btnDeleteAccount.Caption := SETTINGS_BTN_DELETE_ACCOUNT;
  btnDeleteAccount.OnClick := BtnDeleteAccountClick;

  lblIncome := TLabel.Create(Self);
  lblIncome.Parent := pnlTop;
  lblIncome.Left := 20;
  lblIncome.Top := 224;
  lblIncome.Caption := SETTINGS_INCOME_CATEGORY;

  cmbIncome := TComboBox.Create(Self);
  cmbIncome.Parent := pnlTop;
  cmbIncome.Left := 20;
  cmbIncome.Top := 248;
  cmbIncome.Width := 260;
  cmbIncome.Style := csDropDown;

  btnAddIncome := TButton.Create(Self);
  btnAddIncome.Parent := pnlTop;
  btnAddIncome.Left := 290;
  btnAddIncome.Top := 246;
  btnAddIncome.Width := 120;
  btnAddIncome.Caption := SETTINGS_BTN_ADD;
  btnAddIncome.OnClick := BtnAddIncomeClick;

  btnDeleteIncome := TButton.Create(Self);
  btnDeleteIncome.Parent := pnlTop;
  btnDeleteIncome.Left := 420;
  btnDeleteIncome.Top := 246;
  btnDeleteIncome.Width := 120;
  btnDeleteIncome.Caption := SETTINGS_BTN_DELETE;
  btnDeleteIncome.OnClick := BtnDeleteIncomeClick;

  lblExpense := TLabel.Create(Self);
  lblExpense.Parent := pnlTop;
  lblExpense.Left := 20;
  lblExpense.Top := 296;
  lblExpense.Caption := SETTINGS_EXPENSE_CATEGORY;

  cmbExpense := TComboBox.Create(Self);
  cmbExpense.Parent := pnlTop;
  cmbExpense.Left := 20;
  cmbExpense.Top := 320;
  cmbExpense.Width := 260;
  cmbExpense.Style := csDropDown;

  btnAddExpense := TButton.Create(Self);
  btnAddExpense.Parent := pnlTop;
  btnAddExpense.Left := 290;
  btnAddExpense.Top := 318;
  btnAddExpense.Width := 120;
  btnAddExpense.Caption := SETTINGS_BTN_ADD;
  btnAddExpense.OnClick := BtnAddExpenseClick;

  btnDeleteExpense := TButton.Create(Self);
  btnDeleteExpense.Parent := pnlTop;
  btnDeleteExpense.Left := 420;
  btnDeleteExpense.Top := 318;
  btnDeleteExpense.Width := 120;
  btnDeleteExpense.Caption := SETTINGS_BTN_DELETE;
  btnDeleteExpense.OnClick := BtnDeleteExpenseClick;

  RefreshDataLists;
end;

procedure TSettingsPageForm.NotifyDataChanged;
begin
  if Assigned(FOnDataChanged) then
    FOnDataChanged(Self);
end;

procedure TSettingsPageForm.SetCurrentAccountId(const Value: Int64);
begin
  FCurrentAccountId := Value;
  RefreshDataLists;
end;

procedure TSettingsPageForm.RefreshDataLists;
var
  I: Integer;
  S: string;
begin
  S := cmbIncome.Text;
  RepoFillCategories(True, cmbIncome.Items);
  if S <> '' then
    cmbIncome.Text := S;

  S := cmbExpense.Text;
  RepoFillCategories(False, cmbExpense.Items);
  if S <> '' then
    cmbExpense.Text := S;

  RepoLoadAccounts(FAccounts);
  cmbAccounts.Items.BeginUpdate;
  try
    cmbAccounts.Items.Clear;
    for I := 0 to High(FAccounts) do
      cmbAccounts.Items.Add(FAccounts[I].Name);
  finally
    cmbAccounts.Items.EndUpdate;
  end;

  cmbAccounts.ItemIndex := -1;
  for I := 0 to High(FAccounts) do
    if FAccounts[I].Id = FCurrentAccountId then
    begin
      cmbAccounts.ItemIndex := I;
      Break;
    end;
  if (cmbAccounts.ItemIndex < 0) and (Length(FAccounts) > 0) then
    cmbAccounts.ItemIndex := 0;
end;

procedure TSettingsPageForm.BtnExportCsvClick(Sender: TObject);
var
  D: TSaveDialog;
  TimeStamp: TTimeStamp;
  ExportPath: string;
begin
  D := TSaveDialog.Create(nil);
  try
    D.DefaultExt := 'csv';
    D.Filter := SETTINGS_EXPORT_FILTER;
    D.Options := D.Options + [ofPathMustExist, ofOverWritePrompt];
    D.InitialDir := GetCurrentDir;
    TimeStamp := DateTimeToTimeStamp(Now);
    D.FileName := SETTINGS_EXPORT_PREFIX + IntToStr(TimeStamp.Time) + '.csv';
    if not D.Execute then
      Exit;
    ExportPath := Trim(D.FileName);
    if ExportPath = '' then
      Exit;
    try
      RepoExportCsv(ExportPath, True, FCurrentAccountId);
      MessageDlg(Format(SETTINGS_EXPORT_DONE_FMT, [ExportPath]), mtInformation,
        [mbOK], 0);
    except
      on E: Exception do
        MessageDlg(Format(SETTINGS_EXPORT_FAILED_FMT, [E.Message]), mtError,
          [mbOK], 0);
    end;
  finally
    D.Free;
  end;
end;

procedure TSettingsPageForm.BtnImportCsvClick(Sender: TObject);
var
  D: TOpenDialog;
  Imported, Skipped: Integer;
begin
  D := TOpenDialog.Create(nil);
  try
    D.Filter := SETTINGS_IMPORT_FILTER;
    if not D.Execute then
      Exit;
    RepoImportCsv(D.FileName, Imported, Skipped);
    MessageDlg(Format(SETTINGS_IMPORT_DONE_FMT, [Imported, Skipped]),
      mtInformation, [mbOK], 0);
    NotifyDataChanged;
  finally
    D.Free;
  end;
end;

procedure TSettingsPageForm.BtnAddAccountClick(Sender: TObject);
var
  NewId: Int64;
  S: string;
begin
  S := Trim(edtNewAccount.Text);
  if S = '' then
    Exit;
  if not RepoAddAccount(S, NewId) then
  begin
    MessageDlg(SETTINGS_ADD_ACCOUNT_FAILED, mtWarning, [mbOK], 0);
    Exit;
  end;
  edtNewAccount.Clear;
  FCurrentAccountId := NewId;
  RefreshDataLists;
  NotifyDataChanged;
end;

procedure TSettingsPageForm.BtnDeleteAccountClick(Sender: TObject);
var
  AId: Int64;
  DeletedTx, I: Integer;
  AName: string;
begin
  if (cmbAccounts.ItemIndex < 0) or (cmbAccounts.ItemIndex > High(FAccounts)) then
    Exit;
  if Length(FAccounts) <= 1 then
  begin
    MessageDlg(SETTINGS_DELETE_ACCOUNT_LAST_FORBIDDEN, mtWarning, [mbOK], 0);
    Exit;
  end;

  I := cmbAccounts.ItemIndex;
  AId := FAccounts[I].Id;
  AName := FAccounts[I].Name;

  DeletedTx := 0;
  if MessageDlg(Format(SETTINGS_DELETE_ACCOUNT_CONFIRM_FMT, [AName]),
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  if not RepoDeleteAccount(AId, DeletedTx) then
  begin
    MessageDlg(SETTINGS_DELETE_ACCOUNT_FAILED, mtWarning, [mbOK], 0);
    Exit;
  end;
  RefreshDataLists;
  NotifyDataChanged;
end;

procedure TSettingsPageForm.BtnAddIncomeClick(Sender: TObject);
var
  S: string;
begin
  S := ComboBoxValue(cmbIncome);
  if S = '' then
    Exit;
  RepoEnsureCategory(True, S);
  cmbIncome.Text := '';
  RefreshDataLists;
  NotifyDataChanged;
end;

procedure TSettingsPageForm.BtnDeleteIncomeClick(Sender: TObject);
var
  S: string;
begin
  S := ComboBoxValue(cmbIncome);
  if S = '' then
    Exit;
  if MessageDlg(Format(SETTINGS_DELETE_CATEGORY_CONFIRM_FMT, [S]), mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then
    Exit;
  RepoDeleteCategory(True, S);
  cmbIncome.Text := '';
  RefreshDataLists;
  NotifyDataChanged;
end;

procedure TSettingsPageForm.BtnAddExpenseClick(Sender: TObject);
var
  S: string;
begin
  S := ComboBoxValue(cmbExpense);
  if S = '' then
    Exit;
  RepoEnsureCategory(False, S);
  cmbExpense.Text := '';
  RefreshDataLists;
  NotifyDataChanged;
end;

procedure TSettingsPageForm.BtnDeleteExpenseClick(Sender: TObject);
var
  S: string;
begin
  S := ComboBoxValue(cmbExpense);
  if S = '' then
    Exit;
  if MessageDlg(Format(SETTINGS_DELETE_CATEGORY_CONFIRM_FMT, [S]), mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then
    Exit;
  RepoDeleteCategory(False, S);
  cmbExpense.Text := '';
  RefreshDataLists;
  NotifyDataChanged;
end;

end.
