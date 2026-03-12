# Teste 14 - Metabase Dashboard Layout e Nomenclatura

**Data:** 2026-03-12  
**Ambiente:** Producao  
**Dashboard:** `ASX SDR - Monitor Tecnico`  
**URL:** `https://monitor.agenciaprospect.space/dashboard/2-asx-sdr-monitor-tecnico`

## Objetivo

Melhorar a experiencia visual do dashboard no Metabase e substituir nomenclaturas tecnicas (`Path`, `P2`, `P3`, `Unknown`) por termos de negocio e operacao.

## Ajustes Aplicados

### Nomenclatura dos cards

- `Erros Tecnicos por Hora`
- `Erros Tecnicos por Workflow`
- `Ultimos Erros Tecnicos`
- `Roteamento do Inbound - Ultimas 24h`
- `Leads Hoje`
- `Desqualificados Hoje`
- `Distribuidores Hoje`
- `Venda Direta Hoje`
- `Status Atual dos Servicos`
- `Nao Identif. 24h`
- `Responderam sem Handoff`
- `Aguardando Resposta`
- `Min sem Handoff`
- `Funil de Venda Direta - 24h`
- `Conversas Nao Identificadas Recentes`
- `Qualificados Travados no Handoff`

### Rotulos internos ajustados

No card `Roteamento do Inbound - Ultimas 24h`:

- `Distribuidores`
- `Venda Direta`
- `Ja com Vendedor`
- `Nao Identificado`

No card `Funil de Venda Direta - 24h`:

- `Entraram na venda direta`
- `Primeira mensagem enviada`
- `Aguardando resposta do lead`
- `Leads que responderam`
- `Lead criado`
- `Vendedor atribuido`
- `Handoff concluido`
- `Responderam sem handoff`

No card `Conversas Nao Identificadas Recentes`:

- coluna `Lead Type` renomeada para `Rota`

## Layout Aplicado

### Linha 1 - Alertas e indicadores criticos

- `Alertas Ativos`
- `Nao Identif. 24h`
- `Responderam sem Handoff`
- `Aguardando Resposta`
- `Min sem Handoff`

### Linha 2 - Visao diaria do funil

- `Handoffs Hoje`
- `Leads Hoje`
- `Desqualificados Hoje`
- `Distribuidores Hoje`
- `Venda Direta Hoje`

### Linha 3 - Graficos principais

- `Erros Tecnicos por Hora`
- `Erros Tecnicos por Workflow`
- `Roteamento do Inbound - Ultimas 24h`

### Linha 4 - Tabelas centrais

- `Ultimos Erros Tecnicos`
- `Status Atual dos Servicos`

### Linha 5 - Analise operacional

- `Funil de Venda Direta - 24h`
- `Conversas Nao Identificadas Recentes`

### Linha 6 - Excecoes

- `Qualificados Travados no Handoff`

## Validacao

Validado visualmente no dashboard real via navegador headless e por API do Metabase.

### Evidencias visuais

- `output/playwright/metabase-dashboard-current.png`
- `output/playwright/metabase-dashboard-final.png`

## Resultado

O dashboard ficou com:

- menos cortes de titulo
- cards KPI mais legiveis
- melhor distribuicao horizontal
- termos de negocio no lugar de `Path/P2/P3`
- melhor leitura do card de roteamento

## Observacoes

- O dashboard ainda se chama `ASX SDR - Monitor Tecnico`. O conteudo interno ja esta mais orientado a operacao.
- Permanecem alguns warnings visuais do proprio Metabase relacionados a `scalar.field`, mas eles nao impediram a renderizacao nem a atualizacao dos cards.
