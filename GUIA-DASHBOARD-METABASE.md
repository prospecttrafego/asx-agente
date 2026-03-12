# Guia do Dashboard no Metabase

Este arquivo explica como ler o dashboard `ASX SDR - Monitor Tecnico` no Metabase.

O objetivo do painel e responder rapidamente:

1. Entraram leads hoje?
2. O primeiro contato foi enviado?
3. Os leads de venda direta estao avancando?
4. Existe algo parado ou roteado errado?
5. Se existe problema, ele e de negocio ou tecnico?

## Como Ler o Dashboard

Leia o painel de cima para baixo.

### 1. Atencao imediata

Essa primeira linha responde: `tem algo pegando agora?`

- `Alertas Ativos`: soma sinais de risco identificados pelo `WF08`.
- `Sem Primeiro Contato`: lead entrou no funil, mas nao recebeu a primeira mensagem.
- `Parados sem Handoff`: leads qualificados travados sem virar repasse para vendedor.
- `Nao Identificadas`: conversas que o `WF07` nao conseguiu classificar corretamente.
- `Ultimo Handoff`: mostra ha quanto tempo ocorreu o ultimo handoff concluido.

Leitura pratica:

- Se qualquer um desses cards estiver ruim, ja existe uma acao imediata.
- Se `Ultimo Handoff` mostrar `Nenhum registrado`, significa que nao ha handoff encontrado no periodo monitorado.

### 2. Entrada do funil

Essa segunda linha responde: `o topo do funil esta rodando?`

- `Leads Hoje`: quantos formularios viraram lead interno hoje.
- `CNPJ Invalido Hoje`: quantos foram desqualificados logo na entrada.
- `Distribuidores Hoje`: quantos foram direcionados para parceiros.
- `Venda Direta Hoje`: quantos entraram na qualificacao comercial direta.
- `Primeiro Contato Hoje`: quantos receberam a primeira abordagem.

Leitura pratica:

- Se `Leads Hoje` subir e `Primeiro Contato Hoje` nao acompanhar, existe problema no comeco do fluxo.
- Se `Venda Direta Hoje` estiver subindo, vale acompanhar o bloco seguinte.

### 3. Avanco da venda direta

Essa terceira linha responde: `a qualificacao comercial esta andando?`

- `Aguardando Resposta`: leads qualificados esperando retorno do lead.
- `Responderam 24h`: leads qualificados que responderam nas ultimas 24 horas.
- `Leads Criados 24h`: quantos ja viraram lead formal.
- `Vendedores Atrib. 24h`: quantos ja receberam assignment.
- `Handoffs 24h`: quantos chegaram ao repasse final.

Leitura pratica:

- Se `Venda Direta Hoje` subir, mas `Responderam 24h`, `Leads Criados 24h` e `Handoffs 24h` nao acompanharem, o funil esta travando.

### 4. Funil consolidado

Aqui fica a tabela `Funil de Venda Direta - 24h`.

Ela mostra em que etapa o volume esta parando:

- entrou na venda direta
- recebeu primeira mensagem
- aguardando resposta
- respondeu
- virou lead
- recebeu vendedor
- concluiu handoff

Leitura pratica:

- Use essa tabela para localizar o gargalo da qualificacao direta.

### 5. Problemas silenciosos

Esse e um dos blocos mais importantes.

- `Qualificados Travados no Handoff`: mostra leads que deveriam ter avancado e nao avancaram.
- `Nao Identificadas Recentes`: mostra conversas que cairam em rota errada ou nao foram reconhecidas.

Leitura pratica:

- Se `Nao Identificadas` subir, va direto em `Nao Identificadas Recentes`.
- Se houver suspeita de bloqueio no repasse, consulte `Qualificados Travados no Handoff`.

### 6. Diagnostico tecnico

Esses cards ajudam a entender se o problema e tecnico.

- `Status dos Servicos`: mostra a saude atual dos checks do `WF08`.
- `Erros Tecnicos Recentes`: lista as ultimas falhas registradas.

Leitura pratica:

- Se os indicadores operacionais estiverem ruins e os tecnicos parecerem bons, provavelmente existe erro silencioso de negocio.
- Se os dois estiverem ruins, o problema pode ser tecnico e operacional ao mesmo tempo.

### 7. Tendencias tecnicas

Na parte final ficam os cards de apoio:

- `Erros por Hora`
- `Erros por Workflow`
- `Roteamento do Inbound - Ultimas 24h`

Leitura pratica:

- Esses cards ajudam a entender distribuicao e tendencia dos problemas.
- Eles nao sao o primeiro lugar para olhar.

## Uso Diario Recomendado

Se eu resumir o uso do painel:

1. Olhe a primeira linha.
2. Se houver alerta, descubra se o problema esta no primeiro contato, no roteamento ou no handoff.
3. Se nao houver alerta, confira se o topo do funil e a venda direta estao acompanhando o volume esperado.
4. Se houver anomalia, use as tabelas de problemas silenciosos.
5. So depois consulte a camada tecnica para diagnostico.
