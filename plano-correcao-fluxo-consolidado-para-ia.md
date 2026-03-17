# Plano Consolidado de Correcao do Fluxo para Outra IA

Este documento consolida:

- o conteudo do `plano-correcao-fluxo.md`
- o contexto adicional que nao estava explicito no plano original
- a leitura correta dos casos reais discutidos
- as regras de negocio que nao podem ser reinterpretadas

Ele existe para que outra IA consiga entrar no projeto sem historico de conversa
e ainda assim entender:

- quais erros foram encontrados
- por que esses erros sao erros de negocio, e nao apenas de implementacao
- o que os prints e casos reais provaram
- quais ajustes precisam ser feitos
- como validar se o comportamento foi corrigido

## 1. Leitura obrigatoria antes de agir

Os workflows mostram a implementacao atual.

Mas eles nao carregam sozinhos:

- a intencao comercial correta
- a leitura correta dos casos reais
- o motivo pelo qual determinadas respostas do agente foram consideradas erradas

O problema principal deste projeto nao e apenas tecnico.

O problema principal e de interpretacao de negocio dentro dos prompts, tools,
roteamento e persistencia.

Por isso, este documento deve ser lido como contrato de correcao, nao apenas
como brainstorming.

## 2. Premissas de negocio que precisam ficar fechadas

### 2.1 Classificacao inicial e fotografia, nao sentenca eterna

O `WF06` classifica o lead com base no formulario.

Essa classificacao inicial deve definir:

- ponto de partida do atendimento
- canal inicial
- primeiro papel do Joao

Mas ela nao deve congelar para sempre a interpretacao do lead.

Durante a conversa, o sistema pode descobrir:

- que o formulario veio impreciso
- que o volume real e diferente
- que o lead aceita operar no minimo comercial
- que existe potencial de reativacao
- que existe interesse comercial maior do que o formulario sugeria

### 2.2 O Joao precisa agir como SDR conversacional

O Joao nao deve ser um roteador burocratico.

Ele deve:

- entender nuance
- explorar potencial
- argumentar com naturalidade
- tentar recuperar oportunidade quando fizer sentido
- so encerrar quando o nao-fit ficar realmente claro

### 2.3 Deterministico apenas no que precisa ser deterministico

O que deve continuar duro e controlado:

- classificacao inicial
- score
- handoff
- persistencia
- status
- observabilidade

O que deve continuar flexivel e comercial:

- conversa
- tratamento de objecao
- exploracao de potencial
- reativacao
- leitura de contexto

## 3. Regras de negocio canonicas

Estas regras precisam estar escritas de forma literal para que nenhuma outra IA
reinterprete o combinado.

### 3.1 `Path 3` nao pode desqualificar por leitura rasa de `ASX direto`

Se um lead do `Path 3` diz algo como:

- `ASX direto`
- `ja compro de voces`
- `comprava direto`
- `quero voltar a comprar`

isso nao e bloqueio automatico.

Isso deve ser tratado como:

- contexto comercial relevante
- sinal de relacao previa
- gatilho para aprofundamento

Isso nao deve ser tratado como:

- desqualificacao automatica
- motivo para encerrar conversa
- prova de que o vendedor nao precisa entrar

### 3.2 `Path 2` de volume baixo pode ser recuperado

O `Path 2` de volume baixo nao e descarte definitivo.

Se o lead:

- corrige o dado do formulario
- aceita operar no minimo comercial
- demonstra potencial real de concentracao de compra
- pede avaliacao comercial

entao ele pode subir para fluxo de venda direta.

### 3.3 `Path 2` por fora da regiao direta continua restrito, por enquanto

Neste pacote de correcao, a promocao conversacional para venda direta fica
focada no subtipo:

- `Path 2` por volume baixo

O subtipo:

- `Path 2` por fora da regiao direta

continua no canal distribuidor, salvo decisao futura de negocio.

### 3.4 Falta de distribuidor nao pode virar erro ficticio

Se nao houver distribuidor encontrado:

- o agente nao pode falar em "erro na consulta"
- o sistema nao pode fingir falha tecnica inexistente
- o retorno precisa ser objetivo e estruturado

