# ASX SDR - Lógica do Novo Fluxo (Facebook Lead Ads)

> Este documento descreve a lógica do novo sistema de atendimento ativo da ASX Iluminação: como os leads são captados via formulário do Facebook, classificados em 3 caminhos, e como o agente João inicia o contato e conduz a conversa até o handoff para os vendedores.

---

## 1. Objetivo do Sistema

O novo fluxo ASX **substitui** o fluxo receptivo anterior. A lógica se inverte:

- **Captar** leads B2B via formulário nativo do Facebook Ads
- **Classificar** automaticamente em 3 caminhos (paths) com base em CNPJ, volume e região
- **Iniciar contato** proativamente via WhatsApp (o agente João aborda o lead)
- **Direcionar** leads de menor volume para distribuidores parceiros
- **Qualificar** leads de maior volume e fazer handoff para vendedores humanos
- **Ignorar** leads com CNPJ inválido (registrar e não contatar)

### Diferença fundamental do fluxo anterior

| | Fluxo Anterior | Novo Fluxo |
|---|---|---|
| **Quem inicia** | Lead envia mensagem | João envia 1ª mensagem |
| **Origem** | WhatsApp espontâneo | Formulário Facebook Ads |
| **Qualificação** | IA coleta todos os dados | Dados já vêm do formulário |
| **Caminhos** | Qualificado ou desqualificado | 3 paths: desqualificado, distribuidor, qualificado |

---

## 2. O Agente João

João continua sendo o SDR virtual da ASX. No novo fluxo ele atua em **dois papéis diferentes** conforme o path do lead:

### 2.1 João como Direcionador (Path 2 - Distribuidor)

- **Objetivo:** Recomendar distribuidores parceiros na região do lead
- Comunicação leve e prestativa
- Não está vendendo, está direcionando
- Responde dúvidas sobre os distribuidores recomendados
- Encerra naturalmente quando não há mais dúvidas
- Sem limite de interações

### 2.2 João como Consultor Comercial (Path 3 - Qualificado)

- **Objetivo:** Confirmar dados, fazer perguntas extras e conduzir ao handoff
- Comunicação consultiva e profissional
- NÃO repete perguntas já respondidas no formulário
- Conduz um fluxo de 3 etapas até transferir para vendedor

### Personalidade (ambos os papéis)

- Conversacional e natural, não robótico
- Frases curtas, estilo WhatsApp (3-5 linhas)
- Uma pergunta por vez
- Não usa jargão técnico com o cliente

### O que João NÃO faz

- Não inventa dados (especialmente de distribuidores)
- Não promete preços ou descontos
- Não menciona termos internos (score, path, API, tool, label, formulário)
- Não continua conversando após transferir para vendedor
- Não faz perguntas que já foram respondidas no formulário

---

## 3. Sistema de Classificação (3 Paths)

Quando um lead preenche o formulário do Facebook, o sistema classifica automaticamente:

### 3.1 Critérios de Classificação

| Path | Nome | Critérios | Ação |
|------|------|-----------|------|
| **1** | Desqualificado | CNPJ inválido ou ausente | Registrar e ignorar |
| **2** | Distribuidor | CNPJ válido + volume < R$4k (qualquer região) **OU** CNPJ válido + volume >= R$4k + fora N/NE | João envia distribuidores parceiros |
| **3** | Qualificado | CNPJ válido + volume >= R$4k + região N/NE | João conduz qualificação final + handoff |

### 3.2 Faixas de Volume do Formulário

| Opção no formulário | Valor numérico usado |
|---------------------|---------------------|
| Abaixo de 2.000 | R$ 1.500 |
| Entre 2.000 e 4.000 | R$ 3.000 |
| Entre 4.000 e 10.000 | R$ 7.000 |
| Acima de 10.000 | R$ 12.000 |

### 3.3 Estados do Norte/Nordeste aceitos (Path 3)

AC, AM, AP, PA, RO, RR, TO, AL, BA, CE, MA, PB, PE, PI, RN, SE

### 3.4 Diagrama de Classificação

