unit Finance.DateUtils;

interface

uses
  System.SysUtils;

function TryParseRuDate(const S: string; out V: TDateTime): Boolean;

implementation

function TryParseRuDate(const S: string; out V: TDateTime): Boolean;
var
  P1, P2, D, M, Y, Len: Integer;
  T: string;
begin
  Result := False;
  T := Trim(S);
  if T = '' then
    Exit;
  P1 := Pos('.', T);
  if P1 < 2 then
    Exit;
  P2 := Pos('.', Copy(T, P1 + 1, MaxInt));
  if P2 < 2 then
    Exit;
  P2 := P1 + P2;
  Len := Length(T);
  if P2 >= Len then
    Exit;
  if not TryStrToInt(Copy(T, 1, P1 - 1), D) then
    Exit;
  if not TryStrToInt(Copy(T, P1 + 1, P2 - P1 - 1), M) then
    Exit;
  if not TryStrToInt(Copy(T, P2 + 1, Len - P2), Y) then
    Exit;
  if (D < 1) or (D > 31) or (M < 1) or (M > 12) or (Y < 1900) or (Y > 9999) then
    Exit;
  try
    V := EncodeDate(Y, M, D);
    Result := True;
  except
    Result := False;
  end;
end;

end.
