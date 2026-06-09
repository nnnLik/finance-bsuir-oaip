unit Finance.ChartTheme;

interface

uses
  Winapi.Windows,
  Vcl.Graphics;

const
  ANALYTICS_CHART_BG = TColor($0024282C);
  ANALYTICS_CHART_PLOT = TColor($001C2024);
  ANALYTICS_CHART_GRID = TColor($00485058);
  ANALYTICS_CHART_AXIS = TColor($00586068);
  ANALYTICS_CHART_TEXT = TColor($00FFFFFF);
  ANALYTICS_CHART_INCOME = TColor($0082C85A);
  ANALYTICS_CHART_EXPENSE = TColor($00786EE6);

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
