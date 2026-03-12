# Logica do Fluxo — ALMA SDR

## O Que e a ALMA

A ALMA e uma agencia de marketing digital especializada no nicho de **saude e estetica** (clinicas, dentistas, medicos, profissionais de estetica). O sistema SDR automatizado conversa com leads pelo WhatsApp, gera valor real analisando a presenca digital do lead, e conduz naturalmente para o agendamento de uma reuniao chamada **Diagnostico Estrategico** — uma sessao de 30 minutos com o **Marco**, socio da ALMA.

---

## Visao Geral

O lead chega pelo WhatsApp e e atendido por um consultor virtual da ALMA. Esse consultor:

1. Entende o que o lead precisa
2. Pesquisa o perfil digital do lead (Instagram, site)
3. Entrega insights personalizados com valor real
4. Conduz a conversa para agendar o Diagnostico Estrategico

O objetivo final de toda conversa e **agendar a reuniao com o Marco**. Se nao for possivel, o sistema tenta re-engajar. Se ainda assim nao houver resposta, encerra com a porta aberta.

---

## Jornada do Lead

### Etapa 1 — Primeiro Contato

O lead envia uma mensagem pelo WhatsApp. Pode ser qualquer coisa: "oi", "quero saber mais", "vi o anuncio", etc.

O sistema verifica:
- A mensagem e do lead? (ignora mensagens de agentes humanos)
- A conversa ainda esta sob responsabilidade da IA? (ignora se ja foi transferida para humano ou se ja tem reuniao agendada)

Se passar nessas verificacoes, a mensagem entra no fluxo.

**Batching de mensagens:** Se o lead enviar varias mensagens rapidas seguidas (como "oi" + "vi o anuncio" + "queria saber mais"), o sistema espera 10 segundos e junta tudo em uma unica mensagem antes de responder. Isso evita que a IA responda a cada mensagem separadamente.

---

### Etapa 2 — Conversa Inicial (Coleta de Dados)

O consultor cumprimenta o lead de forma natural e busca duas informacoes essenciais:

1. **Objetivo** — O que o lead quer melhorar? (ex: "atrair mais pacientes", "melhorar meu posicionamento", "crescer no Instagram")
2. **Instagram ou site** — Para ter base concreta de analise

O consultor pede isso de forma natural, nunca como um formulario. Exemplos:

> "Me passa o Instagram ou site e me diz em uma frase: qual seu principal desafio hoje?"

> "Pra te dar um direcionamento certeiro, preciso do IG (ou site) e qual objetivo voce ta buscando."

**Regra:** Se o lead nao fornecer apos 2 tentativas, o consultor trabalha com o que tem.

---

### Etapa 3 — Pesquisa e Analise

Quando o lead fornece o Instagram/site e o objetivo, o consultor avisa que vai analisar:

> "Vou dar uma olhada e te retorno com 3 pontos praticos."

Nos bastidores, tres pesquisas acontecem em paralelo:

1. **Instagram** — O sistema acessa o perfil do lead e analisa: numero de seguidores, taxa de engajamento, hashtags mais usadas, conteudo dos ultimos posts
2. **Site** — Se tiver site, extrai o titulo e a descricao para entender como o lead se posiciona
3. **Tendencias do nicho** — Busca no Google as tendencias atuais do nicho do lead (ex: "tendencias estetica marketing digital")

Todos esses dados sao processados por uma IA que gera 4 insights estruturados.

---

### Etapa 4 — Entrega de Valor (Challenger Selling)

O consultor entrega os insights usando a metodologia **Challenger Selling** — ou seja, ele ensina algo novo ao lead em vez de simplesmente perguntar o que ele quer. A estrutura e:

1. **Ponto Forte** — Algo que o lead ja faz bem. Gera rapport e mostra que o consultor realmente analisou o perfil.
   > "Seu conteudo de antes e depois ta muito bom, engajamento acima da media do nicho."

2. **Limitador** — O que esta travando o lead de atingir o objetivo declarado. Gera consciencia do problema.
   > "Mas o perfil nao tem CTA claro nos posts. Quem vê gosta, mas nao sabe o proximo passo pra virar paciente."

3. **Oportunidade Rapida** — Um quick-win pratico que o lead pode implementar em 7 dias. Gera confianca.
   > "Se adicionar um link de agendamento na bio e um CTA nos 3 proximos posts, ja vai sentir diferenca em 1 semana."

