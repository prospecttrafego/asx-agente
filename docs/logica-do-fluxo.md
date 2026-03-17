# Logica do Fluxo - Estado Real de Producao

Ultima sincronizacao com producao: 2026-03-17
Fonte primaria: n8n API, Chatwoot API e Evolution API em producao

Este documento descreve a logica que esta efetivamente rodando hoje.
Quando houver divergencia entre exports antigos, testes historicos e este arquivo,
este arquivo deve ser tratado como fonte documental principal.

## Visao Geral

O agente "Joao" opera em dois momentos:

1. `WF06` recebe o lead do Meta Ads, normaliza e classifica.
2. `WF07` recebe mensagens do WhatsApp pela Evolution API e continua o atendimento.

Os dados operacionais ficam no banco acessado pelos nodes Postgres com credential
`Supabase ASX`.

Nesta auditoria documental, o comportamento do banco foi observado pelos
workflows vivos e pelas execucoes reais do n8n. Nao houve autenticacao direta
na API REST do Supabase porque o workspace documental nao contem `.env` com as
chaves reais.

## Servicos Confirmados em Producao

### n8n

- Base URL: `https://flow.agenciaprospect.space`
- API publica acessivel com autenticacao por `X-N8N-API-KEY`
- Workflows ASX ativos confirmados:
  - `02-Tool-Label (callable)` -> `QBZhzIYU7qBuE6p5`
  - `02A-Company-Enrich (callable)` -> `fRc8nB8qUjJUrTHw`
  - `02B-Score-Lead (callable)` -> `gPxoxxAA88LVdZ7Y`
  - `02C-Agent-Log (callable)` -> `N1b1o3ED1FXDHWBW`
  - `02D-Find-Distributors (callable)` -> `DEwqsmZDj8fIMjuq`
  - `03-Finalize-Handoff (callable)` -> `OvvMcnq571vIb9bK`
  - `04-Chatwoot-Message-Logger` -> `MlscoOb4IqmMpgQr`
  - `05-Error-Logger` -> `WBqj1UKzZORCANPo`
  - `06-FB-Leads-Outbound-Webhook` -> `7LvmLJIL7CdbWpbt`
  - `07-FB-Leads-Inbound` -> `hGsfyVT8TPWau6RH`
  - `08-Health-Check` -> `Oj8SgieQ4HH7Czbk`

### Evolution API

- Base URL: `https://api.agenciaprospect.space`
- Endpoint confirmado: `GET /instance/fetchInstances`
- Instancia ativa: `ASX_SDR`
- `connectionStatus`: `open`
- Integracao Chatwoot habilitada:
  - `enabled = true`
  - `accountId = 1`
  - `nameInbox = Inbox SDR`
  - `reopenConversation = true`
  - `importMessages = true`
  - `mergeBrazilContacts = true`

### Chatwoot

- Base URL: `https://chat.agenciaprospect.space`
- Conta confirmada: `account_id = 1`
- Busca autenticada funcional em `GET /api/v1/accounts/1/contacts/search`
- Inbox principal usada pelo SDR: `Inbox SDR`, `inbox_id = 1`

## WF06 - 06-FB-Leads-Outbound-Webhook

ID: `7LvmLJIL7CdbWpbt`
Atualizado em producao: `2026-03-12T12:43:23.876Z`

### Entrada

- Webhook `meta-leads`
- Metodos aceitos: `POST` e `GET`
- `GET` serve para verificacao do Meta via `hub.challenge`
- `POST` busca o lead real na Graph API e depois processa

### Etapas

1. `HTTP Request`
   - Busca o lead no Meta Graph API por `leadgen_id`
2. `Extract Form Fields`
   - Normaliza `nome`, `email`, `telefone_raw`, `perfil`, `volume_faixa`, `cnpj_raw`, `estado_envio`
3. `Normalize Phone`
   - Normaliza telefone brasileiro para padrao com `55`
4. `Phone Valid?`
   - Se invalido, grava evento `invalid_phone`
5. `Clean CNPJ`
   - Remove pontuacao
6. `CNPJ 14 Digits?`
   - Se falhar, salva `path = 1`, `status = disqualified_cnpj`
7. `02A Company Enrich`
   - Enriquece o CNPJ por cache/local e API externa
8. `CNPJ Valid?`
   - Se falhar, salva `path = 1`, `status = disqualified_cnpj`
9. `Classify Lead`
   - Converte faixa de volume em numero
   - Mapeia UF
   - Decide entre `path = 2` e `path = 3`
10. `Save fb_lead`
   - Faz `INSERT ... ON CONFLICT (facebook_lead_id) DO UPDATE SET updated_at = NOW() RETURNING id`
11. Chatwoot
   - `Search Chatwoot Contact`
   - `Create Chatwoot Contact` se nao existir
   - `Create Conversation`
12. `IF Path`
   - `true` -> Path 3
   - `false` -> Path 2

