# Entendimento do Projeto ASX-Agente

Este documento resume o que o projeto faz do ponto de vista de negocio, como o fluxo opera em producao e quais sao as decisoes que o sistema toma em cada etapa.

## Visao Geral

O projeto e um sistema de triagem comercial automatizada da ASX Iluminacao Automotiva.

O objetivo real nao e apenas responder leads por WhatsApp. O objetivo e decidir, o mais cedo possivel, qual destino comercial cada lead deve seguir:

- ser ignorado, quando nao atende criterio minimo basico
- ser direcionado para distribuidores parceiros, quando nao faz sentido atendimento direto
- ser qualificado para negociacao direta e entregue a um vendedor humano

Na pratica, o sistema protege o canal comercial correto.

Ele evita que:

- vendedor humano perca tempo com lead fora de perfil
- lead bom fique sem atendimento
- a ASX entre em conflito com sua politica de canal
- leads de menor porte ou fora da area de atendimento direto caiam de forma errada no time comercial

## O Papel do Joao

O Joao nao exerce um papel unico. Ele muda de funcao conforme o path do lead.

### Path 2

No Path 2, Joao atua como direcionador.

Ele nao esta vendendo.
Ele orienta o lead para distribuidores parceiros, tira duvidas e tenta manter o lead no canal correto.

### Path 3

No Path 3, Joao atua como consultor comercial.

Ele nao faz o fechamento comercial.
Ele faz a qualificacao final, coleta os sinais necessarios para aprovacao e entao transfere para um vendedor humano.

### Depois do handoff

Depois que a conversa e transferida para vendedor, Joao deve parar de responder.

Esse comportamento e importante porque o projeto separa claramente:

- fase de triagem e qualificacao
- fase de atendimento comercial humano

## Mapa Objetivo de Negocio

## 1. Entradas do Sistema

As entradas reais do negocio sao estas:

- lead enviado por formulario do Facebook Ads
- resposta do lead pelo WhatsApp
- mensagens adicionais do lead em texto, audio, imagem ou documento
- mensagens de continuidade apos handoff

Os dados principais capturados na origem sao:

- nome
- email
- telefone
- perfil do negocio
- faixa de volume mensal
- CNPJ
- estado de atuacao ou envio

Esses dados sao suficientes para o sistema tomar a primeira decisao comercial.

## 2. Decisoes de Negocio

O sistema toma as decisoes em camadas.

### Camada 1: pode entrar no fluxo?

Primeiro ele valida se existem condicoes minimas para contato:

- telefone valido
- CNPJ com formato correto
- CNPJ existente e valido

Se falhar nisso, o lead nao entra no atendimento.

### Camada 2: qual canal comercial deve atender?

Se o CNPJ for valido, o sistema decide entre distribuicao indireta ou atendimento direto da ASX.

As regras sao:

- volume abaixo de `R$ 4 mil` vai para distribuidor
- volume `>= R$ 4 mil` fora de Norte/Nordeste vai para distribuidor
- volume `>= R$ 4 mil` em Norte/Nordeste vai para qualificacao de venda direta

### Camada 3: o lead de venda direta realmente pode ser entregue a vendedor?

Para leads do Path 3, ainda existe uma qualificacao final:

- confirmar os dados do formulario
- entender se ja compra ASX na regiao
- pedir notas fiscais ou identificar empresa nova

So depois disso ocorre handoff.

## 3. Saidas por Path

## Path 1: Desqualificado

### Quando acontece

- telefone invalido
- CNPJ ausente, curto ou malformado
- CNPJ nao localizado ou invalido

### O que o sistema faz

- registra o lead
- marca como desqualificado
- nao envia mensagem
- encerra o fluxo

### Intencao de negocio

Evitar gasto de operacao com lead que nao passou no filtro minimo de empresa valida.

## Path 2: Canal Distribuidor

### Quando acontece

- CNPJ valido + volume abaixo de `R$ 4 mil`
- CNPJ valido + volume `>= R$ 4 mil` fora da regiao Norte/Nordeste

### O que o sistema faz

- registra o lead
- cria ou reaproveita contato no Chatwoot
- cria conversa
- busca distribuidores parceiros no estado do lead
- envia mensagem inicial com justificativa correta
- salva os distribuidores recomendados
- marca o lead como atendido por agente distribuidor

### O que Joao faz depois

