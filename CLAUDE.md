# ASX-Agente

Espelho documental do agente SDR de IA da **ASX Iluminacao Automotiva**.
O projeto real roda em servicos cloud (n8n, Supabase, Chatwoot, Evolution API).
**Nao ha codigo executavel neste repositorio** — apenas documentacao, workflows exportados e testes.

## Stack e Versoes

| Servico | Versao | Funcao | URL |
|---------|--------|--------|-----|
| n8n | 2.3.2 | Orquestrador de workflows | `https://flow.agenciaprospect.space` |
| OpenAI | GPT-4 | LLM do agente | via API |
| Supabase | - | Banco de dados (Postgres) | `https://hxcfvyhjyibdexazrhox.supabase.co` |
| Redis | - | Cache e gestao de filas | interno |
| Chatwoot | 4.9.2 (selfhosted) | Painel de atendimento omnichannel | `https://chat.agenciaprospect.space` |
| Evolution API | 2.3.7 | Middleware WhatsApp (Baileys) | `https://api.agenciaprospect.space` |
| Easypanel | - | Painel de hospedagem | Hostinger |

## Estrutura do Repositorio

| Pasta/Arquivo | Conteudo |
|---------------|----------|
| `docs/logica-do-fluxo.md` | Especificacao completa do fluxo (3 paths, agent, scoring, handoff) |
| `docs/distribuidores-asx-brasil.csv` | Base de 504 distribuidores parceiros |
| `docs/arquivo/` | Fluxo anterior (obsoleto, referencia historica) |
| `workflows/` | 10 workflows n8n exportados como JSON (sanitizados) |
| `workflows/README.md` | Mapa de workflows, dependencias e como importar |
| `testes/` | Casos de teste documentados (7 testes, todos validados) |
| `.env.example` | Template de variaveis de ambiente |

## Logica do Fluxo

**Referencia completa:** `docs/logica-do-fluxo.md`

O agente "Joao" qualifica leads vindos do Facebook Ads e faz handoff para vendedores:

- **Path 1:** CNPJ invalido → Desqualificado (registra, nao entra em contato)
- **Path 2:** CNPJ valido + volume baixo OU fora do N/NE → Redireciona para distribuidores parceiros
- **Path 3:** CNPJ valido + volume >= 4k + regiao N/NE → Qualificado → Agente IA conversa → Score → Handoff para vendedor

## Workflows

**Mapa completo:** `workflows/README.md`

| ID | Workflow | Tipo |
|----|----------|------|
| `7LvmLJIL7CdbWpbt` | 06-FB-Leads-Outbound-Webhook | Principal |
| `hGsfyVT8TPWau6RH` | 07-FB-Leads-Inbound | Principal |
| `QBZhzIYU7qBuE6p5` | 02-Tool-Label | Sub-WF |
| `fRc8nB8qUjJUrTHw` | 02A-Company-Enrich | Sub-WF |
| `gPxoxxAA88LVdZ7Y` | 02B-Score-Lead | Sub-WF |
| `N1b1o3ED1FXDHWBW` | 02C-Agent-Log | Sub-WF |
| `DEwqsmZDj8fIMjuq` | 02D-Find-Distributors | Sub-WF |
| `OvvMcnq571vIb9bK` | 03-Finalize-Handoff | Sub-WF |
| `MlscoOb4IqmMpgQr` | 04-Chatwoot-Message-Logger | Auxiliar |
| `WBqj1UKzZORCANPo` | 05-Error-Logger | Auxiliar |

## Tabelas no Supabase

| Tabela | Proposito |
|--------|-----------|
| `fb_leads` | Cada submissao do formulario Facebook |
| `ia_messages` | Historico de mensagens (phone, direction, content, session_id) |
| `leads` | Leads qualificados (score, class, priority, source) |
| `assignments` | Vinculo lead-vendedor (round-robin) |
| `distributors` | Distribuidores parceiros (83 ativos) |
| `distributor_recommendations` | Historico de recomendacoes feitas |

## Como Acessar os Servicos

Credenciais no `.env` (ver `.env.example` para referencia).

| Servico | Autenticacao |
|---------|-------------|
| n8n API | Header `X-N8N-API-KEY` |
| Supabase REST | Headers `apikey` + `Authorization: Bearer` (service key) |
| Chatwoot API | Header `api_access_token` |
| Evolution API | Header `apikey` + instance name no path |

## Regras para IA

- **NUNCA ler arquivos locais para entender o estado atual do projeto.** Acessar as APIs diretamente (n8n, Supabase, Chatwoot).
- **Excecao:** Pode (e deve) ler os arquivos em `docs/` para entender a logica e o contexto.
- Usar `?includeData=true` ao buscar execucoes no n8n (sem isso, retorna sem dados dos nodes).
- PUT de workflow no n8n: payload = `{name, nodes, connections, settings: {}}` — nao incluir `versionId`.
- O `.env` tem linhas com `**` que quebram `source .env`. Usar: `grep 'KEY_NAME' .env | head -1 | cut -d'=' -f2-`
- Pensar antes de agir. Abrir o node e analisar parametros, inputs e outputs antes de qualquer ajuste.
- Testar incrementalmente. Salvar resultados de teste em `testes/`.
- Usar context7 para buscar docs atualizadas do n8n, Evolution API, Chatwoot conforme as versoes do stack.

## Gotchas Conhecidos

- **n8n Switch node v3.x:** Bug com "Always Output Data" que roteia sempre para Output 0. Usar IF node para decisoes binarias.
- **n8n `$fromAI()` em tools:** Mais de 7-8 parametros faz o LLM pular a tool call. Pre-preencher do contexto do fluxo.
- **n8n node chains:** Nodes intermediarios (Postgres INSERT, HTTP) "engolem" o output anterior. Usar `$('NodeName').first().json.field` para referenciar upstream.
- **Chatwoot auth header:** O header correto e `api_access_token` (com dois 's'). Typo comum: `api_acess_token`.