4. **Pergunta Inteligente** — Uma pergunta que aprofunda a dor e abre caminho para o agendamento.
   > "Hoje voce tem algum processo pra transformar esse engajamento em consultas agendadas?"

---

### Etapa 5 — Conduzindo ao Agendamento

Apos entregar valor, o consultor observa sinais de que e o momento certo para propor a reuniao:

- Lead engajou com o insight (respondeu com interesse)
- Lead expressou frustacao ou dor clara
- Lead perguntou "e agora?" ou "proximos passos?"
- Lead demonstrou urgencia
- Conversa ja teve 3-4+ trocas produtivas

Quando identifica o momento, propoe naturalmente:

> "Se fizer sentido, a proxima etapa e um Diagnostico Estrategico (30 min) com o Marco. Saimos de la com: gargalo principal mapeado + plano 30-60-90 + proximos passos. Quer agendar?"

---

### Etapa 6A — Lead Aceita Agendar

Se o lead aceita, o sistema:

1. Consulta a agenda do Marco no Google Calendar (proximos 5 dias uteis)
2. Identifica horarios disponiveis (slots de 30 min, seg-sex, 9h-18h)
3. Compara com a preferencia do lead (se disse "terca de manha", por exemplo)
4. **Se houver match:** Agenda automaticamente, cria link do Google Meet
5. **Se nao houver match:** Sugere 2-3 horarios proximos da preferencia

Apos agendar:
- A conversa e movida para o time de **Agendamento** no painel
- O contato e atualizado com a data e link da reuniao
- Uma nota interna e criada com o resumo do agendamento
- O lead recebe a confirmacao:
  > "Pronto! Agendei seu Diagnostico Estrategico para terca 18/03 as 14h. O Marco vai te enviar o link do Meet por email."

---

### Etapa 6B — Lead Recusa Agendar

Se o lead recusa, o consultor:
- **NAO insiste** na mesma abordagem
- Continua gerando valor na conversa
- Tenta propor novamente com um angulo diferente apos 2-3 trocas

Se o lead recusar 2 vezes com firmeza, o consultor encerra com a porta aberta e marca a conversa como **follow-up**.

---

### Etapa 6C — Lead Pede para Falar com Humano

Se o lead pede para falar com alguem, ou faz uma objecao muito forte:

1. O consultor aceita sem resistencia
2. Cria uma nota interna com o resumo da conversa (objetivo do lead, contexto importante, motivo do handoff, proximos passos sugeridos)
3. Marca a conversa como **handoff**
4. Transfere para o time humano

A IA para de responder a partir desse momento.

---

## Re-engajamento (Leads que Pararam de Responder)

Se o lead parou de responder, o sistema tem um processo automatico que roda a cada hora:

### Primeira Tentativa (apos 3h sem resposta)

Envia uma mensagem casual e leve, sem pressao:

> "Oi! Vi que ficou corrido. Quando puder, me responde aqui que eu te direciono."

A mensagem e gerada pela IA com base no contexto da conversa, entao nunca e generica.

### Segunda Tentativa (apos 22h sem resposta)

Envia uma mensagem de despedida aberta:

> "Ultima mensagem por aqui — se quiser retomar depois, e so mandar um oi que eu continuo de onde paramos."

### Encerramento (apos 24h sem resposta)

Nenhuma mensagem e enviada. A conversa e marcada como **sem resposta** e encerrada. Se o lead voltar depois, podera ser re-ativado.

---

## Objecoes e Base de Conhecimento

Quando o lead faz uma objecao que o consultor nao sabe responder de cabeca, ou pergunta sobre servicos, metodologia ou diferenciais da ALMA, o sistema consulta uma **base de conhecimento** com informacoes categorizadas:

| Categoria | Quando Usar |
|-----------|-------------|
| Objecoes | Lead diz "ta caro", "nao tenho tempo", "ja tenho agencia" |
| Servicos | Lead pergunta "o que voces fazem?" |
| Metodologia | Lead pergunta "como voces trabalham?" |
| Diferenciais | Lead pergunta "o que diferencia voces?" |
| Cases de sucesso | Lead quer ver resultados anteriores |
| Cenarios | Situacoes especificas de conversa |
| Exemplos | Modelos de conversas |

O consultor usa essa informacao como **base**, mas adapta ao tom e contexto da conversa. Nunca copia literalmente.

---

## Humanizacao das Respostas

Para que a conversa parecao natural no WhatsApp, as respostas nunca sao enviadas como um bloco unico de texto. Em vez disso:

