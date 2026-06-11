unit Finance.Repository;

interface

uses
  System.Classes,
  Finance.Types;

function RepoGetActiveAccountId: Int64;
procedure RepoSetActiveAccountId(const AAccountId: Int64);

procedure RepoLoadAccounts(out AAccounts: TAccountArray);
function RepoAddAccount(const AName: string; out ANewId: Int64): Boolean;
function RepoDeleteAccount(const AAccountId: Int64; out ADeletedTxCount: Integer): Boolean;

procedure RepoLoadTransactionsForAccount(var AHead: PListNode;
  const AAccountId: Int64);
procedure RepoLoadAllTransactions(var AHead: PListNode);
procedure RepoInsertTransaction(var ARec: TTransactionRec);
procedure RepoUpdateTransaction(const ARec: TTransactionRec);
procedure RepoDeleteTransaction(const AId: Int64);

procedure RepoFillCategories(const AIsIncome: Boolean; Target: TStrings);
procedure RepoEnsureCategory(const AIsIncome: Boolean; const AName: string);
procedure RepoDeleteCategory(const AIsIncome: Boolean; const AName: string);
procedure RepoFillFilterCategories(Target: TStrings);

function RepoGetAnalyticsScope: string;
procedure RepoSetAnalyticsScope(const AScope: string);

procedure RepoExportCsv(const APath: string; const AOnlyActive: Boolean;
  const AActiveAccountId: Int64);
procedure RepoImportCsv(const APath: string; out AImported, ASkipped: Integer);

implementation

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  Finance.Db,
  Finance.TransactionList,
  Finance.Strings;

procedure ExecKV(const AKey, AValue: string);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DbConnection;
    Q.SQL.Text := 'UPDATE app_settings SET value = :v WHERE key = :k';
    Q.ParamByName('k').AsString := AKey;
    Q.ParamByName('v').AsString := AValue;
    Q.ExecSQL;
    if Q.RowsAffected = 0 then
    begin
      Q.SQL.Text :=
        'INSERT OR IGNORE INTO app_settings(key, value) VALUES(:k, :v)';
      Q.ParamByName('k').AsString := AKey;
      Q.ParamByName('v').AsString := AValue;
      Q.ExecSQL;
    end;
  finally
    Q.Free;
  end;
end;

function ReadKV(const AKey, ADefault: string): string;
var
  Q: TFDQuery;
begin
  Result := ADefault;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DbConnection;
    Q.SQL.Text := 'SELECT value FROM app_settings WHERE key = :k';
    Q.ParamByName('k').AsString := AKey;
    Q.Open;
    if not Q.Eof then
      Result := Q.Fields[0].AsString;
  finally
    Q.Free;
  end;
end;

function RepoGetActiveAccountId: Int64;
var
  S: string;
begin
  S := ReadKV(REPO_KEY_ACTIVE_ACCOUNT_ID, '0');
  Result := StrToInt64Def(S, 0);
end;

procedure RepoSetActiveAccountId(const AAccountId: Int64);
begin
  ExecKV(REPO_KEY_ACTIVE_ACCOUNT_ID, IntToStr(AAccountId));
end;

procedure RepoLoadAccounts(out AAccounts: TAccountArray);
var
  Q: TFDQuery;
  N: Integer;
begin
  SetLength(AAccounts, 0);
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DbConnection;
    Q.SQL.Text := 'SELECT id, name FROM accounts ORDER BY id';
    Q.Open;
    while not Q.Eof do
    begin
      N := Length(AAccounts);
      SetLength(AAccounts, N + 1);
      AAccounts[N].Id := Q.FieldByName('id').AsLargeInt;
      AAccounts[N].Name := Q.FieldByName('name').AsString;
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function RepoAddAccount(const AName: string; out ANewId: Int64): Boolean;
var
  V: string;
  Q: TFDQuery;
