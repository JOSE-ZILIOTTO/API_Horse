unit uApiKeyAuth;

interface

{ ====Versão do Middleware API-Key com Chave Unica==== }

// uses
// Horse;
//
// type
// TApiKeyValidateFunc = reference to function(const AKey: string; const Req: THorseRequest): Boolean;
//
// function HorseApiKey(const AExpectedKey: string): THorseCallback; overload;
// function HorseApiKey(const AValidate: TApiKeyValidateFunc): THorseCallback; overload;
//
// implementation
//
// uses
// System.SysUtils,
// Horse.Exception; // IMPORTANTE: pra EHorseCallbackInterrupted
//
// function GetApiKeyFromRequest(const Req: THorseRequest): string;
// begin
// // 1) Header X-API-Key
// Result := Req.Headers['x-api-key'];
//
// // 2) Ou Authorization: ApiKey XXXXXX (opcional)
// if Result.IsEmpty then
// begin
// var LAuth := Req.Headers['authorization'];
// if not LAuth.IsEmpty then
// begin
// if LAuth.ToLower.StartsWith('apikey ') then
// Result := LAuth.Substring(Length('apikey '));
// end;
// end;
// end;
//
// function HorseApiKey(const AExpectedKey: string): THorseCallback;
// begin
// Result :=
// procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
// var
// LKey: string;
// begin
// LKey := GetApiKeyFromRequest(Req);
//
// if LKey.IsEmpty then
// begin
// Res.Status(401)
// .ContentType('application/json; charset=utf-8')
// .Send('{"error":"API key ausente"}');
//
// //  PARA O PIPELINE AQUI
// raise EHorseCallbackInterrupted.Create;
// end;
//
// if not SameText(LKey, AExpectedKey) then
// begin
// Res.Status(403)
// .ContentType('application/json; charset=utf-8')
// .Send('{"error":"API key inválida"}');
//
// // PARA O PIPELINE AQUI
// raise EHorseCallbackInterrupted.Create;
// end;
//
// // Autorizado → segue normal
// Next();
// end;
// end;
//
// function HorseApiKey(const AValidate: TApiKeyValidateFunc): THorseCallback;
// begin
// Result :=
// procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
// var
// LKey: string;
// begin
// LKey := GetApiKeyFromRequest(Req);
//
// if LKey.IsEmpty then
// begin
// Res.Status(401)
// .ContentType('application/json; charset=utf-8')
// .Send('{"error":"API key ausente"}');
//
// raise EHorseCallbackInterrupted.Create;
// end;
//
// if not Assigned(AValidate) or not AValidate(LKey, Req) then
// begin
// Res.Status(403)
// .ContentType('application/json; charset=utf-8')
// .Send('{"error":"API key inválida"}');
//
// raise EHorseCallbackInterrupted.Create;
// end;
//
// Next();
// end;
// end;
//
// end.

{ ====Versão do Middleware API-Key com list==== }

uses
  Horse;

type
  // Função de validação
  TApiKeyValidateFunc = reference to function(const AKey: string; const Req: THorseRequest): Boolean;

  // Recebe uma função de validação (pra whitelist, banco...)
function HorseApiKey(const AValidate: TApiKeyValidateFunc): THorseCallback;

implementation

uses
  uDB,
  System.SysUtils,
  Horse.Exception;

function GetApiKeyFromRequest(const Req: THorseRequest): string;
begin

  Result := Req.Headers['x-api-key'];

  if Result.IsEmpty then
  begin
    var
    LAuth := Req.Headers['authorization'];
    if not LAuth.IsEmpty then
    begin
      if LAuth.ToLower.StartsWith('apikey ') then
        Result := LAuth.Substring(Length('apikey '));
    end;
  end;
end;

function HorseApiKey(const AValidate: TApiKeyValidateFunc): THorseCallback;
begin
  Result := procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      LKey: string;
    begin

      LKey := GetApiKeyFromRequest(Req);

      if LKey.IsEmpty then
      begin
        Res.Status(401).ContentType('application/json; charset=utf-8').Send('{"error":"API key ausente"}');

        raise EHorseCallbackInterrupted.Create;
      end;

      if (not Assigned(AValidate)) or (not AValidate(LKey, Req)) then
      begin
        Res.Status(403).ContentType('application/json; charset=utf-8').Send('{"error":"API key inválida"}');

        raise EHorseCallbackInterrupted.Create;
      end;

      Next();

    end;
end;

end.
