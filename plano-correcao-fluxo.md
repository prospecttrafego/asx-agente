# Plano de Correcao do Fluxo

Documento de planejamento consolidado para correcao do fluxo comercial da ASX no n8n real.

Este arquivo substitui o plano anterior focado apenas em `Path 3` e passa a cobrir:

- `WF06`
- `WF07`
- `Path 2`
- `Path 3`
- handoff
- score
- distribuidores
- persistencia
- observabilidade

Importante:

- este documento registra diagnostico e plano
- nenhuma mudanca foi aplicada a partir deste plano
- o projeto real esta no n8n, este repositorio e apenas espelho documental
- a fonte real e correta da lista de distribuidores e a tabela do Supabase em producao
- o CSV deste repositorio nao deve ser tratado como fonte de verdade

## 1. Premissas de Negocio

Este plano parte das seguintes premissas operacionais.

### 1.1 Classificacao inicial e fotografia, nao sentenca eterna

O `WF06` classifica o lead a partir do formulario.

Essa classificacao inicial deve definir:

- o ponto de partida do atendimento
- o canal inicial
- o primeiro papel do Joao

Mas nao deve congelar para sempre a interpretacao do lead.

Durante a conversa real, o sistema pode descobrir:

- que o lead preencheu algo impreciso
- que o volume real mudou
- que o lead aceita operar no minimo comercial
- que existe potencial de reativacao
- que existe interesse comercial maior do que o formulario sugeria

### 1.2 O Joao precisa atuar como SDR conversacional

O Joao nao pode ser um roteador burocratico.

Ele precisa:

- entender nuance
- explorar potencial
- argumentar com naturalidade
- tentar recuperar oportunidade quando fizer sentido
- so encerrar quando o nao-fit ficar claro

### 1.3 Deterministico apenas no que precisa ser deterministico

O que precisa ser duro e controlado:

- classificacao inicial
- regras de score
- execucao de handoff
- persistencia
- status
- observabilidade

O que precisa ser comercial e flexivel:

- conversa
- entendimento do contexto
- tratamento de objecao
- exploracao de reativacao
- validacao de potencial

## 2. Diagnostico Consolidado

## 2.1 Problema principal do Path 3

O caso do lead que respondeu `Asx direto` mostrou que o `WF07` esta tomando uma decisao comercial errada.

O que foi confirmado no n8n real:

- o lead estava no `Path 3`
- o agente respondeu encerrando a conversa
- nao houve chamada de `score_lead`
- nao houve chamada de `finalize`

Causa raiz principal:

- o prompt ativo do `Joao P3` manda desqualificar quando o lead diz que ja compra ASX e a faixa esta em `Entre 4.000 e 10.000`

Problema:

- isso contradiz a logica de qualificacao desejada
- e trata `ASX direto` como se fosse um bloqueio automatico

## 2.2 Problema principal do Path 2

O caso do lead de Roraima mostrou que o `Path 2` hoje funciona como beco sem saida.

O que foi confirmado no n8n real:

- o lead entrou no `Path 2` por volume do formulario `Abaixo de 2.000`
- durante a conversa, ele sinalizou abertura para operar no minimo de `4 mil`
- o agente permaneceu preso em respostas de distribuidores
- nao houve caminho de promocao para handoff
- nao houve chamada de `score_lead`
- nao houve chamada de `finalize`

Causa raiz:

- o `Joao P2` foi instruido explicitamente a nao vender
- o `Joao P2` nao pode requalificar
- o `Joao P2` nao tem tools de handoff
- o roteamento por `agent_type` prende o lead no fluxo de distribuidor

## 2.3 Problema no sub-workflow de distribuidores

No caso de Roraima, o `02D-Find-Distributors` foi chamado em producao.

O que ocorreu:

- o node `Query Distributors` retornou zero linhas
- o workflow terminou nesse node
- o `Format Result` nao executou
- o agente ficou sem retorno estruturado

Consequencia:

- o agente passou a falar em "problema para consultar"
- quando o mais correto seria responder algo objetivo sobre nao ter encontrado distribuidor

## 2.4 Divergencia entre agente e dado de negocio

O agente do `Path 2` afirmou coisas como:

- "a fabrica trabalha com precos tabelados para compras diretas"

Isso nao apareceu como regra formal confirmada na documentacao analisada.

Risco:

- o agente esta explicando politica comercial sem base claramente documentada

## 2.5 Inconsistencias estruturais ja identificadas

