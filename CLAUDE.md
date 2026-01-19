# **Instruções Gerais**

Esse projeto refere-se à um Agente de Atendimento da Industria ASX - Iluminações Automotivas. A pasta local é apenas um espelho do projeto real. O dir "ASX-AGENTE" é apenas um upload que fiz referente ao projeto real, para facilitar a leitura e analise do projeto. 

## **O Stack do Projeto**

Composto por:

- N8N: Orquestrador
    - versão do N8N: 2.3.2
- OpenAI: LLM
- Supabase/Postgres: Banco de dados e Memoria 
- Redis: cache e gestao de filas
- Chatwoot: Painel de Atendimento Omnichannel
    - Versao do Chatwoot (selfhosted): versao 4.9.2
- Evolution API: Middleware de Conexão com o Whatsapp (via baileys)
    - versao do Evolution API: Version: 2.3.7
Lógica do Fluxo e Objetivo:
Ver documento /Users/mateusolinto/Developer Projects/CONVERT/ASX /ASX-Agente/FLUXO-ATUAL/logica_fluxo.md

- O Agente qualifica, classifica e faz handoff para os vendedores.
- A conversa nasce em uma Inbox do Chatwoot que é onde o Agente de IA atua. Assim que a IA qualifica e classifica e define como sendo lead qualificado, ela faz o handoff para os vendedores via round robin. Toda a conversa é transferida para a Janela de Inbox do vendedor.


## **Fluxo atual e Ativo no N8N:**

O fluxo atual e que está ativo, é o que está na pasta "FLUXO-ATUAL" -> /Users/mateusolinto/Developer Projects/CONVERT/ASX /ASX-Agente/FLUXO-ATUAL

Dentro dessa pasta "FLUXO-ATUAL" você verá uma sub-pasta com os workflows do projeto que ajudarão à compreender como foi construido e como está ativo o projeto. É importante entender a logica do fluxo. O que ele deve fazer. Como o Lead irá percorrer ao longo do Fluxo e como o Agente de IA irá atuar.

**ENTENDA QUE ESSE PROJETO É UM FLUXO. Ou seja, como o proprio nome diz, ele tem uma logica à ser seguida, um fluxo a ser percorrido. Tudo precisa estar em harmonia. Todos os fluxos fazem parte de uma Lógica única.** 

Você perceberá ao ler a documentação e visualizar de forma profunda os workflows que nessa logica, o Agente é recepitivo. O que quero dizer é que o Lead que inicia o contato. 

Esse fluxo já está funcionando corretamente. Caso queira veririficar de forma real, use as variáveis de ambiente no arquivo .env para que voce possa acessar o Supabase, Chatwoot e N8N para conferir como tudo foi configurado.

## **NOVO FLUXO:**

Eu preciso criar agora um novo Fluxo. Só que dessa vez, o Agente será ativo. Ele iniciará o contato, irá abordar os leads que preencheram um Formulário do Facebook.

Vamos para a lógica do Fluxo que preciso construir. Atualmente, temos uma campanha de trafego pago para geração de cadastros com formulário nativo, ou seja, um formulário do Facebook. 

**Preciso que, assim que um Lead preencher o formulário e atender aos nossos critérios de qualificação, o Agente de IA colete os dados na planilha e inicie o contato, abordando-o de forma personalizada e com técnicas de vendas. A lógica subsequente será a mesma: o Agente não realizará todo o fluxo. Ele conduzirá até certa etapa e fará o handoff para os vendedores, exatamente igual ao 'FLUXO-ATUAL'.**


## Instruções Adicionais

- Use o context7 para buscar a documentacao referente à versao que estamos usando do N8N, Evolution API, Chatwoot e etc... De modo que você entenda corretamente quais parametros usar, quais variaveis usar, como configurar cada node e integrações entre os serviços.

Observação:

- Meu stack está hospedado em um servidor web. Estamos usando o Easypanel como painel e a hospedagem é a Hostinger.

- Repositorio do Github: https://github.com/prospecttrafego/asx-agente.git