```
              ┌──────────────────────┐
              │  Lead preenche       │
              │  formulário Facebook │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Extrair e           │
              │  normalizar dados    │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  CNPJ válido?        │
              └──────────┬───────────┘
                         │
          ┌──────────────┴──────────────┐
          │                             │
          ▼                             ▼
    ┌──────────┐                 ┌──────────┐
    │   NÃO    │                 │   SIM    │
    └────┬─────┘                 └────┬─────┘
         │                            │
         ▼                            ▼
    ┌──────────┐              ┌──────────────┐
    │ PATH 1   │              │ Volume >= 4k?│
    │ Ignorar  │              └──────┬───────┘
    └──────────┘                     │
                      ┌──────────────┴──────────────┐
                      │                             │
                      ▼                             ▼
                ┌──────────┐                 ┌──────────┐
                │   NÃO    │                 │   SIM    │
                └────┬─────┘                 └────┬─────┘
                     │                            │
                     ▼                            ▼
                ┌──────────┐              ┌──────────────┐
                │ PATH 2   │              │ Região N/NE? │
                │Distribuidor│             └──────┬───────┘
                └──────────┘                     │
                                  ┌──────────────┴──────────────┐
                                  │                             │
                                  ▼                             ▼
                            ┌──────────┐                 ┌──────────┐
                            │   NÃO    │                 │   SIM    │
                            └────┬─────┘                 └────┬─────┘
                                 │                            │
                                 ▼                            ▼
                            ┌──────────┐              ┌──────────────┐
                            │ PATH 2   │              │   PATH 3     │
                            │Distribuidor│             │ Qualificado  │
                            └──────────┘              └──────────────┘
```

---

## 4. Fluxo Outbound - Workflow 06 (1ª Mensagem)

Este workflow é acionado automaticamente quando um lead preenche o formulário do Facebook.

### 4.1 Sequência Completa

```
1. Webhook (path: meta-leads)
   └── Recebe POST do Facebook (leadgen webhook) e GET (verificação)
   └── GET: valida hub.verify_token e retorna challenge
   └── POST: responde 200 imediatamente

1b. Buscar Dados do Lead via Graph API
   └── GET https://graph.facebook.com/v25.0/{leadgen_id}
   └── Retorna field_data completo do formulário

2. Extrair Campos do Formulário
   └── Mapeia field_data: nome, email, telefone, perfil, volume, CNPJ, estado
   └── Usa fuzzy matching para normalizar nomes de campo

3. Normalizar Telefone
   └── Converte qualquer formato para 55DDDNNNNNNNNN
   └── Se inválido → registrar e parar

4. Limpar CNPJ
   └── Remove caracteres não-numéricos
   └── Se não tem 14 dígitos → Path 1 (registrar e parar)

5. Validar CNPJ na Receita Federal
   └── Chama workflow 02A-Company-Enrich
   └── Se inválido → Path 1 (registrar e parar)

6. Registrar na tabela fb_leads

7. Classificar Lead (Path 1, 2 ou 3)

8. IF Node por Path (decisão binária: path=3 → True, senão → False):
   - Nota: Usa IF node v2 em vez de Switch. O Switch node v3.x do n8n tem bug conhecido
     que roteia sempre para o Output 0 quando "Always Output Data" está ativo.
   ├── Path 1 → Atualizar status → FIM
   ├── Path 2 (False) → Buscar distribuidores → Criar contato Chatwoot → Enviar WhatsApp com lista → FIM
   └── Path 3 (True) → Criar contato Chatwoot → Enviar WhatsApp de apresentação → FIM
```

### 4.2 1ª Mensagem - Path 2 (Distribuidor)

A mensagem do Path 2 é dinâmica e varia conforme 4 cenários:

| Cenário | Condição | Justificativa na mensagem |
|---------|----------|---------------------------|
| A | Volume baixo + distribuidores encontrados | Menciona volume como motivo + lista distribuidores |
| B | Volume baixo + sem distribuidores no estado | Menciona volume + informa que não há distribuidor cadastrado |
| C | Fora do N/NE + distribuidores encontrados | Menciona cobertura regional como motivo + lista distribuidores |
| D | Fora do N/NE + sem distribuidores no estado | Menciona cobertura regional + informa que não há distribuidor cadastrado |

Exemplo (cenário A):
```
Olá {nome}! Aqui é o João da ASX Iluminação. 👋

Vi que a {empresa} se cadastrou pelo nosso formulário para conhecer nossos produtos.

Pelo volume mensal informado no cadastro ({volume_faixa}), o canal mais adequado neste momento
é o atendimento pelos nossos distribuidores parceiros, que conseguem te atender com mais agilidade.

Na sua região, recomendo:

1. *{distribuidor_1}* - {cidade_1}
   Tel: {telefone_1}

2. *{distribuidor_2}* - {cidade_2}
   Tel: {telefone_2}

3. *{distribuidor_3}* - {cidade_3}
   Tel: {telefone_3}

Você também pode consultar todos os nossos distribuidores em: asx.com.br/distribuidores

Qualquer dúvida, estou por aqui!
```

### 4.3 1ª Mensagem - Path 3 (Qualificado)

```
Olá {nome}! Aqui é o João, consultor comercial da ASX Iluminação.

Vi que a {empresa} se cadastrou para negociação direta conosco. Que ótimo saber do seu interesse!

Confirmei aqui seus dados do cadastro:
• Perfil: {perfil}
• Volume mensal: {volume_faixa}
• Estado: {estado}

Está tudo certo? Posso dar andamento ao seu atendimento?
```

