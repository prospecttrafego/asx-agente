# Teste 15 - Metabase Dashboard Redesenho Operacional

**Data:** 2026-03-12  
**Ambiente:** Producao  
**Dashboard:** `ASX SDR - Monitor Tecnico`  
**URL:** `https://monitor.agenciaprospect.space/dashboard/2-asx-sdr-monitor-tecnico`

## Objetivo

Reestruturar o dashboard pela otica de operacao do projeto:

- primeiro mostrar o que exige acao imediata
- depois mostrar entrada do funil
- depois mostrar andamento da venda direta
- deixar diagnostico tecnico nas ultimas linhas

## Ajustes Aplicados

### Linha 1 - Atencao imediata

- `Alertas Ativos`
- `Sem Primeiro Contato`
- `Parados sem Handoff`
- `Nao Identificadas`
- `Ultimo Handoff`

### Linha 2 - Entrada do funil

- `Leads Hoje`
- `CNPJ Invalido Hoje`
- `Distribuidores Hoje`
- `Venda Direta Hoje`
- `Primeiro Contato Hoje`

### Linha 3 - Avanco da venda direta

- `Aguardando Resposta`
- `Responderam 24h`
- `Leads Criados 24h`
- `Vendedores Atrib. 24h`
- `Handoffs 24h`

### Linha 4 - Funil consolidado

- `Funil de Venda Direta - 24h`

### Linha 5 - Problemas silenciosos

- `Qualificados Travados no Handoff`
- `Nao Identificadas Recentes`

### Linha 6 - Diagnostico tecnico

- `Status dos Servicos`
- `Erros Tecnicos Recentes`

### Linha 7 - Tendencias tecnicas

- `Erros por Hora`
- `Erros por Workflow`
- `Roteamento do Inbound - Ultimas 24h`

## Cards Criados

- `65` `Sem Primeiro Contato`
- `66` `Primeiro Contato Hoje`
- `67` `Responderam 24h`
- `68` `Leads Criados 24h`
- `69` `Vendedores Atrib. 24h`

## Cards Ajustados

- `58` passou de `Min sem Handoff` para `Ultimo Handoff`
- `58` agora mostra texto humano:
  - exemplo atual: `Nenhum registrado`
- `59` passou para `Parados sem Handoff`
- `61` passou para `Nao Identificadas`
- `44` passou para `Leads Hoje`
- `43` passou para `Handoffs 24h`

## Queries de negocio adicionadas

### Sem Primeiro Contato

Conta leads recentes dos paths `2` e `3` sem `first_message_sent_at`:

```sql
SELECT COUNT(*) AS sem_primeiro_contato
FROM fb_leads
WHERE path IN (2, 3)
  AND first_message_sent_at IS NULL
  AND created_at >= NOW() - INTERVAL '72 hours';
```

### Primeiro Contato Hoje

Conta leads dos paths `2` e `3` com primeiro contato disparado hoje:

```sql
SELECT COUNT(*) AS primeiro_contato_hoje
FROM fb_leads
WHERE path IN (2, 3)
  AND first_message_sent_at >= CURRENT_DATE;
```

### Ultimo Handoff

Mostra texto humano no lugar de numero tecnico:

- `Ha X min`
- `Ha X h`
- `Ha X d`
- `Nenhum registrado`

## Validacao

Validado por API do Metabase e por inspecao visual headless.

### Evidencias visuais

- `output/playwright/metabase-dashboard-user-oriented.png`
- `output/playwright/metabase-dashboard-user-oriented-v2.png`

## Resultado

O dashboard passou a responder melhor, em ordem:

1. Existe algo exigindo acao imediata?
2. O topo do funil esta entrando e recebendo primeiro contato?
3. A venda direta esta avancando?
4. Ha falha silenciosa?
5. Se houver, existe apoio tecnico para diagnostico?

## Observacoes

- Nenhum workflow foi alterado nesta rodada.
- A mudanca foi somente em cards, queries do Metabase e layout do dashboard.
