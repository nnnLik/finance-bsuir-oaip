unit UnitAnalytics;

interface

uses
  System.Classes, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Graphics, Vcl.ComCtrls,
  UnitAnalyticsTabOverview, UnitAnalyticsTabExpenses, UnitAnalyticsTabIncome,
  UnitAnalyticsTabTrends;

type
  TAnalyticsPageForm = class(TForm)
  private
    FActiveAccountId: Int64;
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblScope: TLabel;
    cmbScope: TComboBox;
    pgAnalytics: TPageControl;
    tsOverview: TTabSheet;
    tsExpenses: TTabSheet;
    tsIncome: TTabSheet;
    tsTrends: TTabSheet;
    FOverviewTab: TAnalyticsOverviewTab;
    FExpensesTab: TAnalyticsExpensesTab;
    FIncomeTab: TAnalyticsIncomeTab;
    FTrendsTab: TAnalyticsTrendsTab;
    function CurrentScope: string;
    procedure CmbScopeChange(Sender: TObject);
    procedure SetActiveAccountId(const Value: Int64);
  public
    constructor Create(AOwner: TComponent); override;
    procedure RefreshData;
    property ActiveAccountId: Int64 read FActiveAccountId
      write SetActiveAccountId;
  end;

implementation

uses
  System.SysUtils,
  Finance.Repository,
  Finance.Strings;

constructor TAnalyticsPageForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BorderStyle := bsNone;
  Align := alClient;
  Visible := False;

  pnlHeader := TPanel.Create(Self);
  pnlHeader.Parent := Self;
  pnlHeader.Align := alTop;
  pnlHeader.Height := 44;
  pnlHeader.BevelOuter := bvNone;

  lblTitle := TLabel.Create(Self);
  lblTitle.Parent := pnlHeader;
  lblTitle.Left := 16;
  lblTitle.Top := 10;
  lblTitle.Caption := ANALYTICS_TITLE;
  lblTitle.Font.Style := [fsBold];

  lblScope := TLabel.Create(Self);
  lblScope.Parent := pnlHeader;
  lblScope.Left := 440;
  lblScope.Top := 12;
  lblScope.Caption := ANALYTICS_SCOPE_TITLE;

  cmbScope := TComboBox.Create(Self);
  cmbScope.Parent := pnlHeader;
  cmbScope.Left := 500;
  cmbScope.Top := 8;
  cmbScope.Width := 210;
  cmbScope.Style := csDropDownList;
  cmbScope.Items.Add(ANALYTICS_SCOPE_ACTIVE_CAPTION);
  cmbScope.Items.Add(ANALYTICS_SCOPE_ALL_CAPTION);
  if SameText(RepoGetAnalyticsScope, REPO_SCOPE_ALL) then
    cmbScope.ItemIndex := 1
  else
    cmbScope.ItemIndex := 0;
  cmbScope.OnChange := CmbScopeChange;

  pgAnalytics := TPageControl.Create(Self);
  pgAnalytics.Parent := Self;
  pgAnalytics.Align := alClient;

  tsOverview := TTabSheet.Create(Self);
  tsOverview.PageControl := pgAnalytics;
  tsOverview.Caption := ANALYTICS_TAB_OVERVIEW;

  tsExpenses := TTabSheet.Create(Self);
  tsExpenses.PageControl := pgAnalytics;
  tsExpenses.Caption := ANALYTICS_TAB_EXPENSES;

  tsIncome := TTabSheet.Create(Self);
  tsIncome.PageControl := pgAnalytics;
  tsIncome.Caption := ANALYTICS_TAB_INCOME;

  tsTrends := TTabSheet.Create(Self);
  tsTrends.PageControl := pgAnalytics;
  tsTrends.Caption := ANALYTICS_TAB_TRENDS;

  FOverviewTab := TAnalyticsOverviewTab.Create(Self);
  FOverviewTab.Parent := tsOverview;

  FExpensesTab := TAnalyticsExpensesTab.Create(Self);
  FExpensesTab.Parent := tsExpenses;

  FIncomeTab := TAnalyticsIncomeTab.Create(Self);
  FIncomeTab.Parent := tsIncome;

  FTrendsTab := TAnalyticsTrendsTab.Create(Self);
  FTrendsTab.Parent := tsTrends;
end;

function TAnalyticsPageForm.CurrentScope: string;
begin
  if cmbScope.ItemIndex = 1 then
    Result := REPO_SCOPE_ALL
  else
    Result := REPO_SCOPE_ACTIVE;
end;

procedure TAnalyticsPageForm.SetActiveAccountId(const Value: Int64);
begin
  if FActiveAccountId = Value then
    Exit;
  FActiveAccountId := Value;
  if Visible then
    RefreshData;
end;

procedure TAnalyticsPageForm.CmbScopeChange(Sender: TObject);
begin
  RepoSetAnalyticsScope(CurrentScope);
  RefreshData;
end;

procedure TAnalyticsPageForm.RefreshData;
begin
  if SameText(RepoGetAnalyticsScope, REPO_SCOPE_ALL) then
    cmbScope.ItemIndex := 1
  else
    cmbScope.ItemIndex := 0;
  FOverviewTab.RefreshData(CurrentScope, FActiveAccountId);
  FExpensesTab.RefreshData(CurrentScope, FActiveAccountId);
  FIncomeTab.RefreshData(CurrentScope, FActiveAccountId);
  FTrendsTab.RefreshData(CurrentScope, FActiveAccountId);
end;

end.
