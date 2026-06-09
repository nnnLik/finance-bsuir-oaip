unit Finance.Categories;

interface

uses
  System.Classes;

procedure CategoriesLoad;
procedure FillIncomeCategories(Target: TStrings);
procedure FillExpenseCategories(Target: TStrings);
procedure FillFilterCategories(Target: TStrings);
procedure EnsureUserCategory(const IsIncome: Boolean; const Name: string);

implementation

uses
  Finance.Db,
  Finance.Repository;

procedure CategoriesLoad;
begin
  DbInit;
end;

procedure FillIncomeCategories(Target: TStrings);
begin
  CategoriesLoad;
  RepoFillCategories(True, Target);
end;

procedure FillExpenseCategories(Target: TStrings);
begin
  CategoriesLoad;
  RepoFillCategories(False, Target);
end;

procedure FillFilterCategories(Target: TStrings);
begin
  CategoriesLoad;
  RepoFillFilterCategories(Target);
end;

procedure EnsureUserCategory(const IsIncome: Boolean; const Name: string);
begin
  CategoriesLoad;
  RepoEnsureCategory(IsIncome, Name);
end;

end.
