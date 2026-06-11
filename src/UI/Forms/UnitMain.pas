unit UnitMain;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.UITypes, Vcl.Forms,
  Vcl.Controls,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, Vcl.Dialogs, Finance.Types,
  Finance.TransactionList;

type
  TMainPageForm = class(TForm)
  private const
    COL_EDIT = 5;
    COL_DEL = 6;
  private
    FHead: PListNode;
    FCurrentAccountId: Int64;
    FOnDataChanged: TNotifyEvent;
    pnlToolbar: TPanel;
    lblFilter: TLabel;
    cmbCategoryFilter: TComboBox;
    StringGrid1: TStringGrid;
    pnlFooter: TPanel;
    btnAdd: TButton;
    function MatchesFilters(const AData: TTransactionRec): Boolean;
    function GetNodeByDisplayIndex(ADisplayIndex: Integer;
      out ACur, APrev: PListNode): Boolean;
    procedure FillCategoryFilter;
    procedure SyncCategoryFilter;
    procedure CmbCategoryFilterChange(Sender: TObject);
    procedure BtnAddClick(Sender: TObject);
    procedure StringGridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DoEditGridRow(AGridRow: Integer);
    procedure DoDeleteGridRow(AGridRow: Integer);
    procedure SetCurrentAccountId(const Value: Int64);
    procedure NotifyDataChanged;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RefreshData;
    function CurrentBalance: Double;
    property CurrentAccountId: Int64 read FCurrentAccountId
      write SetCurrentAccountId;
    property OnDataChanged: TNotifyEvent read FOnDataChanged
      write FOnDataChanged;
  end;

implementation

uses
  Finance.Categories, Finance.Repository, Finance.Strings,
  UnitTransactionEditor;

constructor TMainPageForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BorderStyle := bsNone;
  Align := alClient;
  Visible := False;

  FHead := nil;

  pnlToolbar := TPanel.Create(Self);
  pnlToolbar.Parent := Self;
  pnlToolbar.Align := alTop;
  pnlToolbar.Height := 40;
  pnlToolbar.BevelOuter := bvNone;

  lblFilter := TLabel.Create(Self);
  lblFilter.Parent := pnlToolbar;
  lblFilter.Left := 8;
  lblFilter.Top := 12;
  lblFilter.Caption := MAIN_LABEL_FILTER;

  cmbCategoryFilter := TComboBox.Create(Self);
  cmbCategoryFilter.Parent := pnlToolbar;
  cmbCategoryFilter.Left := 80;
  cmbCategoryFilter.Top := 8;
  cmbCategoryFilter.Width := 220;
  cmbCategoryFilter.Style := csDropDownList;
  cmbCategoryFilter.OnChange := CmbCategoryFilterChange;

  StringGrid1 := TStringGrid.Create(Self);
  StringGrid1.Parent := Self;
  StringGrid1.Align := alClient;
  StringGrid1.FixedRows := 1;
  StringGrid1.FixedCols := 0;
  StringGrid1.ColCount := 7;
  StringGrid1.RowCount := 1;
  StringGrid1.Options := StringGrid1.Options + [goRowSelect, goFixedVertLine,
    goFixedHorzLine];
  StringGrid1.Cells[0, 0] := MAIN_COL_DATE;
  StringGrid1.Cells[1, 0] := MAIN_COL_TYPE;
  StringGrid1.Cells[2, 0] := MAIN_COL_CATEGORY;
  StringGrid1.Cells[3, 0] := MAIN_COL_DESCRIPTION;
  StringGrid1.Cells[4, 0] := MAIN_COL_AMOUNT;
  StringGrid1.Cells[COL_EDIT, 0] := MAIN_ICON_EDIT;
  StringGrid1.Cells[COL_DEL, 0] := MAIN_ICON_DELETE;
  StringGrid1.ColWidths[0] := 88;
  StringGrid1.ColWidths[1] := 70;
  StringGrid1.ColWidths[2] := 150;
  StringGrid1.ColWidths[3] := 260;
  StringGrid1.ColWidths[4] := 90;
  StringGrid1.ColWidths[COL_EDIT] := 50;
  StringGrid1.ColWidths[COL_DEL] := 50;
  StringGrid1.OnMouseDown := StringGridMouseDown;

  pnlFooter := TPanel.Create(Self);
  pnlFooter.Parent := Self;
  pnlFooter.Align := alBottom;
  pnlFooter.Height := 52;
  pnlFooter.BevelOuter := bvNone;

  btnAdd := TButton.Create(Self);
  btnAdd.Parent := pnlFooter;
  btnAdd.Left := 8;
  btnAdd.Top := 10;
  btnAdd.Width := 160;
  btnAdd.Height := 32;
  btnAdd.Caption := MAIN_BTN_ADD_TX;
  btnAdd.OnClick := BtnAddClick;

  FillCategoryFilter;
