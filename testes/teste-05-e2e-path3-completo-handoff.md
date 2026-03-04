# Teste 05 — E2E Completo: Path 3 → WF07 Agent → Handoff

**Data:** 2026-03-02
**Status:** PARCIALMENTE SUCESSO (fluxo principal OK, 2 sub-workflows com bugs pré-existentes)

---

## Resumo do Teste

Teste end-to-end completo do fluxo Path 3 (lead qualificado): desde a captação via WF06 até o handoff para vendedor via WF07 + sub-workflows.

---

## 1. WF06 — 1ª Mensagem (Execução #815)

**Status:** SUCESSO ✅

| Campo | Valor |
|-------|-------|
| facebook_lead_id | TEST_E2E_PATH3_004 |
| nome | Maria Qualificada Teste |
| volume_faixa | Entre 4.000 e 10.000 |
| estado_envio | BA |
| cnpj_raw | 12345678000195 |

**Classify Lead:** path=3, reason="Qualificado: volume >= 4k + N/NE"
**IF Path:** True → Compose Message P3 ✅
**Mensagem enviada:**
```
Ola Maria! Aqui e o Joao, consultor comercial da ASX Iluminacao...
Confirmei aqui seus dados do cadastro: Perfil: Distribuidora, Volume: Entre 4.000 e 10.000, Estado: BA
Esta tudo certo? Posso dar andamento ao seu atendimento?
```

---

## 2. WF07 — Interação 1: Confirmação (Execução #820)

**Status:** SUCESSO ✅

**Lead:** "Sim, está tudo certo! Pode dar andamento."
**João P3:** "Você já compra produtos ASX de algum distribuidor na sua região? Se sim, poderia me informar de quem compra?"

- Lookup Lead Path: lead_type = "qualified_agent" ✅
- Switch Lead Type: Output 2 (Qualified) ✅
- WhatsApp enviado ✅

---

## 3. WF07 — Interação 2: Já compra ASX? (Execução #822)

**Status:** SUCESSO ✅

**Lead:** "Não, nunca comprei ASX. Seria a primeira vez."
**João P3:** "Obrigado pela informação! Para dar andamento ao seu cadastro, preciso que envie ao menos duas notas fiscais de compras recentes em fornecedores de autopeças. Pode ser foto ou PDF!"

- Etapa 2 → Etapa 3 (sem NFs) ✅

---

## 4. WF07 — Interação 3: NFs / Handoff (Execução #824)

**Status:** SUCESSO (fluxo principal) ✅

**Lead:** "Não tenho notas no momento. A empresa é recente, estamos começando agora."
**João P3:** "Entendi, Maria. Como sua empresa é recente e ainda não possui notas fiscais, vou encaminhar seu cadastro para um especialista que vai cuidar do seu atendimento. Obrigado pela confiança!"

### Tools invocadas pelo agente:
1. **set_label_p3** (Exec #825) — ❌ ERRO: Chatwoot auth error "You need to sign in or sign up"
2. **score_lead_p3** (Exec #827) — ✅ Score calculado (score=0, class=morno, priority=medium)
3. **finalize_p3** (Exec #826) — ⚠️ PARCIAL (handoff OK, notificação falhou)

### Detalhes do Finalize (Exec #826):

| Etapa | Status |
|-------|--------|
| Validate Input | ✅ |
| Pick Agent | ✅ → Queila (agent_id=2, phone=5571999599797, team_id=1) |
| Persist Lead | ✅ → Lead criado na tabela `leads` |
| Create Assignment | ✅ |
| Transfer Conversation | ✅ → Team "vendedora - queila" |
| **Notify Vendor** | ❌ ERRO: "JSON parameter needs to be valid JSON" |

---

## 5. Verificação Pós-Handoff

### Tabela `leads`
```json
{
  "perfil": "distribuidora",
  "regiao": "BA",
  "volume": "Entre 4.000 e 10.000",
  "score": 0,
  "class": "morno",
  "priority": "medium",
  "source": "facebook_form",
  "ja_compra_asx_regiao": "nao",
  "fornecedor_asx_regiao": "N/A",
  "nfs_enviadas": false,
  "empresa_recente": true,
  "qualified_at": "2026-03-02T17:34:44"
}
```

### Chatwoot Conversation #19
- **Status:** open
- **Team:** vendedora - queila (team_id: 1) ✅
- **Inbox ID:** 1 (SDR inbox — não transferiu para inbox 2 da Queila)
- **Labels:** [] (vazio — bug no set_label)
- **5 mensagens:** 4 outgoing (João) + 1 activity (atribuição)

---

## Bugs Encontrados

### BUG 1: 02-Tool-Label — Auth Chatwoot
- **Workflow:** 02-Tool-Label (callable) — QBZhzIYU7qBuE6p5
- **Erro:** "You need to sign in or sign up before continuing."
- **Causa provável:** Header `api_acess_token` (typo? deveria ser `api_access_token`) ou token inválido
- **Impacto:** Labels não são aplicadas na conversa do Chatwoot

### BUG 2: 03-Finalize-Handoff — Notify Vendor JSON inválido
- **Workflow:** 03-Finalize-Handoff (callable) — OvvMcnq571vIb9bK
- **Erro:** "JSON parameter needs to be valid JSON"
- **Node:** Notify Vendor (HTTP Request → Evolution API sendText)
- **Causa provável:** Template JSON com caracteres especiais ou variáveis não resolvidas
- **Impacto:** Vendedor NÃO recebe notificação WhatsApp do novo lead

### BUG 3 (corrigido nesta sessão): Format AI Output
- **Problema original:** `$json.output` retornava undefined porque Log Assistant Message "engolia" o output do agente
- **Fix:** Alterado para referenciar `$('Joao P3 - Qualified Agent').first().json.output` diretamente

### BUG 4 (corrigido nesta sessão): Send WhatsApp text vazio
- **Problema original:** `$json.messages` retornava undefined porque Presence Composing "engolia" o dado do Loop Items
- **Fix:** Alterado para referenciar `$('Loop Items').first().json.messages`

---

## Correções Aplicadas Nesta Sessão

| Correção | Workflow | Node | Antes | Depois |
|----------|----------|------|-------|--------|
| Switch → IF | WF06 | Switch Path → IF Path | Switch v3.3 (bug) | IF v2 (path===3) |
| Format AI Output | WF07 | Format AI Output | `$json.output` | `$('Joao P3...').first().json.output` |
| Send WhatsApp text | WF07 | Send WhatsApp | `$json.messages` | `$('Loop Items').first().json.messages` |

---

## Método do Teste

Os testes foram realizados via API, simulando payloads que normalmente são gerados pela Evolution API e Facebook Lead Ads:

1. **WF06 trigger:** POST direto no webhook `/webhook/meta-leads` com payload simulando Facebook Lead Ads
2. **WF07 trigger:** POST direto no webhook `/webhook/asx-sdr` com payload simulando Evolution API (mensagem incoming do lead)
3. **Limitação:** Mensagens do lead NÃO aparecem no Chatwoot porque foram enviadas via webhook direto (não passaram pela Evolution API que faz a sincronização bidirecional)
4. **As respostas da IA FORAM enviadas via WhatsApp real** (Evolution API sendText)
