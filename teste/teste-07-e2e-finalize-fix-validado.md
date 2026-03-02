# Teste 07 — E2E Completo: Fix finalize_p3 + Sub-Workflows Validados

**Data:** 2026-03-02
**Status:** SUCESSO COMPLETO ✅

---

## Contexto

Retest E2E após 2 fixes críticos:
1. **finalize_p3 simplificado** — Reduzido de 13 `$fromAI()` para 7, pré-preenchendo 9 parâmetros do contexto do fluxo (Lookup Lead Path, Merge Messages)
2. **02-Tool-Label** — Fix do `Contact Found?` rightValue (string → number) já deployado no teste 06

---

## Dados de Entrada

| Campo | Valor |
|-------|-------|
| facebook_lead_id | TEST_E2E_FULL_005 (hardcoded em Extract Form Fields) |
| nome | Carlos Teste Final |
| telefone | +5562998621000 |
| perfil | Representante |
| volume_faixa | Acima de 10.000 |
| cnpj_raw | 12345678000195 |
| estado_envio | CE |

---

## Fix Aplicado: finalize_p3

### Antes (13 `$fromAI()`)
O agente precisava fornecer todos os 13+ parâmetros via `$fromAI()`:
phone, nome, empresa, cnpj, perfil, uf_atuacao, volume, score, class, priority, chatwoot_conversation_id, ja_compra_asx_regiao, fornecedor_asx_regiao, nfs_enviadas, empresa_recente, source

**Resultado:** LLM (OpenAI) não conseguia preencher tantos parâmetros e **pulava** a chamada do finalize.

### Depois (7 `$fromAI()`)
9 parâmetros pré-preenchidos do contexto do fluxo:
- `phone` ← `$("Merge Messages").item.json.phone`
- `nome` ← `$("Lookup Lead Path").first().json.nome`
- `empresa` ← `$("Lookup Lead Path").first().json.nome_fantasia || razao_social`
- `cnpj` ← `$("Lookup Lead Path").first().json.cnpj`
- `perfil` ← `$("Lookup Lead Path").first().json.perfil`
- `uf_atuacao` ← `$("Lookup Lead Path").first().json.estado_envio`
- `volume` ← `$("Lookup Lead Path").first().json.volume_faixa`
- `chatwoot_conversation_id` ← `$("Merge Messages").item.json.chatwootConversationId || fb_conv_id`
- `source` ← `facebook_form` (fixo)

7 parâmetros ainda via `$fromAI()` (dados que o agente coleta na conversa):
- `score` — Score numérico (de score_lead)
- `class` — quente, morno ou frio (de score_lead)
- `priority` — urgent, high ou medium (de score_lead)
- `ja_compra_asx_regiao` — sim ou nao
- `fornecedor_asx_regiao` — Nome do fornecedor ou N/A
- `nfs_enviadas` — true ou false
- `empresa_recente` — true ou false

---

## 1. WF06 — Outbound (Exec #852) — SUCESSO ✅

- Classify Lead: path=3, reason="Qualificado: volume >= 4k + N/NE"
- IF Path: True → Compose Message P3
- Create Conversation: **conv_id=22**
- Send WhatsApp P3: enviado para 556298621000@s.whatsapp.net
- Mensagem: "Ola Carlos! Aqui e o Joao, consultor comercial da ASX Iluminacao..."

---

## 2. WF07 Interação 1 (Exec #855) — SUCESSO ✅

**Lead:** "Sim, tudo certo. Pode dar andamento."
**João:** "Carlos, você já compra produtos ASX de algum distribuidor na sua região?"
- WhatsApp enviado ✅

---

## 3. WF07 Interação 2 (Exec #857) — SUCESSO ✅

**Lead:** "Nao, ainda nao compro ASX. Quero comecar a revender."
**João:** "Para dar andamento ao seu cadastro, preciso que envie ao menos duas notas fiscais de compras recentes em fornecedores de autopeças. Pode ser foto ou PDF!"
- WhatsApp enviado ✅

---

## 4. WF07 Interação 3 — HANDOFF (Exec #859) — SUCESSO ✅

**Lead:** "A empresa e nova, ainda nao tenho notas fiscais para enviar."
**João:** "Carlos, como sua empresa é nova e ainda não possui notas fiscais, vou passar seu cadastro para um especialista que vai cuidar do seu atendimento. Ele entrará em contato com você em breve!"
- WhatsApp enviado ✅

### Tools chamadas pelo agente:
1. **score_lead_p3** ✅
2. **finalize_p3** ✅ ← **FIX VALIDADO — AGENTE CHAMOU finalize!**
3. **set_label_p3** ✅

### Sub-workflows acionados:

