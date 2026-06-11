unit Finance.ChartTheme;

interface

uses
  Winapi.Windows,
  Vcl.Graphics;

const
  ANALYTICS_CHART_BG = clBtnFace;
  ANALYTICS_CHART_PLOT = clWindow;
  ANALYTICS_CHART_GRID = TColor($00D0D0D0);
  ANALYTICS_CHART_AXIS = clGray;
  ANALYTICS_CHART_TEXT = clWindowText;
  ANALYTICS_CHART_INCOME = TColor($0000A000);
  ANALYTICS_CHART_EXPENSE = TColor($000000D0);

procedure ApplyAnalyticsChartFont(C: TCanvas; const ASource: TFont);
procedure ChartTextOut(C: TCanvas; X, Y: Integer; const S: string);

implementation

procedure ChartTextOut(C: TCanvas; X, Y: Integer; const S: string);
begin
  SetBkMode(C.Handle, TRANSPARENT);
  SetBkColor(C.Handle, ColorToRGB(ANALYTICS_CHART_BG));
  C.Brush.Style := bsClear;
  C.TextOut(X, Y, S);
  C.Brush.Style := bsSolid;
end;

procedure ApplyAnalyticsChartFont(C: TCanvas; const ASource: TFont);
begin
  C.Font.Assign(ASource);
  C.Font.Color := ANALYTICS_CHART_TEXT;
  C.Font.Style := [fsBold];
  if C.Font.Size < 9 then
    C.Font.Size := 10
  else
    C.Font.Size := C.Font.Size + 1;
end;

end.
