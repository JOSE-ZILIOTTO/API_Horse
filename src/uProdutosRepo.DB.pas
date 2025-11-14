unit uProdutosRepo.DB;

interface

uses
  uProdutosController, System.SysUtils, DataSet.Serialize;

type
  TDBProductRepo = class(TInterfacedObject, IProductRepo)
  public
    function FindParamsById(const AId: Int64): string;
    function FindParamsByCode(const ACode: integer): string;
    function ListAllPages(APage, APageSize: Int64): string;
    function ListAll: string;
  end;

implementation

uses
  FireDAC.Comp.Client, System.JSON, uDB, System.Generics.Collections, Data.DB;

function RowsetParamsToJson(AQ: TFDQuery; const AProdId: Int64): string;
var
  Obj: TJSONObject;
  I: integer;
begin

  Obj := TJSONObject.Create(nil);
  Obj := AQ.ToJSONObject();

  // Obj.AddPair('uid', AQ.FieldByName('UID').AsString);
  // Obj.AddPair('descricao', AQ.FieldByName('DESCRICAO').AsString);
  // Obj.AddPair('cod_produto', AQ.FieldByName('COD_PRODUTO').AsString);
  // Obj.AddPair('valor_venda', TJSONNumber.Create(AQ.FieldByName('VALOR_VENDA$').AsFloat));
  Result := Obj.ToJSON;
  Obj.Free;
end;

function TDBProductRepo.FindParamsById(const AId: Int64): string;
var
  Q: TFDQuery;
begin
  Result := '';
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FDConn;
    Q.SQL.Text := 'select * from VIEW_PRODUTOS where UID = :UID';
    Q.ParamByName('UID').DataType := ftLargeInt;
    Q.ParamByName('UID').AsLargeInt := AId;
    Q.Open;
    if Q.IsEmpty then
      Exit;
    Result := RowsetParamsToJson(Q, AId);
  finally
    Q.Free;
  end;
end;

function TDBProductRepo.FindParamsByCode(const ACode: integer): string;
var
  Q: TFDQuery;
  LId: Int64;
  LCode: string;
begin
  Result := '';

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FDConn;
    Q.SQL.Text := 'select * from VIEW_PRODUTOS where COD_PRODUTO = :COD_PRODUTO';
    Q.ParamByName('COD_PRODUTO').DataType := ftLargeInt;
    Q.ParamByName('COD_PRODUTO').Asinteger := ACode;
    Q.Open;
    if Q.IsEmpty then
      Exit;
    Result := RowsetParamsToJson(Q, ACode);
  finally
    Q.Free;
  end;
end;

function TDBProductRepo.ListAll: string;
var
  Query: TFDQuery;
  Items: TJSONArray;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FDConn;
    Query.SQL.Text := 'select * from VIEW_PRODUTOS order by UID';
    Query.Open;

    Items := Query.ToJSONArray;
    try
      Result := Items.ToString;
    finally
      Items.Free;
    end;

  finally
    Query.Free;
  end;
end;

function TDBProductRepo.ListAllPages(APage, APageSize: Int64): string;
var
  Query: TFDQuery;
  Ids: TList<Int64>;
  Offset: integer;
  Arr: TJSONArray;
  Obj: TJSONObject;
  IdValue: Int64;
  PageInt, PageSizeInt: integer;
begin
  Query := TFDQuery.Create(nil);
  Ids := TList<Int64>.Create;
  try
    Query.Connection := FDConn;

    if APage < 1 then
      PageInt := 1
    else
      PageInt := APage;
    if APageSize <= 0 then
      PageSizeInt := 1
    else
      PageSizeInt := APageSize;

    Offset := (PageInt - 1) * PageSizeInt;

    // Para usar somente OFFSET a versão do firebird tem que ser superior a 3.0
    Query.SQL.Text := 'select first :PageSize skip :Offset UID ' + 'from VIEW_PRODUTOS order by UID';

    Query.ParamByName('PageSize').Asinteger := PageSizeInt;
    Query.ParamByName('Offset').Asinteger := Offset;
    Query.Open;
    while not Query.Eof do
    begin
      Ids.Add(Query.FieldByName('UID').AsLargeInt);
      Query.Next;
    end;

    Arr := TJSONArray.Create;
    for IdValue in Ids do
    begin
      Query.Close;
      Query.SQL.Text := 'select * from VIEW_PRODUTOS where UID = :UID';
      Query.ParamByName('UID').DataType := ftLargeInt;
      Query.ParamByName('UID').AsLargeInt := IdValue;
      Query.Open;
      Arr.AddElement(TJSONObject.ParseJSONValue(RowsetParamsToJson(Query, IdValue)));
    end;

    Query.Close;
    Query.SQL.Text := 'select count(*) as QUANTIDADE from VIEW_PRODUTOS';
    Query.Open;

    Obj := TJSONObject.Create;
    Obj.AddPair('page', TJSONNumber.Create(APage));
    Obj.AddPair('pageSize', TJSONNumber.Create(APageSize));
    Obj.AddPair('total', TJSONNumber.Create(Query.FieldByName('QUANTIDADE').Asinteger));
    Obj.AddPair('items', Arr);
    Result := Obj.ToJSON;
    Obj.Free;
  finally
    Ids.Free;
    Query.Free;
  end;
end;

end.
