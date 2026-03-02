# Teste 04 — Path 3: Lead Qualificado (BA + Volume Alto)

**Data:** 2026-03-02
**Execução N8N:** #815
**Status:** SUCESSO ✅

---

## Dados de Entrada (Extract Form Fields - hardcoded)

| Campo | Valor |
|-------|-------|
| facebook_lead_id | TEST_E2E_PATH3_004 |
| nome | Maria Qualificada Teste |
| email | maria@teste.com |
| telefone_raw | +5562998621000 |
| perfil | Distribuidora |
| volume_faixa | Entre 4.000 e 10.000 |
| cnpj_raw | 12345678000195 |
| estado_envio | BA |

## Classificação (Classify Lead)

| Campo | Valor |
|-------|-------|
| path | 3 |
| path_reason | Qualificado: volume >= 4k + N/NE |
| estado_uf | BA |
| volume_numerico | 7000 |
| isNNE | true |
| path_label | qualified |

## Roteamento (IF Path)

- **Condição:** `path === 3`
- **Resultado:** True → Output 0 → **Compose Message P3** ✅
- Path 2 (Find Distributors): NÃO executou ✅

## Mensagem Enviada (WhatsApp P3)

```
Ola Maria! Aqui e o Joao, consultor comercial da ASX Iluminacao.

Vi que a *ROBERIO JOSE DOS SANTOS 16952477870* se cadastrou para negociacao direta conosco. Que otimo saber do seu interesse!

Confirmei aqui seus dados do cadastro:
• Perfil: Distribuidora
• Volume mensal: Entre 4.000 e 10.000
• Estado: BA

Esta tudo certo? Posso dar andamento ao seu atendimento?
```

**Destinatário:** 556298621000@s.whatsapp.net
**Message ID:** 3EB0F5D15C6943A54C21AC

## Nodes Executados (21 total)

Webhook1 → Acknowledge FB Event → Extract Form Fields → Normalize Phone → Phone Valid? → Clean CNPJ → CNPJ 14 Digits? → Prepare Enrich → 02A Company Enrich → CNPJ Valid? → Classify Lead → Save fb_lead → Search Chatwoot Contact → Contact Found? → Use Existing Contact → Create Conversation → **IF Path (True)** → Compose Message P3 → Send WhatsApp P3 → Update fb_lead P3 → Add Labels P3

## Correção Aplicada

O node **Switch Path** (n8n-nodes-base.switch v3.3) foi substituído por **IF Path** (n8n-nodes-base.if v2).

**Motivo:** Bug conhecido do Switch node v3.x — sempre roteava para Output 0 independente da condição. O IF node com decisão binária (path===3 ? True : False) resolveu o problema.
