unit Finance.Db;

interface

uses
  FireDAC.Comp.Client;

procedure DbInit;
function DbConnection: TFDConnection;
procedure DbClose;

implementation

uses
  System.SysUtils,
  System.Classes,
  FireDAC.UI.Intf,
  FireDAC.VCLUI.Wait,
  FireDAC.Stan.Param,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.DApt,
  Finance.Types,
  Finance.Strings;

var
  GConn: TFDConnection;
  GInited: Boolean;

function DbPath: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    DEFAULT_DB_FILE;
end;

function IsoNow: string;
begin
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
end;

procedure ExecSQL(const ASQL: string);
begin
  GConn.ExecSQL(ASQL);
end;

function ScalarInt64(const ASQL: string): Int64;
var
  Q: TFDQuery;
  S: string;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := GConn;
    Q.SQL.Text := ASQL;
    Q.Open;
    if Q.Fields[0].IsNull then
      Result := 0
    else
    begin
      S := Trim(Q.Fields[0].AsString);
      Result := StrToInt64Def(S, 0);
    end;
  finally
    Q.Free;
  end;
end;

procedure EnsureSchema;
begin
  ExecSQL('CREATE TABLE IF NOT EXISTS accounts (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT,' + 'name TEXT NOT NULL UNIQUE,' +
    'created_at TEXT NOT NULL)');

  ExecSQL('CREATE TABLE IF NOT EXISTS categories (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT,' + 'name TEXT NOT NULL,' +
    'is_income INTEGER NOT NULL,' + 'UNIQUE(name, is_income))');

  ExecSQL('CREATE TABLE IF NOT EXISTS transactions (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT,' + 'account_id INTEGER NOT NULL,' +
    'date_str TEXT NOT NULL,' + 'is_income INTEGER NOT NULL,' +
    'category TEXT NOT NULL,' + 'description TEXT NOT NULL,' +
    'amount REAL NOT NULL,' + 'created_at TEXT NOT NULL,' +
    'FOREIGN KEY(account_id) REFERENCES accounts(id))');

  ExecSQL('CREATE TABLE IF NOT EXISTS app_settings (' + 'key TEXT PRIMARY KEY,'
    + 'value TEXT NOT NULL)');
end;

procedure EnsureDefaultAccountAndSettings;
var
  MainId: Int64;
begin
  ExecSQL('INSERT OR IGNORE INTO accounts(name, created_at) VALUES (' +
    QuotedStr(REPO_DEFAULT_ACCOUNT_NAME) + ', ' + QuotedStr(IsoNow) + ')');
  MainId := ScalarInt64('SELECT id FROM accounts WHERE name = ' +
    QuotedStr(REPO_DEFAULT_ACCOUNT_NAME) + ' LIMIT 1');
  if MainId <= 0 then
    Exit;
  ExecSQL('INSERT OR IGNORE INTO app_settings(key, value) VALUES (' +
    QuotedStr(REPO_KEY_ACTIVE_ACCOUNT_ID) + ', ' +
    QuotedStr(IntToStr(MainId)) + ')');
  ExecSQL('INSERT OR IGNORE INTO app_settings(key, value) VALUES (' +
    QuotedStr(REPO_KEY_ANALYTICS_SCOPE) + ', ' +
    QuotedStr(REPO_SCOPE_ACTIVE) + ')');
end;

procedure EnsureDefaultCategories;
var
  I: Integer;
begin
  for I := Low(DEFAULT_INCOME_CATEGORIES) to High(DEFAULT_INCOME_CATEGORIES) do
    ExecSQL('INSERT OR IGNORE INTO categories(name, is_income) VALUES (' +
      QuotedStr(DEFAULT_INCOME_CATEGORIES[I]) + ', 1)');
  for I := Low(DEFAULT_EXPENSE_CATEGORIES)
    to High(DEFAULT_EXPENSE_CATEGORIES) do
    ExecSQL('INSERT OR IGNORE INTO categories(name, is_income) VALUES (' +
      QuotedStr(DEFAULT_EXPENSE_CATEGORIES[I]) + ', 0)');
end;

procedure DbInit;
begin
  if GInited then
    Exit;

  GConn := TFDConnection.Create(nil);
  try
    GConn.LoginPrompt := False;
    GConn.Params.Clear;
    GConn.Params.Add('DriverID=SQLite');
    GConn.Params.Add('Database=' + DbPath);
    GConn.Params.Add('LockingMode=Normal');
    GConn.Params.Add('Synchronous=Normal');
    GConn.Params.Add('JournalMode=WAL');
    GConn.Params.Add('OpenMode=CreateUTF8');
    GConn.Connected := True;

    EnsureSchema;
    EnsureDefaultAccountAndSettings;
    EnsureDefaultCategories;

    GInited := True;
  except
    GConn.Free;
    GConn := nil;
    raise;
  end;
end;

function DbConnection: TFDConnection;
begin
  DbInit;
  Result := GConn;
end;

procedure DbClose;
begin
  FreeAndNil(GConn);
  GInited := False;
end;

end.
