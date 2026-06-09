unit Finance.TransactionList;

interface

uses
  Finance.Types;

procedure ListDispose(var AHead: PListNode);
procedure ListAddToEnd(var AHead: PListNode; const AData: TTransactionRec);
function ListCalcBalance(AHead: PListNode): Double;
function ListSumIncome(AHead: PListNode): Double;
function ListSumExpense(AHead: PListNode): Double;
function ListCount(AHead: PListNode): Integer;

implementation

procedure ListDispose(var AHead: PListNode);
var
  N, T: PListNode;
begin
  N := AHead;
  while N <> nil do
  begin
    T := N^.Next;
    Dispose(N);
    N := T;
  end;
  AHead := nil;
end;

procedure ListAddToEnd(var AHead: PListNode; const AData: TTransactionRec);
var
  P, Q: PListNode;
begin
  New(P);
  P^.Data := AData;
  P^.Next := nil;
  if AHead = nil then
    AHead := P
  else
  begin
    Q := AHead;
    while Q^.Next <> nil do
      Q := Q^.Next;
    Q^.Next := P;
  end;
end;

function ListCalcBalance(AHead: PListNode): Double;
var
  P: PListNode;
  S: Double;
begin
  S := 0;
  P := AHead;
  while P <> nil do
  begin
    if P^.Data.IsIncome then
      S := S + P^.Data.Amount
    else
      S := S - P^.Data.Amount;
    P := P^.Next;
  end;
  Result := S;
end;

function ListSumIncome(AHead: PListNode): Double;
var
  P: PListNode;
begin
  Result := 0;
  P := AHead;
  while P <> nil do
  begin
    if P^.Data.IsIncome then
      Result := Result + P^.Data.Amount;
    P := P^.Next;
  end;
end;

function ListSumExpense(AHead: PListNode): Double;
var
  P: PListNode;
begin
  Result := 0;
  P := AHead;
  while P <> nil do
  begin
    if not P^.Data.IsIncome then
      Result := Result + P^.Data.Amount;
    P := P^.Next;
  end;
end;

function ListCount(AHead: PListNode): Integer;
var
  P: PListNode;
begin
  Result := 0;
  P := AHead;
  while P <> nil do
  begin
    Inc(Result);
    P := P^.Next;
  end;
end;

end.
