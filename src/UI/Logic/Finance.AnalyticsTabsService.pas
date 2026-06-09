unit Finance.AnalyticsTabsService;

interface

type
  TOverviewAnalyticsData = record
    IncomeTotal: Double;
    ExpenseTotal: Double;
    Balance: Double;
    TxCount: Integer;
  end;

  TCategoryChartPoint = record
    Name: string;
    Value: Double;
  end;

  TCategoryChartPointArray = array of TCategoryChartPoint;

  TMonthlyTrendPoint = record
    Year: Word;
    Month: Word;
    IncomeTotal: Double;
    ExpenseTotal: Double;
  end;

  TMonthlyTrendPointArray = array of TMonthlyTrendPoint;

procedure BuildOverview(const Scope: string; const ActiveAccountId: Int64;
  out AData: TOverviewAnalyticsData);
procedure BuildExpenseCategories(const Scope: string; const ActiveAccountId: Int64;
  out AData: TCategoryChartPointArray);
procedure BuildIncomeCategories(const Scope: string; const ActiveAccountId: Int64;
  out AData: TCategoryChartPointArray);
procedure BuildMonthlyTrends(const Scope: string; const ActiveAccountId: Int64;
  out AData: TMonthlyTrendPointArray);

implementation

uses
  System.SysUtils,
  System.DateUtils,
  Finance.Types,
  Finance.Strings,
  Finance.Repository,
  Finance.TransactionList,
  Finance.DateUtils;

procedure LoadByScope(const Scope: string; const ActiveAccountId: Int64;
  var AHead: PListNode);
begin
  if SameText(Scope, REPO_SCOPE_ALL) then
    RepoLoadAllTransactions(AHead)
  else
    RepoLoadTransactionsForAccount(AHead, ActiveAccountId);
end;

procedure SortCategoriesByValueDesc(var AData: TCategoryChartPointArray);
var
  I, J: Integer;
  Tmp: TCategoryChartPoint;
begin
  for I := 0 to High(AData) - 1 do
    for J := I + 1 to High(AData) do
      if AData[J].Value > AData[I].Value then
      begin
        Tmp := AData[I];
        AData[I] := AData[J];
        AData[J] := Tmp;
      end;
end;

procedure BuildOverview(const Scope: string; const ActiveAccountId: Int64;
  out AData: TOverviewAnalyticsData);
var
  H: PListNode;
begin
  FillChar(AData, SizeOf(AData), 0);
  H := nil;
  try
    LoadByScope(Scope, ActiveAccountId, H);
    AData.IncomeTotal := ListSumIncome(H);
    AData.ExpenseTotal := ListSumExpense(H);
    AData.Balance := ListCalcBalance(H);
    AData.TxCount := ListCount(H);
  finally
    ListDispose(H);
  end;
end;

procedure BuildCategories(const Scope: string; const ActiveAccountId: Int64;
  const WantIncome: Boolean; out AData: TCategoryChartPointArray);
var
  H, P: PListNode;
  I, N: Integer;
  Cat: string;
begin
  SetLength(AData, 0);
  H := nil;
  try
    LoadByScope(Scope, ActiveAccountId, H);
    P := H;
    while P <> nil do
    begin
      if P^.Data.IsIncome = WantIncome then
      begin
        Cat := Trim(string(P^.Data.Category));
        if Cat = '' then
          Cat := ANALYTICS_EMPTY_CATEGORY;
        I := 0;
        while (I < Length(AData)) and not SameText(AData[I].Name, Cat) do
          Inc(I);
        if I >= Length(AData) then
        begin
          N := Length(AData);
          SetLength(AData, N + 1);
          AData[N].Name := Cat;
          AData[N].Value := P^.Data.Amount;
        end
        else
          AData[I].Value := AData[I].Value + P^.Data.Amount;
      end;
      P := P^.Next;
    end;
    if Length(AData) > 1 then
      SortCategoriesByValueDesc(AData);
  finally
    ListDispose(H);
  end;
end;

procedure BuildExpenseCategories(const Scope: string; const ActiveAccountId: Int64;
  out AData: TCategoryChartPointArray);
begin
  BuildCategories(Scope, ActiveAccountId, False, AData);
end;

procedure BuildIncomeCategories(const Scope: string; const ActiveAccountId: Int64;
  out AData: TCategoryChartPointArray);
begin
  BuildCategories(Scope, ActiveAccountId, True, AData);
end;

procedure SortMonthsAsc(var AData: TMonthlyTrendPointArray);
var
  I, J: Integer;
  Tmp: TMonthlyTrendPoint;
begin
  for I := 0 to High(AData) - 1 do
    for J := I + 1 to High(AData) do
      if (AData[J].Year < AData[I].Year) or
        ((AData[J].Year = AData[I].Year) and (AData[J].Month < AData[I].Month))
      then
      begin
        Tmp := AData[I];
        AData[I] := AData[J];
        AData[J] := Tmp;
      end;
end;

procedure BuildMonthlyTrends(const Scope: string; const ActiveAccountId: Int64;
  out AData: TMonthlyTrendPointArray);
var
  H, P: PListNode;
  Dt: TDateTime;
  Y, M: Word;
  I, N, StartIdx: Integer;
begin
  SetLength(AData, 0);
  H := nil;
  try
    LoadByScope(Scope, ActiveAccountId, H);
    P := H;
    while P <> nil do
    begin
      if TryParseRuDate(string(P^.Data.DateStr), Dt) then
      begin
        Y := YearOf(Dt);
        M := MonthOf(Dt);
        I := 0;
        while (I < Length(AData)) and
          ((AData[I].Year <> Y) or (AData[I].Month <> M)) do
          Inc(I);
        if I >= Length(AData) then
        begin
          N := Length(AData);
          SetLength(AData, N + 1);
          AData[N].Year := Y;
          AData[N].Month := M;
          AData[N].IncomeTotal := 0;
          AData[N].ExpenseTotal := 0;
          I := N;
        end;
        if P^.Data.IsIncome then
          AData[I].IncomeTotal := AData[I].IncomeTotal + P^.Data.Amount
        else
          AData[I].ExpenseTotal := AData[I].ExpenseTotal + P^.Data.Amount;
      end;
      P := P^.Next;
    end;
    if Length(AData) > 1 then
      SortMonthsAsc(AData);
    if Length(AData) > 6 then
    begin
      StartIdx := Length(AData) - 6;
      for I := 0 to 5 do
        AData[I] := AData[StartIdx + I];
      SetLength(AData, 6);
    end;
  finally
    ListDispose(H);
  end;
end;

end.
