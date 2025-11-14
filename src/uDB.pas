unit uDB;

interface

{ ====Versão Com Cenexão Direta==== }

// uses
// FireDAC.Comp.Client;
//
// function FDConn: TFDConnection;
//
// procedure ConfigureFirebird;
//
// implementation
//
// uses
// System.SysUtils, FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.DApt,
// FireDAC.Phys, FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.UI.Intf;
//
// var
// GConn: TFDConnection;
//
// function FDConn: TFDConnection;
// begin
// Result := GConn;
// end;
//
// procedure ConfigureFirebird;
// begin
// GConn := TFDConnection.Create(nil);
// GConn.Params.DriverID := 'FB';
// GConn.Params.Database := 'D:\Jose\Projetos\SRP_ESTAVEL\dados\SRP_ESTAVEL.FDB';
// GConn.Params.UserName := 'SYSDBA';
// GConn.Params.Password := 'masterkey';
// GConn.Params.Add('CharacterSet=UTF8');
// GConn.LoginPrompt := False;
// GConn.Connected := True;
//
// end;
//
// end.
{ ====Versão com Config.ini==== }
uses
  FireDAC.Comp.Client;

function FDConn: TFDConnection;

procedure ConfigureFirebird;

 var LAPIKey: string;

implementation

uses
  System.SysUtils,
  System.IniFiles,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.DApt,
  FireDAC.Phys,
  FireDAC.Phys.FB,
  FireDAC.Phys.FBDef,
  FireDAC.UI.Intf;

var
  GConn: TFDConnection;


function FDConn: TFDConnection;
begin
  Result := GConn;
end;

procedure ConfigureFirebird;
var
  LIni: TIniFile;
  LIniPath: string;
  LDriverID: string;
  LDatabase: string;
  LUser: string;
  LPassword: string;
  LCharset: string;
  LServer: string;
  LPort: string;
begin
  // Caminho do config.ini (mesma pasta do EXE)
  LIniPath := ExtractFilePath(ParamStr(0)) + 'config.ini';

  if not FileExists(LIniPath) then
    raise Exception.CreateFmt('Arquivo de configuração não encontrado: %s', [LIniPath]);

  LIni := TIniFile.Create(LIniPath);
  try

    LDriverID := LIni.ReadString('Database', 'DriverID', 'FB');
    LDatabase := LIni.ReadString('Database', 'Database', '');
    LUser := LIni.ReadString('Database', 'User_Name', 'SYSDBA');
    LPassword := LIni.ReadString('Database', 'Password', 'masterkey');
    LCharset := LIni.ReadString('Database', 'CharacterSet', 'UTF8');
    LServer := LIni.ReadString('Database', 'Server', '');
    LPort := LIni.ReadString('Database', 'Port', '');
    LAPIKey := LIni.ReadString('API', 'Apikey', '');
  finally
    LIni.Free;
  end;

  if LDatabase = '' then
    raise Exception.Create('Parâmetro [Database]/Database não informado no config.ini');

  if LAPIKey = '' then
    raise Exception.Create('Chave da API não configurada: seção [API], chave ApiKey no config.ini');

  GConn := TFDConnection.Create(nil);
  with GConn.Params do
  begin
    Clear;
    Values['DriverID'] := LDriverID;
    Values['Database'] := LDatabase;
    Values['User_Name'] := LUser;
    Values['Password'] := LPassword;

    if LCharset <> '' then
      Values['CharacterSet'] := LCharset;

    // opcional (local vs remoto)
    if LServer <> '' then
      Values['Server'] := LServer;
    if LPort <> '' then
      Values['Port'] := LPort;
  end;

  GConn.LoginPrompt := False;

  try
    GConn.Connected := True;
  except
    on E: Exception do
    begin
      raise Exception.CreateFmt('Erro ao conectar no Firebird usando %s: %s', [LIniPath, E.Message]);
    end;
  end;
end;

end.