### Path 1

Casos:

- telefone invalido
- CNPJ sem 14 digitos
- CNPJ invalido na Receita

Saida:

- lead salvo como desqualificado
- evento `workflow_success` do `WF06` para path 1

### Path 2

Condicoes:

- `volume_numerico < 4000`
- ou `volume_numerico >= 4000` fora de N/NE

Etapas:

1. `Find Distributors`
2. `Compose Message P2`
3. `Send WhatsApp P2`
4. `Save Recommendations`
5. `Update fb_lead P2`
6. `Add Labels P2`
7. `Log Success P2`

Observacoes:

- O texto do `Compose Message P2` ja diferencia:
  - baixo volume
  - fora da regiao de atendimento direto
  - com distribuidores
  - sem distribuidores
- `Find Distributors` esta com `alwaysOutputData = true`
- `Save Recommendations` ainda usa SQL dinamico montado por expressao

### Path 3

Condicao:

- `volume_numerico >= 4000` e UF em Norte/Nordeste

Etapas:

1. `Compose Message P3`
2. `Send WhatsApp P3`
3. `Update fb_lead P3`
4. `Add Labels P3`
5. `Log Success P3`

Observacao importante:

- No estado atual de producao, o `WF06` nao contem os nodes documentados
  anteriormente para:
  - atualizar contato existente no Chatwoot
  - criar nota privada da conversa
  - sincronizar a mensagem inicial do Path 2/3 para dentro do Chatwoot

## Criterio de Classificacao

Implementado no node `Classify Lead` do `WF06`.

### Volume

- `Abaixo de 2.000` -> `1500`
- `Entre 2.000 e 4.000` -> `3000`
- `Entre 4.000 e 10.000` -> `7000`
- `Acima de 10.000` -> `12000`

### Regiao alvo

UFs consideradas Norte/Nordeste:

- `AC AM AP PA RO RR TO`
- `AL BA CE MA PB PE PI RN SE`

### Resultado

- `path = 2` se volume `< 4000`
- `path = 3` se volume `>= 4000` e UF em N/NE
- `path = 2` se volume `>= 4000` fora de N/NE

## WF07 - 07-FB-Leads-Inbound

ID: `hGsfyVT8TPWau6RH`
Atualizado em producao: `2026-03-12T12:58:54.201Z`

### Entrada

- Webhook de mensagens recebidas da Evolution API

### Normalizacao

Nodes principais:

- `Extrair Campos`
- `Normaliza Payload`
- `IF Lead Message`

Campos extraidos:

- `phone`
- `msgId`
- `fromMe`
- `conversation`
- `messageType`
- `chatwootConversationId`
- `chatwootInboxId`
- `timestamp`

Regra:

- `fromMe = true` vai para `No Op`
- apenas mensagem do lead segue no fluxo

### Tipos de mensagem

O `Switch Message Type` trata:

- `conversation`
- `imageMessage`
- `audioMessage`
- `documentMessage`

Fluxos auxiliares:

- audio -> transcricao OpenAI
- imagem -> analise OpenAI
- texto e documento convergem para texto final

### Batching Redis

Implementacao atual:

- `Prepare for Redis` grava `redis_payload`
- `Redis Push`
- `Redis Get`
- `Parse Redis Batch`
- `IF Last Message`
- `Merge Messages`

Comportamento:

- agrupa por telefone
- compara o item vencedor por `msgId`
- mantem compatibilidade com payload legado em texto puro
- consolida `txt`, `has_document`, `has_image`, `chatwootConversationId`, `chatwootInboxId`

### Persistencia de mensagens

- `Log User Message` -> `ia_messages`
- `Log Assistant Message` -> `ia_messages`

### Roteamento

`Lookup Lead Path` resolve:

- `already_qualified`
- `distributor_agent`
- `qualified_agent`
- `unknown`

`Switch Lead Type` tem tres saidas mapeadas:

- `Already Qualified`
- `Distributor`
- `Qualified`

Observacao importante:

- o fallback `unknown` nao possui node explicito conectado no workflow atual
- nas execucoes reais recentes, mensagens `unknown` terminam em `Switch Lead Type`
- isso aparece no `WF08` como `wf07_unknown_routes_last_24h`

### Agente Path 2

Root node:

- `Joao P2 - Distributor Agent`

Tools:

- `set_label_p2`
- `log_event_p2`
- `find_distributors_p2`

Papel:

- responder duvidas sobre distribuidores
- nao vender diretamente

### Agente Path 3

Root node:

- `Joao P3 - Qualified Agent`

Tools:

- `score_lead_p3`
- `finalize_p3`
- `set_label_p3`
- `log_event_p3`

### Contrato atual do `finalize_p3`

O tool workflow ja esta simplificado no estado real:

Campos pre-preenchidos do contexto:

