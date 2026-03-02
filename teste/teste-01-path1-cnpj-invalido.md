# Teste 01 - Path 1: CNPJ Invalido (Desqualificado)

**Data:** 2026-03-01
**Execution ID:** 799
**Status:** SUCCESS

## Cenario

Lead com CNPJ invalido (7 digitos). Esperado: registrar como desqualificado, NAO enviar WhatsApp.

## Dados de Entrada

| Campo | Valor |
|-------|-------|
| facebook_lead_id | TEST_E2E_PATH1_001 |
| nome | Roberto Teste Path1 |
| email | roberto@teste.com |
| telefone | +5562998621000 |
| perfil | Loja de autopecas |
| volume_faixa | Entre 4.000 e 10.000 |
| cnpj_raw | 1234567 |
| estado_envio | GO |

## Resultado

### Nodes Executados (8 de 8)

| Node | Status |
|------|--------|
| Webhook1 | SUCCESS |
| Acknowledge FB Event | SUCCESS |
| Extract Form Fields | SUCCESS |
| Normalize Phone | SUCCESS |
| Phone Valid? | SUCCESS |
| Clean CNPJ | SUCCESS |
| CNPJ 14 Digits? | SUCCESS (false -> branch desqualificado) |
| Save Disqualified Format | SUCCESS |

### Verificacoes

- WhatsApp enviado: NAO (correto)
- Registro no fb_leads: SIM (status=disqualified_cnpj, path=1)
- Motivo: "CNPJ formato invalido (nao tem 14 digitos)"

### Tempo de Execucao

- Inicio: 19:42:45 UTC
- Fim: 19:42:46 UTC
- Duracao: ~0.6s

## Conclusao

PASSOU - O fluxo identificou corretamente o CNPJ invalido, registrou no banco e NAO enviou mensagem WhatsApp.
