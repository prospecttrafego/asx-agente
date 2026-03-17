# Estado Atual de Producao

Data da auditoria: 2026-03-17

Este documento registra o retrato operacional observado diretamente nos servicos
em producao no momento da auditoria.

## Resumo Executivo

- `n8n`: acessivel e autenticado
- `Chatwoot`: acessivel e autenticado
- `Evolution API`: acessivel; instancia `ASX_SDR` com status `open`
- `WF08`: em estado `down` na ultima execucao analisada

## Inventario de Workflows Ativos

| Workflow | ID | UpdatedAt (UTC) |
|---|---|---|
| 02-Tool-Label (callable) | `QBZhzIYU7qBuE6p5` | `2026-03-02T18:01:50.453Z` |
| 02A-Company-Enrich (callable) | `fRc8nB8qUjJUrTHw` | `2026-03-11T17:28:09.829Z` |
| 02B-Score-Lead (callable) | `gPxoxxAA88LVdZ7Y` | `2025-12-15T13:39:10.407Z` |
| 02C-Agent-Log (callable) | `N1b1o3ED1FXDHWBW` | `2025-12-15T17:11:51.072Z` |
| 02D-Find-Distributors (callable) | `DEwqsmZDj8fIMjuq` | `2026-03-11T17:28:10.115Z` |
| 03-Finalize-Handoff (callable) | `OvvMcnq571vIb9bK` | `2026-03-12T15:50:37.835Z` |
| 04-Chatwoot-Message-Logger | `MlscoOb4IqmMpgQr` | `2026-03-11T17:28:10.529Z` |
| 05-Error-Logger | `WBqj1UKzZORCANPo` | `2026-03-11T14:38:33.357Z` |
| 06-FB-Leads-Outbound-Webhook | `7LvmLJIL7CdbWpbt` | `2026-03-12T12:43:23.876Z` |
| 07-FB-Leads-Inbound | `hGsfyVT8TPWau6RH` | `2026-03-12T12:58:54.201Z` |
| 08-Health-Check | `Oj8SgieQ4HH7Czbk` | `2026-03-16T12:49:21.750Z` |

## Servicos

### Evolution API

Leitura confirmada em `GET /instance/fetchInstances`.

- instancia: `ASX_SDR`
- status: `open`
- `ownerJid`: `557598374087@s.whatsapp.net`
- integracao Chatwoot ativa:
  - `enabled = true`
  - `accountId = 1`
  - `nameInbox = Inbox SDR`
  - `reopenConversation = true`
  - `importMessages = true`
  - `mergeBrazilContacts = true`

### Chatwoot

Busca autenticada confirmou:

- `account_id = 1`
- inbox operacional do SDR: `Inbox SDR`

Leitura de conversas abertas:

- `all_count = 39`
- `assigned_count = 2`
- `unassigned_count = 37`

### Supabase

O projeto aponta para `https://hxcfvyhjyibdexazrhox.supabase.co`.

Nesta auditoria, nao houve autenticacao direta na API REST do Supabase porque o
workspace documental nao contem `.env` com as chaves de acesso e a extracao de
credenciais do n8n nao foi usada como atalho.

Assim, o estado do banco descrito aqui foi inferido por:

- nodes Postgres dos workflows vivos
- resultados reais do `WF08`
- dados operacionais refletidos pelo `WF06`, `WF07` e `03`

### n8n

Leitura autenticada confirmou:

- workflows ativos acessiveis por API
- execucoes acessiveis com `includeData=true`

## WF08 - Saude Operacional Atual

Ultima execucao revisada: `3019`
Inicio: `2026-03-17T13:00:56.035Z`

### Status

- `overall_status = down`

### Critical issues

- `fb_leads_stale_pending`
- `fb_leads_missing_first_message`

### Warnings

- `wf07_unknown_routes_last_24h`

### Roteamento do WF07 nas ultimas 24h

- `qualified_routes_last_24h = 8`
- `distributor_routes_last_24h = 0`
- `already_qualified_routes_last_24h = 0`
- `unknown_routes_last_24h = 3`

### Handoff Path 3

- `path3_last_24h = 1`
- `path3_contacted_last_24h = 1`
- `path3_replied_last_24h = 1`
- `handoffs_last_24h = 1`
- `leads_created_last_24h = 0`
- `assignments_last_24h = 0`

Interpretacao:

- ha evento de handoff
- nao ha associacao consistente com registro de `lead` e `assignment`
- o monitoramento acusa `sem_lead`

## Conversas Relevantes Observadas no Chatwoot

Contato: `Paulo`

- `contact_id = 41`
- `phone = +556984376683`
- `custom_attributes.lead_path = qualified`
- `custom_attributes.fb_form_cnpj = 34887536000192`
- `custom_attributes.fb_form_estado = Rondonia`
- `custom_attributes.fb_form_perfil = Oficina`
- `custom_attributes.fb_form_volume = Entre 4.000 e 10.000`

### Conversa 67

- `conversation_id = 67`
- `inbox_id = 3`
- `team = vendedor - tiago`
- ultima mensagem relevante do lead: `Aguardo`
- possui atividade de atribuicao para vendedor

### Conversa 72

- `conversation_id = 72`
- `inbox_id = 1`
- sem team atribuida
- contem a mensagem final do agente avisando que conectou o lead ao especialista

### Leitura operacional

O mesmo contato esta com duas conversas abertas em estados diferentes.
Isso indica que o handoff e o thread efetivo de atendimento nao estao totalmente
amarrados na mesma conversa.

## Limites desta auditoria

- a leitura do estado do banco veio dos workflows vivos e das execucoes reais do n8n
- nao foi feita extracao direta das credenciais do banco
- o workspace documental nao contem `.env` local com chaves reais do Supabase
- este documento nao substitui teste E2E controlado quando houver mudanca de workflow
