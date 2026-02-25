# Novo Fluxo - ASX

- Novo Fluxo irá substituir o Fluxo Atual. Preciso fazer as adaptações e migrar a lógica.

## Lógica do novo Fluxo

1. Webhook de entrada:

- Formulário de Campanhas do Facebook Ads: usar 'facebookLeadAdsTrigger''
    Obs: As perguntas capturadas no Formulário encontra-se no caminho /NOVO-FLUXO/Forms-Facebook.

2.Extrair dados -> Normalizar os dados extraídos (ao que tudo indica os dados extraidos de telefone de contato precisam ser estruturados porque vem quebrado -> **necessário pesquisar essa informação**)

3.Planilhar Dados e Validar Critérios

3.1 Validar Critérios extraídos que serão usados na etapa 3.2

- Paralelamente será acionado a TOOL de validação do CNPJ para extrair se o cnpj é valido, extrair CNAE e todas as informacoes, igual no Fluxo anterior
    Obs: Ao pesquisar o CNPJ pode ser identificado que a empresa em questao possui o CNPJ fora da Regiao Norte e Nordeste, porém, isso nao o desqualifica, porque a empresa pode ter CNPJ de uma regiao (que foi onde foi fundada), porém, atuar em todo o território Brasileiro. Logo, deve-se extrair apenas para planilhar e registrar.

3.2 Vamos planilhar no supabase os leads em três categórias:

- Leads totalmente desqualificados: (**ao menos uma das duas afirmações abaixo precisa ser verdadeira**)
  - Não possuem um CNPJ válido;
- Leads que compram abaixo de R$ 4000,00 **mas possuem CNPJ válido** (definir uma nomenclatura para esse grupo)
- Leads Qualificados (compram acima de R$ 4000,00 e possuem CNPJ válido e atuam no Norte e Nordeste)  

1. Teremos os seguintes caminhos a partir daqui:

4.1 Leads totalmente desqualificados

- **Serão ignorados**, apenas vamos registrar na tabela.

4.2 Leads que compram abaixo de 4000 **mas tem um CNPJ válido** (podem atuar em qualquer região do Brasil)

- Esses Leads apesar de nao serem o Perfil da ASX, eles devem ser direcionados à um Distribuidor Parceiro mais próximo (ou seja, um distribuidor que compra produtos da ASX). Portanto um Agente entrará em contato com eles para informar que será encaminhado o contato de distribuidores parceiros mais próximo do Lead (as vezes tem apenas um distribuidor para aquele estado do Lead, porém, quando tiver várias opcoes em cidades diferentes, direcionar o distribuidor cuja cidade é a mesma do Lead ou mais próximo possível). Deve ser enviado o nome do Distribuidor, Cidade que atua e o endereço (Rua, numero da rua e CEP)
  - Eu coloquei uma Planilha no caminho 'NOVO-FLUXO/Distribuidores-ASX-BRASIL.csv'.Nessa planilha tem a lista dos distribuidores, região que eles atendem e o endereço.

Obs: Uma ação paralela será registrar em uma tabela de dados essa recomendação. Planilhar o nome do Lead, informacoes da Empresa (cnpj e etc..), telefone de contato e a(s) distribuidora(s) que foi indicada.

4.3 Leads Qualificados (**compram acima de 4000, tem CNPJ válido e atua na região Norte/Nordeste** - se for fora da região, indicar distribuidores parceiros)

Aqui o Agente de IA entrará em contato para confirmar os Dados e o Interesse do Lead, para qualifica-lo como potencial cliente. Além de confirmar volume que esse Lead compra, vamos adicionar duas novas perguntas para que de fato ele seja um candidato à comprar direto da fabrica (ASX).
  
  **Perguntas Extras condicionais:**

  1) Já compra produtos ASX de alguem da regiao? Se sim, de quem?
    Resposta:
    **se for SIM** - Pegar o nome de quem compra e DESQUALIFICAR (**aqui tem uma exceção**)
    - Agradecer o contato, explicar que por questao de politica interna, ele deve continuar comprando com quem ele já compra -> Apos isso o Agente deve registrar essa informacao na tabela para controle interno.
        **Exceção:** Se o lead comprar um volume alto, acima de R$ 10mil, deve-se encaminhar para o vendedor.
    **se for NAO** - seguir para a proxima pergunta.

  2) Me envie ao menos duas NFs de compras realizadas em outros fornecedores de autopeças:
    - Lead envia as NFs
    - Lead diz que não tem -> registrar como empresa recente (primeira compra)
    Em ambos os cenários será feito o Handoff para o Vendedor (seguindo a mesma lógica do Fluxo Atual), porém, precisamos ter registrado as respostas e na mensagem para o vendedor precisa constar essas informações, assim como deve ser registrado no Chatwoot via Campo Personalizado (ou label)

---

## Prompts

Precisamos criar dois prompts:

1. Para o Agente que falará com os Leads que receberão a indicação dos Distribuidores.
2. Prompt para o Agente que falará com os Leads Qualificados.

Diferentemente do prompt atual, precisamos configurar nesses novos Prompts diferentes cenários que podem acontecer na conversa. E principalmente, precisamos criar **Fallbacks** de respostas.

Precisamos de um Prompt com enfase conversacional, ou seja, que o Agente possa ir tirando dúvidas dos Leads, caso isso aconteça, caso nao aconteça, ele seguira para o Handoff. Entendeu? Eu so nao quero que ele seja rígido e robotizado. Ele precisa ser maleável.

---

## Supabase, Chatwoot e EvolutionAPI

- Usar as credenciais fornecidas no arquivo .env para fazer os ajustes necessários no Supabase e no Chatwoot.
- Analisar a Integracao da Evolution API, se está tudo ok para a IA enviar a mensagem e depois receber a mensagem.

---

## Lógica

- Posso estar enganado, mas o que eu imagino é que terá um Fluxo para o cenário do Agente enviar a mensagem e um Fluxo para o cenário em que a interação continua e portanto, será o fluxo que recebe mensagem.