end;

destructor TMainPageForm.Destroy;
begin
  ListDispose(FHead);
  inherited;
end;

procedure TMainPageForm.SetCurrentAccountId(const Value: Int64);
begin
  if FCurrentAccountId = Value then
    Exit;
  FCurrentAccountId := Value;
  RefreshData;
end;

function TMainPageForm.MatchesFilters(const AData: TTransactionRec): Boolean;
var
  FilterCat: string;
begin
  if cmbCategoryFilter.ItemIndex > 0 then
  begin
    FilterCat := Trim(cmbCategoryFilter.Items[cmbCategoryFilter.ItemIndex]);
    if not SameText(AData.Category, FilterCat) then
      Exit(False);
  end;
  Result := True;
end;

function TMainPageForm.GetNodeByDisplayIndex(ADisplayIndex: Integer;
  out ACur, APrev: PListNode): Boolean;
var
  P, PrevInList: PListNode;
  Idx: Integer;
begin
  ACur := nil;
  APrev := nil;
  PrevInList := nil;
  P := FHead;
  Idx := 0;
  while P <> nil do
  begin
    if MatchesFilters(P^.Data) then
    begin
      if Idx = ADisplayIndex then
      begin
        ACur := P;
        APrev := PrevInList;
        Exit(True);
      end;
      Inc(Idx);
    end;
    PrevInList := P;
    P := P^.Next;
  end;
  Result := False;
end;

procedure TMainPageForm.FillCategoryFilter;
begin
  FillFilterCategories(cmbCategoryFilter.Items);
  cmbCategoryFilter.ItemIndex := 0;
end;

procedure TMainPageForm.SyncCategoryFilter;
var
  Old: string;
  I: Integer;
begin
  if cmbCategoryFilter.ItemIndex <= 0 then
    Old := ''
  else
    Old := Trim(cmbCategoryFilter.Items[cmbCategoryFilter.ItemIndex]);
  FillFilterCategories(cmbCategoryFilter.Items);
  cmbCategoryFilter.ItemIndex := 0;
  if Old <> '' then
    for I := 0 to cmbCategoryFilter.Items.Count - 1 do
      if SameText(Trim(cmbCategoryFilter.Items[I]), Old) then
      begin
        cmbCategoryFilter.ItemIndex := I;
        Break;
      end;
end;

procedure TMainPageForm.RefreshData;
var
  P: PListNode;
  R: Integer;
  C: Integer;
  Typ: string;