---

## 5. Fluxo Inbound - Workflow 07 (Respostas)

Este workflow recebe as respostas dos leads via webhook da Evolution API.

### 5.1 Roteamento

Quando uma mensagem chega, o sistema identifica quem é o lead:

```
Mensagem chega via WhatsApp
    │
    ▼
É mensagem enviada por nós? (fromMe)
├── SIM → Ignorar
└── NÃO
    │
    ▼
Processar mídia (texto/áudio/imagem/documento)
    │
    ▼
Agrupar mensagens (Redis - janela de 10s)
    │
    ▼
Identificar Lead (query por telefone)
    │
    ▼
Switch:
├── "already_qualified" → Notificar vendedor → FIM
├── "distributor_agent" → João Direcionador (Path 2) → Responder
├── "qualified_agent"   → João Consultor (Path 3) → Responder
└── "unknown"           → Ignorar (sem resposta) → FIM
```

### 5.2 Processamento de Mídia

| Tipo | Processamento |
|------|---------------|
| **Texto** | Usado diretamente |
| **Áudio** | Transcrito via OpenAI Whisper |
| **Imagem (sem legenda)** | Analisada via OpenAI Vision + sinalizada (has_image = true) |
| **Imagem (com legenda)** | Legenda usada como texto + sinalizada (has_image = true) |
| **Documento** | Sinalizado como possível NF (has_document = true) |

### 5.3 Batching de Mensagens (Redis)

Quando o lead envia várias mensagens seguidas (ex: texto + áudio + foto), o sistema aguarda 10 segundos para agrupar tudo em uma única entrada antes de processar. Isso evita múltiplas respostas fragmentadas.

Cada mensagem é empacotada como JSON com `msgId`, `message`, `chatwootConversationId`, `chatwootInboxId`, `has_document`, `has_image`. A deduplicação usa `msgId` (não texto) para determinar qual execução processa o batch.

```
Msg 1 → Redis PUSH (JSON) → Wait 10s
Msg 2 → Redis PUSH (JSON) → (timer já rodando)
Msg 3 → Redis PUSH (JSON) → (timer já rodando)
                              Timer expira → Redis GET ALL → Parse Redis Batch → IF Last Message → Merge → Processar
```

---

## 6. Fluxo de Qualificação - Path 3 (Detalhado)

O João Consultor conduz o lead qualificado por **3 etapas obrigatórias**:

### 6.1 Etapa 1 - Confirmação de Dados (1-2 mensagens)

João confirma que tem os dados do formulário e pergunta se está tudo certo.

### 6.2 Etapa 2 - Pergunta sobre ASX na Região

```
"Você já compra produtos ASX de algum distribuidor na sua região?"
```

| Resposta | Ação |
|----------|------|
| **SIM + volume ≤ R$10k** | DESQUALIFICAR por política interna |
| **SIM + volume > R$10k** | EXCEÇÃO → registrar fornecedor → continuar |
| **NÃO** | Registrar → continuar para Etapa 3 |

#### Desqualificação por Política

Quando o lead já compra ASX de alguém na região e tem volume ≤ R$10k:

- João explica educadamente que deve continuar com o fornecedor atual
- Registra o nome do fornecedor
- Aplica labels: `desqualificado_politica`, `ja_compra_asx`
- **NÃO** faz handoff
- Conversa encerra

#### Exceção (Volume Alto)

Se o lead já compra ASX mas o volume é > R$10k:

- Registra o fornecedor atual
- Aplica label: `excecao_volume_alto`
- Continua para Etapa 3

### 6.3 Etapa 3 - Solicitar Notas Fiscais

```
"Para dar andamento ao seu cadastro, preciso que envie ao menos duas
notas fiscais de compras recentes em fornecedores de autopeças.
Pode ser foto ou PDF!"
```

| Cenário | Ação |
|---------|------|
| Lead envia NFs (imagem/documento) | Registrar `nfs_enviadas = true` → HANDOFF |
| Lead diz que não tem | Perguntar se é empresa nova → `empresa_recente = true` → HANDOFF |
| Lead envia algo que não é NF | Pedir gentilmente as NFs corretas |

### 6.4 Diagrama Completo - Path 3