1. A resposta e quebrada em mensagens curtas (1-3 frases cada)
2. Antes de cada mensagem, aparece o indicador de "digitando..."
3. O tempo de espera e proporcional ao tamanho do texto (simula digitacao real)
4. Ha uma pausa entre cada mensagem

Isso faz com que a experiencia seja indistinguivel de uma conversa com uma pessoa real.

---

## Coleta e Atualizacao de Dados

Durante toda a conversa, sempre que o lead fornece uma informacao nova, o consultor salva automaticamente no cadastro. Os dados coletados sao:

| Dado | Exemplo |
|------|---------|
| Empresa | "Clinica Dra. Ana" |
| Segmento | "Dermatologia" |
| Instagram | "@clinica.ana" |
| Site | "www.clinicaana.com.br" |
| Objetivo | "Atrair mais pacientes" |
| Cidade | "Salvador" |
| Nicho | "Estetica facial" |
| Telefone | "(71) 99999-0000" |

Esses dados enriquecem o perfil do lead e ficam disponiveis para o Marco quando fizer o Diagnostico Estrategico.

---

## Labels (Status da Conversa)

Cada conversa recebe labels que indicam seu status atual:

| Label | Significado |
|-------|-------------|
| `novo` | Lead acabou de entrar, primeira interacao |
| `em_andamento` | Conversa ativa, lead respondendo |
| `reuniao_agendada` | Diagnostico Estrategico marcado com sucesso |
| `follow_up` | Lead recusou agendar 2x, porta aberta para futuro |
| `sem_resposta` | Lead nao respondeu apos 2 tentativas de re-engajamento |
| `desqualificado` | Lead nao e publico-alvo da ALMA |
| `handoff` | Conversa transferida para atendimento humano |

---

## Regras do Consultor

### Sempre
- Responder rapido e de forma natural
- Mensagens curtas (1-3 frases)
- Terminar com proximo passo claro
- Adaptar tom ao lead (formal se formal, descontraido se descontraido)
- Ancorar analise no objetivo declarado pelo lead
- Coletar e salvar dados do lead ao longo da conversa

### Nunca
- Revelar que e IA
- Falar preco ou valores de servicos
- Fazer mais de 1 pergunta por mensagem
- Enviar blocos longos de texto
- Forcar agendamento na primeira interacao
- Fazer sequencia de perguntas (parece call center)
- Inventar dados sobre o lead
- Prometer resultados especificos
- Criticar concorrentes ou agencias anteriores

---

## Equipes no Painel de Atendimento

| Time | Funcao |
|------|--------|
| SDR (IA) | Consultor virtual atende automaticamente |
| Humano | Atendimento humano (handoff) |
| Agendamento | Leads que ja tem reuniao marcada |

---

## Resumo Visual da Jornada

```
Lead envia mensagem no WhatsApp
        |
    E mensagem nova do lead?
    A conversa ainda e da IA?
        |
       SIM
        |
   Coleta objetivo + Instagram/site
        |
   Pesquisa: Instagram + Site + Tendencias
        |
   Entrega 4 insights personalizados
   (ponto forte, limitador, oportunidade, pergunta)
        |
   Lead engajou? Sinais de interesse?
        |
    ┌───┴───┐
   SIM     NAO
    |       |
  Propoe   Continua gerando valor
  reuniao  (tenta novamente depois)
    |
    ┌───────┼───────┐
 ACEITA  RECUSA   PEDE HUMANO
    |       |         |
 Agenda   2x? →     Nota interna
 Google   follow_up  + handoff
 Calendar            para humano
    |
 Confirma data + link Meet
 Move para time Agendamento


--- Se parou de responder ---

  3h sem resposta → msg casual
 22h sem resposta → msg de despedida
 24h sem resposta → encerra (sem_resposta)
```

---

## Servicos Utilizados

| Servico | Funcao |
|---------|--------|
| WhatsApp (via Chatwoot) | Canal de conversa com o lead |
| Chatwoot | Painel de atendimento, gestao de conversas e equipes |
| Google Calendar | Agenda do Marco para o Diagnostico Estrategico |
| Google Meet | Link da reuniao (criado automaticamente) |
| Supabase | Banco de dados (conversas, mensagens, eventos) |
| Base de conhecimento | Informacoes sobre a ALMA (servicos, objecoes, cases) |
| Instagram (Apify) | Analise do perfil digital do lead |
| Google Search | Tendencias do nicho do lead |
