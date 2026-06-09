unit UnitMainShell;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.UITypes,
  Vcl.Forms, Vcl.Controls, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Buttons, Vcl.Graphics, Finance.Types, UnitMain, UnitAnalytics,
  UnitSettings;

type
  TMainShellForm = class(TForm)
  private
    pnlSidebar: TPanel;
    btnNavMain: TSpeedButton;
    btnNavAnalytics: TSpeedButton;
    btnNavSettings: TSpeedButton;
    lblSidebarTitle: TLabel;

    pnlShell: TPanel;
    pnlTopBar: TPanel;
    lblBalanceTitle: TLabel;
    lblBalance: TLabel;
    lblAccount: TLabel;
    cmbAccounts: TComboBox;

    pnlHost: TPanel;

    FAccounts: TAccountArray;
    FCurrentAccountId: Int64;
    FMainPage: TMainPageForm;
    FAnalyticsPage: TAnalyticsPageForm;
    FSettingsPage: TSettingsPageForm;

    procedure BuildUi;
    procedure BuildPages;
    procedure LoadAccounts;
    procedure EnsureActiveAccount;
    procedure UpdateBalance;
    procedure ApplyAccountToPages;

    procedure SetNavActive(const APage: Integer);
    procedure ShowPageMain;
    procedure ShowPageAnalytics;
    procedure ShowPageSettings;

    procedure BtnNavMainClick(Sender: TObject);
    procedure BtnNavAnalyticsClick(Sender: TObject);
    procedure BtnNavSettingsClick(Sender: TObject);
    procedure CmbAccountsChange(Sender: TObject);
    procedure HandleDataChanged(Sender: TObject);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  MainShellForm: TMainShellForm;

implementation

uses
  Finance.Db, Finance.Categories, Finance.Repository, Finance.Strings,
  UnitTransactionEditor;

procedure TMainShellForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle := Params.ExStyle or WS_EX_APPWINDOW;
  Params.ExStyle := Params.ExStyle and not WS_EX_TOOLWINDOW;
end;

constructor TMainShellForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  FormStyle := fsNormal;
  {$IF Declared(stAlways)}
  ShowInTaskbar := stAlways;
  {$IFEND}
  Caption := APP_CAPTION;
  Width := 940;
  Height := 660;
  Position := poScreenCenter;

  DbInit;
  CategoriesLoad;

  BuildUi;
  BuildPages;
  LoadAccounts;
  EnsureActiveAccount;
  ApplyAccountToPages;
  ShowPageMain;
end;

destructor TMainShellForm.Destroy;
begin
  DbClose;
  inherited;
end;

procedure TMainShellForm.BuildUi;
begin
  pnlSidebar := TPanel.Create(Self);
  pnlSidebar.Parent := Self;
  pnlSidebar.Align := alLeft;
  pnlSidebar.Width := 80;
  pnlSidebar.BevelOuter := bvNone;

  lblSidebarTitle := TLabel.Create(Self);
  lblSidebarTitle.Parent := pnlSidebar;
  lblSidebarTitle.Left := 10;
  lblSidebarTitle.Top := 12;
  lblSidebarTitle.Caption := SHELL_SIDEBAR_TITLE;

  btnNavMain := TSpeedButton.Create(Self);
  btnNavMain.Parent := pnlSidebar;
  btnNavMain.Left := 12;
  btnNavMain.Top := 52;
  btnNavMain.Width := 56;
  btnNavMain.Height := 32;
  btnNavMain.Caption := Char($E80F);
  btnNavMain.ParentFont := False;
  btnNavMain.Font.Name := 'Segoe MDL2 Assets';
  btnNavMain.Font.Size := 14;
  btnNavMain.ShowHint := True;
  btnNavMain.Hint := SHELL_NAV_HINT_MAIN;
  btnNavMain.GroupIndex := 1;
  btnNavMain.OnClick := BtnNavMainClick;

  btnNavAnalytics := TSpeedButton.Create(Self);
  btnNavAnalytics.Parent := pnlSidebar;
  btnNavAnalytics.Left := 12;
  btnNavAnalytics.Top := 92;
  btnNavAnalytics.Width := 56;
  btnNavAnalytics.Height := 32;
  btnNavAnalytics.Caption := Char($E9D2);
  btnNavAnalytics.ParentFont := False;
  btnNavAnalytics.Font.Name := 'Segoe MDL2 Assets';
  btnNavAnalytics.Font.Size := 14;
  btnNavAnalytics.ShowHint := True;
  btnNavAnalytics.Hint := SHELL_NAV_HINT_ANALYTICS;
  btnNavAnalytics.GroupIndex := 1;
  btnNavAnalytics.OnClick := BtnNavAnalyticsClick;

  btnNavSettings := TSpeedButton.Create(Self);
  btnNavSettings.Parent := pnlSidebar;
  btnNavSettings.Left := 12;
  btnNavSettings.Top := 132;
  btnNavSettings.Width := 56;
  btnNavSettings.Height := 32;
  btnNavSettings.Caption := Char($E713);
  btnNavSettings.ParentFont := False;
  btnNavSettings.Font.Name := 'Segoe MDL2 Assets';
  btnNavSettings.Font.Size := 14;
  btnNavSettings.ShowHint := True;
  btnNavSettings.Hint := SHELL_NAV_HINT_SETTINGS;
  btnNavSettings.GroupIndex := 1;
  btnNavSettings.OnClick := BtnNavSettingsClick;

  pnlShell := TPanel.Create(Self);
  pnlShell.Parent := Self;
  pnlShell.Align := alClient;
  pnlShell.BevelOuter := bvNone;

  pnlTopBar := TPanel.Create(Self);
  pnlTopBar.Parent := pnlShell;
  pnlTopBar.Align := alTop;
  pnlTopBar.Height := 52;
  pnlTopBar.BevelOuter := bvNone;

  lblBalanceTitle := TLabel.Create(Self);
  lblBalanceTitle.Parent := pnlTopBar;
  lblBalanceTitle.Left := 16;
  lblBalanceTitle.Top := 16;
  lblBalanceTitle.Caption := SHELL_BALANCE_TITLE;

  lblBalance := TLabel.Create(Self);
  lblBalance.Parent := pnlTopBar;
  lblBalance.Left := 132;
  lblBalance.Top := 12;
  lblBalance.Caption := AMOUNT_FORMAT;
  lblBalance.Font.Size := 14;
  lblBalance.Font.Style := [fsBold];

  lblAccount := TLabel.Create(Self);
  lblAccount.Parent := pnlTopBar;
  lblAccount.Left := 290;
  lblAccount.Top := 16;
  lblAccount.Caption := SHELL_ACCOUNT_TITLE;

  cmbAccounts := TComboBox.Create(Self);
  cmbAccounts.Parent := pnlTopBar;
  cmbAccounts.Left := 340;
  cmbAccounts.Top := 12;
  cmbAccounts.Width := 220;
  cmbAccounts.Style := csDropDownList;
  cmbAccounts.OnChange := CmbAccountsChange;

  pnlHost := TPanel.Create(Self);
  pnlHost.Parent := pnlShell;
  pnlHost.Align := alClient;
  pnlHost.BevelOuter := bvNone;