```
                    ┌─────────────────┐
                    │  Lead responde  │
                    │  1ª mensagem    │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ ETAPA 1:        │
                    │ Confirmar dados │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ ETAPA 2:        │
                    │ Já compra ASX?  │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │ SIM      │   │ SIM      │   │ NÃO      │
        │ Vol ≤10k │   │ Vol >10k │   │          │
        └────┬─────┘   └────┬─────┘   └────┬─────┘
             │              │              │
             ▼              ▼              ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │DESQUALIF.│   │ EXCEÇÃO  │   │ Continua │
        │ Política │   │ Registra │   │          │
        └──────────┘   └────┬─────┘   └────┬─────┘
                            │              │
                            └──────┬───────┘
                                   │
                                   ▼
                          ┌─────────────────┐
                          │ ETAPA 3:        │
                          │ Envie 2 NFs     │
                          └────────┬────────┘
                                   │
                        ┌──────────┴──────────┐
                        │                     │
                        ▼                     ▼
                  ┌──────────┐          ┌──────────┐
                  │ Enviou   │          │ Não tem  │
                  │ NFs      │          │ (nova)   │
                  └────┬─────┘          └────┬─────┘
                       │                     │
                       └─────────┬───────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │    HANDOFF      │
                        │ Score → Finalize│
                        │ → Transferir    │
                        └─────────────────┘
```

---

## 7. Sistema de Scoring

Leads qualificados (Path 3) que chegam ao handoff recebem uma pontuação:

### 7.1 Classificação por Score

| Score | Classe | Prioridade | Significado |
|-------|--------|------------|-------------|
| 80-100 | Quente | Urgent | Alto potencial, atender imediatamente |
| 60-79 | Morno | High | Bom potencial, priorizar |
| 0-59 | Frio | Medium | Potencial moderado |

### 7.2 Fatores que Influenciam o Score

Base: 50 pontos. Máximo: 100.

| Fator | Condição | Pontos |
|-------|----------|--------|
| **Volume** | >= R$8.000 | +20 |
| **Volume** | >= R$5.000 (e < 8k) | +10 |
| **Perfil** | Contém "revenda" ou "loja" | +10 |
| **CNAE** | Códigos relevantes (4530, 4541, 4542, 4661, 4673, 4674, 4742, 4754) | +10 |
| **Idade empresa** | > 5 anos | +5 |

---

## 8. Comportamento das Tools (Ferramentas)

### 8.1 company_enrich (Validar CNPJ) - Workflow 02A

**Quando:** Automaticamente no fluxo outbound (workflow 06), antes de classificar

**O que faz:**

- Primeiro verifica cache na tabela `companies` (se já foi consultado antes, retorna direto)
- Se não encontrar no cache, consulta a API CNPJA (`api.cnpja.com`)
- Busca: razão social, nome fantasia, CNAE, cidade, estado
- Salva/atualiza na tabela `companies` (cache) e retorna dados para o fluxo

**Resultados:**

- CNPJ válido → continua classificação
- CNPJ inválido → Path 1 (registra e ignora)

### 8.2 find_distributors (Buscar Distribuidores) - Workflow 02D

**Quando:** No outbound (Path 2) e quando o agente Path 2 precisa de mais opções

**O que faz:**

- Busca até 3 distribuidores parceiros no estado do lead
- Prioriza: mesma cidade > tipo "Distribuidor" > tipo "Lojista"
- Se não encontrar nenhum: retorna mensagem genérica

**Retorna:** `{ distributors: [{razao_social, cidade, estado}], count }`

### 8.3 score_lead (Calcular Score) - Workflow 02B

**Quando:** No Path 3, após confirmar que o lead será transferido

**O que faz:**

- Calcula score numérico (0-100)
- Classifica: quente/morno/frio
- Define prioridade: urgent/high/medium

**Retorna:** `{ score, class, priority }`

### 8.4 finalize (Transferir para Vendedor) - Workflow 03

**Quando:** IMEDIATAMENTE após score_lead, no Path 3

**O que faz:**

- Registra o lead na tabela `leads` (com source = "facebook_form")
- Escolhe o vendedor com menos leads atribuídos (round-robin)
- Move a conversa para inbox do vendedor no Chatwoot
- Envia notificação WhatsApp ao vendedor com dados extras:
  - Já compra ASX na região?
  - Fornecedor atual
  - NFs enviadas ou empresa nova

**CRÍTICO:** Deve ser chamado ANTES de avisar o cliente sobre a transferência

**Parâmetros do tool (simplificado):**

O tool recebe 16 parâmetros, mas apenas 7 são fornecidos pelo agente via `$fromAI()`.
Os outros 9 são pré-preenchidos automaticamente do contexto do fluxo:

| Parâmetro | Origem |
|-----------|--------|
| phone, nome, empresa, cnpj, perfil, uf_atuacao, volume | `Lookup Lead Path` (dados do fb_leads) |
| chatwoot_conversation_id | `Merge Messages` (ID da conversa) |
| source | Fixo: `facebook_form` |