- `phone`
- `nome`
- `empresa`
- `cnpj`
- `perfil`
- `uf_atuacao`
- `volume`
- `chatwoot_conversation_id`
- `source = facebook_form`

Campos ainda definidos via `$fromAI()`:

- `score`
- `class`
- `priority`
- `ja_compra_asx_regiao`
- `fornecedor_asx_regiao`
- `nfs_enviadas`
- `empresa_recente`

## 03 - Finalize Handoff

ID: `OvvMcnq571vIb9bK`
Atualizado em producao: `2026-03-12T15:50:37.835Z`

### Contrato de entrada

O node `Validate Input` aceita:

- `phone`
- `nome`
- `empresa`
- `cnpj`
- `perfil`
- `regiao`
- `volume`
- `score`
- `class`
- `priority`
- `chatwoot_conversation_id`
- `ja_compra_asx`
- `fornecedor_atual`
- `ja_compra_asx_regiao`
- `fornecedor_asx_regiao`
- `nfs_enviadas`
- `empresa_recente`
- `source`

### Sequencia atual

1. `Pick Agent`
   - escolhe o vendedor com menor total acumulado em `assignments`
2. `Persist Lead`
   - faz upsert de `contacts`
   - faz upsert de `companies`
   - cria registro em `leads`
3. `Create Assignment`
4. `Transfer Conversation`
   - atribui a conversa no Chatwoot por `team_id`
5. `Move to Vendor Inbox`
   - atualiza inbox direto no banco do Chatwoot
6. `Notify Vendor`
   - envia WhatsApp ao vendedor
7. `Log Handoff`
   - grava evento `handoff_complete`

### Observacoes importantes

- O workflow atual nao grava `fb_lead_id` na tabela `leads`
- O `WF08` tenta relacionar `fb_leads -> leads` por `leads.fb_lead_id`
- Isso cria falso negativo de `sem_lead` no monitoramento de handoff

## 04 - Chatwoot Message Logger

ID: `MlscoOb4IqmMpgQr`
Atualizado em producao: `2026-03-11T17:28:10.529Z`

Papel:

- recebe eventos de mensagem do Chatwoot
- normaliza telefone, conversa, direcao, role e conteudo
- verifica se o lead ja esta qualificado
- grava mensagens do lado vendedor na tabela `messages`

## 08 - Health Check

ID: `Oj8SgieQ4HH7Czbk`
Atualizado em producao: `2026-03-16T12:49:21.750Z`

### Sinais monitorados

- Evolution: `fetchInstances`
- Chatwoot API autenticada
- ultimas execucoes do `WF06`
- ultimas execucoes do `WF07`
- snapshot de `fb_leads`
- snapshot de `ia_messages`
- snapshot de sinais em `events`
- snapshot de handoff do Path 3

### Estado real observado em 2026-03-17

Ultima execucao analisada: `3019`

- `overall_status = down`
- `critical_issues`:
  - `fb_leads_stale_pending`
  - `fb_leads_missing_first_message`
- `warnings`:
  - `wf07_unknown_routes_last_24h`

Metrica de roteamento:

- `qualified_routes_last_24h = 8`
- `unknown_routes_last_24h = 3`

### Problema confirmado no handoff

O `WF08` mostra:

- `handoffs_last_24h = 1`
- `leads_created_last_24h = 0`
- `assignments_last_24h = 0`
- `stuck_path3_leads` com issue `sem_lead`

Isso eh consistente com o contrato atual do `03-Finalize-Handoff`,
que nao persiste `fb_lead_id` em `leads`.

## Problemas Operacionais Confirmados em Producao

### 1. Drift entre conversa SDR e conversa transferida no Chatwoot

Para o contato `Paulo` (`contact_id = 41`), foram observadas duas conversas abertas:

- conversa `67`
  - `inbox_id = 3`
  - `team = vendedor - tiago`
  - ultima mensagem relevante do lead: `Aguardo`
- conversa `72`
  - `inbox_id = 1`
  - sem team atribuida
  - contem a mensagem final do agente avisando o handoff

Isso indica que a conversa do handoff e a conversa efetivamente atendida
nao estao totalmente consolidadas no mesmo thread.

### 2. `unknown routes` reais no WF07

Execucoes recentes do `WF07` mostram `lead_type = unknown` para mensagens como:

- `obrigado`
- mensagem de apresentacao comercial do proprio vendedor

No estado atual, essas execucoes param no `Switch Lead Type`.

### 3. `Save Recommendations` ainda usa SQL dinamico

O node ainda monta `INSERT` via expressao completa em `query`.
Isso foge do padrao recomendado de placeholders/query parameters.

## O que este documento nao confirma diretamente

- credenciais brutas do Postgres/Supabase
- versoes exatas expostas por API de todos os servicos

O estado do banco foi inferido por leituras vivas feitas pelos workflows ativos
e pelas execucoes do `WF08`, sem extrair credenciais de banco fora do fluxo.
