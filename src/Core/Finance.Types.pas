unit Finance.Types;

interface

const
  DEFAULT_DB_FILE = 'finance.db';

type
  TTransactionRec = packed record
    Id: Int64;
    AccountId: Int64;
    DateStr: string[20];
    IsIncome: Boolean;
    Category: string[40];
    Description: string[100];
    Amount: Double;
  end;

  PListNode = ^TListNode;

  TListNode = record
    Data: TTransactionRec;
    Next: PListNode;
  end;

  TAccountRec = record
    Id: Int64;
    Name: string;
  end;

  TAccountArray = array of TAccountRec;

implementation

end.
