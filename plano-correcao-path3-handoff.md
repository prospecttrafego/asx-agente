# Plano de Correcao - Path 3, Handoff e Agente Joao

Documento de planejamento para nao perder o contexto da investigacao sobre o `Path 3`, o comportamento do `WF07` e as regras reais de handoff.

Importante:

- este documento registra diagnostico e plano
- nenhuma mudanca foi aplicada a partir deste plano
- o projeto real esta no n8n, este repositorio e apenas espelho documental

## 1. Contexto do Problema

Foi identificado um erro de condução no `Path 3` em producao.

O caso analisado foi um lead qualificado que respondeu algo equivalente a:

- `Sim`
- `Sim`
- `Asx direto`

O agente respondeu encerrando com a logica de:

- "por politica interna..."
- "o ideal e continuar com o fornecedor atual"

Essa resposta foi considerada incorreta.

## 2. O Que Foi Verificado

A investigacao foi feita no n8n real, nos workflows:

- `07-FB-Leads-Inbound` - `hGsfyVT8TPWau6RH`
- `03-Finalize-Handoff (callable)` - `OvvMcnq571vIb9bK`
- `02B-Score-Lead (callable)` - `gPxoxxAA88LVdZ7Y`
- `06-FB-Leads-Outbound-Webhook` - `7LvmLJIL7CdbWpbt`

Tambem foi analisada a execucao real do caso:

- `WF07 #2571`
- `WF07 #2580`
- `WF07 #2583`
- `WF07 #2589`

## 3. Diagnostico Consolidado

### 3.1 Regra estrutural de qualificacao

Hoje, a regra estrutural que classifica o lead como `Path 3` e esta:

- `CNPJ valido`
- `volume >= 4k`
- `UF em Norte/Nordeste`

Isso esta implementado no `WF06` e repetido de forma parecida no `02B-Score-Lead`.

Ou seja:

- se o lead chegou no `Path 3`, ele ja passou no filtro inicial de qualificacao

### 3.2 O erro nao foi falha tecnica de handoff

No caso investigado, o handoff nao falhou por erro no `finalize`.

O que ocorreu foi:

- o agente do `WF07` decidiu encerrar a conversa antes
- nao houve chamada de `score_lead`
- nao houve chamada de `finalize`

Portanto, o erro principal esta na decisao do agente.

### 3.3 Causa raiz principal

O prompt ativo do `Joao P3` no `WF07` contem uma regra errada:

- se o lead disser que ja compra ASX na regiao
- e estiver na faixa `Entre 4.000 e 10.000`
- o agente deve desqualificar por politica
- e nao deve chamar `finalize`

Essa regra esta errada para a operacao desejada.

### 3.4 Erro de interpretacao do caso "ASX direto"

O agente tratou `Asx direto` como se fosse:

- "ja compra de distribuidor da regiao"

Mas isso nao e a mesma coisa.

`ASX direto` pode significar:

- cliente atual
- ex-cliente
- oportunidade de reativacao
- conta com historico comercial

Esse tipo de situacao nao deve ser bloqueado automaticamente.

### 3.5 Erro de postura comercial

O problema nao e so de regra.

O Joao hoje esta operando de forma excessivamente engessada, como um robo de triagem.

Ele nao argumenta.
Ele nao explora nuance.
Ele nao tenta recuperar oportunidade.
Ele nao se comporta como SDR comercial.

## 4. Nova Leitura Correta da Logica

Esta e a leitura ajustada que deve orientar o proximo plano.

### 4.1 O que significa o Path 3

O `Path 3` nao deve significar:

- "handoff automatico imediato em qualquer caso"

Mas tambem nao deve significar:

- "o agente pode requalificar tudo do zero e bloquear por qualquer sinal"

O `Path 3` deve significar:

- lead que ja demonstrou sinal inicial forte
- lead que merece abordagem comercial consultiva
- lead que deve ser conduzido pelo Joao para viabilizar handoff, e nao para ser descartado com rigidez

### 4.2 O papel correto do Joao no Path 3

O Joao deve atuar como SDR conversacional.

Isso significa:

