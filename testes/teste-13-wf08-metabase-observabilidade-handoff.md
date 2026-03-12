# Teste 13 - WF08 + Metabase - Observabilidade de Handoff e Erros Silenciosos

**Data:** 2026-03-12  
**Ambiente:** producao real (`n8n`, `Supabase`, `Metabase`)  
**Objetivo:** ampliar o monitoramento para cobrir falhas silenciosas de negocio, especialmente `handoff` ausente, rotas `unknown` no `WF07` e falta de resposta em conversas rastreadas.

## Escopo executado

### 1. Workflow alterado

- `08-Health-Check` (`Oj8SgieQ4HH7Czbk`)

### 2. Workflows nao alterados nesta rodada

- `06-FB-Leads-Outbound-Webhook`
- `07-FB-Leads-Inbound`
- `03-Finalize-Handoff`

Observacao:
- O `WF07` ja havia sido atualizado previamente pelo usuario com a correcao de telefone `12 -> 13 digitos` + SQL com `OR` para ambos os formatos.
- Nesta rodada, nenhum ajuste adicional foi aplicado fora do `WF08`.

## Mudancas aplicadas no WF08

### 1. Execucoes do n8n

- `WF06 Executions` passou a buscar com `includeData=true` e `limit=25`
- `WF07 Executions` passou a buscar com `includeData=true` e `limit=50`

Motivo:
- permitir ao `WF08` inspecionar `lastNodeExecuted` e `Lookup Lead Path` das execucoes reais do `WF07`
- detectar rotas `unknown` e falhas silenciosas que nao geram `infra_error`

### 2. Message Health Snapshot

Substituido por uma query focada apenas em conversas do funil real:

- considera apenas `fb_leads` de `path in (2,3)` com `first_message_sent_at`
- ignora sessoes ja convertidas em `leads`
- mede:
  - `user_messages_last_24h`
  - `assistant_messages_last_24h`
  - `overdue_reply_count`
  - `stale_unreplied_count`
  - `unreplied_threads`

### 3. Novo node

- `Handoff Health Snapshot`

Nova query para `Path 3`, medindo:

- `path3_last_24h`
- `path3_contacted_last_24h`
- `awaiting_user_reply_count`
- `path3_replied_last_24h`
- `handoffs_last_24h`
- `leads_created_last_24h`
- `assignments_last_24h`
- `replied_without_handoff_count`
- `replied_without_assistant_count`
- `lead_without_assignment_count`
- `assignment_without_handoff_event_count`
- `last_handoff_at`
- `last_path3_reply_at`
- `stuck_path3_leads`

### 4. Consolidate Results

Expandido para gerar:

- `handoff_health`
- `routing_health`
- `message_health` com `stale_unreplied_count`
- `checks` com novos servicos:
  - `handoff_health`
  - `routing_health`

Regras novas:

- `handoff_health = down` se houver:
  - lead que respondeu e nao virou handoff
  - lead criado sem assignment
  - assignment sem evento final de handoff
- `routing_health = warn` se houver rotas `unknown` nas ultimas 24h
- `message_health = down` se houver conversa rastreada sem resposta persistente

## Validacao do WF08

Workflow salvo com sucesso no n8n:

- `updatedAt = 2026-03-12T13:03:48.177Z`

Nova execucao validada:

- `health_check.created_at = 2026-03-12T13:05:53.743505+00:00`

Campos novos confirmados no payload:

- `handoff_health`
- `routing_health`
- check `handoff_health`
- check `routing_health`

Estado retornado nessa execucao:

- `overall_status = warn`
- warnings:
  - `infra_errors_last_24h`
  - `wf07_unknown_routes_last_24h`

## Mudancas aplicadas no Metabase

### Cards atualizados

- `41` -> `Alertas Ativos`
- `42` -> `Rotas WF07 - Ultimas 24h`
- `48` -> `Health Check - Status Atual`

### Cards criados

- `58` -> `Minutos desde o Ultimo Handoff`
- `59` -> `Path 3 Respondidos sem Handoff`
- `60` -> `Path 3 Aguardando Resposta`
- `61` -> `Rotas Unknown 24h`
- `62` -> `Funil Path 3 - 24h`
- `63` -> `Leads Travados no Handoff`
- `64` -> `Rotas Unknown Recentes`

### Dashboard atualizado

- Dashboard: `ASX SDR - Monitor Tecnico`
- Total final de cards: `18`

## Validacao do dashboard

Cards presentes no dashboard apos a atualizacao:

- `Taxa de Erros por Hora`
- `Alertas Ativos`
- `Erros por Workflow`
- `Rotas WF07 - Ultimas 24h`
- `Handoffs Hoje`
- `Leads Hoje - Total`
- `Leads Hoje - Path 1 (Desqualificados)`
- `Leads Hoje - Path 2 (Distribuidores)`
- `Leads Hoje - Path 3 (Qualificados)`
- `Ultimos Erros`
- `Health Check - Status Atual`
- `Minutos desde o Ultimo Handoff`
- `Path 3 Respondidos sem Handoff`
- `Path 3 Aguardando Resposta`
- `Rotas Unknown 24h`
- `Funil Path 3 - 24h`
- `Leads Travados no Handoff`
- `Rotas Unknown Recentes`

Resultados confirmados na validacao:

- `Alertas Ativos = 2`
- `Rotas WF07 - Ultimas 24h`:
  - `Unknown = 4`
  - `P2 = 1`
  - `Ja Qualificado = 0`
- `Health Check - Status Atual` mostra `routing_health = warn`
- `Minutos desde o Ultimo Handoff = -1`
- `Path 3 Respondidos sem Handoff = 0`
- `Path 3 Aguardando Resposta = 2`
- `Rotas Unknown 24h = 4`
- `Funil Path 3 - 24h`:
  - `Path 3 criados = 2`
  - `Primeira mensagem enviada = 2`
  - `Aguardando resposta do lead = 2`
- `Leads Travados no Handoff = []`
- `Rotas Unknown Recentes` exibe as execucoes reais do `WF07` que cairam em `Auto Reply Unknown`

## Leitura operacional final

O dashboard agora cobre melhor:

- saude tecnica dos servicos
- erros de execucao
- funil de `Path 3`
- ausencia de handoff
- falta de resposta em conversas rastreadas
- rotas `unknown` do `WF07`

O painel deixa de depender apenas de `infra_error` e passa a mostrar erros silenciosos de negocio.

## Limitacoes que continuam existindo

- ainda nao existe comparacao direta com a origem externa da Meta Ads
- portanto, o caso `lead preencheu formulario mas webhook nunca chegou` continua sem fonte externa de verdade
- para isso, sera necessario instrumentar um check adicional fora do banco interno