- responde duvidas sobre distribuidores
- tenta oferecer parceiros alternativos quando houver reclamacao ou pedido por cidade mais proxima
- explica que preco depende do distribuidor
- reforca que compra direta da fabrica depende de perfil, volume e regiao

### Intencao de negocio

Direcionar esse lead para o canal parceiro mais adequado sem levar para o time comercial direto da ASX.

## Path 3: Qualificacao para Venda Direta

### Quando acontece

- CNPJ valido
- volume mensal `>= R$ 4 mil`
- estado dentro da area Norte/Nordeste

### O que o sistema faz na entrada

- registra o lead
- cria ou reaproveita contato no Chatwoot
- cria conversa
- envia mensagem inicial de abertura comercial
- passa o lead a ser tratado pelo agente qualificador

### O que Joao faz depois

Etapa 1:

- confirma os dados ja recebidos
- evita repetir perguntas do formulario

Etapa 2:

- pergunta se o lead ja compra produtos ASX na regiao

Etapa 3:

- pede pelo menos duas notas fiscais recentes
- ou identifica que a empresa e nova e ainda nao tem NFs

### Quando o handoff acontece

O handoff acontece quando o lead esta apto para seguir com humano, por exemplo:

- confirmou dados e nao compra ASX na regiao
- confirmou dados, compra ASX mas entrou como excecao de volume alto
- enviou NFs
- ou foi reconhecido como empresa recente sem NFs

### O que acontece no handoff

- score do lead e calculado
- lead e persistido na estrutura comercial principal
- vendedor e escolhido por round-robin
- assignment e criado
- conversa e transferida no Chatwoot
- vendedor recebe notificacao via WhatsApp
- cliente e avisado da transferencia
- Joao para de responder

### Intencao de negocio

Entregar ao vendedor apenas oportunidades que ja passaram pelo filtro operacional e comercial da ASX.

## 4. Regras de Excecao

Essas regras sao parte importante da politica real do fluxo.

### Excecao 1: Ja compra ASX na regiao

Se o lead ja compra ASX de algum distribuidor da regiao, o sistema precisa proteger o canal.

#### Caso A: volume ate `R$ 10 mil`

- o lead e desqualificado por politica comercial
- Joao orienta a continuar com o fornecedor atual
- nao existe handoff

Essa e uma regra de protecao da rede parceira.

#### Caso B: volume acima de `R$ 10 mil`

- o lead pode seguir como excecao
- o fornecedor atual e registrado
- o handoff continua possivel

Aqui a ASX aceita que o caso merece avaliacao direta.

### Excecao 2: empresa nova sem notas fiscais

Se o lead diz que nao possui NFs porque a empresa e recente:

- isso nao bloqueia automaticamente o handoff
- o sistema registra `empresa_recente = true`
- o atendimento pode seguir para vendedor

Essa regra mostra que a falta de historico fiscal nao elimina necessariamente o potencial do lead.

### Excecao 3: pedido direto para falar com alguem

Se o lead do Path 3 pede claramente para falar com humano:

- o Joao pode antecipar o handoff

O negocio aqui prioriza velocidade quando ja existe intencao clara de avancar.

### Excecao 4: lead recorrente ja qualificado

Se um lead ja entregue para vendedor manda nova mensagem:

- a IA nao deve retomar a conversa
- o vendedor responsavel deve ser notificado

Essa regra impede disputa de atendimento entre IA e humano.

### Excecao 5: lead desconhecido

Se alguem escreve para o numero sem ter vindo do fluxo:

- o sistema ignora silenciosamente

O objetivo e manter esse numero focado no fluxo do SDR, nao virar um canal generico de atendimento.

## 5. Sequencia Operacional Real

Vendo o projeto como operacao, a sequencia real e esta:

1. O lead preenche o formulario no Facebook.
2. O sistema busca os dados completos desse lead.
3. O telefone e normalizado.
4. O CNPJ e validado e enriquecido.
5. O sistema decide o path comercial.
6. O sistema cria ou localiza o contato no Chatwoot.
7. A primeira mensagem ja sai proativamente pelo WhatsApp.
8. Se for Path 2, o lead entra em atendimento de distribuicao.
9. Se for Path 3, o lead entra em qualificacao final.
10. Se o lead passar nas regras finais, ele vira lead comercial real.
11. O sistema escolhe o vendedor, transfere a conversa e notifica esse vendedor.
12. A IA se retira da conversa apos a transferencia.

## 6. O Que Este Projeto Realmente Resolve

Em termos de negocio, o projeto resolve cinco problemas centrais:

