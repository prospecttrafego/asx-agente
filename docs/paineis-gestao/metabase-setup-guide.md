# Guia de Instalacao — Metabase no Easypanel

Este guia cobre a instalacao completa do Metabase no Easypanel usando o **template nativo** (1-click), com conexao ao Supabase.

**Resultado final:** Dashboard tecnico acessivel em `https://monitor.agenciaprospect.space`

---

## Pre-requisitos

- Acesso ao Easypanel (painel de hospedagem no VPS Hostinger)
- Senha do banco Supabase (a mesma usada na connection string do `.env`)
- Acesso ao painel DNS (Hostinger ou Cloudflare) para criar registro A

---

## Passo 1 — Criar o Metabase via template nativo

1. Acesse o Easypanel do seu VPS
2. Entre no projeto desejado (ex: `agents`)
3. Clique em **"Modelos"** (ou "Templates")
4. Pesquise por **"metabase"**
5. Clique no card do **Metabase**
6. Preencha os campos:

| Campo | O que preencher |
|-------|----------------|
| **App Service Name** | `metabase` (pode manter o padrao) |
| **App Service Image** | Manter o padrao (`metabase/metabase:v0.59` ou a versao que aparecer) |
| **Metabase Site Name (Title)** | `ASX SDR Monitor` (ou deixar em branco — e so o titulo que aparece na interface) |

7. Clique em **"Criar"**

O Easypanel vai automaticamente:
- Criar o container com a imagem do Metabase
- Configurar a porta 3000
- Criar um volume persistente em `/metabase-data` (seus dados sobrevivem a restarts)
- Setar as variaveis `MB_DB_FILE`, `MB_SITE_NAME` e `MB_APPLICATION_NAME`

**Aguarde 1-2 minutos** — o Metabase demora um pouco para iniciar pela primeira vez (ele faz setup interno do banco H2).

---

## Passo 2 — Configurar dominio

### 2.1 No Easypanel

1. Apos o servico estar criado, clique nele para abrir os detalhes
2. Va na aba **"Dominios"** (ou "Domains")
3. Remova o dominio automatico gerado pelo Easypanel (se houver)
4. Clique em **"Adicionar Dominio"**
5. Digite: `monitor.agenciaprospect.space`
6. Marque **HTTPS** (Let's Encrypt automatico)
7. Salve

### 2.2 No DNS (Hostinger ou Cloudflare)

1. Acesse o painel de DNS do dominio `agenciaprospect.space`
2. Crie um registro:

| Tipo | Nome | Valor | TTL |
|------|------|-------|-----|
| A | `monitor` | IP do seu VPS | Auto |

3. Aguarde propagacao (geralmente 5-10 minutos)

### 2.3 Verificar

Acesse `https://monitor.agenciaprospect.space` — deve aparecer a tela de setup do Metabase.

---

## Passo 3 — Setup inicial do Metabase

Ao acessar pela primeira vez, o Metabase mostra um wizard de configuracao:

### 3.1 Idioma
- Selecione **"Portugues (Brasil)"**

### 3.2 Conta de administrador
- Preencha com seus dados (email e senha da agencia Convert)
- **Guarde essas credenciais** — elas serao necessarias para eu configurar o dashboard

### 3.3 Adicionar banco de dados

Quando o wizard perguntar "Adicione seus dados", selecione **PostgreSQL** e preencha:

| Campo | Valor |
|-------|-------|
| Display name | `ASX Supabase` |
| Host | `aws-1-sa-east-1.pooler.supabase.com` |
| Port | `5432` |
| Database name | `postgres` |
| Username | `postgres.hxcfvyhjyibdexazrhox` |
| Password | *(senha do banco Supabase — a mesma da connection string no .env)* |

### 3.4 SSL

Se aparecer uma opcao de SSL, marque **"Use SSL"** ou **"Require"**.

Caso nao apareca toggle de SSL, expanda "Additional JDBC connection string options" e adicione:
```
ssl=true&sslmode=require
```

### 3.5 Salvar e continuar

Clique em salvar. O Metabase vai se conectar ao Supabase e sincronizar o schema.

---

## Passo 4 — Verificar conexao

Apos o setup, va em **Admin** (engrenagem no canto superior direito) → **Databases** → **ASX Supabase**

### O que deve aparecer:

**Tabelas:**
- `events`
- `fb_leads`
- `ia_messages`
- `leads`
- `assignments`
- `distributors`
- `distributor_recommendations`

**Views (aparecem como tabelas):**
- `v_errors_per_hour`
- `v_errors_by_workflow`
- `v_agent_latency`
- `v_events_by_type`
- `v_daily_lead_flow`
- `v_health_check_latest`
- `v_funnel_summary`
- `v_path3_pipeline`
- `v_regional_performance`

Se alguma tabela ou view nao aparecer, clique em **"Sync database schema now"**.

---

## Passo 5 — Me avisar

Apos completar todos os passos acima, me avise com:
- Confirmacao de que o Metabase esta acessivel em `https://monitor.agenciaprospect.space`
- Email e senha do admin que voce criou (para eu configurar o dashboard)

Eu entao configurarei o dashboard com os 7 cards e 3 alertas definidos no plano.

---

## Troubleshooting

### Metabase nao abre / fica carregando
- Na primeira vez, o Metabase pode demorar 2-3 minutos para iniciar
- No Easypanel, verifique se o servico esta com status "Running"
- Veja os logs do servico no Easypanel para identificar erros

### "Unable to connect to database" (ao conectar Supabase)
- Verifique se a senha esta correta (sem espacos extras)
- Tente a conexao direta em vez do pooler:
  - Host: `db.hxcfvyhjyibdexazrhox.supabase.co`
  - Port: `5432`
- Verifique se SSL esta habilitado

### Tabelas nao aparecem
- Va em Admin → Databases → ASX Supabase → "Sync database schema now"
- Verifique se voce executou os SQLs (001 e 002) no Supabase SQL Editor antes

### Erro "prepared statement already exists"
- Isso acontece com o pooler do Supabase em modo Transaction
- Solucao: usar a conexao direta (Host: `db.hxcfvyhjyibdexazrhox.supabase.co`) em vez do pooler
