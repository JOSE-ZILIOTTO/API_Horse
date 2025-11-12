unit uProdutosController;

interface

uses Horse;

type
  IProductRepo = interface
    ['{6B4B8E29-0A28-4D1E-9D36-4E7B51C9C61A}']
    function FindParamsById(const AId: Int64): string;           // JSON { params: {...} }
    function FindParamsByCode(const ACode: string): string;         // JSON { params: {...} }
    function ListAllParams(APage, APageSize: Int64): string;      // JSON { items: [...], page:..., pageSize:... }
  end;

procedure RegisterProductsRoutes(const Repo: IProductRepo);

implementation

uses
  System.SysUtils;

procedure RegisterProductsRoutes(const Repo: IProductRepo);
begin
  // GET /api/products/:id/params   (por ID numérico)
  THorse.Get('/api/products/:id/params',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      LId: Int64;
      LJson: string;
    begin
      LId := StrToInt64(Req.Params.Items['id']);
      LJson := Repo.FindParamsById(LId);
      if LJson = '' then
        Res.Status(404).Send('{"error":"Produto não encontrado"}')
      else
        Res.Send(LJson);
    end);

  // GET /api/products/code/:code/params   (por código interno/barras)
  THorse.Get('/api/products/code/:code/params',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      LCode, LJson: string;
    begin
      LCode := Req.Params.Items['code'];
      LJson := Repo.FindParamsByCode(LCode);
      if LJson = '' then
        Res.Status(404).Send('{"error":"Produto não encontrado"}')
      else
        Res.Send(LJson);
    end);

  // GET /api/products/params?page=1&pageSize=50
  THorse.Get('/api/products/params',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      LPage, LPageSize: Integer;
    begin
      LPage     := Req.Query.Field('page').AsInteger;
      if LPage <= 0 then LPage := 1;
      LPageSize := Req.Query.Field('pageSize').AsInteger;
      if (LPageSize <= 0) or (LPageSize > 500) then LPageSize := 50;

      Res.Send(Repo.ListAllParams(LPage, LPageSize));
    end);
end;

end.

