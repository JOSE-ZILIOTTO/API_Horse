program API_Produtos;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Horse,
  Horse.CORS,
  uDB in 'src\uDB.pas',
  uProdutosRepo.DB in 'src\uProdutosRepo.DB.pas',
  uProdutosRepo.Mock in 'src\uProdutosRepo.Mock.pas',
  uProdutosController in 'src\uProdutosController.pas',
  uServer in 'src\uServer.pas';

begin
  THorse.Use(CORS);

  ConfigureFirebird;

  THorse.Use(
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.ContentType('application/json; charset=utf-8');
      Next();
    end);

//  RegisterProductsRoutes(TMemProductRepo.Create);
  RegisterProductsRoutes(TDBProductRepo.Create);
  THorse.Listen(9000);

end.
