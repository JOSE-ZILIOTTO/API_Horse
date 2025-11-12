unit uProdutosRepo.Mock;

interface

uses
  uProdutosController,
  System.Math,
  System.Generics.Defaults,
  System.Generics.Collections;

type
  TMemProductRepo = class(TInterfacedObject, IProductRepo)
  private
    FData: TDictionary<Integer, string>;        // ID -> JSON com params
    FCodeToId: TDictionary<string, Int64>;    // CODE -> ID
  public
    constructor Create;
    destructor Destroy; override;
    function FindParamsById(const AId: Int64): string;
    function FindParamsByCode(const ACode: string): string;
    function ListAllParams(APage, APageSize: Int64): string;
  end;

implementation

uses
  System.SysUtils, System.JSON;

constructor TMemProductRepo.Create;
var
  Obj: TJSONObject;
begin
  FData := TDictionary<Integer, string>.Create;
  FCodeToId := TDictionary<string, Int64>.Create(TIStringComparer.Ordinal);

  // Produto 1 (code 404)
  Obj := TJSONObject.Create;
  Obj.AddPair('product_id', TJSONNumber.Create(1));
  Obj.AddPair('params', TJSONObject.Create
    .AddPair('ncm','1234.56.78')
    .AddPair('csosn','102')
    .AddPair('unidade','UN')
  );
  FData.Add(1, Obj.ToJSON);
  Obj.Free;
  FCodeToId.Add('404', 1);

  // Produto 2 (code 404)
  Obj := TJSONObject.Create;
  Obj.AddPair('product_id', TJSONNumber.Create(2));
  Obj.AddPair('params', TJSONObject.Create
    .AddPair('ncm','2203.00.00')
    .AddPair('csosn','500')
    .AddPair('unidade','CX')
  );
  FData.Add(2, Obj.ToJSON);
  Obj.Free;
  FCodeToId.Add('56', 2);
end;

destructor TMemProductRepo.Destroy;
begin
  FData.Free;
  FCodeToId.Free;
  inherited;
end;

function TMemProductRepo.FindParamsById(const AId: Int64): string;
begin
  if not FData.TryGetValue(AId, Result) then
    Result := '';
end;

function TMemProductRepo.FindParamsByCode(const ACode: string): string;
var
  LId: Int64;
begin
  if FCodeToId.TryGetValue(ACode, LId) then
    Result := FindParamsById(LId)
  else
    Result := '';
end;

function TMemProductRepo.ListAllParams(APage, APageSize: Int64): string;
var
  Keys: TArray<Integer>;
  I, StartIdx, EndIdx: Integer;
  Arr: TJSONArray;
  Obj: TJSONObject;
  S: string;
begin
  Keys := FData.Keys.ToArray;
  TArray.Sort<Integer>(Keys);
  StartIdx := (APage - 1) * APageSize;
  EndIdx := StartIdx + APageSize - 1;
  if StartIdx > High(Keys) then
    StartIdx := Length(Keys); // vazio

  Arr := TJSONArray.Create;
  for I := StartIdx to Min(EndIdx, High(Keys)) do
  begin
    S := FData[Keys[I]];
    Arr.AddElement(TJSONObject.ParseJSONValue(S) as TJSONValue);
  end;

  Obj := TJSONObject.Create;
  Obj.AddPair('page', TJSONNumber.Create(APage));
  Obj.AddPair('pageSize', TJSONNumber.Create(APageSize));
  Obj.AddPair('total', TJSONNumber.Create(Length(Keys)));
  Obj.AddPair('items', Arr);
  Result := Obj.ToJSON;
  Obj.Free;
end;

end.