- `02B-Score-Lead` faz parsing fragil do volume textual
- `03-Finalize-Handoff` mistura naming de campos comerciais
- a relacao entre `fb_leads`, `leads`, `assignments` e `events` precisa de melhor rastreabilidade
- o `WF08` hoje nao cobre varios stuck states relevantes
- o comportamento de leads desconhecidos no `WF07` precisa ser revisto, porque a implementacao real aparenta responder em vez de ignorar silenciosamente

## 3. Leitura Correta da Logica de Negocio

## 3.1 Path 3

O `Path 3` deve significar:

- lead com sinal inicial forte
- lead que merece qualificacao comercial consultiva
- lead que deve ser conduzido para viabilizar handoff

O `Path 3` nao deve significar:

- handoff automatico em qualquer situacao
- requalificacao do zero com regras frias e engessadas

## 3.2 Path 2

O `Path 2` precisa deixar de ser interpretado como "desqualificado para sempre".

O `Path 2` deve significar:

- lead inicialmente mais aderente ao canal distribuidor
- lead que comeca fora da rota direta
- mas que pode revelar, durante a conversa, capacidade ou interesse para operacao direta

## 3.3 Dois subtipos de Path 2

O `Path 2` hoje mistura dois cenarios de negocio diferentes:

### Subtipo A - volume baixo

- CNPJ valido
- volume abaixo de `4 mil`
- qualquer regiao

Esse subtipo pode evoluir durante a conversa se o lead:

- corrigir o volume
- aceitar operar no minimo
- mostrar potencial de concentracao de compras
- pedir avaliacao comercial

### Subtipo B - fora da area de atendimento direto

- CNPJ valido
- volume alto
- fora de Norte/Nordeste

Por enquanto, este plano assume a politica atual:

- esse subtipo continua no canal distribuidor
- a promocao conversacional para handoff fica focada principalmente no subtipo de volume baixo

Se a ASX quiser flexibilizar isso depois, sera uma decisao de negocio separada.

## 3.4 Cliente atual, ex-cliente ou reativacao

Respostas como:

- `ASX direto`
- `comprava direto`
- `ja fui cliente`
- `faz tempo que nao compro`
- `quero voltar a comprar`

nao devem gerar:

- handoff automatico cego
- desqualificacao automatica

Essas respostas devem ser tratadas como:

- sinal comercial positivo
- gatilho para aprofundamento
- contexto importante para o vendedor

## 3.5 Volume abaixo do minimo

Se o lead indicar volume atual abaixo do minimo, o Joao nao deve descartar como robo.

Ele deve:

- explorar se o lead consegue atingir o minimo
- entender se ha consolidacao de compra
- avaliar abertura para condicoes comerciais
- propor conversa com vendedor se houver viabilidade

So deve encerrar quando o proprio lead deixar claro que:

- nao chega no minimo
- nao pretende chegar
- nao faz sentido avaliacao comercial

## 4. Objetivo do Fluxo Corrigido

O fluxo corrigido deve produzir este comportamento:

### Para Path 2

- Joao tenta direcionar para distribuidores quando esse e o canal correto
- se o lead mostrar potencial real para compra direta, Joao pode promover o caso para avaliacao comercial
- se nao houver distribuidor disponivel e houver potencial direto, Joao nao entra em loop; ele tenta viabilizar proximo passo comercial

### Para Path 3

- Joao aprofunda a conversa comercial
- entende o contexto
- trata objecoes e reativacao com naturalidade
- faz handoff quando houver viabilidade
- so encerra quando o nao-fit estiver claro

## 5. Plano Completo de Ajustes

## 5.1 Ajustes no WF06 - Outbound e classificacao inicial

### Objetivo

Preservar a classificacao inicial, mas melhorar o contexto que sera usado depois pelo `WF07`.

### Ajustes necessarios

- manter a classificacao inicial atual como snapshot do formulario
- explicitar no registro do `fb_lead` o motivo do path com mais granularidade

Sugestao de granularidade:

- `path_reason = low_volume_distributor`
- `path_reason = outside_direct_region`
- `path_reason = qualified_direct`

- garantir que o `WF07` receba esse contexto e saiba distinguir subtipo de `Path 2`
- registrar no `fb_lead` se o lead esta em regiao de atendimento direto
- registrar o valor numerico de volume de forma consistente para todo o fluxo

### Ajuste de mensagem inicial do Path 2