begin
  ANewId := 0;
  V := Trim(AName);
  if V = '' then
    Exit(False);

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DbConnection;
    Q.SQL.Text := 'INSERT OR IGNORE INTO accounts(name, created_at) ' +
      'VALUES(:name, :dt)';
    Q.ParamByName('name').AsString := V;
    Q.ParamByName('dt').AsString := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
    Q.ExecSQL;
    if Q.RowsAffected = 0 then
      Exit(False);

    Q.Close;
    Q.SQL.Text := 'SELECT id FROM accounts WHERE name = :name LIMIT 1';
    Q.ParamByName('name').AsString := V;
    Q.Open;
    if not Q.Eof then
      ANewId := Q.Fields[0].AsLargeInt;
  finally
    Q.Free;
  end;
  Result := ANewId > 0;
end;

function RepoDeleteAccount(const AAccountId: Int64;
  out ADeletedTxCount: Integer): Boolean;
var
  Q: TFDQuery;
begin
  Result := False;
  ADeletedTxCount := 0;
  if AAccountId <= 0 then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DbConnection;

    Q.SQL.Text := 'SELECT COUNT(*) FROM transactions WHERE account_id = :id';
    Q.ParamByName('id').AsLargeInt := AAccountId;
    Q.Open;
    if not Q.Eof then
      ADeletedTxCount := Q.Fields[0].AsInteger;

    Q.Close;
    Q.SQL.Text := 'DELETE FROM transactions WHERE account_id = :id';
    Q.ParamByName('id').AsLargeInt := AAccountId;
    Q.ExecSQL;

    Q.Close;
    Q.SQL.Text := 'DELETE FROM accounts WHERE id = :id';
    Q.ParamByName('id').AsLargeInt := AAccountId;
    Q.ExecSQL;
    Result := Q.RowsAffected > 0;
  finally
    Q.Free;
  end;
end;

function FindAccountIdByName(const AName: string): Int64;
var
  Q: TFDQuery;
begin
  Result := 0;
  if Trim(AName) = '' then
    Exit;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DbConnection;
    Q.SQL.Text := 'SELECT id FROM accounts WHERE name = :name LIMIT 1';
    Q.ParamByName('name').AsString := Trim(AName);
    Q.Open;
    if not Q.Eof then
      Result := Q.Fields[0].AsLargeInt;
  finally
    Q.Free;
  end;
end;

procedure AppendRec(var AHead: PListNode; const ARec: TTransactionRec);
begin
  ListAddToEnd(AHead, ARec);
end;

procedure LoadTxBySql(var AHead: PListNode; const ASql: string;
  const AParamAccountId: Int64; const AUseParam: Boolean);
var
  Q: TFDQuery;
  R: TTransactionRec;
const
  TX_SELECT =
    'SELECT t.id, t.account_id, t.date_str, t.is_income, ' +
    'CASE WHEN t.category_id IS NOT NULL THEN c.name ELSE t.category END AS category, ' +
    't.description, t.amount ' +
    'FROM transactions t LEFT JOIN categories c ON c.id = t.category_id ';
begin
  ListDispose(AHead);
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DbConnection;
    Q.SQL.Text := TX_SELECT + ASql;
    if AUseParam then
      Q.ParamByName('account_id').AsLargeInt := AParamAccountId;
    Q.Open;
    while not Q.Eof do
    begin
      R := Default(TTransactionRec);
      R.Id := Q.FieldByName('id').AsLargeInt;
      R.AccountId := Q.FieldByName('account_id').AsLargeInt;
      R.DateStr := Q.FieldByName('date_str').AsString;
      R.IsIncome := Q.FieldByName('is_income').AsInteger = 1;
      R.Category := Q.FieldByName('category').AsString;
      R.Description := Q.FieldByName('description').AsString;
      R.Amount := Q.FieldByName('amount').AsFloat;
      AppendRec(AHead, R);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure RepoLoadTransactionsForAccount(var AHead: PListNode;
  const AAccountId: Int64);
begin
  LoadTxBySql(AHead,
    'WHERE t.account_id = :account_id ORDER BY t.id',
    AAccountId, True);
end;

procedure RepoLoadAllTransactions(var AHead: PListNode);
begin
  LoadTxBySql(AHead, 'ORDER BY t.id', 0, False);
end;