- separa automaticamente canal indireto e canal direto
- filtra o que nao vale operacao comercial humana
- reduz tempo de resposta inicial
- mantem politica de canal com distribuidores
- organiza o handoff para vendedor sem depender de triagem manual

## 7. Pontos Sensiveis do Fluxo Hoje

Aqui estao os pontos que considero mais sensiveis do ponto de vista operacional e de negocio.

### 1. Dependencia forte da classificacao inicial

Toda a operacao depende da classificacao correta do lead no primeiro workflow.

Se telefone, CNPJ, volume ou estado forem interpretados de forma errada:

- lead bom pode cair em Path 2 por engano
- lead ruim pode cair em Path 3 por engano
- o canal errado pode assumir o atendimento

Esse e o ponto mais critico de negocio, porque afeta destino comercial.

### 2. Dependencia da mensagem inicial correta no Path 2

No Path 2, a justificativa precisa refletir o motivo real da decisao.

Se a mensagem usar justificativa errada:

- o lead entende errado porque nao foi atendido diretamente
- pode parecer incoerencia comercial
- aumenta atrito com o canal

Como essa mensagem ja foi alvo de ajuste recente, ela e um ponto sensivel.

### 3. Handoff e o momento mais delicado do projeto

No Path 3, o processo inteiro converge para o handoff.

Se houver falha em qualquer etapa:

- lead pode ficar sem vendedor
- conversa pode nao ser transferida corretamente
- vendedor pode nao ser notificado
- IA pode continuar respondendo quando nao deveria

Esse e o trecho mais sensivel do fluxo porque e onde a oportunidade comercial muda de dono.

### 4. Politica de canal depende de interpretacao correta do contexto

A regra de "ja compra ASX na regiao" e delicada.

Se o sistema interpretar errado:

- pode barrar um lead que deveria virar excecao
- pode liberar um lead que deveria permanecer com distribuidor

Esse ponto e sensivel porque toca diretamente a politica comercial da ASX com parceiros.

### 5. Dependencia da memoria e continuidade no WF07

O atendimento do WF07 depende de:

- identificar corretamente o telefone
- reconhecer o tipo do lead
- manter coerencia entre mensagens agrupadas
- saber se o lead ainda esta com IA ou ja esta com vendedor

Se isso falhar, o comportamento do agente pode sair da logica esperada.

### 6. Conversao de sinais conversacionais em decisao operacional

No Path 3, o sistema precisa entender respostas humanas abertas como:

- "ja compro"
- "nao tenho NF"
- "empresa e nova"
- "quero falar com alguem"

Isso e sensivel porque a decisao comercial depende de interpretacao de linguagem natural.

### 7. Dependencia da integracao entre varios servicos

Mesmo com foco em negocio, o desenho operacional depende de varias pecas:

- Facebook para origem do lead
- n8n para orquestracao
- Supabase para memoria e persistencia
- Evolution para WhatsApp
- Chatwoot para conversa e transferencia

Se um desses falhar, o impacto de negocio aparece imediatamente:

- lead nao recebe primeira mensagem
- conversa nao transfere
- vendedor nao recebe aviso
- historico fica incompleto

### 8. O numero do SDR nao foi desenhado para canal aberto

O fluxo pressupoe que o numero do SDR atende apenas o universo dos leads captados.

Por isso mensagens de desconhecidos sao ignoradas.

Se na pratica esse numero passar a receber trafego organico ou espontaneo:

- o fluxo atual pode deixar oportunidades sem resposta

Isso nao e necessariamente erro tecnico. E uma decisao de operacao que precisa permanecer alinhada com o uso real do canal.

## 8. Leitura Final do Projeto

Minha leitura consolidada e esta:

O projeto existe para transformar uma politica comercial da ASX em uma operacao automatizada.

Ele nao foi construido para apenas conversar com leads.
Ele foi construido para decidir:

- quem nao deve entrar
- quem deve ser atendido por distribuidor
- quem merece venda direta
- em que momento o vendedor humano deve assumir

O valor real do projeto esta menos na IA em si e mais na disciplina comercial que a IA ajuda a executar.

Se o fluxo estiver correto, a ASX ganha:

- triagem consistente
- protecao de canal
- velocidade de resposta
- melhor aproveitamento do time comercial

Se o fluxo errar, o prejuizo nao e apenas tecnico.
O erro afeta canal, priorizacao, experiencia do lead e conversao comercial.
