# Teste 12 - WF06 Path 2 com justificativa correta

**Data:** 2026-03-11  
**Workflow:** `06-FB-Leads-Outbound-Webhook` (`7LvmLJIL7CdbWpbt`)  
**Node alterado:** `Compose Message P2`

## Objetivo

Corrigir a mensagem enviada para leads do `Path 2`, para que o texto reflita o motivo real da classificacao:

- `volume abaixo de 4 mil`
- `fora da regiao de atendimento direto`

Sem adicionar ou remover nodes.

## Alteracao aplicada

Foi alterado apenas o node `Compose Message P2`.

O node agora diferencia 4 cenarios:

1. `baixo_volume + com_distribuidor`
2. `baixo_volume + sem_distribuidor`
3. `fora_regiao_atendimento_direto + com_distribuidor`
4. `fora_regiao_atendimento_direto + sem_distribuidor`

## Logica usada

- `isLowVolume = volume_numerico < 4000`
- `hasDistributors = distributors_json.length > 0`

### Regra de texto

- Se `isLowVolume = true`:
  - a justificativa menciona o **volume mensal informado no formulario**
  - nao menciona regiao como causa da desqualificacao

- Se `isLowVolume = false`:
  - a justificativa menciona que o **atendimento comercial direto prioriza Norte e Nordeste**

- Se `hasDistributors = false`:
  - a mensagem informa que **nao foi encontrado distribuidor ativo cadastrado para o estado**
  - nao afirma genericamente que a ASX nao atende a regiao

## Validacao

O workflow foi salvo no n8n real em:

- `2026-03-11T17:33:13.266Z`

Foi feita simulacao local do texto gerado nas 4 combinacoes:

- `baixo_volume_com_distribuidor`
- `baixo_volume_sem_distribuidor`
- `fora_regiao_com_distribuidor`
- `fora_regiao_sem_distribuidor`

Resultado:

- a mensagem de baixo volume passou a justificar por volume
- a mensagem de fora da regiao passou a justificar por cobertura de atendimento direto
- as quebras de linha ficaram corretas para envio via WhatsApp

## Escopo

Nao houve alteracao em:

- `IF Path`
- `Find Distributors`
- `Save Recommendations`
- `Update fb_lead P2`
- qualquer outro node do `WF06`