- a mensagem inicial deve continuar explicando o motivo real da classificacao
- mas nao deve fechar semanticamente a porta para reavaliacao comercial posterior

### Distribuidores

- continuar usando apenas a base real do Supabase
- nao depender do CSV deste repositorio para nenhuma decisao operacional

## 5.2 Ajustes no WF07 - Roteamento principal

### Objetivo

Parar de prender o lead para sempre no agente inicial quando a conversa revelar novo potencial comercial.

### Ajustes necessarios

- revisar o desenho atual de roteamento por `agent_type`
- permitir promocao de `Path 2` para fluxo de venda direta quando o caso justificar
- diferenciar no prompt e no contexto:
  - `Path 2 por volume baixo`
  - `Path 2 por fora da regiao direta`

### Comportamento esperado

- `Path 2 por volume baixo` pode ser recuperado comercialmente
- `Path 2 por fora da regiao direta` continua restrito ao canal distribuidor, salvo decisao futura da ASX

### Ajuste recomendado de arquitetura

Ha duas opcoes validas:

#### Opcao recomendada

Manter dois agentes, mas permitir que o agente do `Path 2` promova o lead para handoff quando a conversa justificar.

#### Opcao alternativa

Unificar a logica comercial em um unico Joao mais adaptativo.

Por enquanto, a opcao recomendada e:

- manter dois agentes
- corrigir profundamente os prompts
- dar ao `Path 2` capacidade real de promocao

## 5.3 Ajustes no Joao P2 - Distributor Agent

### Problema atual

O prompt ativo diz que ele:

- nao esta vendendo
- nao faz qualificacao
- sempre deve manter o lead nos distribuidores

Isso engessa o comportamento e impede recuperacao comercial.

### Novo papel desejado

O Joao do `Path 2` deve ser:

- direcionador por padrao
- SDR consultivo quando a conversa revelar potencial para venda direta

### O que o prompt novo precisa ensinar

- o `Path 2` nao e descarte permanente
- se o lead demonstrar potencial de operar no minimo, o Joao deve explorar isso
- se o lead disser que houve erro no formulario, o Joao deve considerar a nova informacao
- se o lead quiser avaliar compra direta e houver viabilidade, o Joao pode encaminhar
- se nao houver distribuidor no estado, o Joao nao deve ficar repetindo a mesma mensagem
- se nao houver distribuidor e o lead tiver potencial direto, o Joao deve migrar a conversa para avaliacao comercial
- se o lead nao tiver potencial e nao houver distribuidor, o Joao deve encerrar com coerencia, nao com loop

### Regras conversacionais desejadas para o Path 2

- o Joao pode argumentar quando o obstaculo for apenas volume
- o Joao pode perguntar se o lead consegue operar em `4 mil`
- o Joao pode oferecer avaliacao por vendedor quando houver abertura comercial
- o Joao nao pode inventar politica comercial
- o Joao nao pode alegar "problema de consulta" quando o dado real for simplesmente zero distribuidor

### O que remover do prompt do P2

- a ideia de que ele "nao esta vendendo" em absoluto
- a proibicao total de qualificacao
- a logica de repeticao eterna do canal distribuidor

## 5.4 Ajustes estruturais para o Path 2 subir para handoff

### Problema atual

O agente do `Path 2` nao tem como executar handoff mesmo que entenda que deveria.

### Ajustes necessarios

- dar ao `Path 2` uma capacidade real de promocao

Opcoes tecnicas possiveis:

#### Opcao recomendada

Adicionar ao `Joao P2` acesso aos tools necessarios para promocao:

- `score_lead`
- `finalize`
- `set_label`

com os campos fixos pre-preenchidos do contexto

#### Complemento importante

Persistir que o lead:

- nasceu no `Path 2`
- foi recuperado comercialmente
- foi promovido para handoff a partir da conversa

### Labels sugeridas

- `path_distributor`
- `recovered_from_path2`
- `direct_interest_confirmed`
- `no_distributor_in_state`

## 5.5 Ajustes no Joao P3 - Qualified Agent

### Problema atual

O `Joao P3` desqualifica por regra dura quando o lead diz que ja compra ASX em determinados cenarios.

### Novo papel desejado

O Joao do `Path 3` deve ser um SDR consultivo.

### O que o prompt novo precisa ensinar

