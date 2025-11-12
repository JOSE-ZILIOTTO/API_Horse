unit uProdutosRepo.DB;

interface

uses
  uProdutosController, System.SysUtils;

type
  TDBProductRepo = class(TInterfacedObject, IProductRepo)
  public
    function FindParamsById(const AId: Int64): string;
    function FindParamsByCode(const ACode: string): string;
    function ListAllParams(APage, APageSize: Int64): string;
  end;

implementation

uses
  FireDAC.Comp.Client, System.JSON, uDB, System.Generics.Collections, Data.DB;

const
  cMaxCodeLen = 14; // tamanho da coluna COD_BARRA

function RowsetParamsToJson(AQ: TFDQuery; const AProdId: Int64): string;
var
  Obj, Params: TJSONObject;
begin
  Params := TJSONObject.Create;
  AQ.First;
  if not AQ.Eof then
  begin
    // Inclui o UID (como string) no objeto interno
    Params.AddPair('uid', TJSONString.Create(IntToStr(AProdId)));
    // Campos fixos: descrição (texto) e valor_venda (numérico)
    Params.AddPair('descricao', AQ.FieldByName('DESCRICAO').AsString);
    Params.AddPair('valor_venda', TJSONNumber.Create(AQ.FieldByName('VALOR_VENDA$').AsFloat));
  end;

  Obj := TJSONObject.Create;
  // Usa string para product_id para não perder precisão ao enviar para JavaScript
  // Obj.AddPair('product_id', TJSONString.Create(IntToStr(AProdId)));
  Obj.AddPair('params', Params);
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
    Q.SQL.Text := 'select DESCRICAO, VALOR_VENDA$ from TBL_PRODUTOS where UID = :UID';
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

function TDBProductRepo.FindParamsByCode(const ACode: string): string;
var
  Q: TFDQuery;
  LId: Int64;
  LCode: string;
begin
  Result := '';
  // Remove espaços e limita o tamanho para evitar truncamento
  LCode := Trim(ACode);
  if Length(LCode) > cMaxCodeLen then
    LCode := Copy(LCode, 1, cMaxCodeLen);

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FDConn;
    Q.SQL.Text := 'select UID from TBL_PRODUTOS where COD_PRODUTO = :COD_PRODUTO';
    with Q.ParamByName('COD_PRODUTO') do
    begin
      DataType := ftString;
      Size := cMaxCodeLen;
      AsString := LCode;
    end;
    Q.Open;
    if Q.IsEmpty then
      Exit;
    LId := Q.FieldByName('UID').AsLargeInt;
  finally
    Q.Free;
  end;
  Result := FindParamsById(LId);
end;

function TDBProductRepo.ListAllParams(APage, APageSize: Int64): string;
var
  Q: TFDQuery;
  Ids: TList<Int64>;
  Offset: Integer;
  Arr: TJSONArray;
  Obj: TJSONObject;
  IdValue: Int64;
  PageInt, PageSizeInt: Integer;
begin
  Q := TFDQuery.Create(nil);
  Ids := TList<Int64>.Create;
  try
    Q.Connection := FDConn;

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
    Q.SQL.Text := 'select first :PageSize skip :Offset UID ' + 'from TBL_PRODUTOS order by UID';

    Q.ParamByName('PageSize').AsInteger := PageSizeInt;
    Q.ParamByName('Offset').AsInteger := Offset;
    Q.Open;
    while not Q.Eof do
    begin
      Ids.Add(Q.FieldByName('UID').AsLargeInt);
      Q.Next;
    end;

    Arr := TJSONArray.Create;
    for IdValue in Ids do
    begin
      Q.Close;
      Q.SQL.Text := 'select DESCRICAO, VALOR_VENDA$ from TBL_PRODUTOS where UID = :UID';
      Q.ParamByName('UID').DataType := ftLargeInt;
      Q.ParamByName('UID').AsLargeInt := IdValue;
      Q.Open;
      Arr.AddElement(TJSONObject.ParseJSONValue(RowsetParamsToJson(Q, IdValue)));
    end;

    Q.Close;
    Q.SQL.Text := 'select count(*) as QUANTIDADE from TBL_PRODUTOS';
    Q.Open;

    Obj := TJSONObject.Create;
    Obj.AddPair('page', TJSONNumber.Create(APage));
    Obj.AddPair('pageSize', TJSONNumber.Create(APageSize));
    Obj.AddPair('total', TJSONNumber.Create(Q.FieldByName('QUANTIDADE').AsInteger));
    Obj.AddPair('items', Arr);
    Result := Obj.ToJSON;
    Obj.Free;
  finally
    Ids.Free;
    Q.Free;
  end;
end;

end.