Parâmetros que o agente fornece (coletados na conversa + resultado do score_lead):
- `score`, `class`, `priority` — Resultado do score_lead
- `ja_compra_asx_regiao` — sim ou nao
- `fornecedor_asx_regiao` — Nome do fornecedor ASX ou N/A
- `nfs_enviadas` — true ou false
- `empresa_recente` — true ou false

> Nota: Reduzido de 13 para 7 `$fromAI()` porque LLMs tendem a pular tool calls com muitos parâmetros.

### 8.5 set_label (Aplicar Etiquetas) - Workflow 02

**Quando:** Para marcar o status e path do lead

**Labels do novo fluxo:**

- `fb_lead` - Lead originado do formulário Facebook
- `path_distributor` - Path 2: redirecionado para distribuidor
- `path_qualified` - Path 3: qualificado para handoff
- `path_disqualified` - Path 1: desqualificado (CNPJ inválido)
- `desqualificado_politica` - Já compra ASX na região (volume ≤ 10k)
- `ja_compra_asx` - Lead já compra ASX de alguém
- `nfs_recebidas` - Lead enviou NFs
- `empresa_nova` - Lead sem NFs (empresa recente)
- `excecao_volume_alto` - Compra ASX mas volume > 10k (exceção)

### 8.6 log_agent_event (Registrar Eventos) - Workflow 02C

**Quando:** Para auditoria de decisões importantes

**Tipos de eventos na tabela `events`:**

- `workflow_success` - Workflow executado com sucesso (WF06, WF07)
- `handoff_complete` - Lead transferido para vendedor
- `label_added` - Labels aplicadas no Chatwoot
- `agent_log` - Eventos do agente IA (score calculado, desqualificação, etc.)
- `invalid_phone` - Telefone inválido
- `infra_error` - Erro em qualquer workflow (via WF05)
- `health_check` - Resultado do monitoramento (via WF08)

---

## 9. Fluxo de Handoff (Transferência) - Path 3

### 9.1 Sequência Obrigatória

```
1. João confirma dados do formulário
2. João pergunta se já compra ASX na região
3. João solicita NFs (ou registra empresa nova)
4. João chama score_lead → recebe score/class/priority
5. João chama finalize → transferência acontece
6. João avisa cliente: "Vou te passar para um especialista"
7. João PARA de responder
8. Vendedor recebe notificação no WhatsApp
9. Vendedor assume conversa no Chatwoot
```

### 9.2 O que Acontece no Handoff (Workflow 03)

```
1. Pick Agent
   └── Seleciona vendedor com menos leads atribuídos
   └── Retorna: agent_id, agent_name, agent_phone, team_id

2. Persist Lead
   └── Cria/atualiza contato e empresa
   └── Cria lead com source = "facebook_form"
   └── Inclui: ja_compra_asx_regiao, fornecedor, nfs_enviadas, empresa_recente

3. Create Assignment
   └── Vincula lead ao vendedor

4. Transfer Conversation
   └── Transfere conversa para o TIME do vendedor no Chatwoot

5. Notify Vendor
   └── Envia WhatsApp ao vendedor com resumo expandido
   └── Usa bodyParameters (keypair: number + text) em vez de jsonBody
       (jsonBody com emojis/quebras de linha causava JSON inválido)

6. Log Handoff
   └── Registra evento
```

### 9.3 Distribuição de Leads

| Vendedor | Telefone | Team ID | Inbox ID |
|----------|----------|---------|----------|
| Queila | 5575991803083 | 1 | 2 |
| Tiago | 5575999216589 | 2 | 3 |

### 9.4 Mensagem para o Vendedor

```
*NOVO LEAD QUALIFICADO* (via Formulário Facebook)

Nome: João Silva
Empresa: ABC Autopeças
Estado: BA
Telefone: +5575999999999

Score: Quente

Já compra ASX na região: Não
Fornecedor atual: Nenhum
NFs enviadas: Sim

Entre em contato!
```

---

## 10. Comportamento com Lead Já Qualificado (Lead Recorrente)

Se um lead que já foi transferido para vendedor enviar nova mensagem:

### 10.1 Detecção

O sistema consulta as tabelas `contacts → leads → assignments → agents` para verificar se o telefone já tem um lead qualificado.

### 10.2 Comportamento

1. João **NÃO** responde (a IA não processa a mensagem)
2. Sistema **notifica o vendedor responsável** via WhatsApp
3. Vendedor continua atendimento no Chatwoot

### 10.3 Mensagem de Notificação

```
*Lead Recorrente*

5575999999999 enviou nova mensagem.
Continue o atendimento no Chatwoot.
```

---

## 11. Comportamento com Lead Desconhecido

Se alguém enviar mensagem para o número do SDR sem ter preenchido o formulário:

