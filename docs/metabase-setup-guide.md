# Guia de Instalacao — Metabase no Easypanel

Este guia cobre a instalacao completa do Metabase no Easypanel com conexao ao Supabase.

**Resultado final:** Dashboard tecnico acessivel em `https://monitor.agenciaprospect.space`

---

## Pre-requisitos

- Acesso ao Easypanel (painel de hospedagem no VPS Hostinger)
- Senha do banco Supabase (a mesma usada na connection string do `.env`)
- Acesso ao painel DNS (Hostinger ou Cloudflare) para criar registro A

---

## Passo 1 — Criar servico no Easypanel

1. Acesse o Easypanel do seu VPS
2. Clique em **"Create Project"** (ou use um projeto existente como "asx")
3. Dentro do projeto, clique em **"+ Service"** → **"Docker"**
4. Configure:

| Campo | Valor |
|-------|-------|
| Service Name | `metabase` |
| Image | `metabase/metabase:latest` |
| Port | `3000` |

5. Clique em **"Deploy"** para criar o servico

---

## Passo 2 — Configurar variaveis de ambiente

Na aba **"Environment"** do servico metabase, adicione:

```
MB_DB_TYPE=h2
MB_JETTY_PORT=3000
MB_DB_FILE=/metabase-data/metabase.db
JAVA_TIMEZONE=America/Sao_Paulo
```

**O que cada variavel faz:**
- `MB_DB_TYPE=h2` — Banco interno do Metabase (nao confundir com o Supabase que sera a fonte de dados)
- `MB_JETTY_PORT=3000` — Porta do servidor web
- `MB_DB_FILE=/metabase-data/metabase.db` — Onde o Metabase salva suas configuracoes
- `JAVA_TIMEZONE=America/Sao_Paulo` — Fuso horario para os graficos

---

## Passo 3 — Configurar volume persistente

Na aba **"Volumes"** (ou "Mounts") do servico:

1. Clique em **"Add Volume"**
2. Configure:

| Campo | Valor |
|-------|-------|
| Type | Volume |
| Name | `metabase-data` |
| Mount Path | `/metabase-data` |

Isso garante que as configuracoes do Metabase sobrevivam a restarts do container.

3. Clique em **"Deploy"** novamente para aplicar

---

## Passo 4 — Configurar dominio

### 4.1 No Easypanel

1. Va na aba **"Domains"** do servico metabase
2. Clique em **"Add Domain"**
3. Digite: `monitor.agenciaprospect.space`
4. Port: `3000`
5. Marque **"HTTPS"** (Let's Encrypt)
6. Salve

### 4.2 No DNS (Hostinger ou Cloudflare)

1. Acesse o painel de DNS do dominio `agenciaprospect.space`
2. Crie um registro:

| Tipo | Nome | Valor | TTL |
|------|------|-------|-----|
| A | `monitor` | IP do seu VPS | Auto |

3. Aguarde propagacao (geralmente 5-10 minutos)

### 4.3 Verificar

Acesse `https://monitor.agenciaprospect.space` — deve aparecer a tela de setup do Metabase.

Se nao carregar, aguarde uns minutos. O Metabase demora ~1-2 minutos para iniciar na primeira vez.

---

## Passo 5 — Setup inicial do Metabase

Ao acessar pela primeira vez, o Metabase mostra um wizard de configuracao:

### 5.1 Idioma
- Selecione **"Portugues (Brasil)"**

### 5.2 Conta de administrador
- Preencha com seus dados (email e senha da agencia Convert)
- **Guarde essas credenciais** — elas serao necessarias para configurar o dashboard

### 5.3 Adicionar banco de dados

Quando o wizard perguntar "Adicione seus dados", selecione **PostgreSQL** e preencha:

| Campo | Valor |
|-------|-------|
| Display name | `ASX Supabase` |
| Host | `aws-1-sa-east-1.pooler.supabase.com` |
| Port | `5432` |
| Database name | `postgres` |
| Username | `postgres.hxcfvyhjyibdexazrhox` |
| Password | *(senha do banco Supabase — a mesma da connection string no .env)* |

### 5.4 Opcoes avancadas

Expanda "Additional JDBC connection string options" e adicione:

```
ssl=true&sslmode=require
```

Ou se houver um toggle de SSL, marque **"Use SSL"**.

### 5.5 Salvar e continuar

Clique em salvar. O Metabase vai se conectar ao Supabase e sincronizar o schema.

---

## Passo 6 — Verificar conexao

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

## Passo 7 — Me avisar

Apos completar todos os passos acima, me avise com:
- Confirmacao de que o Metabase esta acessivel em `https://monitor.agenciaprospect.space`
- Email e senha do admin que voce criou (para eu configurar o dashboard)

Eu entao configurarei o dashboard com os 7 cards e 3 alertas definidos no plano.

---

## Troubleshooting

### "Connection refused" ou "Could not connect"
- Verifique se o DNS ja propagou: `ping monitor.agenciaprospect.space`
- Aguarde 2 minutos apos o deploy — o Metabase demora para iniciar

### "Unable to connect to database" (ao conectar Supabase)
- Verifique se a senha esta correta (sem espacos extras)
- Tente a conexao direta em vez do pooler:
  - Host: `db.hxcfvyhjyibdexazrhox.supabase.co`
  - Port: `5432`
- Verifique se SSL esta habilitado

### Tabelas nao aparecem
- Va em Admin → Databases → ASX Supabase → "Sync database schema now"
- Verifique se voce executou os SQLs (001 e 002) no Supabase SQL Editor

### Metabase reinicia sozinho / perde configuracoes
- Verifique se o volume `/metabase-data` esta configurado corretamente
- No Easypanel, confirme que o volume nao esta marcado como "ephemeral"
