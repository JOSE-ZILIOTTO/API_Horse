unit uProdutosController;

interface

uses Horse;

type
  IProductRepo = interface
    ['{6B4B8E29-0A28-4D1E-9D36-4E7B51C9C61A}']
    function FindParamsById(const AId: Int64): string;
    function FindParamsByCode(const ACode: Integer): string;
    function ListAllPages(APage, APageSize: Int64): string;
    function ListAll: string;
  end;

procedure RegisterProductsRoutes(const Repo: IProductRepo);

implementation

uses
  System.SysUtils;

procedure RegisterProductsRoutes(const Repo: IProductRepo);
begin
  // GET /api/products/:id/params
  THorse.Get('/api/products/:id/params',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      LId: Int64;
      LJson: string;
    begin
      if not TryStrToInt64(Req.Params.Items['id'], LId) then
      begin
        Res.Status(400).Send('{"error":"id inválido"}');
        Exit;
      end;

      LJson := Repo.FindParamsById(LId);
      if LJson = '' then
        Res.Status(404).Send('{"error":"Produto não encontrado"}')
      else
        Res.Send(LJson);
    end);

  // GET /api/products/code/:code/params
  THorse.Get('/api/products/code/:code/params',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      LCode: Integer;
      LJson: string;
    begin
      if not TryStrToInt(Req.Params.Items['code'], LCode) then
      begin
        Res.Status(400).Send('{"error":"id inválido"}');
        Exit;
      end;

      LJson := Repo.FindParamsByCode(LCode);
      if LJson = '' then
        Res.Status(404).Send('{"error":"Produto não encontrado"}')
      else
        Res.Send(LJson);
    end);

  // GET /api/products/params?page=1&pageSize=50
  THorse.Get('/api/products/pages/params',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      LPage, LPageSize: Integer;
    begin
      LPage := Req.Query.Field('page').AsInteger;
      if LPage <= 0 then
        LPage := 1;

      LPageSize := Req.Query.Field('pageSize').AsInteger;
      if (LPageSize <= 0) or (LPageSize > 500) then
        LPageSize := 50;

      Res.Send(Repo.ListAllPages(LPage, LPageSize));
    end);
  // Get /api/products/all/params
  THorse.Get('/api/products/all/params',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Json: string;
    begin
      Json := Repo.ListAll; // chama a função
      Res.ContentType('application/json; charset=UTF-8').Send(Json);
    end);
end;

end.
