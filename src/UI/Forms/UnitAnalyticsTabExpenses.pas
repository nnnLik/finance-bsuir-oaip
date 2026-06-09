unit UnitAnalyticsTabExpenses;

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
  TAnalyticsExpensesTab = class(TPanel)
  private
    FPaint: TPaintBox;
    FEmpty: TLabel;
    FData: TCategoryChartPointArray;
    procedure PaintChart(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure RefreshData(const Scope: string; const ActiveAccountId: Int64);
  end;

implementation

uses
  Vcl.Graphics,
  Finance.Strings,
  Finance.ChartTheme;

constructor TAnalyticsExpensesTab.Create(AOwner: TComponent);
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

procedure TAnalyticsExpensesTab.RefreshData(const Scope: string;
  const ActiveAccountId: Int64);
var
  D: TCategoryChartPointArray;
begin
  BuildExpenseCategories(Scope, ActiveAccountId, D);
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

procedure TAnalyticsExpensesTab.PaintChart(Sender: TObject);
var
  C: TCanvas;
  R: TRect;
  I, TopN, X, Y, BarW, Gap, MaxH, H, BaseY: Integer;
  MaxV: Double;
begin
  C := FPaint.Canvas;
  R := FPaint.ClientRect;
  C.Brush.Color := ANALYTICS_CHART_BG;
  C.FillRect(R);
  if Length(FData) = 0 then
    Exit;

  TopN := Length(FData);
  if TopN > 8 then
    TopN := 8;
  MaxV := FData[0].Value;
  if MaxV <= 0 then
    Exit;

  Gap := 12;
  BarW := ((R.Right - R.Left) - (TopN + 1) * Gap) div TopN;
  if BarW < 12 then
    BarW := 12;
  BaseY := R.Bottom - 32;
  MaxH := BaseY - R.Top - 24;
  if MaxH < 10 then
    MaxH := 10;

  C.Pen.Color := ANALYTICS_CHART_AXIS;
  C.Pen.Width := 1;
  C.MoveTo(Gap div 2, BaseY);
  C.LineTo(R.Right - Gap div 2, BaseY);

  ApplyAnalyticsChartFont(C, (Sender as TPaintBox).Font);

  X := Gap;
  for I := 0 to TopN - 1 do
  begin
    H := Round((FData[I].Value / MaxV) * MaxH);
    Y := BaseY - H;
    C.Brush.Color := ANALYTICS_CHART_EXPENSE;
    C.Pen.Color := ANALYTICS_CHART_EXPENSE;
    C.Rectangle(X, Y, X + BarW, BaseY);
    ChartTextOut(C, X, BaseY + 4, Copy(FData[I].Name, 1, 12));
    Inc(X, BarW + Gap);
  end;
end;

end.
