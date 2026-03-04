# ASX-Agente — Agente SDR de IA

Sistema de qualificacao automatica de leads para a **ASX Iluminacao Automotiva**, operando como um agente SDR (Sales Development Representative) via WhatsApp.

> **Este repositorio e um espelho documental.** O projeto real roda em servicos cloud (n8n, Supabase, Chatwoot, Evolution API). Aqui voce encontra a documentacao completa, os workflows exportados e os testes realizados.

---

## Como Funciona

Leads chegam via **Facebook Ads** (formulario), sao processados automaticamente e classificados em 3 paths:

```
Facebook Ads (formulario)
        |
        v
  [WF06] Outbound
        |
        ├── Path 1: CNPJ invalido
        │   └── Desqualificado (registra, nao contata)
        │
        ├── Path 2: Volume baixo OU fora do N/NE
        │   └── Envia lista de distribuidores parceiros via WhatsApp
        │
        └── Path 3: Volume >= 4k + regiao N/NE (Qualificado)
            └── Agente "Joao" inicia conversa via WhatsApp
                        |
                        v
                  [WF07] Inbound
                        |
                  Agente IA conversa
                  (confirma dados, pergunta sobre ASX, pede NFs)
                        |
                        v
                  Score + Handoff
                  (atribui vendedor, transfere conversa)
```

O agente **Joao** conduz a qualificacao no Path 3, coletando informacoes em 3 etapas e fazendo handoff para vendedores humanos via round-robin.

---

## Stack

| Servico | Versao | Funcao |
|---------|--------|--------|
| **n8n** | 2.3.2 | Orquestrador de workflows |
| **OpenAI** | GPT-4 | LLM do agente de IA |
| **Supabase** | Postgres | Banco de dados e memoria |
| **Redis** | - | Cache e gestao de filas |
| **Chatwoot** | 4.9.2 | Painel de atendimento omnichannel |
| **Evolution API** | 2.3.7 | Conexao com WhatsApp (Baileys) |
| **Easypanel** | - | Painel de hospedagem (Hostinger) |

---

## Estrutura do Repositorio

```
ASX-Agente/
├── README.md                 # Este arquivo
├── CLAUDE.md                 # Instrucoes para agentes de IA
├── .env.example              # Template de variaveis de ambiente
│
├── docs/
│   ├── logica-do-fluxo.md    # Especificacao completa do sistema
│   ├── distribuidores-asx-brasil.csv  # Base de distribuidores (504 registros)
│   └── arquivo/
│       └── fluxo-antigo.md   # Fluxo anterior (obsoleto)
│
├── workflows/                # 10 workflows n8n exportados (JSON)
│   ├── README.md             # Mapa, dependencias e como importar
│   ├── 06-fb-leads-outbound-webhook.json
│   ├── 07-fb-leads-inbound.json
│   └── ... (sub-workflows e auxiliares)
│
└── testes/                   # Casos de teste documentados
    ├── teste-01 a 03         # Testes por path (1, 2, 3)
    └── teste-04 a 07         # Testes E2E com handoff completo
```

---

## Workflows

O sistema e composto por **10 workflows** no n8n:

| Tipo | Workflow | Funcao |
|------|----------|--------|
| **Principal** | 06-FB-Leads-Outbound | Processa formulario Facebook, classifica e envia 1a mensagem |
| **Principal** | 07-FB-Leads-Inbound | Recebe respostas, roteia para agente IA |
| **Sub-WF** | 02-Tool-Label | Aplica labels no Chatwoot |
| **Sub-WF** | 02A-Company-Enrich | Valida CNPJ via Receita Federal |
| **Sub-WF** | 02B-Score-Lead | Calcula score do lead (0-100) |
| **Sub-WF** | 02C-Agent-Log | Registra eventos do agente |
| **Sub-WF** | 02D-Find-Distributors | Busca distribuidores por estado |
| **Sub-WF** | 03-Finalize-Handoff | Cria lead, atribui vendedor, transfere conversa |
| **Auxiliar** | 04-Chatwoot-Message-Logger | Salva mensagens na base |
| **Auxiliar** | 05-Error-Logger | Captura erros |

Detalhes completos em [`workflows/README.md`](workflows/README.md).

---

## Configuracao

1. Copie `.env.example` para `.env`
2. Preencha com suas credenciais (n8n, Supabase, Chatwoot, Evolution API, OpenAI, CNPJA, OCR)
3. Importe os workflows do `workflows/` no seu n8n
4. Configure as credenciais dentro do n8n (os JSONs estao sanitizados)
5. Crie as tabelas no Supabase conforme documentado em `docs/logica-do-fluxo.md`

---

## Documentacao

| Documento | Descricao |
|-----------|-----------|
| [`docs/logica-do-fluxo.md`](docs/logica-do-fluxo.md) | Especificacao completa: 3 paths, agente, scoring, handoff, tabelas, exemplos |
| [`workflows/README.md`](workflows/README.md) | Mapa de workflows e grafo de dependencias |
| [`docs/arquivo/fluxo-antigo.md`](docs/arquivo/fluxo-antigo.md) | Fluxo anterior (reativo) — referencia historica |

---

## Testes

Todos os paths e o fluxo E2E foram testados e validados:

| Teste | Cenario | Status |
|-------|---------|--------|
| 01 | Path 1 — CNPJ invalido | Validado |
| 02 | Path 2 — Volume baixo, GO | Validado |
| 03 | Path 2 — Volume alto, SP (fora N/NE) | Validado |
| 04 | Path 3 — Qualificado, BA | Validado |
| 05 | E2E — Path 3 completo com handoff | Validado |
| 06 | E2E — Retest apos bug fixes | Validado |
| 07 | E2E — Validacao final (finalize fix) | Validado |

Detalhes de cada teste em `testes/`.
