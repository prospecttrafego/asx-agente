# Teste 11 - Chatwoot contexto do lead + espelhamento de mensagens + ajuste Path 2

**Data:** 2026-03-11
**Ambiente:** producao real
**Workflows:** `06-FB-Leads-Outbound-Webhook` (`7LvmLJIL7CdbWpbt`), `07-FB-Leads-Inbound` (`hGsfyVT8TPWau6RH`)

## Objetivo

Resolver tres lacunas operacionais do fluxo original:

1. Garantir que o Chatwoot receba contexto util do lead, inclusive quando o contato ja existe.
2. Fazer as mensagens aparecerem na conversa do Chatwoot, sem depender da integracao nativa da Evolution.
3. Ajustar a mensagem inicial do `Path 2` para refletir o motivo real da classificacao.

## Ajustes aplicados no n8n real

### WF06

- Adicionado `Prepare Chatwoot Contact`
- Adicionado `Update Chatwoot Contact`
- Adicionado `Create Conversation Note`
- Adicionado `Sync P2 Message to Chatwoot`
- Adicionado `Sync P3 Message to Chatwoot`
- Ajustado `Compose Message P2`

### Comportamento novo no WF06

- Mesmo quando o contato ja existe no Chatwoot, o workflow agora atualiza:
  - `custom_attributes.fb_form_perfil`
  - `custom_attributes.fb_form_volume`
  - `custom_attributes.fb_form_estado`
  - `custom_attributes.fb_form_cnpj`
  - `custom_attributes.lead_path`
  - `additional_attributes.source`
  - `additional_attributes.fb_lead_id`
  - `additional_attributes.lead_path_reason`
  - `additional_attributes.cnpj_city`
  - `additional_attributes.cnpj_state`

- Assim que a conversa e criada, o workflow agora grava uma **nota privada** com:
  - nome
  - email
  - telefone
  - empresa
  - perfil
  - volume
  - estado do formulario
  - CNPJ
  - path
  - motivo do path
  - `fb_lead_id`

- Depois do envio inicial no WhatsApp:
  - o `Path 2` grava a mesma mensagem como `outgoing` no Chatwoot
  - o `Path 3` grava a mesma mensagem como `outgoing` no Chatwoot

### Ajuste de negocio no `Path 2`

O `Compose Message P2` deixou de usar um texto unico para todos os cenarios.

Agora ele diferencia:

- `Volume < R$4000 - distribuidor`
- `Volume >= 4k mas fora N/NE - distribuidor`
- com distribuidores encontrados
- sem distribuidores encontrados

Com isso:

- lead de Norte/Nordeste com volume baixo nao recebe mais uma mensagem que sugere desqualificacao por regiao
- lead fora de N/NE recebe a explicacao correta sobre atendimento direto
- quando nao ha distribuidor ativo na UF, a mensagem fala da ausencia de base ativa naquela localidade, e nao de um bloqueio generico

## WF07

### Nodes adicionados

- `Has Inbound Chatwoot Conversation?`
- `Sync Inbound Message to Chatwoot`
- `Has Outbound Chatwoot Conversation?`
- `Sync Outbound Message to Chatwoot`

### Comportamento novo no WF07

- Depois do `Lookup Lead Path`, se houver `fb_conv_id` ou `chatwootConversationId`, o texto consolidado do lead agora e gravado como `incoming` no Chatwoot.
- Depois de cada envio do agente no WhatsApp, a mesma mensagem agora e gravada como `outgoing` no Chatwoot.

Isso cobre o historico principal da conversa:

- primeira mensagem enviada no `WF06`
- mensagem do lead no `WF07`
- resposta do agente no `WF07`

## Validacao tecnica feita

Nao foi executado um E2E com lead real para evitar disparo desnecessario de mensagens reais via WhatsApp.

Foi feita validacao direta no Chatwoot API com um contato tecnico temporario:

- contato teste criado com sucesso: `id=16`
- conversa teste criada com sucesso: `id=41`
- nota privada criada com sucesso: `id=338`
- mensagem `incoming` criada com sucesso: `id=339`
- mensagem `outgoing` criada com sucesso: `id=340`
- leitura posterior da conversa retornou `payload_count=3`

Tambem foi validado por API que o contato passou a refletir:

- `custom_attributes.lead_path = "Path 2"`
- `additional_attributes.lead_path_reason = "Teste tecnico"`

## Resultado

Os dois workflows foram salvos no n8n real com sucesso:

- `WF06` atualizado em `2026-03-11T15:52:33.731Z`
- `WF07` atualizado em `2026-03-11T15:52:14.948Z`

## Risco residual

O comportamento de escrita no Chatwoot foi validado por API e os nodes foram inseridos nas cadeias corretas dos workflows.

O que ainda nao foi feito nesta rodada:

- um disparo E2E real de `WF06` com lead novo
- uma resposta E2E real do lead passando pelo `WF07`

Ou seja: a integracao do Chatwoot foi validada tecnicamente, e a orquestracao foi salva no n8n real, mas ainda falta a validacao operacional com um lead real controlado para fechar o ciclo completo.