### 11.1 Ignorar Silenciosamente

O sistema **NÃO** responde. A mensagem é recebida pelo WF07, classificada como `unknown`, e a execução encerra sem nenhuma ação. Nenhuma resposta é enviada.

---

## 11B. Normalização de Telefone (WF07)

O WhatsApp JID chega com 12 dígitos (55+DDD+8dígitos, sem o 9 móvel), enquanto a `fb_leads` armazena com 13 dígitos (55+DDD+9+8dígitos). O WF07 normaliza para 13 dígitos no node `Normalisa Payload` e o SQL do `Lookup Lead Path` faz match com OR em ambos os formatos (12 e 13 dígitos).

## 11C. Integração Chatwoot ↔ Evolution API

A sincronização de mensagens entre WhatsApp e Chatwoot é feita **automaticamente pela Evolution API** (configuração `enabled: true` com `mergeBrazilContacts: true` na integração Chatwoot). Não há nodes nos workflows para postar mensagens no Chatwoot — a Evolution API cuida disso.

O WF06 enriquece o contato no Chatwoot com:
- `custom_attributes` e `additional_attributes` (dados do lead)
- Private note na conversa com resumo do lead (nome, empresa, CNPJ, perfil, volume, estado, path, motivo)

---

## 12. Tratamento de Erros e Exceções

### 12.1 CNPJ Inválido (Path 1)

O lead é registrado na tabela `fb_leads` com `path = 1` e `status = disqualified_cnpj`. Nenhuma mensagem é enviada.

### 12.2 Telefone Inválido

O sistema tenta normalizar o telefone para o formato `55DDDNNNNNNNNN`. Se não conseguir, registra o evento `invalid_phone` e para.

### 12.3 Desqualificação por Política (Path 3 - Etapa 2)

Quando o lead já compra ASX de um distribuidor na região e tem volume ≤ R$10k:

```
João: "Entendo! Por questão de política interna, para manter
a organização dos nossos parceiros, o ideal é continuar
comprando com [nome do fornecedor]. Eles vão te atender
muito bem! Qualquer dúvida, estou por aqui."
```

### 12.4 Lead Pergunta Sobre Preços

- **Path 2 (Distribuidor):** "Os preços variam conforme o distribuidor e volume. O melhor é entrar em contato direto com eles!"
- **Path 3 (Qualificado):** "O especialista que vai te atender poderá apresentar todas as condições e preços!"

### 12.5 Lead Pede Compra Direta (Path 2)

```
João: "Para compras diretas da fábrica, trabalhamos com
volumes a partir de R$4.000/mês na região Norte/Nordeste.
Para o seu perfil, o canal mais rápido são nossos parceiros."
```

### 12.6 Lead Reclama dos Distribuidores (Path 2)

```
João: "Sinto muito! Posso verificar se existe outro
parceiro mais próximo. Qual sua cidade?"
```

(João consulta find_distributors para buscar alternativas)

### 12.7 Sem Distribuidores no Estado (Path 2)

```
João: "No momento estamos expandindo nossa rede de
distribuidores na sua região. Em breve teremos novidades!
Posso anotar seu contato para quando tivermos um parceiro por aí."
```

### 12.8 Lead Pede para Falar com Alguém (Path 3)

João faz o handoff direto, sem precisar completar todas as etapas.

---

## 13. Exemplos de Conversas

### 13.1 Path 2 - Distribuidor (Completo)

```
[1ª msg enviada automaticamente pelo sistema]
João: Olá Carlos! Aqui é o João da ASX Iluminação.
      Vi que a Auto Center Sul se cadastrou no nosso formulário.
      Para o perfil da sua empresa, o canal mais rápido para
      adquirir nossos produtos são nossos distribuidores parceiros.

      Na sua região (São Paulo), recomendo:
      • Distribuidora Paulista - São Paulo/SP
      • Loja Iluminar - Campinas/SP
      • Auto Parts SP - Santos/SP

      Qualquer dúvida, estou por aqui!

Carlos: Oi João! Obrigado pelas indicações. A Distribuidora
        Paulista fica longe de mim. Tem algo mais perto de Osasco?

João: Deixa eu verificar! Na região de Osasco, o mais próximo
      seria a Loja Iluminar em Campinas. Infelizmente ainda não
      temos um parceiro na cidade de Osasco, mas estamos expandindo.

Carlos: Entendi. E qual o preço médio das lâmpadas H4?

João: Os preços variam conforme o distribuidor e volume.
      O melhor é entrar em contato direto com eles!
      A Distribuidora Paulista costuma ter boa variedade.

Carlos: Beleza, vou entrar em contato com eles. Obrigado!

João: Por nada! Precisando, estou por aqui. Boas compras!
```

