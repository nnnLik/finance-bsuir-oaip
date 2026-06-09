unit UnitAnalyticsTabTrends;

interface

uses
  System.Classes,
  System.Types,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.Forms,
  Finance.AnalyticsTabsService;

type
  TAnalyticsTrendsTab = class(TPanel)
  private
    FPaint: TPaintBox;
    FEmpty: TLabel;
    FData: TMonthlyTrendPointArray;
    procedure PaintChart(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure RefreshData(const Scope: string; const ActiveAccountId: Int64);
  end;

implementation

uses
  System.SysUtils,
  Vcl.Graphics,
  Finance.Strings,
  Finance.ChartTheme;

constructor TAnalyticsTrendsTab.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Align := alClient;
  BevelOuter := bvNone;

  FPaint := TPaintBox.Create(Self);
  FPaint.Parent := Self;
  FPaint.Align := alClient;
  FPaint.Color := ANALYTICS_CHART_BG;
  FPaint.OnPaint := PaintChart;

  FEmpty := TLabel.Create(Self);
  FEmpty.Parent := Self;
  FEmpty.Align := alClient;
  FEmpty.Alignment := taCenter;
  FEmpty.Layout := tlCenter;
  FEmpty.Caption := ANALYTICS_EMPTY_DATA;
  FEmpty.Visible := False;
end;

procedure TAnalyticsTrendsTab.RefreshData(const Scope: string;
  const ActiveAccountId: Int64);
var
  D: TMonthlyTrendPointArray;
begin
  BuildMonthlyTrends(Scope, ActiveAccountId, D);
  FData := D;

  if Length(FData) = 0 then
  begin
    FPaint.Visible := False;
    FEmpty.Visible := True;
    Exit;
  end;

  FEmpty.Visible := False;
  FPaint.Visible := True;
  FPaint.Invalidate;
end;

procedure TAnalyticsTrendsTab.PaintChart(Sender: TObject);
var
  C: TCanvas;
  R: TRect;
  I, N, X, YInc, YExp, PrevX, PrevInc, PrevExp, G, GStep: Integer;
  MaxV, V: Double;
  PlotLeft, PlotTop, PlotRight, PlotBottom: Integer;
begin
  C := FPaint.Canvas;
  R := FPaint.ClientRect;
  C.Brush.Color := ANALYTICS_CHART_BG;
  C.FillRect(R);
  N := Length(FData);
  if N = 0 then
    Exit;

  PlotLeft := 44;
  PlotTop := 28;
  PlotRight := R.Right - 20;
  PlotBottom := R.Bottom - 36;
  MaxV := 0;
  for I := 0 to N - 1 do
  begin
    if FData[I].IncomeTotal > MaxV then
      MaxV := FData[I].IncomeTotal;
    if FData[I].ExpenseTotal > MaxV then
      MaxV := FData[I].ExpenseTotal;
  end;
  if MaxV <= 0 then
    Exit;

  C.Brush.Color := ANALYTICS_CHART_PLOT;
  C.Pen.Color := ANALYTICS_CHART_GRID;
  C.Pen.Width := 1;
  C.Rectangle(PlotLeft, PlotTop, PlotRight, PlotBottom);

  for G := 1 to 4 do
  begin
    GStep := PlotTop + Round((G / 5) * (PlotBottom - PlotTop));
    C.Pen.Color := ANALYTICS_CHART_GRID;
    C.MoveTo(PlotLeft, GStep);
    C.LineTo(PlotRight, GStep);
  end;

  PrevX := -1;
  PrevInc := -1;
  PrevExp := -1;
  ApplyAnalyticsChartFont(C, (Sender as TPaintBox).Font);
  for I := 0 to N - 1 do
  begin
    if N = 1 then
      X := (PlotLeft + PlotRight) div 2
    else
      X := PlotLeft + Round((I * (PlotRight - PlotLeft)) / (N - 1));

    V := FData[I].IncomeTotal / MaxV;
    YInc := PlotBottom - Round(V * (PlotBottom - PlotTop));
    V := FData[I].ExpenseTotal / MaxV;
    YExp := PlotBottom - Round(V * (PlotBottom - PlotTop));

    C.Pen.Width := 2;
    C.Pen.Color := ANALYTICS_CHART_INCOME;
    if PrevX >= 0 then
    begin
      C.MoveTo(PrevX, PrevInc);
      C.LineTo(X, YInc);
    end;
    C.Brush.Color := ANALYTICS_CHART_INCOME;
    C.Ellipse(X - 3, YInc - 3, X + 3, YInc + 3);

    C.Pen.Color := ANALYTICS_CHART_EXPENSE;
    if PrevX >= 0 then
    begin
      C.MoveTo(PrevX, PrevExp);
      C.LineTo(X, YExp);
    end;
    C.Brush.Color := ANALYTICS_CHART_EXPENSE;
    C.Ellipse(X - 3, YExp - 3, X + 3, YExp + 3);

    ChartTextOut(C, X - 22, PlotBottom + 8,
      Format('%.2d.%d', [FData[I].Month, FData[I].Year]));

    PrevX := X;
    PrevInc := YInc;
    PrevExp := YExp;
  end;

  C.Pen.Width := 1;
  ChartTextOut(C, PlotLeft, 6, ANALYTICS_SERIES_INCOME + ' —');
  ChartTextOut(C, PlotLeft + 160, 6, ANALYTICS_SERIES_EXPENSE);
end;

end.
