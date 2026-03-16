# Painel de Gestao e Dashboard — Planejamento

> Documento de planejamento para os paineis de observabilidade e gestao do ASX-Agente.
> Status: **Em discussao** (ainda nao iniciado)

---

## Decisao: Dois Paineis Separados

| | Painel Tecnico (Interno) | Painel de Gestao (ASX) |
|---|---|---|
| **Audiencia** | Convert (agencia) | Equipe ASX (gestores) |
| **Foco** | Execucoes, erros, latencia, health | Leads, conversao, vendedores, distribuidores |
| **Frequencia** | Tempo real / alertas | Diario / semanal |
| **Sensibilidade** | Dados tecnicos (logs, payloads) | Dados de negocio (metricas, status) |
| **Acesso** | Restrito | Compartilhavel com cliente |

---

## Abordagem Recomendada: Hibrida

- **Painel Tecnico → Grafana** (padrao de mercado para observabilidade, Docker no Easypanel, alertas nativos)
- **Painel de Gestao → Next.js custom** (UX profissional, branding ASX, apresentavel para o cliente)

### Alternativas Consideradas

| Caminho | Descricao | Pros | Contras |
|---------|-----------|------|---------|
| A) Ferramentas prontas | Metabase (gestao) + Grafana (tecnico) | Rapido, sem codigo | Visual generico, menos controle |
| B) Full custom | Next.js para ambos | Controle total | Mais tempo, mais manutencao |
| **C) Hibrido** | **Grafana (tecnico) + Next.js (gestao)** | **Melhor de cada mundo** | **Dois sistemas** |

---

## Painel Tecnico (Grafana)

### Metricas e Funcionalidades

- Taxa de sucesso por workflow (WF06, WF07, sub-workflows)
- Tempo medio de resposta do agente (latencia entre mensagem do lead e resposta)
- Alertas quando erro > threshold (ex: 3 falhas em 1h)
- Fila de mensagens pendentes no Redis
- Health check dos servicos (n8n, Evolution API, Chatwoot)
- Log de execucoes com status (sucesso/erro) e detalhes

---

## Painel de Gestao (Next.js)

### Metricas e Funcionalidades

**Funil e Conversao:**
- Funil visual (leads entram → Path 1/2/3 → qualificados → handoff → convertidos)
- % de leads desqualificados vs qualificados
- Taxa de resposta dos leads (quantos responderam o agente vs ignoraram)
- Tempo medio de qualificacao (do primeiro contato ao handoff)

**Performance do Agente:**
- Score medio dos leads qualificados
- Quantidade de interacoes ate handoff
- Qualidade das conversas

**Vendedores:**
- Quantos leads foram para cada vendedor (round-robin)
- Status dos leads por vendedor

**Leads Quentes:**
- Aba com leads de score alto que ainda nao tiveram handoff ou estao parados
- Status atualizado para iteracao manual

**Distribuidores (Prestacao de Contas):**
- Quais leads foram redirecionados para cada distribuidor
- Historico de recomendacoes (tabela `distributor_recommendations`)

**Comparativos:**
- Semana atual vs anterior
- Mes a mes
- Periodo customizado

---

## Dados Disponiveis no Supabase

A base atual ja suporta a maioria das metricas:

| Tabela | O que fornece |
|--------|---------------|
| `fb_leads` | Funil completo (todos os leads, path, status) |
| `leads` | Leads qualificados (score, class, priority) |
| `assignments` | Distribuicao por vendedor |
| `ia_messages` | Tempo de resposta, quantidade de interacoes |
| `distributor_recommendations` | Prestacao de contas distribuidores |
| `distributors` | Base de distribuidores |

Pode ser necessario criar 2-3 views SQL no Supabase para agregar dados.

---

## Stack Prevista

| Componente | Tecnologia |
|------------|------------|
| Painel Tecnico | Grafana (Docker, Easypanel) |
| Painel Gestao | Next.js + React |
| UI Components | Shadcn/UI ou Tremor |
| Backend/API | Supabase (ja existente) |
| Auth | Supabase Auth (built-in) |
| Hospedagem | Easypanel (Hostinger) ou Vercel |