procedure RepoResolveCategoryForSave(const AIsIncome: Boolean;
  const AName: string; out ACategoryId: Int64; out ACategoryName: string);
var
  Q: TFDQuery;
  V: string;
  Flag: Integer;
begin
  ACategoryId := 0;
  ACategoryName := Trim(AName);
  if ACategoryName = '' then
    Exit;
  if AIsIncome then
    Flag := 1
  else
    Flag := 0;
  RepoEnsureCategory(AIsIncome, ACategoryName);
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DbConnection;
    Q.SQL.Text :=
      'SELECT id, name FROM categories WHERE is_income = :f AND ' +
      'lower(trim(name)) = lower(trim(:n)) LIMIT 1';
    Q.ParamByName('f').AsInteger := Flag;
    Q.ParamByName('n').AsString := ACategoryName;
    Q.Open;
    if not Q.Eof then
    begin
      ACategoryId := Q.FieldByName('id').AsLargeInt;
      ACategoryName := Q.FieldByName('name').AsString;
    end;
  finally
    Q.Free;
  end;
end;

procedure RepoInsertTransaction(var ARec: TTransactionRec);
var
  Q: TFDQuery;
  CatId: Int64;
  CatName: string;
begin
  RepoResolveCategoryForSave(ARec.IsIncome, ARec.Category, CatId, CatName);
  if CatId <= 0 then
    raise Exception.Create(TX_ERR_CATEGORY_NOT_FOUND);
  ARec.Category := CatName;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DbConnection;
    Q.SQL.Text :=
      'INSERT INTO transactions(account_id, date_str, is_income, category, category_id, description, amount, created_at) '
      + 'VALUES(:account_id, :date_str, :is_income, :category, :category_id, :description, :amount, :created_at)';
    Q.ParamByName('account_id').AsLargeInt := ARec.AccountId;
    Q.ParamByName('date_str').AsString := ARec.DateStr;
    if ARec.IsIncome then
      Q.ParamByName('is_income').AsInteger := 1
    else
      Q.ParamByName('is_income').AsInteger := 0;
    Q.ParamByName('category').AsString := CatName;
    Q.ParamByName('category_id').AsLargeInt := CatId;
    Q.ParamByName('description').AsString := ARec.Description;
    Q.ParamByName('amount').AsFloat := ARec.Amount;
    Q.ParamByName('created_at').AsString :=
      FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
    Q.ExecSQL;

    Q.Close;
    Q.SQL.Text := 'SELECT last_insert_rowid()';
    Q.Open;
    if not Q.Eof then
      ARec.Id := Q.Fields[0].AsLargeInt;
  finally
    Q.Free;
  end;
end;

procedure RepoUpdateTransaction(const ARec: TTransactionRec);
var
  Q: TFDQuery;
  CatId: Int64;
  CatName: string;
begin
  RepoResolveCategoryForSave(ARec.IsIncome, ARec.Category, CatId, CatName);
  if CatId <= 0 then
    raise Exception.Create(TX_ERR_CATEGORY_NOT_FOUND);
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DbConnection;
    Q.SQL.Text :=
      'UPDATE transactions SET account_id=:account_id, date_str=:date_str, ' +
      'is_income=:is_income, category=:category, category_id=:category_id, ' +
      'description=:description, amount=:amount WHERE id=:id';
    Q.ParamByName('account_id').AsLargeInt := ARec.AccountId;
    Q.ParamByName('date_str').AsString := ARec.DateStr;
    if ARec.IsIncome then
      Q.ParamByName('is_income').AsInteger := 1
    else
      Q.ParamByName('is_income').AsInteger := 0;
    Q.ParamByName('category').AsString := CatName;
    Q.ParamByName('category_id').AsLargeInt := CatId;
    Q.ParamByName('description').AsString := ARec.Description;
    Q.ParamByName('amount').AsFloat := ARec.Amount;
    Q.ParamByName('id').AsLargeInt := ARec.Id;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure RepoDeleteTransaction(const AId: Int64);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DbConnection;
    Q.SQL.Text := 'DELETE FROM transactions WHERE id = :id';
    Q.ParamByName('id').AsLargeInt := AId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure RepoFillCategories(const AIsIncome: Boolean; Target: TStrings);