### 13.2 Path 3 - Qualificado (Caminho Feliz → Handoff)

```
[1ª msg enviada automaticamente pelo sistema]
João: Olá Maria! Aqui é o João da ASX Iluminação.
      Vi que a Nordeste Autopeças se cadastrou para negociação direta.
      Tenho os dados do formulário aqui. Podemos conversar
      sobre as melhores condições para vocês?

Maria: Oi João! Sim, podemos sim.

João: Perfeito! Tenho aqui os dados da Nordeste Autopeças,
      CNPJ confirmado, volume na faixa de R$4.000 a R$10.000.
      Está tudo certo?

Maria: Sim, está certo!

João: Ótimo! Você já compra produtos ASX de algum distribuidor
      na sua região?

Maria: Não, seria a primeira vez.

João: Entendi! Para dar andamento ao seu cadastro, preciso que
      envie ao menos duas notas fiscais de compras recentes em
      fornecedores de autopeças. Pode ser foto ou PDF!

Maria: [envia 2 fotos de NFs]

João: Recebi as notas! Vou te passar para um especialista que
      vai cuidar do seu cadastro e apresentar as melhores condições.
      Ele entra em contato em breve!

[Vendedor recebe notificação e assume a conversa]
```

### 13.3 Path 3 - Desqualificado por Política

```
[1ª msg + confirmação de dados já feitas]

João: Você já compra produtos ASX de algum distribuidor
      na sua região?

Roberto: Sim, compro da Distribuidora Bahia há uns 2 anos.

João: Que bom! De quem da Distribuidora Bahia você compra?

Roberto: Do pessoal de lá mesmo, compro uns 5 mil por mês.

João: Entendo! Por questão de política interna, para manter
      a organização dos nossos parceiros, o ideal é continuar
      comprando com a Distribuidora Bahia. Eles vão te atender
      muito bem! Qualquer dúvida, estou por aqui.

Roberto: Ah entendi, tudo bem então. Obrigado!

João: Por nada! Boas compras com a Distribuidora Bahia!
```

### 13.4 Path 3 - Exceção Volume Alto (já compra ASX mas volume > 10k)

```
[1ª msg + confirmação de dados já feitas]

João: Você já compra produtos ASX de algum distribuidor
      na sua região?

Pedro: Sim, compro da Auto Nordeste. Mas nosso volume
       cresceu muito e quero negociar direto.

João: Entendi! E qual o volume mensal atualmente?

Pedro: Mais de 12 mil por mês.

João: Perfeito! Nesse caso, faz sentido uma negociação direta.
      Para dar andamento, preciso que envie ao menos duas
      notas fiscais de compras recentes. Pode ser foto ou PDF!

Pedro: [envia NFs]

João: Recebi! Vou te passar para um especialista que vai
      cuidar do seu cadastro com condições especiais.
      Ele entra em contato em breve!

[Handoff realizado]
```

### 13.5 Lead Desconhecido (sem formulário)

```
Pessoa: Oi, quero comprar lâmpada pro meu carro

[Nenhuma resposta é enviada. O sistema ignora silenciosamente.]
```

---

## 14. Arquitetura dos Workflows

### 14.1 Mapa Completo

| # | Workflow | Tipo | Função |
|---|----------|------|--------|
| 02 | 02-Tool-Label | Callable | Aplicar labels no Chatwoot |
| 02A | 02A-Company-Enrich | Callable | Validar CNPJ na Receita Federal (com cache em `companies`) |
| 02B | 02B-Score-Lead | Callable | Calcular score do lead (0-100) |
| 02C | 02C-Agent-Log | Callable | Registrar eventos na tabela `events` |
| 02D | 02D-Find-Distributors | Callable | Buscar distribuidores por estado |
| 03 | 03-Finalize-Handoff | Callable | Transferir lead para vendedor (round-robin) |
| 04 | 04-Chatwoot-Message-Logger | Webhook | Salvar mensagens de vendedores na tabela `messages` |
| 05 | 05-Error-Logger | Error Handler | Capturar e registrar erros na tabela `events` |
| 06 | 06-FB-Leads-Outbound-Webhook | Webhook | Processar formulário Facebook → classificar → enviar 1ª msg |
| 07 | 07-FB-Leads-Inbound | Webhook | Receber respostas → batching Redis → agente IA responde |
| 08 | 08-Health-Check | Schedule (5 min) | Monitoramento operacional (serviços, leads, mensagens, workflows) |

### 14.2 Dependências

