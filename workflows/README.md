# Workflows do Projeto ASX-Agente

Os workflows do n8n que compoe o sistema do Agente SDR da ASX.

## Como Importar

1. Acesse sua instancia do n8n
2. Va em **Workflows** > **Import from File**
3. Selecione o arquivo `.json` desejado
4. **Configure as credenciais** — os JSONs estao sanitizados (credentials substituidas por `CONFIGURE_ME`)

## Workflows Ativos

### Principais (entry points)

| Arquivo | Nome no n8n | Tipo | Descricao |
|---------|-------------|------|-----------|
| `06-fb-leads-outbound-webhook.json` | 06-FB-Leads-Outbound-Webhook | Webhook | Recebe leads do Facebook Ads, classifica em 3 paths e envia 1a mensagem via WhatsApp |
| `07-fb-leads-inbound.json` | 07-FB-Leads-Inbound | Webhook | Recebe respostas dos leads via Evolution API, roteia para o agente IA correto |

### Sub-Workflows (callable)

Chamados como tools pelo agente IA dentro do WF07:

| Arquivo | Nome no n8n | Funcao |
|---------|-------------|--------|
| `02-tool-label.json` | 02-Tool-Label | Aplica labels no contato do Chatwoot |
| `02a-company-enrich.json` | 02A-Company-Enrich | Valida e enriquece CNPJ via Receita Federal |
| `02b-score-lead.json` | 02B-Score-Lead | Calcula score do lead (0-100) |
| `02c-agent-log.json` | 02C-Agent-Log | Registra eventos do agente |
| `02d-find-distributors.json` | 02D-Find-Distributors | Busca distribuidores por estado no Supabase |
| `03-finalize-handoff.json` | 03-Finalize-Handoff | Cria lead, atribui vendedor, transfere conversa, notifica vendedor |

### Auxiliares

| Arquivo | Nome no n8n | Funcao |
|---------|-------------|--------|
| `04-chatwoot-message-logger.json` | 04-Chatwoot-Message-Logger | Salva mensagens de vendedores (Chatwoot webhook) na tabela messages |
| `05-error-logger.json` | 05-Error-Logger | Captura e registra erros dos workflows na tabela events |
| `08-health-check.json` | 08-Health-Check | Monitoramento operacional a cada 5 min: pinga servicos, verifica pipeline de leads, saude de mensagens, execucoes WF06/WF07, e consolida relatorio com severidade (ok/warning/critical) |

## Grafo de Dependencias

```
Facebook Ads (formulario)
    |
    v
[WF06] Outbound Webhook
    |
    ├── Chama: 02A-Company-Enrich (enriquecer CNPJ)
    ├── Path 1 → FIM (CNPJ invalido)
    ├── Path 2 → Envia lista de distribuidores → FIM
    └── Path 3 → Envia apresentacao → Aguarda resposta
                                          |
                                          v
                                    [WF07] Inbound
                                        |
                                        ├── Agente P2 (Distribuidor)
                                        │   └── Chama: 02D-Find-Distributors
                                        │
                                        └── Agente P3 (Qualificado)
                                            ├── Chama: 02B-Score-Lead
                                            ├── Chama: 03-Finalize-Handoff
                                            │       ├── Pick Agent (round-robin)
                                            │       ├── Persist Lead (Supabase)
                                            │       ├── Transfer Conversation (Chatwoot)
                                            │       └── Notify Vendor (WhatsApp)
                                            ├── Chama: 02-Tool-Label
                                            └── Chama: 02C-Agent-Log

[WF04] Chatwoot Message Logger ← Webhook do Chatwoot (salva mensagens)
[WF05] Error Logger ← Error trigger (captura falhas)
[WF08] Health Check ← Schedule (5 min) → Ping servicos + Lead/Message/WF health → Log status
```

## IDs dos Workflows no n8n

| Workflow | ID |
|----------|----|
| 06-FB-Leads-Outbound-Webhook | `7LvmLJIL7CdbWpbt` |
| 07-FB-Leads-Inbound | `hGsfyVT8TPWau6RH` |
| 02-Tool-Label | `QBZhzIYU7qBuE6p5` |
| 02A-Company-Enrich | `fRc8nB8qUjJUrTHw` |
| 02B-Score-Lead | `gPxoxxAA88LVdZ7Y` |
| 02C-Agent-Log | `N1b1o3ED1FXDHWBW` |
| 02D-Find-Distributors | `DEwqsmZDj8fIMjuq` |
| 03-Finalize-Handoff | `OvvMcnq571vIb9bK` |
| 04-Chatwoot-Message-Logger | `MlscoOb4IqmMpgQr` |
| 05-Error-Logger | `WBqj1UKzZORCANPo` |
| 08-Health-Check | `Oj8SgieQ4HH7Czbk` |
