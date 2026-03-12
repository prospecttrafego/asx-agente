# Teste 09 - Auditoria de Workflows Ativos e Revisao do WF08

Data: 2026-03-11
Ambiente: n8n real `https://flow.agenciaprospect.space`
Escopo: workflows ativos `02A`, `02C`, `02D`, `02-Tool-Label`, `03`, `04`, `05`, `06`, `07`, `08`

## Objetivo

Fazer uma varredura dos workflows ativos no ambiente real para identificar:

- configuracoes hardcoded que podem quebrar a operacao real;
- fixtures ou logica de teste remanescente;
- parametros errados em nodes;
- pontos em que o `WF08` pode indicar falso positivo;
- sinais reais disponiveis para dashboard/monitoramento no Metabase.

## Evidencias verificadas

- Lista de workflows ativos via n8n API.
- Nodes e parametros reais dos workflows `06`, `07`, `03`, `02A`, `08`.
- Execucao recente do `WF08` com `includeData=true`.
- Estrutura real dos nodes de `HTTP Request`, `Postgres`, `Code`, `Webhook`, `Switch`, `IF`, `Redis`, `Agent`.

## Achados confirmados

### 1. `WF08` hoje mede disponibilidade basica, nao saude operacional do funil

Workflow: `08-Health-Check`
ID: `Oj8SgieQ4HH7Czbk`

Nodes atuais:

- `Ping Evolution`
- `Ping Chatwoot`
- `Ping N8N`
- `Consolidate Results`
- `Log Health`

Problema:

- `Ping Chatwoot` consulta `https://chat.agenciaprospect.space/auth/sign_in`.
- Esse endpoint devolve a tela HTML/login e mesmo assim o `Consolidate Results` trata isso como `up`.
- `Ping N8N` consulta `GET /api/v1/workflows`, que apenas prova que a API respondeu.
- `Ping Evolution` consulta `fetchInstances`, que prova alcance da API, mas nao prova que o fluxo de negocio processou lead.

Conclusao:

- O `WF08` pode ficar verde mesmo com o `WF06` quebrado.
- O `WF08` nao detecta lead preso em `pending`.
- O `WF08` nao detecta falta de envio da primeira mensagem.
- O `WF08` nao detecta falta de resposta no `WF07`.

### 2. Evidencia concreta de falso positivo no `WF08`

Execucao analisada:

- `WF08` retornou `status=success`
- `all_up=true`

Mesmo assim:

- `Ping Chatwoot` retornou a pagina HTML de login/sign-in, nao um endpoint de negocio autenticado.
- O `Consolidate Results` marcou `chatwoot=up` apenas porque nao havia `error` no payload.

### 3. `WF06` ainda possui dependencia hardcoded de token da Meta

Workflow: `06-FB-Leads-Outbound-Webhook`
Node: `HTTP Request`

Achado:

- o `access_token` da Graph API esta hardcoded no node.

Risco:

- se o token expirar ou for rotacionado fora do n8n, o `WF06` volta a falhar na leitura do lead real.

### 4. `02A-Company-Enrich` ainda possui chave hardcoded

Workflow: `02A-Company-Enrich (callable)`
Node: `CNPJ API`

Achado:

- o header `Authorization` da CNPJA esta hardcoded no node.

Risco:

- rotacao manual obrigatoria e risco de quebra silenciosa do enriquecimento.

### 5. Chatwoot e Evolution estao funcionais, mas ainda dependem de credenciais inline em varios nodes

Workflows observados:

- `06-FB-Leads-Outbound-Webhook`
- `07-FB-Leads-Inbound`
- `03-Finalize-Handoff (callable)`
- `02-Tool-Label (callable)`
- `08-Health-Check`

Achado:

- varios `HTTP Request` usam tokens inline em headers.

Status:

- os tokens atuais batem com as credenciais vigentes observadas na revisao.

Risco:

- manutencao fragil; rotacao de segredo exige revisao manual node por node.

### 6. `WF07` ainda tem risco de processar mensagens enviadas pela propria operacao

Workflow: `07-FB-Leads-Inbound`

Achado:

- o payload extrai `fromMe`, mas esse campo nao participa de nenhuma decisao de roteamento.

Risco:

- se a Evolution reenviar mensagens proprias pelo webhook, o fluxo pode processar trafego que nao veio do lead.

### 7. O batching do `WF07` em Redis tem criterio fraco para detectar a ultima mensagem

Workflow: `07-FB-Leads-Inbound`

Achado:

- o agrupamento em Redis usa o telefone como chave e compara conteudo da mensagem, nao `msgId`.

Risco:

- mensagens repetidas com mesmo texto podem ser tratadas de forma ambigua;
- o controle de ultima mensagem nao e robusto para concorrencia e duplicidade.

### 8. Ha divergencia entre documentacao e telemetria de mensagens

Workflow observado:

- `04-Chatwoot-Message-Logger`

Achado:

- a estrategia de monitoramento descrita para `ia_messages` precisa ser validada contra a implementacao real, porque a malha de logs de mensagens nao esta claramente concentrada em uma unica tabela.

Risco:

- dashboard de resposta pode ficar cego ou parcial se confiar em uma tabela diferente da que esta sendo alimentada.

## O que ja havia sido corrigido antes desta auditoria

