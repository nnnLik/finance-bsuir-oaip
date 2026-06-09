unit UnitAnalyticsTabOverview;

interface

uses
  System.Classes,
  System.Types,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.Forms;

type
  TAnalyticsOverviewTab = class(TPanel)
  private
    pnlKpi: TPanel;
    lblIncome: TLabel;
    lblExpense: TLabel;
    lblBalance: TLabel;
    lblCount: TLabel;
    lblEmpty: TLabel;
    pbChart: TPaintBox;
    FIncomeValue: Double;
    FExpenseValue: Double;
    procedure PbChartPaint(Sender: TObject);
    procedure SetKpiLabel(ALabel: TLabel; const ATitle: string;
      const AValue: string);
  public
    constructor Create(AOwner: TComponent); override;
    procedure RefreshData(const Scope: string; const ActiveAccountId: Int64);
  end;

implementation

uses
  System.SysUtils,
  Vcl.Graphics,
  Finance.Strings,
  Finance.ChartTheme,
  Finance.AnalyticsTabsService;

constructor TAnalyticsOverviewTab.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Align := alClient;
  BevelOuter := bvNone;

  pnlKpi := TPanel.Create(Self);
  pnlKpi.Parent := Self;
  pnlKpi.Align := alTop;
  pnlKpi.Height := 68;
  pnlKpi.BevelOuter := bvNone;

  lblIncome := TLabel.Create(Self);
  lblIncome.Parent := pnlKpi;
  lblIncome.Left := 16;
  lblIncome.Top := 10;

  lblExpense := TLabel.Create(Self);
  lblExpense.Parent := pnlKpi;
  lblExpense.Left := 220;
  lblExpense.Top := 10;

  lblBalance := TLabel.Create(Self);
  lblBalance.Parent := pnlKpi;
  lblBalance.Left := 424;
  lblBalance.Top := 10;

  lblCount := TLabel.Create(Self);
  lblCount.Parent := pnlKpi;
  lblCount.Left := 628;
  lblCount.Top := 10;

  pbChart := TPaintBox.Create(Self);
  pbChart.Parent := Self;
  pbChart.Align := alClient;
  pbChart.Color := ANALYTICS_CHART_BG;
  pbChart.OnPaint := PbChartPaint;

  lblEmpty := TLabel.Create(Self);
  lblEmpty.Parent := Self;
  lblEmpty.Align := alClient;
  lblEmpty.Alignment := taCenter;
  lblEmpty.Layout := tlCenter;
  lblEmpty.Caption := ANALYTICS_EMPTY_DATA;
  lblEmpty.Visible := False;
end;

procedure TAnalyticsOverviewTab.SetKpiLabel(ALabel: TLabel; const ATitle: string;
  const AValue: string);
begin
  ALabel.Caption := ATitle + ': ' + AValue;
  ALabel.Font.Style := [fsBold];
end;

procedure TAnalyticsOverviewTab.PbChartPaint(Sender: TObject);
var
  C: TCanvas;
  R: TRect;
  MaxV: Double;
  BarW, Gap, BaseY, H: Integer;
  IncH, ExpH: Integer;
  X1, X2: Integer;
begin
  C := pbChart.Canvas;
  R := pbChart.ClientRect;
  C.Brush.Color := ANALYTICS_CHART_BG;
  C.FillRect(R);
  if (FIncomeValue <= 0) and (FExpenseValue <= 0) then
    Exit;

  MaxV := FIncomeValue;
  if FExpenseValue > MaxV then
    MaxV := FExpenseValue;
  if MaxV <= 0 then
    Exit;

  Gap := 40;
  BarW := ((R.Right - R.Left) - Gap * 3) div 2;
  if BarW < 20 then
    BarW := 20;
  BaseY := R.Bottom - 36;
  H := (R.Bottom - R.Top) - 70;
  if H < 10 then
    H := 10;

  IncH := Round((FIncomeValue / MaxV) * H);
  ExpH := Round((FExpenseValue / MaxV) * H);

  X1 := Gap;
  X2 := X1 + BarW + Gap;

  C.Pen.Color := ANALYTICS_CHART_AXIS;
  C.Pen.Width := 1;
  C.MoveTo(Gap div 2, BaseY);
  C.LineTo(R.Right - Gap div 2, BaseY);

  C.Brush.Color := ANALYTICS_CHART_INCOME;
  C.Pen.Color := ANALYTICS_CHART_INCOME;
  C.Rectangle(X1, BaseY - IncH, X1 + BarW, BaseY);

  C.Brush.Color := ANALYTICS_CHART_EXPENSE;
  C.Pen.Color := ANALYTICS_CHART_EXPENSE;
  C.Rectangle(X2, BaseY - ExpH, X2 + BarW, BaseY);

  ApplyAnalyticsChartFont(C, pbChart.Font);
  ChartTextOut(C, X1, BaseY + 6, ANALYTICS_SERIES_INCOME);
  ChartTextOut(C, X1, BaseY - IncH - 20, FormatFloat(AMOUNT_FORMAT, FIncomeValue));
  ChartTextOut(C, X2, BaseY + 6, ANALYTICS_SERIES_EXPENSE);
  ChartTextOut(C, X2, BaseY - ExpH - 20, FormatFloat(AMOUNT_FORMAT, FExpenseValue));
end;

procedure TAnalyticsOverviewTab.RefreshData(const Scope: string;
  const ActiveAccountId: Int64);
var
  D: TOverviewAnalyticsData;
begin
  BuildOverview(Scope, ActiveAccountId, D);

  SetKpiLabel(lblIncome, ANALYTICS_KPI_INCOME,
    FormatFloat(AMOUNT_FORMAT, D.IncomeTotal));
  SetKpiLabel(lblExpense, ANALYTICS_KPI_EXPENSE,
    FormatFloat(AMOUNT_FORMAT, D.ExpenseTotal));
  SetKpiLabel(lblBalance, ANALYTICS_KPI_BALANCE,
    FormatFloat(AMOUNT_FORMAT, D.Balance));
  SetKpiLabel(lblCount, ANALYTICS_KPI_TX_COUNT, IntToStr(D.TxCount));

  FIncomeValue := D.IncomeTotal;
  FExpenseValue := D.ExpenseTotal;
  if D.TxCount = 0 then
  begin
    pbChart.Visible := False;
    lblEmpty.Visible := True;
    Exit;
  end;

  lblEmpty.Visible := False;
  pbChart.Visible := True;
  pbChart.Invalidate;
end;

end.