Se houver potencial direto e a regra permitir, o proximo passo comercial pode
ser avaliado. Se nao houver potencial, o encerramento deve ser coerente.

### 3.5 O agente nao pode inventar politica comercial

O agente pode:

- argumentar
- explorar viabilidade
- investigar contexto

O agente nao pode:

- inventar regra de preco
- inventar regra de compra direta
- afirmar politica comercial especifica sem base validada

### 3.6 Volume abaixo do minimo nao deve gerar descarte robotico

Quando o obstaculo for apenas volume, o Joao deve explorar:

- se o lead consegue operar no minimo
- se existe consolidacao de compras
- se existe abertura para avaliacao comercial

So deve encerrar quando o proprio caso mostrar que nao faz sentido avancar.

## 4. O que os casos reais provaram

Esta secao transforma a leitura dos prints e casos discutidos em texto
estruturado. Isso evita que outra IA tenha que adivinhar o que foi extraido da
conversa original.

### Caso 1 - `Path 3` com resposta `ASX direto`

#### O que foi observado

- o lead estava no `Path 3`
- o lead respondeu `ASX direto`
- o agente encerrou em vez de aprofundar
- nao houve chamada de `score_lead`
- nao houve chamada de `finalize`

#### Leitura correta do caso

Esse caso nao provou falta de fit.

Esse caso provou que o agente estava lendo `ASX direto` como bloqueio automatico
quando deveria ler como contexto comercial positivo ou, no minimo, contexto que
merece aprofundamento.

#### Erro confirmado

- regra de prompt errada no `Joao P3`
- interpretacao de negocio errada no `Path 3`

#### Comportamento esperado

O agente deveria:

- aprofundar relacao atual ou passada com a ASX
- entender como compra hoje
- entender volume atual e viabilidade
- conduzir para handoff se houver oportunidade

### Caso 2 - `Path 2` de volume baixo com abertura para `4 mil`

#### O que foi observado

- o lead caiu no `Path 2` por volume inicial `Abaixo de 2.000`
- durante a conversa, o lead sinalizou abertura para operar em `4 mil`
- o agente permaneceu preso em distribuidores
- nao houve promocao para fluxo de venda direta
- nao houve chamada de `score_lead`
- nao houve chamada de `finalize`

#### Leitura correta do caso

O problema nao foi classificacao inicial incorreta.

O problema foi o sistema tratar a classificacao inicial como destino final,
mesmo depois da conversa revelar potencial comercial novo.

#### Erro confirmado

- `Joao P2` proibido de requalificar
- `Joao P2` sem tools de promocao
- roteamento travado por `agent_type`

#### Comportamento esperado

Quando o `Path 2` for por volume baixo e o lead aceitar operar no minimo
comercial, o agente deve poder levar o caso para avaliacao e handoff.

### Caso 3 - busca de distribuidores com zero resultado

#### O que foi observado

- o `02D-Find-Distributors` foi chamado
- o node `Query Distributors` retornou zero linhas
- o fluxo terminou sem payload estruturado
- o agente ficou sem resposta confiavel

#### Leitura correta do caso

O problema nao foi "falta de resposta do agente". O problema foi o sub-workflow
nao devolver retorno deterministico em cenario de zero resultado.

#### Erro confirmado

- fallback estrutural ausente no `02D-Find-Distributors`

#### Comportamento esperado

Mesmo com zero resultados, o sub-workflow precisa devolver algo como:

- `found = false`
- `count = 0`
- `message = nenhum distribuidor encontrado`

## 5. Diagnostico consolidado

### 5.1 Problema principal do `Path 3`

O `Joao P3` esta tomando decisao comercial errada ao transformar relacao previa
com a ASX em motivo de encerramento.

Causa raiz principal:

- prompt ativo com logica comercial ruim

### 5.2 Problema principal do `Path 2`

O `Path 2` hoje funciona como beco sem saida para casos que poderiam ser
recuperados comercialmente.

Causa raiz principal:

- prompt restritivo
- ausencia de tools de promocao
- arquitetura de roteamento travada

