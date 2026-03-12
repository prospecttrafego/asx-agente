# Teste 10 - Hardening do Batching Redis no WF07

Data: 2026-03-11
Ambiente: n8n real `https://flow.agenciaprospect.space`
Workflow: `07-FB-Leads-Inbound`
ID: `hGsfyVT8TPWau6RH`

## Objetivo

Endurecer o batching de mensagens do `WF07` sem alterar a logica funcional desejada:

- continuar agrupando mensagens enviadas em janela de `10s`;
- continuar entregando o lote inteiro para o agente `Joao`;
- continuar limpando o Redis apos o processamento;
- trocar o criterio de “ultima execucao valida” de texto da mensagem para `msgId`.

## Problema da implementacao anterior

Antes da mudanca:

- o `Redis Push` gravava apenas o texto da mensagem;
- o `IF Last Message` comparava `ultima mensagem da lista == mensagem atual`;
- o `Merge Messages` juntava os textos, mas `has_document` e `has_image` vinham apenas da execucao vencedora.

Impacto potencial:

- mensagens duplicadas com o mesmo texto podiam gerar ambiguidade;
- reenvio/duplicidade de webhook podia escapar do criterio textual;
- flags de documento/imagem podiam refletir apenas a ultima execucao, e nao o lote inteiro.

## Ajustes aplicados no ambiente real

### `Prepare for Redis`

Novos campos adicionados:

- `msgId`
- `messageType`
- `redis_payload`

O `redis_payload` agora grava JSON serializado contendo:

- `msgId`
- `message`
- `chatwootConversationId`
- `chatwootInboxId`
- `has_document`
- `has_image`
- `messageType`

### `Redis Push`

Antes:

- gravava somente `message`

Agora:

- grava `redis_payload`

### Novo node `Parse Redis Batch`

Adicionado entre `Redis Get` e `IF Last Message`.

Responsabilidades:

- fazer parse do array lido do Redis;
- manter compatibilidade com entradas legadas em texto puro;
- consolidar o lote inteiro;
- montar:
  - `last_match_key`
  - `current_match_key`
  - `txt`
  - `chatwootConversationId`
  - `chatwootInboxId`
  - `has_document`
  - `has_image`

### `IF Last Message`

Antes:

- comparava texto da ultima mensagem com texto atual

Agora:

- compara `last_match_key` com `current_match_key`
- prioridade de match:
  - `msgId`
  - fallback para texto, se houver item legado sem `msgId`

### `Merge Messages`

Agora recebe o lote ja consolidado do `Parse Redis Batch`.

Resultado:

- `txt` passa a representar o lote inteiro;
- `has_document` e `has_image` passam a refletir o lote inteiro;
- `chatwootConversationId` e `chatwootInboxId` passam a usar o ultimo item do lote que tiver contexto valido.

## Validacao realizada

### 1. Validacao estrutural no workflow real

Confirmado via n8n API:

- `Prepare for Redis` contem `msgId` e `redis_payload`
- `Redis Push` grava `redis_payload`
- `Redis Get -> Parse Redis Batch -> IF Last Message`
- `Merge Messages` consome os campos consolidados

### 2. Simulacao controlada da logica de lote

Entrada simulada:

- `m1 = "Oi"`
- `m2 = "tudo bem?"`

Saida consolidada esperada e confirmada:

```json
{
  "last_match_key": "m2",
  "current_match_key": "m2",
  "txt": "Oi\ntudo bem?",
  "chatwootConversationId": 11,
  "chatwootInboxId": 1,
  "has_document": false,
  "has_image": false
}
```

Interpretacao:

- apenas a execucao referente ao `msgId` mais recente segue;
- o agente recebe o texto consolidado `Oi\ntudo bem?`;
- o lote permanece dentro da intencao funcional original.

## Observacao

Nao foi disparado teste E2E artificial no webhook produtivo para evitar envio real via Evolution API durante a validacao.

## Parecer

O batching do `WF07` permanece com a mesma intencao funcional, mas agora ficou mais robusto contra:

- mensagens repetidas com o mesmo texto;
- duplicidade de webhook;
- perda de flags de documento/imagem no lote.
