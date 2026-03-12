# Teste 08 - WF06 Webhook Meta Hotfix + Backfill Validado

**Data:** 2026-03-11
**Status:** SUCESSO COMPLETO

## Contexto

O problema relatado era: formularios do Meta Ads estavam sendo preenchidos, mas o fluxo principal `WF06` nao estava gerando o comportamento esperado.

Analise no ambiente real mostrou que o webhook estava chegando no n8n, porem o fluxo estava quebrado em pontos criticos.

## Causa raiz encontrada no ambiente real

1. **Meta -> n8n estava funcionando**
   - O webhook `/webhook/meta-leads` estava recebendo eventos reais do Facebook.
   - Foram encontrados varios `leadgen_id` reais nas execucoes do `WF06`.

2. **`Extract Form Fields` estava hardcoded**
   - O node usava payload fixo de teste (`TEST_E2E_FULL_005`) em vez de ler o lead real.

3. **Node `HTTP Request` da Graph API estava desconectado**
   - O fluxo nao buscava os dados reais do Lead Ads antes de classificar/processar.

4. **Chave da Evolution API estava incorreta**
   - `WF06` e `WF07` estavam com `apikey` antiga nos nodes de envio.
   - Isso gerava `Unauthorized` no envio de WhatsApp.

5. **Path 2 parava quando nao havia distribuidores**
   - `Find Distributors` retornava zero itens e a branch nao chegava em `Compose Message P2`.

6. **Retry manual nao era idempotente**
   - `Save fb_lead` usava `ON CONFLICT DO NOTHING`.
   - Em replay manual, o node deixava de retornar `id`, quebrando updates a jusante.

## Ajustes aplicados no n8n real

### WF06 - `06-FB-Leads-Outbound-Webhook`

1. Conectado:
   - `Acknowledge FB Event -> HTTP Request -> Extract Form Fields`

2. Reescrito `Extract Form Fields` para:
   - Ler `field_data` real da Graph API
   - Mapear `nome`, `email`, `telefone`, `perfil`, `volume_faixa`, `cnpj_raw`, `estado_envio`
   - Normalizar labels do formulario (`abaixo_de_2.000`, `oficina_`, etc.)
   - Usar `leadgen_id`, `form_id` e `page_id` reais do webhook

3. Atualizada `apikey` da Evolution nos nodes:
   - `Send WhatsApp P2`
   - `Send WhatsApp P3`

4. Ajustado `Find Distributors`:
   - `alwaysOutputData = true`
   - Permite fallback generico quando nao ha distribuidores no estado

5. Ajustado `Save Recommendations`:
   - Quando `distributors_json` vem vazio, faz `SELECT 1`
   - Evita SQL invalido em path 2 sem distribuidores

6. Ajustado `Save fb_lead`:
   - `ON CONFLICT (facebook_lead_id) DO UPDATE SET updated_at = NOW() RETURNING id`
   - Garante retry seguro e retorno de `id`

### WF07 - `07-FB-Leads-Inbound`

Atualizada `apikey` da Evolution nos nodes:

- `Notify Vendor`
- `Auto Reply Unknown`
- `Presence Composing`
- `Send WhatsApp`

## Validacao incremental

### 1. Replay de lead real - Path 2

**leadgen_id:** `1471815894298366`

Resultado:
- `Extract Form Fields` passou a ler lead real
- `Classify Lead` => `path = 2`
- `Send WhatsApp P2` executado com sucesso
- `fb_leads.status = contacted`
- `agent_type = distributor_agent`
- `chatwoot_contact_id` e `chatwoot_conversation_id` preenchidos

### 2. Replay de lead real - Path 3

**leadgen_id:** `1106485325145097`

Resultado:
- `Classify Lead` => `path = 3`
- `Send WhatsApp P3` executado com sucesso
- `fb_leads.status = contacted`
- `agent_type = qualified_agent`
- conversa criada no Chatwoot

## Backfill executado

Foram reprocessados os 7 leads recentes do backlog:

| leadgen_id | Nome | Path | Status final | Agent type | Conv. Chatwoot |
|-----------|------|------|--------------|------------|----------------|
| `1471815894298366` | Alves Jesus | 2 | `contacted` | `distributor_agent` | 34 |
| `1106485325145097` | Francisco Junior | 3 | `contacted` | `qualified_agent` | 35 |
| `1041337892394302` | Lucas | 2 | `contacted` | `distributor_agent` | 37 |
| `1487127269650514` | Raffael | 2 | `contacted` | `distributor_agent` | 36 |
| `2060049421232298` | Leofilms | 2 | `contacted` | `distributor_agent` | 38 |
| `1227430549589137` | Carlos | 2 | `contacted` | `distributor_agent` | 40 |
| `1999376027327312` | W L Climatizacao Automotiva | 2 | `contacted` | `distributor_agent` | 39 |

## Conclusao

O problema principal **nao era ausencia de disparo do webhook da Meta**.

O que acontecia na pratica era:

1. A Meta chamava o webhook normalmente
2. O `WF06` usava payload de teste hardcoded
3. O envio de WhatsApp falhava por `apikey` incorreta
4. Em alguns casos o path 2 ainda parava sem fallback

Depois do hotfix:

- o webhook continua chegando normalmente
- o `WF06` agora processa o lead real vindo do Meta Ads
- o envio pelo WhatsApp voltou a funcionar
- os 7 leads recentes foram tratados manualmente com sucesso

## Observacao

As execucoes historicas tambem mostram 3 `leadgen_id` reais mais antigos em erro antes deste hotfix:

- `2187827958689710`
- `1503840248044295`
- `1974165907313490`

Eles nao foram incluidos neste backfill do lote recente de 7 leads.
