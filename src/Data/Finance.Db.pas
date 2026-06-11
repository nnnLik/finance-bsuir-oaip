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
  FireDAC.Phys.SQLiteWrapper.Stat,
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
    'category TEXT NOT NULL,' + 'category_id INTEGER,' +
    'description TEXT NOT NULL,' + 'amount REAL NOT NULL,' +
    'created_at TEXT NOT NULL,' +
    'FOREIGN KEY(account_id) REFERENCES accounts(id),' +
    'FOREIGN KEY(category_id) REFERENCES categories(id))');

  ExecSQL('CREATE TABLE IF NOT EXISTS app_settings (' + 'key TEXT PRIMARY KEY,'
    + 'value TEXT NOT NULL)');
end;

procedure EnsureDefaultAccountAndSettings;
var
  Q: TFDQuery;
  MainId: Int64;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := GConn;
    Q.SQL.Text :=
      'INSERT OR IGNORE INTO accounts(name, created_at) VALUES (:n, :dt)';
    Q.ParamByName('n').AsString := REPO_DEFAULT_ACCOUNT_NAME;
    Q.ParamByName('dt').AsString := IsoNow;
    Q.ExecSQL;
  finally
    Q.Free;
  end;

  MainId := ScalarInt64('SELECT id FROM accounts WHERE name = ' +
    QuotedStr(REPO_DEFAULT_ACCOUNT_NAME) + ' LIMIT 1');
  if MainId <= 0 then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := GConn;
    Q.SQL.Text :=
      'INSERT OR IGNORE INTO app_settings(key, value) VALUES (:k, :v)';
    Q.ParamByName('k').AsString := REPO_KEY_ACTIVE_ACCOUNT_ID;
    Q.ParamByName('v').AsString := IntToStr(MainId);
    Q.ExecSQL;
    Q.ParamByName('k').AsString := REPO_KEY_ANALYTICS_SCOPE;
    Q.ParamByName('v').AsString := REPO_SCOPE_ACTIVE;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure InsertDefaultCategory(const AName: string; AIsIncome: Integer);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := GConn;
    Q.SQL.Text :=
      'INSERT OR IGNORE INTO categories(name, is_income) VALUES (:n, :f)';
    Q.ParamByName('n').AsString := AName;
    Q.ParamByName('f').AsInteger := AIsIncome;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure EnsureDefaultCategories;
var
  I: Integer;
begin
  for I := Low(DEFAULT_INCOME_CATEGORIES) to High(DEFAULT_INCOME_CATEGORIES) do
    InsertDefaultCategory(DEFAULT_INCOME_CATEGORIES[I], 1);
  for I := Low(DEFAULT_EXPENSE_CATEGORIES)
    to High(DEFAULT_EXPENSE_CATEGORIES) do
    InsertDefaultCategory(DEFAULT_EXPENSE_CATEGORIES[I], 0);
end;

function HasTableColumn(const ATable, AColumn: string): Boolean;
var
  Q: TFDQuery;
begin
  Result := False;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := GConn;
    Q.SQL.Text := 'PRAGMA table_info(' + ATable + ')';
    Q.Open;
    while not Q.Eof do
    begin
      if SameText(Q.FieldByName('name').AsString, AColumn) then
        Exit(True);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure EnsureCategoryIdColumn;
begin
  if HasTableColumn('transactions', 'category_id') then
    Exit;
  ExecSQL('ALTER TABLE transactions ADD COLUMN category_id INTEGER ' +
    'REFERENCES categories(id)');
end;

procedure RepairTransactionCategories;
begin
  ExecSQL(
    'UPDATE transactions SET category_id = (' +
    'SELECT c.id FROM categories c ' +
    'WHERE c.is_income = transactions.is_income AND ' +
    'lower(trim(c.name)) = lower(trim(transactions.category)) ' +
    'LIMIT 1) WHERE category_id IS NULL OR category_id NOT IN ' +
    '(SELECT id FROM categories)');
  ExecSQL(
    'UPDATE transactions SET category_id = (' +
    'SELECT c.id FROM categories c WHERE c.is_income = transactions.is_income ' +
    'ORDER BY c.id LIMIT 1) WHERE category_id IS NULL');
  ExecSQL(
    'UPDATE transactions SET category = (' +
    'SELECT c.name FROM categories c WHERE c.id = transactions.category_id) ' +
    'WHERE category_id IS NOT NULL');
end;

function ReadSetting(const AKey, ADefault: string): string;
var
  Q: TFDQuery;
begin
  Result := ADefault;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := GConn;
    Q.SQL.Text := 'SELECT value FROM app_settings WHERE key = :k';
    Q.ParamByName('k').AsString := AKey;
    Q.Open;
    if not Q.Eof then
      Result := Q.Fields[0].AsString;
  finally
    Q.Free;
  end;
end;

procedure EnsureCategoryEncoding;
var
  Cur: string;
  CurNum: Integer;
begin
  Cur := Trim(ReadSetting(REPO_KEY_ENCODING_VERSION, '1'));
  if SameText(Cur, REPO_ENCODING_VERSION) then
    Exit;
  CurNum := StrToIntDef(Cur, 1);

  if CurNum < 2 then
  begin
    ExecSQL('DELETE FROM categories');
    EnsureDefaultCategories;
  end;

  if CurNum < 3 then
    ExecSQL('DELETE FROM transactions');

  if CurNum < 4 then
  begin
    EnsureCategoryIdColumn;
    RepairTransactionCategories;
  end;

  if CurNum < 5 then
    RepairTransactionCategories;

  ExecSQL('INSERT OR REPLACE INTO app_settings(key, value) VALUES (' +
    QuotedStr(REPO_KEY_ENCODING_VERSION) + ', ' +
    QuotedStr(REPO_ENCODING_VERSION) + ')');
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
    EnsureCategoryEncoding;
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