- confirmar contexto
- entender nuances
- explorar potencial comercial
- contornar objecoes quando fizer sentido
- tentar viabilizar a passagem para vendedor
- desqualificar apenas quando o nao-fit ficar realmente claro

### 4.3 Regra correta para cliente atual, ex-cliente ou reativacao

Respostas como:

- `ASX direto`
- `comprava direto`
- `ja fui cliente`
- `faz tempo que nao compro`
- `quero voltar a comprar`

nao devem gerar handoff automatico por si so.

Tambem nao devem gerar desqualificacao automatica.

Essas respostas devem ser tratadas como:

- sinal comercial positivo
- gatilho para aprofundamento consultivo
- contexto importante para o vendedor

O Joao deve investigar:

- como esse lead compra hoje
- quanto compra hoje
- se existe potencial de atingir ou sustentar o minimo comercial
- se existe abertura para negociar condicoes com vendedor

### 4.4 Regra correta para volume abaixo do minimo

Se o lead indicar que hoje compra abaixo do minimo, por exemplo `2 mil`, isso nao deveria levar a descarte seco.

O Joao deve agir como SDR comercial:

- argumentar
- explorar se o lead consegue chegar no minimo
- entender se existe consolidacao de compras
- verificar se faz sentido passar para vendedor para avaliar condicoes

Exemplo de postura correta:

- "Hoje nosso minimo e 4 mil. Voce conseguiria operar nessa faixa?"
- "Se fizer sentido, posso te passar para um vendedor avaliar as condicoes com voce."

Se o lead demonstrar abertura:

- faz handoff

Se o lead confirmar que nao chega nesse patamar e nao ha perspectiva:

- encerra com elegancia

## 5. Plano Revisado - Parte 1

## WF07 e Prompt do Joao P3

### Objetivo

Transformar o Joao de um agente rigido em um SDR conversacional, sem perder o controle operacional.

### Direcao principal

O foco nao deve ser criar mais arvore fixa.
O foco deve ser escrever um prompt muito melhor, com principios comerciais claros.

### Mudancas planejadas no prompt

- deixar explicito que o lead do `Path 3` ja passou na qualificacao inicial do sistema
- deixar explicito que o Joao nao deve requalificar do zero por volume/regiao
- remover completamente a regra atual de:
  `sim + faixa entre 4k e 10k => desqualificar`
- remover a associacao automatica entre `ja compra ASX` e bloqueio de handoff
- instruir o Joao a tratar respostas ambiguas como algo a esclarecer, e nao como decisao final
- instruir o Joao a agir como SDR consultivo, e nao como fiscal de politica
- ensinar no prompt que cliente atual, ex-cliente ou reativacao devem ser explorados com inteligencia comercial
- instruir o Joao a tentar recuperar oportunidade antes de desqualificar por volume
- instruir o Joao a fazer handoff quando houver potencial comercial real, mesmo que o caso precise de avaliacao humana
- manter regras duras apenas no necessario:
  - nao inventar
  - nao prometer preco
  - nao seguir respondendo apos handoff
  - nao encerrar sem antes clarificar quando houver potencial comercial

### Mudancas planejadas na forma de conduzir a conversa

- substituir perguntas fechadas e secas por perguntas com finalidade comercial
- evitar duas perguntas decisivas na mesma mensagem quando isso puder confundir o lead
- permitir respostas naturais, sem obrigar a conversa a seguir uma escada rigida
- ensinar o agente a argumentar quando o entrave for apenas volume
- ensinar o agente a reconhecer oportunidade de reativacao
- ensinar o agente a valorizar sinais de interesse e historico comercial

### Filosofia do agente

O Joao precisa pensar assim:

- "Meu trabalho nao e achar motivo para barrar"
- "Meu trabalho e entender se existe potencial real e, se existir, facilitar o handoff"

## 6. Plano Revisado - Parte 2

## Sub-workflows, Persistencia e Observabilidade

Mesmo com o foco principal no prompt, existem alguns pontos estruturais que precisam ser corrigidos ou endurecidos.

### 6.1 Score

O `02B-Score-Lead` hoje tem risco de interpretar mal o volume textual.

Ponto observado:

- o parser tende a capturar o primeiro numero do texto
- isso pode distorcer score em faixas como `Entre 4.000 e 10.000`

