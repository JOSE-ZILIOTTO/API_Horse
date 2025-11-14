# API de Parâmetros de Produtos (Horse + FireDAC + Firebird)

API **somente leitura** para consultar parâmetros de produtos a partir de um banco **Firebird**.
Construída em **Delphi** com [Horse](https://github.com/HashLoad/horse) e **FireDAC**.

- **Status:** MVP – leitura apenas  
- **Banco:** Firebird (UID = BIGINT, COD_BARRA = VARCHAR(14))  
- **Formato:** JSON (UTF-8)  
- **Porta padrão:** `9000`

---

## Sumário

- [Arquitetura](#arquitetura)
- [Pré-requisitos](#pré-requisitos)
- [Configuração](#configuração)
- [Como rodar](#como-rodar)
- [Endpoints](#endpoints)
  - [GET `/api/products/:id/params`](#get-apiproductsidparams)
  - [GET `/api/products/code/:code/params`](#get-apiproductscodecodeparams)
  -  [GET `/api/products/all/params`](#get-apiproductsallparams)
  - [GET `/api/products/pages/params?page=&pageSize=`](#get-apiproductspagesparamspagepagesize)
- [Esquemas de resposta](#esquemas-de-resposta)
- [Paginação (Firebird)](#paginação-firebird)
- [Códigos de status](#códigos-de-status)
- [Exemplos de uso](#exemplos-de-uso)

---

## Arquitetura

- **uServer / Server.dpr**: sobe o Horse, registra middlewares/rotas.  
- **uProductsController**: define rotas HTTP e valida entradas.  
- **uProductRepo.DB**: repositório que consulta o banco via FireDAC.  
- **uProductRepo.Mem (opcional)**: mock em memória para desenvolvimento rápido.  
- **uDB**: configuração de conexão (DriverID, Database, UserName, Password, Charset).

Fluxo: **Request → Controller → Repository → Firebird → JSON Response**.

---

## Pré-requisitos

- Delphi (RAD Studio) com **FireDAC**  
- Horse + units auxiliares (Horse.CORS, etc.)  
- Firebird instalado e acessível (2.5+)  

---

## Configuração

Edite **`uDB.pas`**:

```pascal
GConn := TFDConnection.Create(nil);
GConn.Params.DriverID := 'FB';
GConn.Params.Database := 'Diretório do Banco';
GConn.Params.UserName := 'USERNAME';
GConn.Params.Password := 'SENHA';
GConn.Params.Add('CharacterSet=UTF8');
GConn.LoginPrompt := False;
GConn.Connected := True;
```

> Dica: crie um alias no `databases.conf` (FB 2.5+) e aponte `Database := 'alias:nome'`.

---

## Como rodar

1. **Clonar** o projeto e abrir no Delphi.  
2. **Instalar dependências**
3. (Horse,Horse-CORS,dataset-serealize,horse/basic-auth).  
4. **Executar** o servidor:

```pascal
ConfigureFirebird;
RegisterProductsRoutes(TDBProductRepo.Create);
THorse.Listen(9000);
```

A API ficará acessível em `http://localhost:9000/`.

---

## Endpoints

### GET `/api/products/:id/params`

Busca parâmetros por **UID** (BIGINT).

- **Path param:** `id` (Int64)  
- **Retornos:**  
  - `200 OK`: JSON do produto  
  - `400 Bad Request`: `id` inválido  
  - `404 Not Found`: produto não existe

### GET `/api/products/code/:code/params`

Busca por **código de barras**.

### GET `/api/products/all/params

### GET `/api/products/pages/params?page=&pageSize=`

Lista parâmetros paginados.

- **Query params:**  
  - `page` (int, padrão `1`, mínimo `1`)  
  - `pageSize` (int, padrão `50`, máx. recomendado `500`)
- **Retornos:** `200 OK` com `page`, `pageSize`, `total`, `items`

---

## Esquemas de resposta

### Produto (por id/code)
```json
{
  {
    "uid": "1234567890123",
    "descricao": "Nome do produto",
    "valor_venda": 19.9...
  }
}
```

> `product_id` e `uid` são **strings** para não perder precisão em clientes JavaScript quando o `UID` é muito grande.

### Lista paginada
```json
{
  "page": 1,
  "pageSize": 50,
  "total": 287,
  "items": [
    {
        "uid":"1", "descricao":"...", "valor_venda": 12.34 ...
    }
  ]
}
```

---

## Paginação (Firebird)

Para ampla compatibilidade (FB 2.5+), a API usa:

```sql
SELECT FIRST :PageSize SKIP :Offset UID
FROM TBL_PRODUTOS
ORDER BY COD_PRODUTO;
```

`Offset = (page - 1) * pageSize`

---

## Códigos de status

- **200** OK – requisição bem-sucedida  
- **400** Bad Request – parâmetro inválido (ex.: `code` > 14 chars ou `id` não numérico)  
- **404** Not Found – produto não existe  
- **500** Internal Server Error – erro inesperado (ver logs do servidor)

---

## Exemplos de uso

### cURL

```bash
# Por UID
curl -i http://localhost:9000/api/products/123/params

# Por código de barras
curl -i http://localhost:9000/api/products/code/7891234567890/params

# Lista paginada
curl -i "http://localhost:9000/api/products/pages/params?page=1&pageSize=50"
```

### Postman

- Método: **GET**  
- URL: conforme endpoint  
- Params: `page`, `pageSize` quando aplicável  
- Headers: `Accept: application/json`


**Como proteger a API?**  
Implemente verificação de header `X-API-Key` em um middleware antes das rotas.

---