var
  Q: TFDQuery;
  V: Integer;
begin
  Target.Clear;
  if AIsIncome then
    V := 1
  else
    V := 0;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DbConnection;
    Q.SQL.Text :=
      'SELECT name FROM categories WHERE is_income = :v ORDER BY name';
    Q.ParamByName('v').AsInteger := V;
    Q.Open;
    while not Q.Eof do
    begin
      Target.Add(Q.Fields[0].AsString);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure RepoEnsureCategory(const AIsIncome: Boolean; const AName: string);
var
  Q: TFDQuery;
  V: string;
  Flag: Integer;
begin
  V := Trim(AName);
  if V = '' then
    Exit;
  if AIsIncome then
    Flag := 1
  else
    Flag := 0;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DbConnection;
    Q.SQL.Text :=
      'INSERT OR IGNORE INTO categories(name, is_income) VALUES(:n, :f)';
    Q.ParamByName('n').AsString := V;
    Q.ParamByName('f').AsInteger := Flag;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure RepoDeleteCategory(const AIsIncome: Boolean; const AName: string);
var
  Q: TFDQuery;
  V: string;
  Flag: Integer;
begin
  V := Trim(AName);
  if V = '' then
    Exit;
  if AIsIncome then
    Flag := 1
  else
    Flag := 0;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DbConnection;
    Q.SQL.Text :=
      'DELETE FROM categories WHERE is_income = :f AND LOWER(TRIM(name)) = LOWER(TRIM(:n))';
    Q.ParamByName('f').AsInteger := Flag;
    Q.ParamByName('n').AsString := V;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure RepoFillFilterCategories(Target: TStrings);
var
  Q: TFDQuery;
begin
  Target.Clear;
  Target.Add(REPO_FILTER_ALL);
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DbConnection;
    Q.SQL.Text := 'SELECT DISTINCT name FROM categories ORDER BY name';
    Q.Open;
    while not Q.Eof do
    begin
      Target.Add(Q.Fields[0].AsString);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function RepoGetAnalyticsScope: string;
begin
  Result := ReadKV(REPO_KEY_ANALYTICS_SCOPE, REPO_SCOPE_ACTIVE);
  if not SameText(Result, REPO_SCOPE_ALL) then
    Result := REPO_SCOPE_ACTIVE;
end;

procedure RepoSetAnalyticsScope(const AScope: string);
begin
  if SameText(AScope, REPO_SCOPE_ALL) then
    ExecKV(REPO_KEY_ANALYTICS_SCOPE, REPO_SCOPE_ALL)
  else
    ExecKV(REPO_KEY_ANALYTICS_SCOPE, REPO_SCOPE_ACTIVE);
end;

procedure CsvWriteEscaped(Writer: TStreamWriter; const S: string;
  const Last: Boolean);
var
  E: string;
begin
  E := StringReplace(S, '"', '""', [rfReplaceAll]);
  Writer.Write('"' + E + '"');
  if not Last then
    Writer.Write(',');
end;

procedure RepoExportCsv(const APath: string; const AOnlyActive: Boolean;
  const AActiveAccountId: Int64);
var
  Q: TFDQuery;
  Writer: TStreamWriter;