- o lead do `Path 3` ja passou no filtro inicial
- o Joao nao pode requalificar do zero por volume/regiao
- cliente atual, ex-cliente e reativacao sao contextos comerciais, nao bloqueios automáticos
- o Joao deve explorar:
  - como compra hoje
  - quanto compra hoje
  - se consegue operar no minimo
  - se faz sentido avaliacao comercial
- o Joao deve tentar recuperar oportunidade antes de desqualificar por volume
- o Joao deve fazer handoff quando houver viabilidade, nao so quando o caso for perfeito

### O que remover do prompt do P3

- a regra:
  `sim + entre 4.000 e 10.000 => desqualificar`
- a associacao automatica entre `ja compra ASX` e bloqueio
- a postura de fiscal de politica

## 5.6 Ajustes nas tools do WF07

### Objetivo

Deixar o agente mais inteligente sem depender demais de tool inputs improvisados.

### Ajustes necessarios

- pre-preencher `score_lead` com:
  - `cnpj`
  - `perfil`
  - `uf_atuacao`
  - `volume`
- reduzir o uso de `$fromAI()` para campos fixos ja conhecidos
- manter o agente preenchendo apenas o que e realmente conversacional

### Para o finalize

Padronizar os campos comerciais que vao do agente para o workflow.

Campos sugeridos:

- `customer_relation`
- `fornecedor_contexto`
- `nfs_enviadas`
- `empresa_recente`
- `motivo_handoff`
- `origem_recuperacao`

## 5.7 Ajustes no 02D-Find-Distributors

### Problema atual

Quando a query retorna zero linhas:

- o workflow termina sem payload estruturado
- o agente fica sem resposta confiavel

### Ajustes necessarios

- garantir que o workflow sempre retorne um objeto estruturado

Mesmo com zero resultados, precisa voltar algo como:

- `found = false`
- `count = 0`
- `message = nenhum distribuidor encontrado`

### Efeito esperado

- o agente para de alucinar "problema de consulta"
- a conversa fica coerente
- o fallback passa a ser deterministicamente controlado

### Fonte de verdade dos distribuidores

- usar apenas a base real do Supabase
- considerar o CSV do repositorio como obsoleto

## 5.8 Ajustes no 02B-Score-Lead

### Problema atual

O parser textual do volume e fragil.

### Ajustes necessarios

- usar o mesmo mapeamento de faixa do `WF06`

Exemplo:

- `Abaixo de 2.000` -> `1500`
- `Entre 2.000 e 4.000` -> `3000`
- `Entre 4.000 e 10.000` -> `7000`
- `Acima de 10.000` -> `12000`

### Efeito esperado

- score consistente
- menos distorcao na prioridade

## 5.9 Ajustes no 03-Finalize-Handoff

### Problemas atuais

- naming inconsistente
- contexto comercial parcial
- rastreabilidade incompleta

### Ajustes necessarios

- padronizar naming dos campos de contexto comercial
- incluir `fb_lead_id` no processo de persistencia
- atualizar o `fb_lead` ao concluir handoff
- marcar claramente:
  - `handoff_done`
  - data do handoff
  - origem do handoff
  - se veio de recuperacao do `Path 2`

### Notificacao ao vendedor

A mensagem ao vendedor precisa refletir melhor o contexto real:

- cliente atual
- ex-cliente
- reativacao
- recuperado do `Path 2`
- sem distribuidor no estado
- aceitou operar no minimo
- empresa nova
- NFs enviadas

## 5.10 Ajustes em status e persistencia

### Objetivo

Fazer o banco refletir de forma fiel o funil real.

### Ajustes necessarios

- revisar o ciclo de status do `fb_lead`
- persistir claramente quando houver:
  - conversa em andamento
  - promocao de `Path 2`
  - handoff realizado
  - desqualificacao final

### Status adicionais uteis

- `recovered_for_direct`
- `no_distributor_found`
- `handoff_done`
- `closed_no_fit`

## 5.11 Ajustes em labels e logs

### Objetivo

Melhorar leitura operacional e auditoria.

### Labels sugeridas

- `path_distributor`
- `path_qualified`
- `recovered_from_path2`
- `cliente_direto_asx`
- `reativacao`
- `sem_distribuidor_estado`
- `handoff_done`
- `closed_no_fit`

### Eventos sugeridos

- `p2_direct_interest_detected`
- `p2_recovered_for_handoff`
- `p2_no_distributor_found`
- `p3_existing_customer_detected`
- `p3_reativacao_detected`
- `p3_handoff_started`
- `p3_handoff_completed`
- `closed_no_fit`