```
06-Outbound ──usa──→ 02A (enrich CNPJ)
             ──usa──→ 02D (buscar distribuidores)
             ──usa──→ 02  (labels)
             ──usa──→ 02C (logs)

07-Inbound  ──usa──→ 02  (labels)
             ──usa──→ 02B (score)
             ──usa──→ 02C (logs)
             ──usa──→ 02D (distribuidores - Path 2)
             ──usa──→ 03  (handoff - Path 3)

04-Chatwoot  ← Webhook Chatwoot (message_created)
05-Error     ← Error trigger (qualquer workflow)
08-Health    ← Schedule (5 min) → Ping serviços + snapshots operacionais
```

**IMPORTANTE:** Os workflows callable (02, 02A, 02B, 02C, 02D, 03) devem permanecer ATIVOS. Não podem ser desativados.

---

## 15. Banco de Dados

### 15.1 Tabelas

| Tabela | Propósito |
|--------|-----------|
| `fb_leads` | Registra cada submissão do formulário Facebook |
| `ia_messages` | Histórico de mensagens da IA (phone, direction, content, session_id) |
| `messages` | Mensagens do lado vendedor (via webhook Chatwoot → WF04) |
| `leads` | Leads qualificados (score, class, priority, source, ja_compra_asx_regiao, etc.) |
| `contacts` | Registro de contatos (phone, name) — upsert no handoff |
| `companies` | Cache de dados CNPJ (razão social, nome fantasia, CNAE, cidade, estado) |
| `agents` | Vendedores (nome, phone, team_id) — usado no round-robin |
| `assignments` | Vínculo lead-vendedor |
| `distributors` | Distribuidores parceiros (~83 ativos) |
| `distributor_recommendations` | Histórico de recomendações feitas |
| `events` | Log universal de eventos do sistema |

### 15.2 Status do fb_lead

| Status | Significado |
|--------|-------------|
| `pending` | Formulário recebido, processando |
| `contacted` | 1ª mensagem enviada |
| `in_conversation` | Lead respondeu, conversa em andamento |
| `handoff_done` | Transferido para vendedor |
| `disqualified_cnpj` | CNPJ inválido (Path 1) |
| `disqualified_policy` | Desqualificado por política (já compra ASX) |
| `send_failed` | Falha ao enviar mensagem |

---

## 16. Isolamento de Memória

Cada agente (Path 2 e Path 3) usa uma **session key diferente** no Postgres Chat Memory:

| Agente | Session Key | Propósito |
|--------|-------------|-----------|
| Direcionador (P2) | `distributor_{telefone}` | Contexto de recomendação de distribuidores |
| Consultor (P3) | `qualified_{telefone}` | Contexto de qualificação e handoff |

Isso garante que se um mesmo telefone passar por ambos os paths (improvável mas possível), os contextos não se misturam.

---

## 17. Métricas e KPIs

O sistema registra dados para acompanhamento:

| Métrica | Tabela | Uso |
|---------|--------|-----|
| Formulários recebidos | `fb_leads` | Volume total de captação |
| Taxa Path 1 (desqualificados) | `fb_leads` WHERE path=1 | Qualidade dos leads do Facebook |
| Taxa Path 2 (distribuidores) | `fb_leads` WHERE path=2 | Leads fora do perfil direto |
| Taxa Path 3 (qualificados) | `fb_leads` WHERE path=3 | Leads para handoff |
| Handoffs realizados | `fb_leads` WHERE handoff_done=true | Conversões efetivas |
| Desqualificação por política | `fb_leads` WHERE status='disqualified_policy' | Leads que já compram ASX |
| Conversas da IA | `ia_messages` | Análise de qualidade |
| Distribuições de distribuidores | `distributor_recommendations` | Efetividade das recomendações |
| Atribuições por vendedor | `assignments` | Distribuição de carga |

---

## 18. Glossário

| Termo | Significado |
|-------|-------------|
| **SDR** | Sales Development Representative - quem qualifica leads |
| **Lead** | Potencial cliente que preencheu o formulário |
| **Path** | Caminho de classificação (1, 2 ou 3) |
| **Handoff** | Transferência do lead da IA para vendedor humano |
| **Score** | Pontuação de 0-100 que indica potencial do lead |
| **Outbound** | Fluxo de saída: sistema envia 1ª mensagem |
| **Inbound** | Fluxo de entrada: lead responde a mensagem |
| **Distribuidor Parceiro** | Empresa que revende produtos ASX |
| **Inbox** | Caixa de entrada no Chatwoot |
| **Callable** | Workflow auxiliar chamado por outros workflows |
| **Batching** | Agrupamento de mensagens em janela de 10 segundos |
| **B2B** | Business to Business - venda para empresas |
| **NF** | Nota Fiscal |
| **N/NE** | Norte e Nordeste do Brasil |
| **Evolution API** | Middleware de conexão com WhatsApp |
| **Webhook** | Endpoint que recebe dados quando um evento acontece |