begin
  Q := TFDQuery.Create(nil);
  Writer := TStreamWriter.Create(APath, False, TEncoding.UTF8);
  try
    Q.Connection := DbConnection;
    if AOnlyActive then
    begin
      Q.SQL.Text :=
        'SELECT t.date_str, t.is_income, COALESCE(c.name, t.category) category, ' +
        't.description, t.amount, a.name account_name ' +
        'FROM transactions t JOIN accounts a ON a.id=t.account_id ' +
        'LEFT JOIN categories c ON c.id=t.category_id ' +
        'WHERE t.account_id=:id ORDER BY t.id';
      Q.ParamByName('id').AsLargeInt := AActiveAccountId;
    end
    else
      Q.SQL.Text :=
        'SELECT t.date_str, t.is_income, COALESCE(c.name, t.category) category, ' +
        't.description, t.amount, a.name account_name ' +
        'FROM transactions t JOIN accounts a ON a.id=t.account_id ' +
        'LEFT JOIN categories c ON c.id=t.category_id ORDER BY t.id';
    Q.Open;

    Writer.WriteLine(REPO_CSV_HEADER);
    while not Q.Eof do
    begin
      CsvWriteEscaped(Writer, Q.FieldByName('date_str').AsString, False);
      CsvWriteEscaped(Writer, Q.FieldByName('is_income').AsString, False);
      CsvWriteEscaped(Writer, Q.FieldByName('category').AsString, False);
      CsvWriteEscaped(Writer, Q.FieldByName('description').AsString, False);
      CsvWriteEscaped(Writer, FormatFloat(AMOUNT_FORMAT, Q.FieldByName('amount')
        .AsFloat), False);
      CsvWriteEscaped(Writer, Q.FieldByName('account_name').AsString, True);
      Writer.WriteLine;
      Q.Next;
    end;
  finally
    Writer.Free;
    Q.Free;
  end;
end;

function CsvSplit(const Line: string): TStringList;
var
  I: Integer;
  C: Char;
  InQ: Boolean;
  Cur: string;
begin
  Result := TStringList.Create;
  Result.StrictDelimiter := True;
  InQ := False;
  Cur := '';
  I := 1;
  while I <= Length(Line) do
  begin
    C := Line[I];
    if C = '"' then
    begin
      if InQ and (I < Length(Line)) and (Line[I + 1] = '"') then
      begin
        Cur := Cur + '"';
        Inc(I);
      end
      else
        InQ := not InQ;
    end
    else if (C = ',') and (not InQ) then
    begin
      Result.Add(Cur);
      Cur := '';
    end
    else
      Cur := Cur + C;
    Inc(I);
  end;
  Result.Add(Cur);
end;

procedure RepoImportCsv(const APath: string; out AImported, ASkipped: Integer);
var
  Reader: TStreamReader;
  Line: string;
  Parts: TStringList;
  Tx: TTransactionRec;
  FS: TFormatSettings;
  SAmount: string;
  AccountName: string;
  AccountId: Int64;
  IsIncome: Boolean;
begin
  AImported := 0;
  ASkipped := 0;
  if not FileExists(APath) then
    Exit;

  Reader := TStreamReader.Create(APath, TEncoding.UTF8);
  try
    if not Reader.EndOfStream then
      Reader.ReadLine;
    FS := TFormatSettings.Create;
    FS.DecimalSeparator := '.';
    while not Reader.EndOfStream do
    begin
      Line := Reader.ReadLine;
      if Trim(Line) = '' then
        Continue;
      Parts := CsvSplit(Line);
      try
        if Parts.Count <> 6 then
        begin
          Inc(ASkipped);
          Continue;
        end;
        Tx := Default(TTransactionRec);
        Tx.DateStr := Trim(Parts[0]);
        IsIncome := Trim(Parts[1]) = REPO_CSV_BOOL_TRUE;
        Tx.IsIncome := IsIncome;
        Tx.Category := Trim(Parts[2]);
        Tx.Description := Trim(Parts[3]);
        SAmount := StringReplace(Trim(Parts[4]), ',', '.', [rfReplaceAll]);
        if not TryStrToFloat(SAmount, Tx.Amount, FS) then
        begin
          Inc(ASkipped);
          Continue;
        end;
        if Tx.Amount <= 0 then
        begin
          Inc(ASkipped);
          Continue;
        end;
        AccountName := Trim(Parts[5]);
        if AccountName = '' then
          AccountName := REPO_DEFAULT_ACCOUNT_NAME;
        if not RepoAddAccount(AccountName, AccountId) then
          AccountId := FindAccountIdByName(AccountName);
        if AccountId <= 0 then
        begin
          Inc(ASkipped);
          Continue;
        end;
        Tx.AccountId := AccountId;
        RepoInsertTransaction(Tx);
        Inc(AImported);
      finally
        Parts.Free;
      end;
    end;
  finally
    Reader.Free;
  end;
end;

end.