| Sub-Workflow | Exec | Status | Detalhe |
|---|---|---|---|
| 02-Tool-Label | #860 | ✅ SUCCESS | Contato encontrado, label `empresa_recente` aplicada |
| 03-Finalize-Handoff | #861 | ✅ SUCCESS | Lead criado, Queila atribuída, Notify Vendor enviado |
| 02B-Score-Lead | #862 | ✅ SUCCESS | Score calculado |

---

## 5. Verificação Pós-Handoff

### Tabela `leads`
```json
{
  "id": "fb0dc79f-526f-4baa-a59c-c60f4ce5e0d3",
  "perfil": "Representante",
  "regiao": "CE",
  "volume": "Acima de 10.000",
  "score": 0,
  "class": "quente",
  "priority": "high",
  "source": "facebook_form",
  "ja_compra_asx_regiao": "nao",
  "fornecedor_asx_regiao": "N/A",
  "nfs_enviadas": false,
  "empresa_recente": true,
  "qualified_at": "2026-03-02T20:34:50"
}
```

### Tabela `assignments`
```json
{
  "id": "0c06f1d1-b6b7-4e29-8eb6-0eba83a65a5f",
  "lead_id": "fb0dc79f-526f-4baa-a59c-c60f4ce5e0d3",
  "assignee_id": 2,
  "assigned_at": "2026-03-02T20:34:50"
}
```
→ Queila (agent_id=2) atribuída via round-robin ✅

### Chatwoot Conversation #22
- **Status:** open
- **Team:** vendedora - queila (team_id: 1) ✅
- **Inbox ID:** 1
- **Label no contato:** empresa_recente ✅

### Notify Vendor (WhatsApp para Queila)
- **Exec #861:** Notify Vendor → SUCCESS
- **Message ID:** 3EB0C8D21DF3C8F
- Queila recebeu notificação WhatsApp sobre o novo lead ✅

---

## Conversa Completa (Lead ↔ João)

| # | Direção | Mensagem |
|---|---------|----------|
| 1 | → Outbound (WF06) | "Ola Carlos! Aqui e o Joao, consultor comercial da ASX Iluminacao. Vi que a *ROBERIO JOSE DOS SANTOS 16952477870* se cadastrou... Confirmei aqui seus dados: Perfil: Representante, Volume: Acima de 10.000, Estado: CE. Esta tudo certo?" |
| 2 | ← Lead | "Sim, tudo certo. Pode dar andamento." |
| 3 | → João (Agent) | "Carlos, você já compra produtos ASX de algum distribuidor na sua região?" |
| 4 | ← Lead | "Nao, ainda nao compro ASX. Quero comecar a revender." |
| 5 | → João (Agent) | "Para dar andamento ao seu cadastro, preciso que envie ao menos duas notas fiscais de compras recentes em fornecedores de autopeças. Pode ser foto ou PDF!" |
| 6 | ← Lead | "A empresa e nova, ainda nao tenho notas fiscais para enviar." |
| 7 | → João (Agent) | "Carlos, como sua empresa é nova e ainda não possui notas fiscais, vou passar seu cadastro para um especialista que vai cuidar do seu atendimento. Ele entrará em contato com você em breve!" |

---

## Resumo de Todos os Fixes Validados

| Fix | Componente | Problema | Solução | Status |
|-----|-----------|----------|---------|--------|
| Switch → IF | WF06 | Switch v3.x bug (sempre Output 0) | Substituído por IF node v2 | ✅ Validado (teste 04) |
| Format AI Output | WF07 | `$json.output` retornava undefined | Referência direta `$('Joao P3...').first().json.output` | ✅ Validado (teste 05) |
| Send WhatsApp | WF07 | `$json.messages` retornava undefined | Referência direta `$('Loop Items').first().json.messages` | ✅ Validado (teste 05) |
| 02-Tool-Label Auth | Sub-WF | Header `api_acess_token` (typo) | Headers manuais com `api_access_token` | ✅ Validado |
| 02-Tool-Label Type | Sub-WF | rightValue `"0"` (string) com strict | rightValue = `0` (number) | ✅ Validado |
| 03-Finalize Notify | Sub-WF | jsonBody com \\n = JSON inválido | bodyParameters (keypair) | ✅ Validado |
| **finalize_p3 $fromAI** | **WF07** | **13 $fromAI() → LLM pulava a tool** | **Reduzido para 7 $fromAI()** | **✅ Validado** |

---

## Método do Teste

1. **Limpeza de dados:** Deletadas `ia_messages` (session 5562998621000) e `fb_leads` (TEST_E2E_FULL_005) do teste anterior
2. **WF06:** POST no webhook `/webhook/meta-leads` com payload simulando Facebook Lead Ads (CE, Acima de 10.000)
3. **WF07:** POSTs sequenciais no webhook `/webhook/asx-sdr` com payloads simulando Evolution API (mensagens incoming do lead)
4. **Verificação:** Consulta direta às APIs (n8n executions, Supabase tables, Chatwoot conversations) para validar cada etapa
