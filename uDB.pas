unit uDB;

interface

uses
  FireDAC.Comp.Client;

function FDConn: TFDConnection;

procedure ConfigureFirebird; // ou ConfigureSQLite

implementation

uses
  System.SysUtils, FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Phys, FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.UI.Intf;

var
  GConn: TFDConnection;

function FDConn: TFDConnection;
begin
  Result := GConn;
end;

procedure ConfigureFirebird;
begin
  GConn := TFDConnection.Create(nil);
  GConn.Params.DriverID := 'FB';
  GConn.Params.Database := 'Diretório do Banco';
  GConn.Params.UserName := 'USERNAME';
  GConn.Params.Password := 'SENHA';
  GConn.Params.Add('CharacterSet=UTF8');
  GConn.LoginPrompt := False;
  GConn.Connected := True;

end;

end.

