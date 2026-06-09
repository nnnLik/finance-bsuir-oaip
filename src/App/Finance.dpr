program Finance;

{$APPTYPE GUI}
{$R *.res}

uses
  Winapi.Windows,
  Vcl.Forms,
  Finance.Types in '..\Core\Finance.Types.pas',
  Finance.TransactionList in '..\Data\Finance.TransactionList.pas',
  Finance.Db in '..\Data\Finance.Db.pas',
  Finance.Strings in '..\Core\Finance.Strings.pas',
  Finance.ChartTheme in '..\Core\Finance.ChartTheme.pas',
  Finance.DateUtils in '..\Core\Finance.DateUtils.pas',
  Finance.Categories in '..\Core\Finance.Categories.pas',
  UnitMainShell in '..\UI\Forms\UnitMainShell.pas' {MainShellForm},
  UnitMain in '..\UI\Forms\UnitMain.pas',
  UnitAnalytics in '..\UI\Forms\UnitAnalytics.pas',
  UnitAnalyticsTabOverview in '..\UI\Forms\UnitAnalyticsTabOverview.pas',
  UnitAnalyticsTabExpenses in '..\UI\Forms\UnitAnalyticsTabExpenses.pas',
  UnitAnalyticsTabIncome in '..\UI\Forms\UnitAnalyticsTabIncome.pas',
  UnitAnalyticsTabTrends in '..\UI\Forms\UnitAnalyticsTabTrends.pas',
  UnitSettings in '..\UI\Forms\UnitSettings.pas' {UnitSettings},
  UnitTransactionEditor in '..\UI\Forms\UnitTransactionEditor.pas' {TransactionEditForm},
  Finance.AnalyticsTabsService in '..\UI\Logic\Finance.AnalyticsTabsService.pas',
  FireDAC.VCLUI.Wait,
  Vcl.Themes,
  Vcl.Styles,
  Finance.Repository in '..\Data\Finance.Repository.pas';

var
  GAppMutex: THandle;

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle(APP_STYLE_NAME);
  Application.CreateForm(TMainShellForm, MainShellForm);
  Application.Run;
end.

