unit uServer;

interface

procedure StartServer(const APort: Integer; UseMemoryRepo: Boolean);

implementation

uses
  Horse, System.SysUtils,
  uProdutosController,
  uProdutosRepo.DB,
  uProdutosRepo.Mock;

procedure StartServer(const APort: Integer; UseMemoryRepo: Boolean);
begin
  THorse.Use(Procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
  begin
    Res.ContentType('application/json; charset=utf-8');
    Next();
  end);

  // Registra rotas do módulo de produtos (usando repositório em memória)
  // RegisterProductsRoutes(TMemProductRepo.Create);
  RegisterProductsRoutes(TDBProductRepo.Create);
  THorse.Listen(APort);
end;

end.
