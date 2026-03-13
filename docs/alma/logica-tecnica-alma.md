# Logica Tecnica — ALMA SDR

Documentacao tecnica completa dos 7 workflows do agente SDR ALMA: nodes, expressoes, parametros, conexoes, credenciais, queries e codigo.

---

## Indice

1. [WF01 — Orquestrador ALMA](#wf01--orquestrador-alma)
2. [WF02 — Pesquisador ALMA](#wf02--pesquisador-alma)
3. [WF03 — Agendador ALMA](#wf03--agendador-alma)
4. [WF04 — Re-engajamento ALMA](#wf04--re-engajamento-alma)
5. [WF05 — Aplicar Label ALMA](#wf05--aplicar-label-alma)
6. [WF06 — Atualizar Lead ALMA](#wf06--atualizar-lead-alma)
7. [WF09 — Buscar Conhecimento ALMA (RAG)](#wf09--buscar-conhecimento-alma-rag)
8. [Infraestrutura e Credenciais](#infraestrutura-e-credenciais)
9. [Mapa de Dependencias](#mapa-de-dependencias)

---

## WF01 — Orquestrador ALMA

**ID:** `iVLW5nD9TmDh42Jz`
**Tipo:** Principal
**Nodes:** 37
**Tags:** `ALMA SDR`, `Principal`
**Status:** Inativo

### Cadeia de Execucao

```
Webhook (POST /alma-sdr)
  → Extrair Campos (Set)
    → Filter Incoming (IF: message_type==0 AND sender_type=="contact")
      → [TRUE] Fetch Conversation (GET Chatwoot)
        → Check Team + Labels (IF: team==1, sem handoff, sem reuniao_agendada)
          → [TRUE] Prepare for Redis (Set)
            → Redis Push (RPUSH alma:conv:{id})
              → Wait 10s
                → Redis Get Messages
                  → IF Last Message == Mine (deduplicacao)
                    → [TRUE] Merge Messages (Code)
                      → Upsert Conversa (POST Supabase)
                        → Redis Delete
                          → Log User Message (POST Supabase)
                            → ORQUESTRADOR (AI Agent)
                              → Log AI Message (POST Supabase)
                                → Fragmentar Resposta (Code)
                                  → Split Out
                                    → Loop Over Items
                                      → Typing Indicator (POST Chatwoot)
                                        → Calculate Delay (Code)
                                          → Wait Dynamic
                                            → Send Message (POST Chatwoot)
                                              → Wait Between (1.5s)
                                                → Loop (volta)
                    → [FALSE] No Operation (descarta)

Conexoes AI do ORQUESTRADOR:
  Claude Sonnet --------→ ai_languageModel
  Postgres Chat Memory --→ ai_memory
  tool_pesquisador ------→ ai_tool
  tool_agendador --------→ ai_tool
  tool_atualizar_lead ---→ ai_tool
  tool_aplicar_label ----→ ai_tool
  tool_mover_para_humano → ai_tool
  tool_private_note -----→ ai_tool
  tool_buscar_conhecimento → ai_tool
```

### Nodes Detalhados

#### Webhook

| Campo | Valor |
|-------|-------|
| Tipo | `n8n-nodes-base.webhook` v2.1 |
| Metodo | POST |
| Path | `alma-sdr` |
| webhookId | `alma-sdr-webhook` |

Recebe eventos `message_created` do Chatwoot.

#### Extrair Campos

| Campo | Valor |
|-------|-------|
| Tipo | `n8n-nodes-base.set` v3.4 |
| Modo | raw JSON |

```javascript
{
  "conversation_id": {{ $json.body.conversation.id }},
  "contact_id": {{ $json.body.conversation.contact_id || $json.body.sender.id }},
  "message_content": {{ JSON.stringify($json.body.content || '') }},
  "message_type": {{ $json.body.message_type }},
  "sender_type": {{ JSON.stringify($json.body.sender?.type || '') }},
  "inbox_id": {{ $json.body.inbox?.id || 0 }},
  "account_id": {{ $json.body.account?.id || 0 }}
}
```

#### Filter Incoming

| Campo | Valor |
|-------|-------|
| Tipo | `n8n-nodes-base.if` v2.2 |
| Combinator | AND |

Condicoes:
1. `$json.message_type` == `0` (incoming)
2. `$json.sender_type` == `"contact"`

#### Fetch Conversation

| Campo | Valor |
|-------|-------|
| Tipo | `n8n-nodes-base.httpRequest` v4.2 |
| Metodo | GET |
| URL | `https://chat.almaagencia.com.br/api/v1/accounts/1/conversations/{{ $json.conversation_id }}` |
| Auth | httpHeaderAuth (Chatwoot) |
| neverError | true |

#### Check Team + Labels

| Campo | Valor |
|-------|-------|
| Tipo | `n8n-nodes-base.if` v2.2 |
| Combinator | AND, loose |

Condicoes:
1. `$json.meta?.team?.id || 0` == `1` (Team IA)
2. `($json.labels || []).join(',')` NAO contem `"handoff"`
3. `($json.labels || []).join(',')` NAO contem `"reuniao_agendada"`

#### Prepare for Redis

```javascript
{
  "redis_key": "alma:conv:{{ $('Extrair Campos').item.json.conversation_id }}",
  "message_content": {{ JSON.stringify($('Extrair Campos').item.json.message_content) }},
  "conversation_id": {{ $('Extrair Campos').item.json.conversation_id }},
  "contact_id": {{ $('Extrair Campos').item.json.contact_id }}
}
```

#### Redis Push

| Campo | Valor |
|-------|-------|
| Tipo | `n8n-nodes-base.redis` v1 |
| Operation | push (RPUSH) |
| tail | true |

#### Wait 10s (Batching Window)

Pausa de 10 segundos para acumular mensagens rapidas.

#### Redis Get Messages

| Campo | Valor |
|-------|-------|
| Operation | get |
| Key | `={{ $('Prepare for Redis').item.json.redis_key }}` |
| dotNotation | false |

#### IF Last Message == Mine (Deduplicacao)

```
leftValue: Array.isArray($json.value) ? $json.value[$json.value.length - 1] : $json.value
operator: equals
rightValue: $('Prepare for Redis').item.json.message_content
```

Quando o lead envia 3 mensagens rapidas, 3 execucoes do workflow sao disparadas. Todas empurram para a mesma lista Redis e esperam 10s. Apos o wait, todas leem a mesma lista. So a execucao cuja mensagem e a ULTIMA da lista prossegue. As demais caem no NoOp.

#### Merge Messages (Code)

```javascript
const messages = $input.first().json.value;
const merged = Array.isArray(messages) ? messages.join('\n') : (messages || '');
const conversationId = $('Prepare for Redis').first().json.conversation_id;
const contactId = $('Prepare for Redis').first().json.contact_id;

return [{
  json: {
    txt: merged,
    conversation_id: conversationId,
    contact_id: contactId,
    redis_key: $('Prepare for Redis').first().json.redis_key
  }
}];
```

#### Upsert Conversa

| Campo | Valor |
|-------|-------|
| Metodo | POST |
| URL | `https://ujdlrrzpkbuxcrpmmast.supabase.co/rest/v1/conversas` |
| Header extra | `Prefer: resolution=merge-duplicates` (upsert) |

```json
{
  "chatwoot_conversation_id": {{ $json.conversation_id }},
  "chatwoot_contact_id": {{ $json.contact_id }},
  "ultima_msg_lead": "{{ new Date().toISOString() }}"
}
```

#### Redis Delete

| Campo | Valor |
|-------|-------|
| Operation | delete |
| Key | `={{ $('Merge Messages').item.json.redis_key }}` |

#### Log User Message

| Campo | Valor |
|-------|-------|
| Metodo | POST |
| URL | `https://ujdlrrzpkbuxcrpmmast.supabase.co/rest/v1/mensagens` |

```json
{
  "chatwoot_conversation_id": {{ $('Merge Messages').item.json.conversation_id }},
  "direction": "user",
  "content": {{ JSON.stringify($('Merge Messages').item.json.txt) }}
}
```

#### ORQUESTRADOR (AI Agent)

| Campo | Valor |
|-------|-------|
| Tipo | `@n8n/n8n-nodes-langchain.agent` v1.7 |
| promptType | define |
| text (input) | `={{ $('Merge Messages').item.json.txt }}` |

**Contexto injetado no system prompt:**
```
Conversation ID: {{ $('Merge Messages').item.json.conversation_id }}
Contact ID: {{ $('Merge Messages').item.json.contact_id }}
```

**System prompt (resumo da estrutura):**
1. Identidade: Consultor de crescimento da ALMA (saude/estetica)
2. Regras obrigatorias (7): msgs curtas, proximo passo claro, adaptar tom, coletar dados via tool
3. Regras proibidas (9): nao revelar IA, nao falar preco, nao forcar agendamento
4. Framework Challenger Selling: Ponto Forte → Limitador → Oportunidade → Pergunta
5. Conduzir ao agendamento apos 3-4+ trocas. Recusou 2x → follow_up
6. Instrucoes de uso de cada tool
7. Cenarios de conversa

#### Claude Sonnet (LLM)

| Campo | Valor |
|-------|-------|
| Tipo | `@n8n/n8n-nodes-langchain.lmChatAnthropic` v1.3 |
| Modelo | `claude-sonnet-4-20250514` |
| maxTokensToSample | 1024 |
| temperature | 0.4 |

#### Postgres Chat Memory

| Campo | Valor |
|-------|-------|
| Tipo | `@n8n/n8n-nodes-langchain.memoryPostgresChat` v1.3 |
| sessionKey | `={{ $('Merge Messages').item.json.conversation_id }}` |
| contextWindowLength | 25 |

#### Tools do Agente (7)

| Tool | Tipo | Workflow/Config |
|------|------|-----------------|
| tool_pesquisador | toolWorkflow v2.2 | WF `vtPkk2SLbdP1j4G4Guu2V` |
| tool_agendador | toolWorkflow v2.2 | WF `dYiG2Rku9Oo4hhF6QSVlZ` |
| tool_atualizar_lead | toolWorkflow v2.2 | WF `9N9KoZqoH8wTi7Wu` |
| tool_aplicar_label | toolWorkflow v2.2 | WF `K8JeeL6xjpEPVXiNCsRgt` |
| tool_buscar_conhecimento | toolWorkflow v2.2 | WF `HcfcLymgh9HSu8Oc` |
| tool_mover_para_humano | toolHttpRequest v1.1 | POST `/conversations/{id}/assignments` body `{"team_id": 2}` |
| tool_private_note | toolHttpRequest v1.1 | POST `/conversations/{id}/messages` body `{"content": $fromAI('conteudo', '...'), "message_type": "outgoing", "private": true}` |

**Descricoes das tools (passadas ao LLM):**

- **tool_pesquisador:** "Pesquisa e analisa o perfil Instagram e/ou site do lead, cruzando com tendencias do nicho. Chame quando o lead fornecer Instagram/site E seu objetivo."
- **tool_agendador:** "Verifica disponibilidade e agenda o Diagnostico Estrategico no Google Calendar. Chame quando o lead aceitar agendar."
- **tool_atualizar_lead:** "Atualiza os custom attributes do contato no Chatwoot. Chame sempre que coletar informacoes do lead."
- **tool_aplicar_label:** "Adiciona labels a conversa SEM sobrescrever as existentes. Labels: novo, em_andamento, reuniao_agendada, follow_up, sem_resposta, desqualificado, handoff."
- **tool_buscar_conhecimento:** "Busca informacoes na base de conhecimento da ALMA (RAG). USE QUANDO: objecao desconhecida, pergunta sobre servicos/metodologia/diferenciais, cenario complexo."
- **tool_mover_para_humano:** Move para Team 2 (humano) via Chatwoot assignments API.
- **tool_private_note:** Cria nota privada com resumo. Usa `$fromAI('conteudo', '...')` (1 parametro).

#### Log AI Message

| Campo | Valor |
|-------|-------|
| Metodo | POST |
| URL | `https://ujdlrrzpkbuxcrpmmast.supabase.co/rest/v1/mensagens` |

```json
{
  "chatwoot_conversation_id": {{ $('Merge Messages').item.json.conversation_id }},
  "direction": "assistant",
  "content": {{ JSON.stringify($json.output || '') }}
}
```

#### Fragmentar Resposta (Code)

```javascript
const output = $input.first().json.output || '';

// Split por paragrafo
let fragments = output.split('\n\n').filter(part => part.trim().length > 0);

// Se fragmento > 200 chars, subdivide por sentenca (max 2 por fragmento)
const finalFragments = [];
for (const frag of fragments) {
  if (frag.length > 200) {
    const sentences = frag.match(/[^.!?]+[.!?]+/g) || [frag];
    let current = '';
    let sentenceCount = 0;
    for (const s of sentences) {
      if (sentenceCount >= 2 && current.trim()) {
        finalFragments.push(current.trim());
        current = s;
        sentenceCount = 1;
      } else {
        current += s;
        sentenceCount++;
      }
    }
    if (current.trim()) finalFragments.push(current.trim());
  } else {
    finalFragments.push(frag.trim());
  }
}

return [{
  json: {
    messages: finalFragments.length > 0 ? finalFragments : [output],
    conversation_id: $('Merge Messages').first().json.conversation_id
  }
}];
```

#### Split Out

| Campo | Valor |
|-------|-------|
| Tipo | `n8n-nodes-base.splitOut` v1 |
| fieldToSplitOut | `messages` |

Transforma array `messages` em itens individuais.

#### Loop Over Items

| Campo | Valor |
|-------|-------|
| Tipo | `n8n-nodes-base.splitInBatches` v3 |
| Batch size | 1 (padrao) |

#### Typing Indicator

| Campo | Valor |
|-------|-------|
| Metodo | POST |
| URL | `https://chat.almaagencia.com.br/api/v1/accounts/1/conversations/{{ $('Fragmentar Resposta').item.json.conversation_id }}/toggle_typing` |
| Body | `{"typing_status": "on"}` |

#### Calculate Delay (Code)

```javascript
const message = $input.first().json.messages || $input.first().json.message || '';
const chars = typeof message === 'string' ? message.length : 0;

// chars * 30ms + random(1000, 3000)ms
// Min: 2000ms, Max: 8000ms
const baseDelay = chars * 30;
const randomExtra = Math.floor(Math.random() * 2000) + 1000;
let delay = baseDelay + randomExtra;
delay = Math.max(2000, Math.min(8000, delay));

return [{
  json: {
    ...$input.first().json,
    delay_ms: delay,
    delay_seconds: Math.ceil(delay / 1000)
  }
}];
```

#### Wait Dynamic

| Campo | Valor |
|-------|-------|
| amount | `={{ $json.delay_seconds }}` |

#### Send Message

| Campo | Valor |
|-------|-------|
| Metodo | POST |
| URL | `https://chat.almaagencia.com.br/api/v1/accounts/1/conversations/{{ $('Fragmentar Resposta').item.json.conversation_id }}/messages` |

```json
{
  "content": {{ JSON.stringify($json.messages || $json.message || '') }},
  "message_type": "outgoing"
}
```

#### Wait Between

Pausa de **1.5 segundos** entre fragmentos. Volta para o Loop Over Items.

---

## WF02 — Pesquisador ALMA

**ID:** `q492GAhZzTDjjgYg`
**Tipo:** Sub-workflow (tool do orquestrador)
**Nodes:** 12
**Tags:** `ALMA SDR`, `Sub-Agente`
**Status:** Inativo

### Cadeia de Execucao

```
When Executed by Another Workflow
  → Validate Input (Set)
    ├→ Apify Instagram Scrape (HTTP POST, 120s timeout)
    ├→ IF Site Exists
    │   ├→ [TRUE] Fetch Site (HTTP GET, 15s timeout)
    │   └→ [FALSE] No Site (noOp)
    └→ Web Search / SerpAPI (HTTP GET, 15s timeout)
         ↓ (todos convergem)
    → Process Data (Code)
      → AI Pesquisador (Agent)
        ← Claude Haiku (ai_languageModel)
      → Format Output (Code)
        → [Retorna ao workflow pai]
```

Os 3 branches (Instagram, Site, Tendencias) rodam em **paralelo**.

### Nodes Detalhados

#### Validate Input

```javascript
{
  "instagram": {{ JSON.stringify(($json.instagram_handle || '').replace('@', '').trim()) }},
  "site_url": {{ JSON.stringify($json.site_url || '') }},
  "objetivo": {{ JSON.stringify($json.objetivo || 'crescer no digital') }},
  "nicho": {{ JSON.stringify($json.nicho || 'geral') }}
}
```

#### Apify Instagram Scrape

| Campo | Valor |
|-------|-------|
| Metodo | POST |
| URL | `https://api.apify.com/v2/acts/apify~instagram-profile-scraper/run-sync-get-dataset-items?token={{ apify_api_... }}` |
| Timeout | 120000ms |
| neverError | true |

```json
{
  "usernames": [{{ JSON.stringify($json.instagram) }}],
  "resultsLimit": 12
}
```

Actor: `apify~instagram-profile-scraper` (execucao sincrona).

#### IF Site Exists

Condicao: `$json.site_url` isNotEmpty

#### Fetch Site

| Campo | Valor |
|-------|-------|
| Metodo | GET |
| URL | `={{ $('Validate Input').item.json.site_url }}` |
| Timeout | 15000ms |
| responseFormat | text |

#### Web Search (SerpAPI)

| Campo | Valor |
|-------|-------|
| Metodo | GET |
| URL | `https://serpapi.com/search?q={{ encodeURIComponent('tendencias ' + $('Validate Input').item.json.nicho + ' marketing digital 2025') }}&api_key={{ ... }}&num=5&hl=pt-br&gl=br` |
| Timeout | 15000ms |

#### Process Data (Code)

Logica principal:
1. **Instagram:** Valida resultado Apify, extrai perfil, calcula **engagement rate** `(avg likes+comments / followers * 100)`, analisa ate 12 posts, identifica top 5 hashtags
2. **Site:** Extrai `<title>` e `<meta description>` via regex
3. **Tendencias:** Extrai 3 primeiros resultados organicos (title + snippet)

Output:
```json
{
  "instagram": { "username", "fullName", "biography", "followersCount", "engagementRate", "topHashtags", "recentPosts" },
  "site": { "title", "description", "hasContent" } | null,
  "trends": [{ "title", "snippet" }],
  "objetivo": "...",
  "nicho": "..."
}
```

Se perfil nao encontrado: `instagram: { error: 'perfil_nao_encontrado' }`

#### AI Pesquisador (Agent)

| Campo | Valor |
|-------|-------|
| Tipo | `@n8n/n8n-nodes-langchain.agent` v1.7 |
| LLM | Claude Haiku 4 (`claude-haiku-4-20250514`) |
| maxTokens | 800 |
| temperature | 0.5 |

**System prompt:** Analista de marketing digital. Gera 4 insights:
1. PONTO_FORTE — algo que o perfil ja faz bem
2. LIMITADOR — gap entre situacao atual e objetivo
3. OPORTUNIDADE — quick-win pratico em 7 dias
4. PERGUNTA — aprofunda a dor, abre caminho para agendamento

**User prompt:** Dados estruturados (Instagram + Site + Tendencias + Objetivo + Nicho).

#### Format Output (Code)

Adiciona contexto numerico ao output da IA: `[Contexto: X seguidores, Y% engagement]`

Output final: `{ resultado: string, success: true }`

---

## WF03 — Agendador ALMA

**ID:** `aUzDLzLnPBhA1p3u`
**Tipo:** Sub-workflow (tool do orquestrador)
**Nodes:** 18
**Tags:** `ALMA SDR`, `Sub-Agente`
**Status:** Inativo

### Cadeia de Execucao

```
When Executed by Another Workflow
  → Validate Input (Set)
    → List Calendar Events (GET Google Calendar)
      → Process Available Slots (Code)
        → AI Agendador (Agent + Claude Haiku + tool criar_evento)
          → Parse Result (Code)
            → IF Agendado
              ├→ [TRUE] Mover Team Agendamento (POST Chatwoot)
              │   → Get Current Labels (GET Chatwoot)
              │     → Apply Label reuniao_agendada (POST Chatwoot)
              │       → Update Contact (PUT Chatwoot)
              │         → Private Note (POST Chatwoot)
              │           → Log Evento (POST Supabase)
              │             → Return Agendado (Set)
              └→ [FALSE] Return Sugestao (Set)
```

### Nodes Detalhados

#### Validate Input

```javascript
{
  "preferencia": {{ JSON.stringify($json.preferencia_horario || 'qualquer') }},
  "lead_name": {{ JSON.stringify($json.lead_name || 'Lead') }},
  "conversation_id": {{ $json.conversation_id || 0 }},
  "contact_id": {{ $json.contact_id || 0 }}
}
```

#### List Calendar Events

| Campo | Valor |
|-------|-------|
| Metodo | GET |
| URL | `https://www.googleapis.com/calendar/v3/calendars/{{ PRIMARY }}/events` |
| Auth | oAuth2Api (Google) |
| Query Params | `timeMin={{ now }}`, `timeMax={{ now + 5 dias }}`, `singleEvents=true`, `orderBy=startTime` |

#### Process Available Slots (Code)

```javascript
// Parametros
const SLOT_DURATION_MIN = 30;
const START_HOUR = 9;
const END_HOUR = 18;

// Gera slots para proximos 7 dias (5 uteis)
// Pula finais de semana (sab/dom)
// Pula hoje se > 17h
// Para hoje, pula hora atual + 1h (buffer)
// Detecta conflitos: slotStart < eventEnd && slotEnd > eventStart
// Formato: "segunda 17/03 as 14h"
// Limite: 6 slots

// Output inclui:
// slots[], slots_formatted[], preferencia, lead_name,
// conversation_id, contact_id, calendar_id, responsavel_nome, responsavel_email
```

#### AI Agendador

| Campo | Valor |
|-------|-------|
| LLM | Claude Haiku 4 |
| maxTokens | 500 |
| temperature | 0.2 |

**System prompt:** Decidir entre agendar (se preferencia bate com slot) ou sugerir 2-3 horarios. Retorna JSON estruturado:
- `{"action": "agendado", "slot": "...", "meet_link": "..."}`
- `{"action": "sugestao", "horarios": [...]}`

#### Tool criar_evento (HTTP Request Tool)

| Campo | Valor |
|-------|-------|
| Metodo | POST |
| URL | `https://www.googleapis.com/calendar/v3/calendars/{{ calendar_id }}/events?conferenceDataVersion=1` |
| Auth | oAuth2Api |

```json
{
  "summary": "Diagnostico Estrategico - {{ lead_name }}",
  "start": { "dateTime": "{{ $fromAI('slot_start', '...') }}", "timeZone": "America/Sao_Paulo" },
  "end": { "dateTime": "{{ $fromAI('slot_end', '...') }}", "timeZone": "America/Sao_Paulo" },
  "attendees": [{"email": "{{ responsavel_email }}"}],
  "conferenceData": { "createRequest": { "requestId": "alma-{{ conversation_id }}-{{ Date.now() }}" } },
  "description": "Diagnostico Estrategico com {{ lead_name }}\nAgendado via ALMA SDR"
}
```

`$fromAI()` — apenas 2 parametros: `slot_start` e `slot_end`.
Google Meet criado automaticamente via `conferenceDataVersion=1`.

#### Parse Result (Code)

```javascript
const output = $input.first().json.output || '';
let result;
try {
  const jsonMatch = output.match(/\{[\s\S]*\}/);
  if (jsonMatch) result = JSON.parse(jsonMatch[0]);
  else result = { action: 'sugestao', message: output };
} catch (e) {
  result = { action: 'sugestao', message: output };
}
return [{ json: { ...result, conversation_id, contact_id, is_agendado: result.action === 'agendado' } }];
```

#### Pos-agendamento (5 acoes em cadeia)

1. **Mover Team Agendamento:** POST `/conversations/{id}/assignments` → `{"team_id": 3}` (Team Agendamento)
2. **Get Current Labels:** GET conversa para obter labels existentes
3. **Apply Label:** POST labels → `[...existing, 'reuniao_agendada']` (dedup com Set)
4. **Update Contact:** PUT contato → `custom_attributes: { reuniao_data, reuniao_link }`
5. **Private Note:** POST mensagem privada com resumo do agendamento
6. **Log Evento:** POST na tabela `eventos` do Supabase → `{ type: "agendamento", payload: {...} }`

#### Schema Input/Output

**Input:**
```json
{
  "preferencia_horario": "terca de manha",
  "lead_name": "Dr. Ana",
  "conversation_id": 123,
  "contact_id": 456
}
```

**Output (agendado):**
```json
{
  "success": true,
  "action": "agendado",
  "message": "Reuniao agendada: segunda 17/03 as 14h. Link do Meet sera enviado por email.",
  "slot": "segunda 17/03 as 14h",
  "meet_link": "https://meet.google.com/xxx"
}
```

**Output (sugestao):**
```json
{
  "success": true,
  "action": "sugestao",
  "message": "segunda 17/03 as 14h, terca 18/03 as 10h",
  "horarios": ["segunda 17/03 as 14h", "terca 18/03 as 10h", "quarta 19/03 as 9h"]
}
```

---

## WF04 — Re-engajamento ALMA

**ID:** `rNlGdxf93lsV8YuD`
**Tipo:** Scheduled (cron)
**Nodes:** 18
**Tags:** `ALMA SDR`, `Cron`
**Status:** Inativo

### Cadeia de Execucao

```
Schedule Trigger (cada 1h)
  → Calculate Boundaries (Code)
    → Fetch Conversas Pendentes (GET Supabase)
      → IF Has Results
        → [TRUE] Loop Over Conversas (SplitInBatches)
          → Calculate Time Delta (Code)
            → Switch Action
              ├→ "1a tentativa": AI Msg → Send Chatwoot → Update Supabase (tentativas=1) → Wait 3s → Loop
              ├→ "2a tentativa": AI Msg → Send Chatwoot → Update Supabase (tentativas=2) → Wait 3s → Loop
              ├→ "Encerrar": Get Labels → Apply Label sem_resposta → Update Status → Wait 3s → Loop
              └→ fallback "none": descarta (skip)
        → [FALSE] (fim silencioso)
```

### Nodes Detalhados

#### Schedule Trigger

| Campo | Valor |
|-------|-------|
| Tipo | `n8n-nodes-base.scheduleTrigger` v1.2 |
| Intervalo | Cada 1 hora |

#### Calculate Boundaries (Code)

```javascript
const now = new Date();
const threeHoursAgo = new Date(now - 3 * 60 * 60 * 1000).toISOString();
const twentyFourHoursAgo = new Date(now - 24 * 60 * 60 * 1000).toISOString();

return [{ json: { now: now.toISOString(), three_hours_ago: threeHoursAgo, twenty_four_hours_ago: twentyFourHoursAgo } }];
```

#### Fetch Conversas Pendentes

| Campo | Valor |
|-------|-------|
| Metodo | GET |
| URL | `https://ujdlrrzpkbuxcrpmmast.supabase.co/rest/v1/conversas` |

Query PostgREST:
- `status=eq.ativa`
- `ultima_msg_lead=lt.{{ three_hours_ago }}`
- `ultima_msg_lead=gt.{{ twenty_four_hours_ago }}`
- `tentativas_reengajamento=lt.2`
- `select=*`

Tabela: `conversas` (colunas: `status`, `ultima_msg_lead`, `tentativas_reengajamento`, `chatwoot_conversation_id`, `ultimo_tema`, `nicho`)

#### Calculate Time Delta (Code)

```javascript
const conversa = $input.first().json;
const now = new Date();
const ultimaMsg = new Date(conversa.ultima_msg_lead);
const horasSinceLastMsg = (now - ultimaMsg) / (1000 * 60 * 60);
const tentativas = conversa.tentativas_reengajamento || 0;

let action = 'skip';
if (tentativas === 0 && horasSinceLastMsg >= 3) action = 'primeira_tentativa';
else if (tentativas === 1 && horasSinceLastMsg >= 22) action = 'segunda_tentativa';
else if (horasSinceLastMsg >= 24) action = 'encerrar';
```

**Regras de timing:**

| Tempo sem resposta | Tentativas | Action |
|--------------------|------------|--------|
| >= 3h | 0 | `primeira_tentativa` |
| >= 22h | 1 | `segunda_tentativa` |
| >= 24h | qualquer | `encerrar` |
| outro | - | `skip` |

#### Switch Action

| Output | Condicao |
|--------|----------|
| 0: "1a tentativa" | `action == "primeira_tentativa"` |
| 1: "2a tentativa" | `action == "segunda_tentativa"` |
| 2: "Encerrar" | `action == "encerrar"` |
| fallback: none | descarta |

#### AI Msg 1a Tentativa

| Campo | Valor |
|-------|-------|
| Metodo | POST |
| URL | `https://api.anthropic.com/v1/messages` |
| Modelo | `claude-3-haiku-20240307` |
| maxTokens | 100 |
| Header | `anthropic-version: 2023-06-01` |

Prompt: "Gere UMA mensagem de re-engajamento leve (1a tentativa)... Max 1 frase curta, tom casual e leve, sem pressao."

#### AI Msg 2a Tentativa

Mesmo endpoint, modelo e config. Prompt diferente: "Gere UMA mensagem de re-engajamento final (2a e ultima tentativa)... Tom de despedida aberta, deixar a porta aberta."

#### Send Message 1 / 2

| Campo | Valor |
|-------|-------|
| Metodo | POST |
| URL | `https://chat.almaagencia.com.br/api/v1/accounts/1/conversations/{{ chatwoot_conversation_id }}/messages` |

```json
{
  "content": {{ JSON.stringify($json.content?.[0]?.text || $json.text || '') }},
  "message_type": "outgoing"
}
```

Extracao: `$json.content[0].text` (formato Anthropic) → fallback `$json.text`.

#### Update Tentativa 1 / 2

| Campo | Valor |
|-------|-------|
| Metodo | PATCH |
| URL | `https://ujdlrrzpkbuxcrpmmast.supabase.co/rest/v1/conversas?chatwoot_conversation_id=eq.{{ id }}` |

```json
{ "tentativas_reengajamento": 1, "updated_at": "now()" }  // ou 2 para 2a tentativa
```

**Bug conhecido:** `"now()"` e salvo como string literal pelo PostgREST (nao interpretado como funcao SQL).

#### Path Encerrar

1. **Get Labels:** GET conversa no Chatwoot
2. **Apply Label sem_resposta:** POST labels → `[...existing, 'sem_resposta']`
3. **Update Status:** PATCH `conversas` → `{ "status": "sem_resposta" }`

#### Wait 3s (Rate Limit)

Pausa de 3 segundos entre processamento de cada conversa. Volta para o Loop.

---

## WF05 — Aplicar Label ALMA

**ID:** `FB8vEBxK3FTDHLzf`
**Tipo:** Sub-workflow
**Nodes:** 10
**Tags:** `ALMA SDR`, `Sub-Workflow`
**Status:** Inativo

### Cadeia de Execucao

```
When Executed by Another Workflow
  → Validate Input (Code)
    → IF Valid
      ├→ [TRUE] GET Current Labels (Chatwoot)
      │   → Merge Labels (Code)
      │     → POST Labels (Chatwoot)
      │       → Log Evento (Supabase)
      │         → Return Success
      └→ [FALSE] Return Error
```

### Nodes Detalhados

#### Validate Input (Code)

- Faz split da string `labels_to_add` por virgula
- Aplica `trim()` e `toLowerCase()`
- Filtra contra allowlist: `['novo', 'em_andamento', 'reuniao_agendada', 'follow_up', 'sem_resposta', 'desqualificado', 'handoff']`

#### GET Current Labels

| Campo | Valor |
|-------|-------|
| Metodo | GET |
| URL | `https://chat.almaagencia.com.br/api/v1/accounts/1/conversations/{{ conversation_id }}` |

#### Merge Labels (Code)

```javascript
const existing = $input.first().json.labels || [];
const newLabels = $('Validate Input').first().json.new_labels;
const merged = [...new Set([...existing, ...newLabels])];
return [{ json: { conversation_id, existing_labels: existing, new_labels: newLabels, merged_labels: merged } }];
```

#### POST Labels

| Campo | Valor |
|-------|-------|
| Metodo | POST |
| URL | `https://chat.almaagencia.com.br/api/v1/accounts/1/conversations/{{ conversation_id }}/labels` |

```json
{ "labels": {{ JSON.stringify($json.merged_labels) }} }
```

#### Log Evento

| Campo | Valor |
|-------|-------|
| Metodo | POST |
| URL | `https://ujdlrrzpkbuxcrpmmast.supabase.co/rest/v1/eventos` |

```json
{
  "type": "label_added",
  "payload": {
    "conversation_id": {{ $json.conversation_id }},
    "labels_added": {{ JSON.stringify($('Validate Input').first().json.new_labels) }},
    "labels_final": {{ JSON.stringify($json.merged_labels) }}
  }
}
```

#### Schema Input/Output

**Input:** `{ conversation_id: number, labels_to_add: string }`
**Output:** `{ success: true, labels_final: string[] }` ou `{ success: false, error: string }`

---

## WF06 — Atualizar Lead ALMA

**ID:** `9M2c4BUSDpW0Enko`
**Tipo:** Sub-workflow
**Nodes:** 9
**Tags:** `ALMA SDR`, `Sub-Workflow`
**Status:** Inativo

### Cadeia de Execucao

```
When Executed by Another Workflow
  → Validate Input (Code)
    → IF Valid
      ├→ [TRUE] GET Contact Atual (Chatwoot)
      │   → Merge Attributes (Code)
      │     → PUT Update Contact (Chatwoot)
      │       → Return Success
      └→ [FALSE] Return Error
```

### Nodes Detalhados

#### Validate Input (Code)

- Aceita `custom_attributes` como objeto ou string JSON (faz parse automatico)
- Filtra campos contra allowlist: `['empresa', 'segmento', 'instagram', 'site', 'objetivo', 'cidade', 'reuniao_data', 'reuniao_link', 'nicho', 'telefone']`
- Aplica `String(value).trim()`, ignora null/undefined/vazio

#### GET Contact Atual

| Campo | Valor |
|-------|-------|
| Metodo | GET |
| URL | `https://chat.almaagencia.com.br/api/v1/accounts/1/contacts/{{ contact_id }}` |

#### Merge Attributes (Code)

```javascript
const currentAttributes = $input.first().json.custom_attributes || {};
const newAttributes = $('Validate Input').first().json.custom_attributes;
const merged = { ...currentAttributes, ...newAttributes };
// Novos sobrescrevem existentes; existentes nao presentes sao preservados
```

#### PUT Update Contact

| Campo | Valor |
|-------|-------|
| Metodo | PUT |
| URL | `https://chat.almaagencia.com.br/api/v1/accounts/1/contacts/{{ contact_id }}` |

```json
{ "custom_attributes": {{ JSON.stringify($json.custom_attributes) }} }
```

#### Schema Input/Output

**Input:** `{ contact_id: number, custom_attributes: object | string }`
**Output:** `{ success: true, message: string, fields_updated: string[] }` ou `{ success: false, error: string }`

**Nota:** Este workflow NAO faz log de evento no Supabase (diferente do WF05).

---

## WF09 — Buscar Conhecimento ALMA (RAG)

**ID:** `l9uRavndwuPMdUmP`
**Tipo:** Sub-workflow
**Nodes:** 5
**Tags:** Nenhuma
**Status:** Inativo

### Cadeia de Execucao

```
When Executed by Another Workflow
  → Validate Input (Code)
    → RPC buscar_conhecimento (POST Supabase)
      → Format Result (Code)
        → [Retorna ao workflow pai]
```

### Nodes Detalhados

#### Validate Input (Code)

Mapeamento de tipos de busca → categorias do banco:
```javascript
{
  'objecao': 'objecao',
  'objecoes': 'objecao',
  'servico': 'servico_alma',
  'servicos': 'servico_alma',
  'metodologia': 'metodologia_alma',
  'diferencial': 'diferencial_alma',
  'diferenciais': 'diferencial_alma',
  'case': 'case_alma',
  'cases': 'case_alma',
  'cenario': 'cenario',
  'exemplo': 'exemplo_conversa'
}
```

Remocao de stopwords em portugues. Filtra palavras < 3 chars. Max 3 palavras-chave.

#### RPC buscar_conhecimento

| Campo | Valor |
|-------|-------|
| Metodo | POST |
| URL | `https://ujdlrrzpkbuxcrpmmast.supabase.co/rest/v1/rpc/buscar_conhecimento` |

```json
{
  "p_categoria": {{ $json.categoria ? JSON.stringify($json.categoria) : 'null' }},
  "p_termo": {{ $json.termo ? JSON.stringify($json.termo) : 'null' }}
}
```

Chama stored function `buscar_conhecimento(p_categoria, p_termo)` no Postgres.

#### Format Result (Code)

- Se resultado vazio: `{ success: true, encontrado: false, message: "Nenhum conhecimento especifico encontrado... Use seu conhecimento base para responder." }`
- Se resultados: Formata em Markdown (`**titulo**\nconteudo`), retorna `{ success: true, encontrado: true, quantidade, conhecimento, detalhes[] }`

#### Schema Input/Output

**Input:** `{ tipo_busca: string, termo_busca: string }`
**Output (encontrado):** `{ success: true, encontrado: true, quantidade: number, conhecimento: string, detalhes: array }`
**Output (nao encontrado):** `{ success: true, encontrado: false, message: string }`

---

## Infraestrutura e Credenciais

### URLs dos Servicos

| Servico | URL |
|---------|-----|
| Chatwoot ALMA | `https://chat.almaagencia.com.br` (Account ID: 1) |
| Supabase ALMA | `https://ujdlrrzpkbuxcrpmmast.supabase.co` |
| n8n ALMA | `https://n8n.agenciaprospect.space` |
| Google Calendar API | `https://www.googleapis.com/calendar/v3` |
| Apify API | `https://api.apify.com/v2` |
| SerpAPI | `https://serpapi.com/search` |
| Anthropic API | `https://api.anthropic.com/v1` |

### Credenciais Necessarias

| Credencial | Tipo | Usada em |
|------------|------|----------|
| Chatwoot API | httpHeaderAuth (`api_access_token`) | WF01, WF03, WF04, WF05, WF06 |
| Supabase API | httpHeaderAuth (`apikey` + `Authorization: Bearer`) | WF01, WF03, WF04, WF05, WF09 |
| Supabase Postgres | PostgreSQL connection | WF01 (Postgres Chat Memory) |
| Redis ALMA | Redis connection | WF01 (batching) |
| Anthropic (Claude) | API key | WF01 (Sonnet), WF02 (Haiku), WF03 (Haiku), WF04 (Haiku) |
| Google oAuth2 | oAuth2Api | WF03 (Calendar) |
| Apify | Token na URL | WF02 |
| SerpAPI | API key na URL | WF02 |

### Chatwoot Teams

| Team ID | Nome | Funcao |
|---------|------|--------|
| 1 | SDR (IA) | Agente virtual atende automaticamente |
| 2 | Humano | Atendimento humano (handoff) |
| 3 | Agendamento | Leads com reuniao marcada |

### Tabelas no Supabase (ALMA)

| Tabela | Usada por | Campos relevantes |
|--------|-----------|-------------------|
| `conversas` | WF01, WF04 | chatwoot_conversation_id, chatwoot_contact_id, ultima_msg_lead, status, tentativas_reengajamento, ultimo_tema, nicho |
| `mensagens` | WF01 | chatwoot_conversation_id, direction ("user"/"assistant"), content |
| `eventos` | WF03, WF05 | type, payload (jsonb) |
| (base de conhecimento) | WF09 | titulo, conteudo, categoria — acessada via RPC `buscar_conhecimento` |

### Modelos LLM Utilizados

| Modelo | Workflow | Uso | Tokens | Temp |
|--------|----------|-----|--------|------|
| Claude Sonnet 4 (`claude-sonnet-4-20250514`) | WF01 | Agente principal | 1024 | 0.4 |
| Claude Haiku 4 (`claude-haiku-4-20250514`) | WF02 | Analise de pesquisa | 800 | 0.5 |
| Claude Haiku 4 (`claude-haiku-4-20250514`) | WF03 | Decisao de agendamento | 500 | 0.2 |
| Claude 3 Haiku (`claude-3-haiku-20240307`) | WF04 | Mensagens de re-engajamento | 100 | default |

---

## Mapa de Dependencias

```
WF01 — Orquestrador ALMA (Principal)
  ├── WF02 — Pesquisador ALMA (tool_pesquisador)
  ├── WF03 — Agendador ALMA (tool_agendador)
  ├── WF05 — Aplicar Label ALMA (tool_aplicar_label)
  ├── WF06 — Atualizar Lead ALMA (tool_atualizar_lead)
  ├── WF09 — Buscar Conhecimento ALMA (tool_buscar_conhecimento)
  ├── tool_mover_para_humano (inline HTTP)
  └── tool_private_note (inline HTTP)

WF04 — Re-engajamento ALMA (independente, cron cada 1h)
  └── Nao chama sub-workflows (tudo inline)
```

### Labels do Chatwoot (allowlist)

| Label | Significado |
|-------|-------------|
| `novo` | Lead acabou de entrar |
| `em_andamento` | Conversa ativa |
| `reuniao_agendada` | Diagnostico Estrategico marcado |
| `follow_up` | Lead recusou 2x, porta aberta |
| `sem_resposta` | Lead nao respondeu apos re-engajamento |
| `desqualificado` | Nao e publico-alvo |
| `handoff` | Transferida para humano |

---

## Pontos de Atencao

1. **Bug `"now()"` no WF04:** Os PATCHs do Supabase usam `"now()"` como string — PostgREST salva literal, nao interpreta como funcao SQL. Deveria ser `new Date().toISOString()`.

2. **Credenciais expostas no WF02:** Tokens Apify e SerpAPI estao hardcoded nas URLs dos nodes HTTP Request em vez de usar o sistema de credentials do n8n.

3. **Variavel `PRIMARY` no WF03:** Referenciada como variavel JavaScript no Code node e na URL do Calendar. Se nao for variavel global do n8n, causara erro.

4. **Logica de `encerrar` no WF04:** Possivelmente inalcancavel dado que a query filtra `tentativas_reengajamento < 2` e a logica `if/else if` captura os casos antes.

5. **Sem error handler:** Nenhum workflow tem tratamento de erros ou logging de falhas (diferente do ASX que tem WF05-Error-Logger).

6. **Todos os workflows estao inativos** (`active: false`) — ainda nao estao em producao.

7. **neverError em todos os HTTP nodes:** Boa resiliencia mas pode mascarar falhas silenciosas.

8. **Fragmentar Resposta referencia `$json.output`** apos o Log AI Message — funciona porque o n8n preserva dados upstream acessiveis via `$('NodeName')`.