begin
  RepoLoadTransactionsForAccount(FHead, FCurrentAccountId);
  // Clear possible stale data cells before rebuilding visible rows.
  if StringGrid1.RowCount > StringGrid1.FixedRows then
    for C := 0 to StringGrid1.ColCount - 1 do
      StringGrid1.Cells[C, StringGrid1.FixedRows] := '';
  StringGrid1.RowCount := StringGrid1.FixedRows;
  if StringGrid1.RowCount < 1 then
    StringGrid1.RowCount := 1;

  R := StringGrid1.FixedRows;
  P := FHead;
  while P <> nil do
  begin
    if MatchesFilters(P^.Data) then
    begin
      if R >= StringGrid1.RowCount then
        StringGrid1.RowCount := R + 1;
      StringGrid1.Cells[0, R] := P^.Data.DateStr;
      if P^.Data.IsIncome then
        Typ := MAIN_TX_INCOME
      else
        Typ := MAIN_TX_EXPENSE;
      StringGrid1.Cells[1, R] := Typ;
      StringGrid1.Cells[2, R] := P^.Data.Category;
      StringGrid1.Cells[3, R] := P^.Data.Description;
      StringGrid1.Cells[4, R] := FormatFloat(AMOUNT_FORMAT, P^.Data.Amount);
      StringGrid1.Cells[COL_EDIT, R] := MAIN_ICON_EDIT;
      StringGrid1.Cells[COL_DEL, R] := MAIN_ICON_DELETE;
      Inc(R);
    end;
    P := P^.Next;
  end;
  if R = StringGrid1.FixedRows then
  begin
    StringGrid1.RowCount := StringGrid1.FixedRows;
    if StringGrid1.RowCount < 1 then
      StringGrid1.RowCount := 1;
    StringGrid1.Invalidate;
    Exit;
  end;
  StringGrid1.RowCount := R;
  if StringGrid1.RowCount < StringGrid1.FixedRows then
    StringGrid1.RowCount := StringGrid1.FixedRows;
  if StringGrid1.RowCount < 1 then
    StringGrid1.RowCount := 1;
end;

function TMainPageForm.CurrentBalance: Double;
begin
  Result := ListCalcBalance(FHead);
end;

procedure TMainPageForm.NotifyDataChanged;
begin
  if Assigned(FOnDataChanged) then
    FOnDataChanged(Self);
end;

procedure TMainPageForm.CmbCategoryFilterChange(Sender: TObject);
begin
  RefreshData;
end;

procedure TMainPageForm.BtnAddClick(Sender: TObject);
var
  Rec: TTransactionRec;
begin
  Rec := Default(TTransactionRec);
  if not Assigned(TransactionEditForm) then
    TransactionEditForm := TTransactionEditForm.Create(Application);
  if TransactionEditForm.Execute(Rec, False) then
  begin
    Rec.AccountId := FCurrentAccountId;
    RepoInsertTransaction(Rec);
    SyncCategoryFilter;
    RefreshData;
    NotifyDataChanged;
  end;
end;

procedure TMainPageForm.DoEditGridRow(AGridRow: Integer);
var
  Di: Integer;
  Cur, Prev: PListNode;
  Rec: TTransactionRec;
begin
  if AGridRow < StringGrid1.FixedRows then
    Exit;
  Di := AGridRow - StringGrid1.FixedRows;
  if not GetNodeByDisplayIndex(Di, Cur, Prev) or (Cur = nil) then
    Exit;
  Rec := Cur^.Data;
  if not Assigned(TransactionEditForm) then
    TransactionEditForm := TTransactionEditForm.Create(Application);
  if TransactionEditForm.Execute(Rec, True) then
  begin
    Rec.AccountId := FCurrentAccountId;
    RepoUpdateTransaction(Rec);
    SyncCategoryFilter;
    RefreshData;
    NotifyDataChanged;
  end;
end;

procedure TMainPageForm.DoDeleteGridRow(AGridRow: Integer);
var
  Di: Integer;
  Cur, Prev: PListNode;
begin
  if AGridRow < StringGrid1.FixedRows then
    Exit;
  Di := AGridRow - StringGrid1.FixedRows;
  if not GetNodeByDisplayIndex(Di, Cur, Prev) or (Cur = nil) then
    Exit;
  if MessageDlg(MAIN_DELETE_CONFIRM, mtConfirmation, [mbYes, mbNo], 0) <> mrYes
  then
    Exit;
  RepoDeleteTransaction(Cur^.Data.Id);
  RefreshData;
  NotifyDataChanged;
end;

procedure TMainPageForm.StringGridMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ACol, ARow: Integer;
begin
  if Button <> mbLeft then
    Exit;
  StringGrid1.MouseToCell(X, Y, ACol, ARow);
  if ARow < StringGrid1.FixedRows then
    Exit;
  if ACol = COL_EDIT then
    DoEditGridRow(ARow)
  else if ACol = COL_DEL then
    DoDeleteGridRow(ARow);
end;

end.