end;

procedure TMainShellForm.BuildPages;
begin
  FMainPage := TMainPageForm.Create(Self);
  FMainPage.Parent := pnlHost;
  FMainPage.OnDataChanged := HandleDataChanged;

  FAnalyticsPage := TAnalyticsPageForm.Create(Self);
  FAnalyticsPage.Parent := pnlHost;

  FSettingsPage := TSettingsPageForm.Create(Self);
  FSettingsPage.Parent := pnlHost;
  FSettingsPage.OnDataChanged := HandleDataChanged;
end;

procedure TMainShellForm.LoadAccounts;
var
  I: Integer;
begin
  RepoLoadAccounts(FAccounts);
  cmbAccounts.Items.BeginUpdate;
  try
    cmbAccounts.Items.Clear;
    for I := 0 to High(FAccounts) do
      cmbAccounts.Items.Add(FAccounts[I].Name);
  finally
    cmbAccounts.Items.EndUpdate;
  end;
end;

procedure TMainShellForm.EnsureActiveAccount;
var
  I: Integer;
begin
  FCurrentAccountId := RepoGetActiveAccountId;
  for I := 0 to High(FAccounts) do
    if FAccounts[I].Id = FCurrentAccountId then
    begin
      cmbAccounts.ItemIndex := I;
      Exit;
    end;
  if Length(FAccounts) > 0 then
  begin
    FCurrentAccountId := FAccounts[0].Id;
    cmbAccounts.ItemIndex := 0;
    RepoSetActiveAccountId(FCurrentAccountId);
  end;
end;

procedure TMainShellForm.ApplyAccountToPages;
begin
  FMainPage.CurrentAccountId := FCurrentAccountId;
  // Force refresh to avoid any stale grid presentation
  // when switching to accounts without transactions.
  FMainPage.RefreshData;
  FAnalyticsPage.ActiveAccountId := FCurrentAccountId;
  FSettingsPage.CurrentAccountId := FCurrentAccountId;
  UpdateBalance;
  FAnalyticsPage.RefreshData;
end;

procedure TMainShellForm.UpdateBalance;
begin
  lblBalance.Caption := FormatFloat(AMOUNT_FORMAT, FMainPage.CurrentBalance);
end;

procedure TMainShellForm.SetNavActive(const APage: Integer);
begin
  btnNavMain.Down := APage = 0;
  btnNavAnalytics.Down := APage = 1;
  btnNavSettings.Down := APage = 2;
end;

procedure TMainShellForm.ShowPageMain;
begin
  FMainPage.Visible := True;
  FAnalyticsPage.Visible := False;
  FSettingsPage.Visible := False;
  SetNavActive(0);
end;

procedure TMainShellForm.ShowPageAnalytics;
begin
  FMainPage.Visible := False;
  FAnalyticsPage.Visible := True;
  FSettingsPage.Visible := False;
  FAnalyticsPage.RefreshData;
  SetNavActive(1);
end;

procedure TMainShellForm.ShowPageSettings;
begin
  FMainPage.Visible := False;
  FAnalyticsPage.Visible := False;
  FSettingsPage.Visible := True;
  SetNavActive(2);
end;

procedure TMainShellForm.BtnNavMainClick(Sender: TObject);
begin
  ShowPageMain;
end;

procedure TMainShellForm.BtnNavAnalyticsClick(Sender: TObject);
begin
  ShowPageAnalytics;
end;

procedure TMainShellForm.BtnNavSettingsClick(Sender: TObject);
begin
  ShowPageSettings;
end;

procedure TMainShellForm.CmbAccountsChange(Sender: TObject);
begin
  if (cmbAccounts.ItemIndex < 0) or (cmbAccounts.ItemIndex > High(FAccounts)) then
    Exit;
  FCurrentAccountId := FAccounts[cmbAccounts.ItemIndex].Id;
  RepoSetActiveAccountId(FCurrentAccountId);
  ApplyAccountToPages;
end;

procedure TMainShellForm.HandleDataChanged(Sender: TObject);
begin
  LoadAccounts;
  EnsureActiveAccount;
  ApplyAccountToPages;
end;

end.