### 5.3 Problema no sub-workflow de distribuidores

Quando nao ha distribuidor, o fluxo nao devolve resposta estruturada.

Consequencia:

- o agente improvisa
- a resposta perde confiabilidade

### 5.4 Divergencia entre agente e dado de negocio

O agente esta falando de politica comercial sem base formal claramente validada.

### 5.5 Inconsistencias estruturais complementares

- `02B-Score-Lead` faz parsing fragil do volume textual
- `03-Finalize-Handoff` mistura naming de campos comerciais
- rastreabilidade entre `fb_leads`, `leads`, `assignments` e `events` precisa melhorar
- observabilidade ainda nao cobre bem os stuck states relevantes

## 6. Objetivo do fluxo corrigido

### 6.1 Para `Path 2`

- Joao direciona para distribuidores quando esse for o canal correto
- Joao pode recuperar comercialmente o caso quando houver abertura real
- ausencia de distribuidor nao pode gerar loop ou resposta falsa de erro

### 6.2 Para `Path 3`

- Joao aprofunda conversa comercial
- Joao entende contexto e objecoes
- Joao trata cliente atual, ex-cliente e reativacao como contexto comercial
- Joao faz handoff quando houver viabilidade
- Joao so encerra quando o nao-fit estiver claro

## 7. Plano de ajustes por workflow

### 7.1 `WF06` - classificacao inicial e contexto

#### Objetivo

Preservar a classificacao inicial, mas registrar melhor o contexto que sera
consumido depois pelo `WF07`.

#### Ajustes necessarios

- manter a classificacao inicial como snapshot do formulario
- explicitar o motivo do path com granularidade
- registrar valor numerico de volume de forma consistente
- registrar se o lead esta ou nao em regiao de atendimento direto

#### Granularidade sugerida

- `path_reason = low_volume_distributor`
- `path_reason = outside_direct_region`
- `path_reason = qualified_direct`

#### Efeito esperado

O `WF07` deixa de receber apenas "Path 2" ou "Path 3" e passa a receber
contexto suficiente para distinguir o subtipo do caso.

### 7.2 `WF07` - roteamento principal

#### Objetivo

Parar de prender o lead para sempre no agente inicial quando a conversa revelar
potencial comercial novo.

#### Ajustes necessarios

- revisar o roteamento atual por `agent_type`
- permitir promocao do `Path 2` de volume baixo para venda direta
- diferenciar com clareza:
  - `Path 2 por volume baixo`
  - `Path 2 por fora da regiao direta`

#### Efeito esperado

- `Path 2` de volume baixo pode ser recuperado
- `Path 2` fora da regiao direta continua em distribuidores

### 7.3 `Joao P2` - Distributor Agent

#### Problema atual

O prompt atual faz o agente agir como direcionador rigido.

#### Novo papel desejado

- direcionador por padrao
- SDR consultivo quando a conversa revelar potencial para venda direta

#### O que o prompt precisa ensinar

- `Path 2` nao e descarte permanente
- se o lead demonstrar potencial de operar no minimo, o Joao deve explorar isso
- se o lead disser que o formulario veio errado, a nova informacao importa
- se o lead quiser avaliar compra direta e houver viabilidade, o Joao pode encaminhar
- se nao houver distribuidor no estado, o Joao nao pode repetir a mesma resposta indefinidamente
- se nao houver distribuidor e houver potencial direto, o Joao pode migrar para avaliacao comercial

#### O que remover do prompt

- a ideia de que ele "nao vende" em absoluto
- a proibicao total de qualificacao
- a repeticao eterna do canal distribuidor

### 7.4 `Path 2` subindo para handoff

#### Problema atual

O agente do `Path 2` nao consegue executar handoff mesmo quando entende que deveria.

#### Ajustes necessarios

Adicionar ao `Joao P2` acesso real aos tools de promocao:

- `score_lead`
- `finalize`
- `set_label`

com campos fixos pre-preenchidos do contexto.

#### Persistencia necessaria

Precisa ficar rastreado que o lead:

- nasceu no `Path 2`
- foi recuperado comercialmente
- foi promovido para handoff a partir da conversa

