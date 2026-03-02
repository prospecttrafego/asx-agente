# **Instruções Gerais**

Esse projeto refere-se à um Agente de Atendimento da Industria ASX - Iluminações Automotivas. A pasta local é apenas um espelho do projeto real. O dir "ASX-Agente" é apenas um upload que fiz referente ao projeto real, para facilitar a leitura e analise do projeto.

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

O fluxo atual e que está ativo, é o que está na pasta "NOVO-FLUXO" -> /Users/mateusolinto/Developer Projects/CONVERT/ASX /ASX-Agente/NOVO-FLUXO

Dentro dessa pasta "NOVO-FLUXO" você verá um arquivo que explica a lógica do fluxo e como ele funciona. O arquivo é o "logica_novo_fluxo.md"

**ENTENDA QUE ESSE PROJETO É UM FLUXO. Ou seja, como o proprio nome diz, ele tem uma logica à ser seguida, um fluxo a ser percorrido. Tudo precisa estar em harmonia. Todos os fluxos fazem parte de uma Lógica única.**

Ao corrigir algo, ou implementar algo, voce precisa LER como está configurado aquele node. Os parametros, os inputs e outputs gerados. Só assim voce será capaz de corrigir ou implementar algo corretamente.

## Instruções Adicionais

- Use o context7 para buscar a documentacao referente à versao que estamos usando do N8N, Evolution API, Chatwoot e etc... De modo que você entenda corretamente quais parametros usar, quais variaveis usar, como configurar cada node e integrações entre os serviços.

Observação:

- Meu stack está hospedado em um servidor web. Estamos usando o Easypanel como painel e a hospedagem é a Hostinger.