- `WF06`: parser real da Meta Graph API recolocado no fluxo.
- `WF06`: fixture hardcoded de lead removida da logica efetiva.
- `WF06`: branch de distribuidores passou a tolerar ausencia de distribuidores.
- `WF06`: `Save fb_lead` ajustado para `upsert` com `RETURNING id`.
- `WF06`: `apikey` da Evolution corrigida.
- `WF07`: `apikey` da Evolution corrigida.
- `03-Finalize-Handoff`: `apikey` da Evolution corrigida.

## Correcoes aplicadas nesta rodada

### 1. `WF07` endurecido para ignorar mensagens proprias

Workflow: `07-FB-Leads-Inbound`

- adicionado node `IF Lead Message` logo apos `Normaliza Payload`;
- `fromMe=true` agora vai para `No Op`;
- apenas mensagens do lead seguem para `Switch Message Type`.

### 2. Queries SQL interpoladas foram convertidas para placeholders preparados

Workflows ajustados:

- `03-Finalize-Handoff (callable)`
- `02D-Find-Distributors (callable)`
- `04-Chatwoot-Message-Logger`
- `02A-Company-Enrich (callable)`
- `05-Error-Logger`
- `07-FB-Leads-Inbound` (`Lookup Lead Path`)

Resumo:

- interpolacoes inline com `{{ ... }}` foram substituidas por `$1`, `$2`, ...;
- os valores passaram a usar `queryReplacement`;
- os logs de evento passaram a gravar `jsonb` por payload serializado, reduzindo risco de quebra por aspas/conteudo arbitrario.

### 3. `WF08` foi refeito para monitoramento operacional real

Workflow: `08-Health-Check`
ID: `Oj8SgieQ4HH7Czbk`

Nodes atuais:

- `Ping Evolution`
- `Ping Chatwoot API`
- `WF06 Executions`
- `WF07 Executions`
- `Lead Health Snapshot`
- `Message Health Snapshot`
- `Workflow Signal Snapshot`
- `Consolidate Results`
- `Log Health`

O que ele mede agora:

- instancia `ASX_SDR` da Evolution com `connectionStatus`;
- acesso autenticado na API do Chatwoot;
- ultimo status de execucao do `WF06`;
- ultimo status de execucao do `WF07`;
- `fb_leads` recentes, `pending`, sem `first_message_sent_at`, ultimo lead recebido;
- sinais de `workflow_success` e `infra_error` em `events`;
- backlog recente de resposta em `ia_messages`.

### 4. Ajustes finos no `WF08` para evitar falso positivo operacional

- leads de teste `facebook_lead_id` com prefixo `TEST_` foram excluidos dos checks criticos;
- a janela de backlog de resposta foi reduzida para atividade recente, evitando ruído historico;
- sessoes ja qualificadas/handoffadas deixaram de ser consideradas “sem resposta”.

## O que o monitoramento deveria medir de verdade

### Infra minima

- Evolution acessivel e instancia `ASX_SDR` com `connectionStatus = open`
- Chatwoot acessivel por endpoint autenticado de API, nao por tela de login
- n8n acessivel por endpoint autenticado de API

### Saude de negocio do `WF06`

- quantidade de leads recebidos em janela recente
- quantidade de `fb_leads` ainda em `pending`
- quantidade de `fb_leads` em `pending` acima do SLA
- quantidade de leads com `status=contacted`
- quantidade de leads sem `first_message_sent_at`
- horario do ultimo `workflow_success` do `WF06`

### Saude de resposta do `WF07`

- horario da ultima mensagem do usuario
- horario da ultima mensagem do assistente
- quantidade de mensagens do usuario sem resposta dentro do SLA
- quantidade de falhas recentes registradas em `events`

## Sinais reais ja existentes para o Metabase

Tabelas/sinais uteis:

- `fb_leads`
- `events`
- `ia_messages` (depende de validacao de alimentacao real)

Eventos reais observados na malha:

- `health_check`
- `workflow_success`
- `infra_error`
- `handoff_complete`
- `label_added`
- `agent_log`

## Parecer

Sim, procede.

O `WF08` atual pode mostrar execucao bem sucedida sem garantir que:

- um lead entrou no `WF06`;
- o lead foi processado ate `contacted`;
- a primeira mensagem saiu;
- o `WF07` continuou respondendo;
- houve regressao no funil principal.

Ou seja, do jeito atual, ele serve mais como ping tecnico superficial do que como monitoramento operacional do projeto.

## Validacao final no ambiente real

Execucoes validadas do `WF08`:

- `1360` em `2026-03-11T14:40:02Z`
- `1361` em `2026-03-11T14:45:07Z`
- `1363` em `2026-03-11T14:55:25Z`

Resultado final confirmado na execucao `1363`:

- `overall_status = up`
- `all_up = true`
- `lead_pipeline.status = up`
- `message_health.status = up`
- `wf06_execution.status = up`
- `wf07_execution.status = up`
- `chatwoot_api.status = up`
- `evolution_api.status = up`

Payload final observado em `events.type='health_check'`:

- `last_wf06_success_at = 2026-03-11T13:53:48.014Z`
- `wf06_success_last_24h = 7`
- `stale_pending_count = 0`
- `stale_missing_first_message_count = 0`
- `overdue_reply_count = 0`

## Divida tecnica remanescente

- tokens inline ainda existem em varios `HTTP Request` de `03`, `06`, `07`, `08` e `02-Tool-Label`;
- `WF06` ainda usa `Save Recommendations` com SQL dinamico;
- o token da Meta Graph API no `WF06` foi mantido hardcoded por decisao explicita desta rodada;
- a chave da CNPJA no `02A` foi mantida hardcoded por decisao explicita desta rodada.