## 5.12 Ajustes no WF08 - Health Check e observabilidade

### Objetivo

Detectar buracos operacionais que hoje passam invisiveis.

### Novos checks sugeridos

- lead do `Path 3` respondeu e nao houve `score`
- lead do `Path 3` respondeu e nao houve `finalize`
- lead do `Path 2` demonstrou interesse em compra direta e nao houve promocao
- lead do `Path 2` ficou em loop de distribuidores sem resolucao
- `find_distributors` retornou zero resultado sem fallback estruturado
- lead promovido do `Path 2` sem handoff concluido
- handoff executado sem atualizacao consistente de `fb_lead`

### Comportamento com leads desconhecidos

Precisa ser revisto no `WF07`, porque a implementacao real aparenta responder para `unknown`, enquanto a regra documental previa ignorar silenciosamente.

## 6. Plano de Implementacao por Prioridade

## Fase 1 - Corrigir cerebro comercial

- reescrever prompt do `Joao P3`
- reescrever prompt do `Joao P2`
- corrigir principios comerciais dos dois agentes

## Fase 2 - Abrir rota real de promocao do Path 2

- dar capacidade de handoff ao `Path 2`
- registrar promocao para venda direta
- impedir que `Path 2` seja beco sem saida

## Fase 3 - Corrigir distribuidores e fallback

- corrigir `02D-Find-Distributors` para sempre retornar payload
- validar tabela real de distribuidores no Supabase
- retirar qualquer dependencia conceitual do CSV do repositorio

## Fase 4 - Corrigir score, finalize e persistencia

- corrigir parsing do volume
- padronizar naming
- persistir melhor o funil
- melhorar contexto enviado ao vendedor

## Fase 5 - Corrigir observabilidade

- atualizar `WF08`
- adicionar checks de stuck leads
- melhorar logs e labels

## 7. Casos que Precisam ser Validados Apos os Ajustes

### Path 3

- lead qualificado que diz `ASX direto`
- ex-cliente que quer voltar a comprar
- lead com volume atual abaixo do minimo, mas aberto a operar em `4 mil`
- lead com volume baixo e sem abertura real

### Path 2

- lead de baixo volume que aceita comprar `4 mil`
- lead de baixo volume que nao aceita o minimo
- lead com erro no formulario e volume real maior
- lead sem distribuidor no estado e com potencial direto
- lead sem distribuidor no estado e sem potencial direto
- lead fora da regiao direta, para confirmar que continua no canal distribuidor

### Distribuidores

- estado com distribuidores ativos
- estado sem distribuidores ativos
- busca por cidade
- fallback coerente com zero resultado

### Handoff

- handoff vindo do `Path 3`
- handoff recuperado do `Path 2`
- notificacao ao vendedor com contexto correto
- persistencia completa em banco

## 8. O Que Nao Fazer

- nao transformar o agente em arvore ainda mais rigida
- nao resolver tudo com dezenas de regras duras no prompt
- nao depender do CSV do repositorio para decisao de distribuidores
- nao deixar o `Path 2` sem caminho de promocao
- nao continuar permitindo que o agente explique politica comercial que nao foi formalmente validada

## 9. Resumo Executivo

O fluxo hoje tem dois problemas centrais:

- no `Path 3`, o Joao barra handoff por logica comercial errada
- no `Path 2`, o Joao nao tem permissao nem capacidade de promover um lead para venda direta

O problema do projeto, portanto, nao e apenas prompt ruim.

E uma combinacao de:

- prompt ruim
- modelo mental engessado
- arquitetura de roteamento travada
- toolset incompleto para o `Path 2`
- fallback ruim de distribuidores
- persistencia e observabilidade incompletas

O objetivo da correcao deve ser este:

- fazer o Joao agir como SDR conversacional
- permitir recuperacao comercial quando houver potencial
- manter deterministico apenas o que precisa ser controlado
- e garantir que o sistema consiga rastrear, medir e auditar o que aconteceu com cada lead

## 10. Proximas Observacoes

Este arquivo deve continuar sendo alimentado conforme novos casos forem aparecendo.

Pontos que ainda podem ser aprofundados:

- exemplos reais adicionais de `Path 2`
- exemplos reais adicionais de `Path 3`
- regras finais de promocao do `Path 2`
- revisao do comportamento de `unknown`
- definicao fina do contexto que deve chegar ao vendedor
