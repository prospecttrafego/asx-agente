# Novo Fluxo - ASX

- Novo Fluxo irá substituir o Fluxo Atual. Preciso fazer as adaptações e migrar a lógica.

## Lógica do novo Fluxo

- Webhook de entrada:
  - Formulário de Campanhas do Facebook Ads: usar 'facebookLeadAdsTrigger''
    Obs: As perguntas capturadas no Formulário encontra-se

              FacebookLeadAdsTrigger  → Valida critérios
                                                    ↓
                                          [Lead qualificado?]
                                                    ↓
                                    ┌───────────────┴───────────────┐
                                    ↓                               ↓
                                  NÃO                             SIM
                            (descarta)                             ↓
                                                      Agente INICIA contato
                                                      via WhatsApp (Evolution)
                                                              ↓
                                                    Qualificação/Handoff
                                                    (mesma lógica atual)

•⁠  ⁠Lead abaixo de 4.000 - direcionar o distribuidor mais proximo.
•⁠  ⁠⁠Lead acima de 4.000 - qualifica para potencial cliente - mas vamos validar com duas perguntas para ser um candidato a comprar direto da fabrica (ASX).
  Pergunta Extra.1) Já compra produtos ASX de alguem da regiao? Se sim, de quem?
   _ Resposta:
    se for SIM - pegar o nome de quem compra e DESQUALIFICAR.
    se for NAO - seguir para a proxima pergunta.

  Pergunta Extra.2) Me envie ao menos duas NFs de compras realizadas em outros fornecedores de autopeças. 

    se ele nao tiver - recomendaremos o distribuidor mais proximo da regiao e Acionar o vendedor - incluindo os dados.
    se ele tiver as NFS - QUALIFICADO para comprar direto da fabrica (ASX).