### 7.5 `Joao P3` - Qualified Agent

#### Problema atual

O `Joao P3` desqualifica por regra dura em situacoes que deveriam gerar
aprofundamento comercial.

#### Novo papel desejado

O `Joao P3` deve agir como SDR consultivo.

#### O que o prompt precisa ensinar

- o lead do `Path 3` ja passou no filtro inicial
- o Joao nao deve requalificar do zero por volume ou regiao
- cliente atual, ex-cliente e reativacao sao contexto comercial
- o Joao deve explorar compra atual, volume, minimo viavel e chance de avaliacao
- o Joao deve tentar recuperar oportunidade antes de concluir nao-fit

#### O que remover do prompt

- a regra `sim + entre 4.000 e 10.000 => desqualificar`
- a associacao automatica entre `ja compra ASX` e bloqueio
- a postura de fiscal de politica

### 7.6 Tools do `WF07`

#### Objetivo

Reduzir improviso e padronizar o que vem da conversa versus o que ja e conhecido
do contexto.

#### Para `score_lead`

Pre-preencher com:

- `cnpj`
- `perfil`
- `uf_atuacao`
- `volume`

#### Para `finalize`

Declarar contrato explicito de campos comerciais:

- `customer_relation`
- `fornecedor_contexto`
- `nfs_enviadas`
- `empresa_recente`
- `motivo_handoff`
- `origem_recuperacao`

### 7.7 `02D-Find-Distributors`

#### Problema atual

Zero resultado gera vazio estrutural.

#### Ajustes necessarios

- garantir retorno estruturado sempre
- inclusive quando a query trouxer zero linhas

#### Retorno minimo esperado

- `found = false`
- `count = 0`
- `message = nenhum distribuidor encontrado`

### 7.8 `02B-Score-Lead`

#### Problema atual

O parser textual de volume e fragil.

#### Ajustes necessarios

Usar o mesmo mapeamento do `WF06`:

- `Abaixo de 2.000` -> `1500`
- `Entre 2.000 e 4.000` -> `3000`
- `Entre 4.000 e 10.000` -> `7000`
- `Acima de 10.000` -> `12000`

### 7.9 `03-Finalize-Handoff`

#### Problemas atuais

- naming inconsistente
- contexto comercial parcial
- rastreabilidade incompleta

#### Ajustes necessarios

- padronizar naming dos campos comerciais
- melhorar persistencia para rastrear origem e motivo do handoff
- atualizar o lead/funil de forma coerente quando o handoff acontecer

#### Contexto que precisa chegar ao vendedor

- cliente atual
- ex-cliente
- reativacao
- recuperado do `Path 2`
- sem distribuidor no estado
- aceitou operar no minimo
- empresa nova
- NFs enviadas

### 7.10 Status, labels e logs

#### Objetivo

Tornar recuperacao, handoff e fechamento auditaveis.

#### Status uteis

- `recovered_for_direct`
- `no_distributor_found`
- `handoff_done`
- `closed_no_fit`

#### Labels sugeridas

- `path_distributor`
- `path_qualified`
- `recovered_from_path2`
- `cliente_direto_asx`
- `reativacao`
- `sem_distribuidor_estado`
- `handoff_done`
- `closed_no_fit`

#### Eventos sugeridos

- `p2_direct_interest_detected`
- `p2_recovered_for_handoff`
- `p2_no_distributor_found`
- `p3_existing_customer_detected`
- `p3_reativacao_detected`
- `p3_handoff_started`
- `p3_handoff_completed`
- `closed_no_fit`

### 7.11 `WF08` - observabilidade

#### Objetivo

Detectar stuck states que hoje passam invisiveis ou mal classificados.

#### Checks sugeridos

- lead do `Path 3` respondeu e nao houve `score`
- lead do `Path 3` respondeu e nao houve `finalize`
- lead do `Path 2` demonstrou interesse direto e nao houve promocao
- lead do `Path 2` ficou em loop de distribuidores
- `find_distributors` retornou zero sem fallback estruturado
- lead promovido do `Path 2` sem handoff concluido
- handoff executado sem persistencia coerente no funil

