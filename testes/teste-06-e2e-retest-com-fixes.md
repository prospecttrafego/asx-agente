# Teste 06 — Retest E2E com Fixes nos Sub-Workflows

**Data:** 2026-03-02
**Status:** PARCIAL — Fixes deployados, sub-workflows parcialmente validados

---

## Fixes Aplicados Antes do Teste

### Fix 1: 02-Tool-Label (QBZhzIYU7qBuE6p5)
- **Chatwoot - Search Contact**: Removido `predefinedCredentialType` (credential com typo `api_acess_token`). Trocado por headers manuais com `api_access_token: U1DuRjHXeeuaaiBdG1hTkuR6`
- **Add Labels**: Mesma correção de auth
- **Contact Found?**: `rightValue` de `"0"` (string) para `0` (number) — o `typeValidation: "strict"` exige tipos corretos

### Fix 2: 03-Finalize-Handoff (OvvMcnq571vIb9bK)
- **Notify Vendor**: Trocado de `specifyBody: "json"` com template complexo (emojis + `\\n` + ternários inline) para `specifyBody: "keypair"` com `bodyParameters` separados (`number` e `text`). O n8n serializa o JSON automaticamente.

---

## Teste: WF06 + WF07 Path 3 (CE + Acima de 10.000)

### WF06 (Exec #831) — SUCESSO ✅
- Lead: Carlos Teste Final, CE, Acima de 10.000, Representante
- Path 3: Qualificado (volume >= 4k + N/NE)
- Conv ID: 20

### WF07 Interação 1 (Exec #836) — SUCESSO ✅
- Lead: "Sim, tudo certo. Pode prosseguir!"
- João: "Carlos, você já compra produtos ASX de algum distribuidor na sua região?"
- WhatsApp enviado ✅

### WF07 Interação 2 (Exec #838) — SUCESSO ✅
- Lead: "Não, ainda não compro ASX. Quero começar a revender."
- João: "Obrigado pela informação, Carlos! Para dar andamento ao seu cadastro, preciso que envie ao menos duas notas fiscais..."
- WhatsApp enviado ✅

### WF07 Interação 3 (Exec #840) — PARCIAL ⚠️
- Lead: "A empresa é nova, ainda não tenho notas fiscais para enviar."
- João: "Entendi, Carlos. Como sua empresa é nova... vou encaminhar seu cadastro para um especialista..."
- WhatsApp enviado ✅
- **Tools chamadas:** set_label_p3, log_event_p3, score_lead_p3
- **finalize_p3 NÃO foi chamada** ❌

#### Sub-workflows acionados:
| Sub-Workflow | Exec | Status | Detalhe |
|---|---|---|---|
| 02-Tool-Label | #841, #845 | ❌ ERRO | `Contact Found?` rightValue type (corrigido após) |
| 02B-Score-Lead | #842, #847 | ✅ | Score calculado |
| 02C-Agent-Log | #843, #846 | ✅ | Evento logado |
| 03-Finalize-Handoff | — | NÃO CHAMADO | Agente não invocou finalize |

### WF07 Interação 4 (Exec #850) — PARCIAL ⚠️
- Lead: "Ok, quando o especialista vai entrar em contato?"
- João: "Vou passar seu contato para o especialista agora mesmo..."
- WhatsApp enviado ✅
- **finalize AINDA não foi chamada** ❌

---

## Problemas Identificados

### PROBLEMA 1: Agente P3 não chama `finalize_p3`
- **Prompt diz:** score_lead → finalize → set_label → avisar cliente
- **Agente fez:** set_label → score_lead (pula finalize) → avisa cliente
- **Causa provável:** `finalize_p3` exige 17 parâmetros via `$fromAI()`. O LLM (OpenAI) pode estar tendo dificuldade com tantos parâmetros ou não seguindo a sequência multi-tool corretamente.
- **Impacto:** Lead NÃO é persistido na tabela `leads`, NÃO é atribuído a vendedor, conversa NÃO é transferida no Chatwoot.

### PROBLEMA 2 (corrigido): 02-Tool-Label Contact Found?
- O rightValue `"0"` (string) com `typeValidation: "strict"` e operator `number.gt` causava erro de tipo
- **Fix:** rightValue = `0` (number)
- **Status:** Fix deployado, aguardando validação no próximo teste

### PROBLEMA 3 (corrigido): 02-Tool-Label Auth
- Credential `httpHeaderAuth` tinha header `api_acess_token` (typo, 1 's')
- **Fix:** Headers manuais com `api_access_token` (2 's') e token correto
- **Status:** Fix deployado, Chatwoot Search Contact funcionou no teste (exec #845 passou no Search)

### PROBLEMA 4 (corrigido, não testado): 03-Finalize-Handoff Notify Vendor
- jsonBody com template complexo gerava JSON inválido (\\n → newlines literais)
- **Fix:** bodyParameters com campos separados
- **Status:** Fix deployado, NÃO testado (finalize não foi chamada pelo agente)

---

## Validação Parcial do Fix "already_qualified"

Na exec #834, o lead foi detectado como `already_qualified` (do teste anterior). O `Notify Vendor` no WF07 (path already_qualified) **executou com sucesso** — confirmando que a comunicação com Evolution API está funcionando.

---

## Próximos Passos

1. **Investigar/corrigir** por que o agente P3 não chama `finalize_p3` (simplificar parâmetros? reforçar no prompt? quebrar em steps?)
2. **Validar** 02-Tool-Label fix completo (auth + Contact Found?)
3. **Validar** 03-Finalize-Handoff Notify Vendor fix