Plano:

- alinhar o score com o mesmo mapeamento de faixa usado no `WF06`
- evitar subavaliacao ou classificacao torta de lead

### 6.2 Tool inputs do score

Hoje o `score_lead_p3` depende demais do que o LLM preencher via `$fromAI()`.

Plano:

- reduzir dependencia do modelo para campos fixos
- pre-preencher do contexto do `Lookup Lead Path` tudo o que ja e conhecido

Objetivo:

- deixar o score mais confiavel
- diminuir chance de erro por tool call mal formada

### 6.3 Finalize / handoff

O `03-Finalize-Handoff` hoje tem inconsistencias de naming e de persistencia.

Pontos observados:

- mistura entre `ja_compra_asx`, `fornecedor_atual`, `ja_compra_asx_regiao`, `fornecedor_asx_regiao`
- parte do contexto comercial pode chegar inconsistente ao vendedor
- o proprio handoff nao persiste tudo de forma suficientemente clara para observabilidade futura

Plano:

- padronizar campos do handoff
- garantir que o contexto comercial relevante chegue ao vendedor
- incluir o vinculo com `fb_lead_id`
- atualizar o `fb_lead` de forma coerente ao concluir handoff

### 6.4 Status do fb_lead

A documentacao fala em estados como:

- `contacted`
- `handoff_done`
- `disqualified_policy`

Mas a implementacao real precisa ser revista para garantir que esses estados sejam atualizados de forma estrutural.

Plano:

- revisar onde o status realmente muda
- garantir consistencia entre o que o agente fala, o que o banco registra e o que o monitoramento enxerga

### 6.5 Observabilidade

O `WF08-Health-Check` precisa detectar melhor situacoes em que:

- um lead do `Path 3` respondeu
- houve conversa do Joao
- mas nao houve `score`
- e nao houve `finalize`

Plano:

- criar checks especificos para esse buraco operacional
- melhorar visibilidade sobre casos de Path 3 que "morreram no agente"

### 6.6 Relacao entre leads e fb_leads

Foi identificado risco de inconsistencia na relacao entre:

- `fb_leads`
- `leads`
- `assignments`
- `events`

Plano:

- revisar persistencia para que o caminho completo do lead fique rastreavel
- melhorar capacidade de auditoria do funil

## 7. O Que Nao Fazer

Este plano parte de uma restricao importante:

- nao transformar tudo em uma arvore cada vez mais dura de tools e regras

Motivo:

- isso deixa o agente ainda mais engessado
- e vai contra o papel real que ele precisa ter

A ideia aqui e:

- deixar deterministico apenas o necessario
- deixar a conversa ser guiada por um prompt forte e bem escrito

Deterministico no que realmente importa:

- classificacao inicial
- score final
- finalize/handoff
- status e persistencia
- observabilidade

Conversacional no que precisa ser comercial:

- explorar contexto
- trabalhar objecoes
- entender reativacao
- testar potencial
- conduzir o lead com naturalidade

## 8. Resumo Executivo

### Problema central

O erro principal do caso analisado esta no `WF07`, no prompt e no modelo mental do `Joao P3`.

### Correcao central

O Joao precisa deixar de agir como robo de triagem e passar a agir como SDR comercial consultivo.

### Correcao estrutural complementar

Depois disso, sera necessario alinhar:

- score
- finalize
- persistencia
- status
- observabilidade

### Regra mais importante deste plano

O objetivo do Joao no `Path 3` nao deve ser:

- achar motivo para barrar

O objetivo dele deve ser:

- entender se existe potencial comercial real
- tentar recuperar a oportunidade quando fizer sentido
- e facilitar o handoff para vendedor quando houver viabilidade

## 9. Proximas Observacoes

Este arquivo deve ser atualizado conforme novas observacoes forem sendo feitas.

Itens que ainda podem ser aprofundados:

- exemplos reais adicionais de conversa no `Path 3`
- comportamento com leads que dizem comprar pouco hoje
- comportamento com clientes antigos
- comportamento com pedidos diretos de condicao comercial
- clareza do contexto que chega ao vendedor apos handoff
- qualidade do monitoramento dos stuck leads