## 8. Contratos que precisam estar explicitos

Outra IA nao pode adivinhar payload nem semantica.

### 8.1 O que e contexto fixo

Campos que devem vir pre-preenchidos sempre que ja forem conhecidos:

- `phone`
- `nome`
- `empresa`
- `cnpj`
- `perfil`
- `uf_atuacao`
- `volume`
- `path`
- `path_reason`

### 8.2 O que e inferencia conversacional

Campos que de fato dependem da conversa:

- `customer_relation`
- `fornecedor_contexto`
- `nfs_enviadas`
- `empresa_recente`
- `motivo_handoff`
- `origem_recuperacao`

### 8.3 Semantica minima que precisa estar escrita

- `customer_relation`
  - cliente atual
  - ex-cliente
  - reativacao
  - sem relacao previa
- `origem_recuperacao`
  - nasceu no `Path 2` e subiu para venda direta
  - permaneceu no `Path 3`
- `motivo_handoff`
  - por que este caso deve ir ao vendedor agora

## 9. Criterios de aceite

Uma correcao so esta pronta quando o comportamento observado bater com estes
criterios.

### 9.1 `Path 3` com `ASX direto`

- nao pode mais encerrar de forma automatica
- precisa explorar contexto comercial antes de concluir

### 9.2 `Path 2` de baixo volume com abertura para `4 mil`

- precisa permitir promocao para venda direta
- precisa conseguir chegar em `score` e `finalize` quando o caso justificar

### 9.3 Zero distribuidor

- precisa retornar fallback estruturado
- nao pode gerar mensagem inventando falha tecnica

### 9.4 Lead recuperado do `Path 2`

- precisa deixar rastro claro em status, labels, eventos ou persistencia equivalente

### 9.5 Caso realmente sem fit

- precisa poder ser encerrado com coerencia
- nao pode entrar em loop

## 10. Ordem de implementacao recomendada

### Fase 1 - corrigir cerebro comercial

- reescrever prompt do `Joao P3`
- reescrever prompt do `Joao P2`
- corrigir principios comerciais dos dois agentes

### Fase 2 - abrir rota real de promocao do `Path 2`

- dar capacidade de handoff ao `Path 2`
- registrar promocao para venda direta

### Fase 3 - corrigir distribuidores e fallback

- corrigir `02D-Find-Distributors`
- garantir fallback estruturado

### Fase 4 - corrigir score, finalize e persistencia

- corrigir parsing de volume
- padronizar naming
- melhorar rastreabilidade

### Fase 5 - corrigir observabilidade

- atualizar `WF08`
- adicionar checks de stuck states

## 11. Casos que precisam ser validados depois das mudancas

### `Path 3`

- lead qualificado que diz `ASX direto`
- ex-cliente que quer voltar a comprar
- lead com volume atual abaixo do minimo, mas aberto a operar em `4 mil`
- lead com volume baixo e sem abertura real

### `Path 2`

- lead de baixo volume que aceita comprar `4 mil`
- lead de baixo volume que nao aceita o minimo
- lead com erro no formulario e volume real maior
- lead sem distribuidor no estado e com potencial direto
- lead sem distribuidor no estado e sem potencial direto
- lead fora da regiao direta, para confirmar que continua no canal distribuidor

### distribuidores

- estado com distribuidores ativos
- estado sem distribuidores ativos
- busca por cidade
- fallback coerente com zero resultado

### handoff

- handoff vindo do `Path 3`
- handoff recuperado do `Path 2`
- notificacao ao vendedor com contexto correto
- persistencia completa no funil

## 12. O que ainda pode ser anexado para deixar o material ainda mais fechado

Se quiser deixar este material ainda mais autosuficiente para outra IA, os
proximos anexos ideais sao:

- transcricao textual dos prints
- tabela caso -> workflow -> node -> ajuste
- exemplos concretos de payload final de `score_lead` e `finalize`

Mesmo sem esses anexos, este documento ja consolida o que uma outra IA precisa
entender para nao repetir os erros de interpretacao que aconteceriam lendo
apenas os workflows crus.
