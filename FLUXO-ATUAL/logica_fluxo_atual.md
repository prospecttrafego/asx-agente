# ASX SDR - Lógica do Fluxo

> Este documento descreve a lógica do sistema do ponto de vista do usuário e do negócio: como o João (agente IA) se comporta, quais decisões toma, e como os leads são qualificados e transferidos.

---

## 1. Objetivo do Sistema

O ASX SDR automatiza a primeira etapa do processo de vendas da ASX Iluminação:

- **Atender** leads B2B via WhatsApp 24/7
- **Qualificar** leads com base em critérios de negócio
- **Rejeitar educadamente** leads B2C ou fora do perfil
- **Transferir** leads qualificados para vendedores humanos

---

## 2. O Agente João

João é o SDR virtual da ASX. Ele foi programado para:

### Personalidade
- Comunicação direta e profissional
- Frases curtas (1-2 linhas)
- Uma pergunta por vez
- Não usa jargão técnico com o cliente

### O que João NÃO faz
- Não inventa dados
- Não promete descontos
- Não menciona termos técnicos (score, API, tool, label)
- Não continua conversando após transferir para vendedor

---

## 3. Critérios de Qualificação

Um lead é **QUALIFICADO** quando atende **TODOS** os critérios:

| Critério | Requisito | Por quê? |
|----------|-----------|----------|
| **CNPJ** | Válido na Receita Federal | Garante que é empresa real |
| **Região** | Norte ou Nordeste | Área de atuação da ASX |
| **Volume** | >= R$ 4.000/mês | Ticket mínimo viável |

### Estados do Norte/Nordeste aceitos
AC, AM, AP, PA, RO, RR, TO, AL, BA, CE, MA, PB, PE, PI, RN, SE

### Tipos de Desqualificação

| Motivo | Ação do João |
|--------|--------------|
| Sem CNPJ (B2C) | Explica que atende apenas empresas |
| CNPJ inválido | Pede correção até 3x, depois encerra |
| Fora do N/NE | Informa que atende apenas essas regiões |
| Volume < R$4k | Informa ticket mínimo |

---

## 4. Fluxo de Qualificação

### 4.1 Ordem de Coleta de Dados

João coleta os dados nesta ordem, **uma pergunta por vez**:

```
1. Nome da pessoa
2. Nome da empresa
3. CNPJ
   └── [Validação imediata via API]
4. Perfil (revenda/oficina/representante)
5. UF de atuação
6. Volume mensal (R$)
7. Já compra produtos ASX?
   └── Se sim: de qual fornecedor/distribuidora?
```

### 4.2 Diagrama do Fluxo de Decisão

```
                    ┌─────────────────┐
                    │  Lead inicia    │
                    │   conversa      │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  Coletar nome,  │
                    │ empresa, CNPJ   │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  CNPJ válido?   │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │ Inválido │   │  B2C     │   │  Válido  │
        │ (3 tent) │   │ (s/CNPJ) │   │          │
        └────┬─────┘   └────┬─────┘   └────┬─────┘
             │              │              │
             ▼              ▼              ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │ Encerrar │   │ Encerrar │   │ Continuar│
        │ conversa │   │ conversa │   │ coleta   │
        └──────────┘   └──────────┘   └────┬─────┘
                                           │
                                           ▼
                                  ┌─────────────────┐
                                  │ Coletar perfil, │
                                  │   UF, volume    │
                                  └────────┬────────┘
                                           │
                                           ▼
                                  ┌─────────────────┐
                                  │  UF no N/NE?    │
                                  └────────┬────────┘
                                           │
                            ┌──────────────┴──────────────┐
                            │                             │
                            ▼                             ▼
                      ┌──────────┐                 ┌──────────┐
                      │   Não    │                 │   Sim    │
                      └────┬─────┘                 └────┬─────┘
                           │                            │
                           ▼                            ▼
                      ┌──────────┐                ┌──────────────┐
                      │ Encerrar │                │ Volume >= 4k?│
                      └──────────┘                └──────┬───────┘
                                                        │
                                         ┌──────────────┴──────────────┐
                                         │                             │
                                         ▼                             ▼
                                   ┌──────────┐                 ┌──────────┐
                                   │   Não    │                 │   Sim    │
                                   └────┬─────┘                 └────┬─────┘
                                        │                            │
                                        ▼                            ▼
                                   ┌──────────┐                ┌──────────────┐
                                   │ Encerrar │                │ QUALIFICADO! │
                                   └──────────┘                └──────┬───────┘
                                                                      │
                                                                      ▼
                                                              ┌───────────────┐
                                                              │ Calcular score│
                                                              │ e classificar │
                                                              └───────┬───────┘
                                                                      │
                                                                      ▼
                                                              ┌───────────────┐
                                                              │  Transferir   │
                                                              │ p/ vendedor   │
                                                              └───────────────┘
```

---

## 5. Sistema de Scoring

Leads qualificados recebem uma pontuação que determina prioridade de atendimento:

### 5.1 Classificação por Score

| Score | Classe | Prioridade | Significado |
|-------|--------|------------|-------------|
| 70-100 | Quente | Urgent | Alto potencial, atender imediatamente |
| 40-69 | Morno | High | Bom potencial, priorizar |
| 0-39 | Frio | Medium | Potencial moderado |

### 5.2 Fatores que Influenciam o Score

| Fator | Impacto Positivo | Impacto Negativo |
|-------|------------------|------------------|
| **Volume** | >= R$10k (+pontos) | Mínimo R$4k |
| **Perfil** | Representante (+) | - |
| **UF** | Estados estratégicos (+) | - |
| **CNAE** | Autopeças/oficinas (+) | Outros CNAEs |
| **Idade empresa** | > 5 anos (+) | < 1 ano |

---

## 6. Comportamento das Tools (Ferramentas)

O João tem acesso a ferramentas que executa automaticamente:

### 6.1 company_enrich (Validar CNPJ)

**Quando usar:** Assim que o cliente informar o CNPJ

**O que faz:**
- Valida se o CNPJ existe na Receita Federal
- Busca dados da empresa (razão social, nome fantasia, CNAE, cidade, estado)
- Salva os dados para uso posterior

**Possíveis resultados:**
- CNPJ válido → continua qualificação
- CNPJ inválido → pede correção (até 3x)

### 6.2 score_lead (Calcular Score)

**Quando usar:** Após confirmar que lead atende todos os critérios

**O que faz:**
- Calcula score numérico (0-100)
- Classifica: quente/morno/frio
- Define prioridade: urgent/high/medium

**Retorna:** `{ score, class, priority }`

### 6.3 finalize (Transferir para Vendedor)

**Quando usar:** IMEDIATAMENTE após score_lead

**O que faz:**
- Registra o lead no banco de dados
- Escolhe o vendedor com menos leads
- Move a conversa para inbox do vendedor
- Envia notificação WhatsApp ao vendedor

**CRÍTICO:** Deve ser chamado ANTES de avisar o cliente sobre a transferência

### 6.4 set_label (Aplicar Etiquetas)

**Quando usar:** Para marcar o status do lead

**Labels possíveis:**
- `qualificado` - Lead aprovado e transferido
- `quente`, `morno`, `frio` - Classificação por score
- `ja_compra_asx` - Lead já compra produtos ASX
- `novo_cliente_asx` - Lead ainda não compra ASX

### 6.5 log_agent_event (Registrar Eventos)

**Quando usar:** Para auditoria de decisões importantes

**Eventos registrados:**
- `score_calculated` - Score calculado
- `lead_finalized` - Lead transferido
- `b2c_rejected` - Lead B2C rejeitado

---

## 7. Fluxo de Handoff (Transferência)

### 7.1 Sequência Obrigatória

```
1. João coleta todos os dados
2. João verifica critérios → QUALIFICADO
3. João chama score_lead → recebe score/class/priority
4. João chama finalize → transferência acontece
5. João avisa cliente: "Vou te passar para um especialista"
6. João PARA de responder
7. Vendedor recebe notificação no WhatsApp
8. Vendedor assume conversa no Chatwoot
```

### 7.2 O que Acontece no Handoff (Fluxo Sequencial)

O workflow 03-Finalize-Handoff executa os seguintes passos **em sequência**:

```
1. Pick Agent
   └── Seleciona vendedor com menos leads atribuídos
   └── Retorna: agent_id, agent_name, agent_phone, team_id

2. Persist Lead
   └── Cria/atualiza contato na tabela contacts
   └── Cria/atualiza empresa na tabela companies
   └── Cria lead na tabela leads
   └── Retorna: lead_id

3. Create Assignment
   └── Vincula lead ao vendedor na tabela assignments

4. Transfer Conversation
   └── Transfere conversa para o TIME do vendedor no Chatwoot
   └── Usa chatwootConversationId (vem do webhook da Evolution)
   └── POST /conversations/{id}/assignments com team_id

5. Notify Vendor
   └── Envia WhatsApp para o vendedor
   └── Mensagem com resumo do lead qualificado

6. Log Handoff
   └── Registra evento na tabela events
```

### 7.3 Distribuição de Leads

Os vendedores são atribuídos com base em **round-robin por carga**:

| Vendedor | Telefone | Team ID | Inbox ID |
|----------|----------|---------|----------|
| Queila | 5575991803083 | 1 | 2 |
| Tiago | 5575999216589 | 2 | 3 |

A query seleciona o vendedor com **menos leads atribuídos**:
```sql
SELECT agent_id, COUNT(assignments)
ORDER BY COUNT ASC
LIMIT 1
```

### 7.4 Mensagem para o Vendedor

```
*NOVO LEAD QUALIFICADO*

👤 João Silva
🏢 ABC Autopeças
📍 BA
📱 +5575999999999

🎯 Quente

🛒 Já compra ASX de: Distribuidora Nordeste
   (ou "Ainda não compra ASX" se for novo cliente)

⏰ Entre em contato!
```

---

## 8. Comportamento com Lead Já Qualificado (Lead Recorrente)

Se um lead já transferido enviar nova mensagem pelo WhatsApp do SDR:

### 8.1 Detecção

O sistema verifica se o lead já foi qualificado:
```sql
SELECT lead_id, qualified_at, assignee_id, vendedor_nome, vendedor_whatsapp
FROM contacts → leads → assignments → agents
WHERE phone = 'telefone' AND qualified_at IS NOT NULL
```

### 8.2 Comportamento

1. João **NÃO** responde (a IA não processa a mensagem)
2. Sistema **notifica o vendedor responsável** via WhatsApp
3. Vendedor continua atendimento no Chatwoot

### 8.3 Mensagem de Notificação

```
🔔 *Lead Recorrente*

5575999999999 enviou nova mensagem.
Continue o atendimento no Chatwoot.
```

### 8.4 Lógica no Workflow

```
Check Lead Exists
    │
    ▼
Lead Already Qualified?
├── SIM → Notify Assigned Vendor (WhatsApp) → FIM
└── NÃO → Continua fluxo normal (IA responde)
```

---

## 9. Tratamento de Erros e Exceções

### 9.1 CNPJ Inválido

| Tentativa | Ação do João |
|-----------|--------------|
| 1ª | "Não encontrei esse CNPJ. Pode verificar os 14 dígitos?" |
| 2ª | "Ainda não consegui validar. Confirme o número do CNPJ, por favor." |
| 3ª | "Não consegui validar o CNPJ. Quando tiver o número correto, me chame!" |

### 9.2 Lead B2C

```
João: "Entendo! A ASX atende apenas empresas com CNPJ.
Para compras pessoais, recomendo procurar nossas revendas autorizadas.
Posso ajudar em algo mais?"
```

### 9.3 Fora da Região

```
João: "No momento a ASX atende apenas as regiões Norte e Nordeste.
Mas estamos em expansão! Posso anotar seu contato para quando
chegarmos na sua região?"
```

### 9.4 Volume Abaixo do Mínimo

```
João: "Nosso atendimento direto é para compras a partir de R$4.000/mês.
Para volumes menores, posso indicar um distribuidor na sua região.
Quer que eu verifique?"
```

---

## 10. Exemplos de Conversas

### 10.1 Lead Qualificado (Caminho Feliz)

```
Cliente: Oi, quero saber sobre produtos de iluminação
João: Olá! Sou o João da ASX Iluminação. Posso te ajudar com informações sobre nossos produtos.
      Qual seu nome?
Cliente: Carlos
João: Prazer, Carlos! Qual o nome da sua empresa?
Cliente: Auto Center Nordeste
João: Ótimo! Me passa o CNPJ da Auto Center Nordeste?
Cliente: 12345678000190
João: Perfeito, encontrei! Auto Center Nordeste LTDA, de Salvador/BA.
      Vocês são revenda, oficina ou representante?
Cliente: Revenda de autopeças
João: Entendi! E qual UF vocês atuam?
Cliente: Bahia
João: E qual o volume mensal de compras, mais ou menos?
Cliente: Uns 8 mil reais
João: Vocês já compram produtos ASX de algum fornecedor ou distribuidora?
Cliente: Sim, compramos da Distribuidora Nordeste
João: Ótimo! Vou te passar para um especialista que vai te apresentar
      as melhores condições. Ele entra em contato em breve!
[Vendedor assume a conversa]
```

### 10.2 Lead Desqualificado (Fora da Região)

```
Cliente: Boa tarde, quero fazer um pedido
João: Boa tarde! Sou o João da ASX. Qual seu nome?
Cliente: Fernanda
João: Prazer, Fernanda! Qual o nome da empresa?
Cliente: Fernanda Autopeças
João: Me passa o CNPJ?
Cliente: 98765432000188
João: Encontrei! Fernanda Autopeças, de São Paulo/SP.
      No momento a ASX atende apenas as regiões Norte e Nordeste.
      Quando expandirmos para SP, podemos te avisar?
Cliente: Ah que pena, tudo bem
João: Desculpa não poder ajudar agora! Fica meu contato caso precise
      de algo no futuro. Boa sorte nos negócios!
```

### 10.3 Lead B2C

```
Cliente: Oi, quero comprar uma lâmpada pro meu carro
João: Olá! A ASX atende apenas empresas com CNPJ (revendas, oficinas, representantes).
      Para compras pessoais, posso indicar uma loja na sua região. Qual sua cidade?
Cliente: Fortaleza
João: Em Fortaleza você encontra nossos produtos na Auto Center Fortaleza
      ou na Casa das Lâmpadas. Posso ajudar em mais alguma coisa?
```

---

## 11. Métricas e KPIs

O sistema registra dados para acompanhamento:

| Métrica | Tabela | Uso |
|---------|--------|-----|
| Conversas da IA | `ia_messages` | Análise de qualidade |
| Leads qualificados | `leads` | Taxa de conversão |
| Eventos | `events` | Auditoria e debugging |
| Atribuições | `assignments` | Distribuição por vendedor |

---

## 12. Glossário

| Termo | Significado |
|-------|-------------|
| **SDR** | Sales Development Representative - quem qualifica leads |
| **Lead** | Potencial cliente que entrou em contato |
| **Handoff** | Transferência do lead da IA para vendedor humano |
| **Score** | Pontuação de 0-100 que indica potencial do lead |
| **Inbox** | Caixa de entrada no Chatwoot |
| **B2B** | Business to Business - venda para empresas |
| **B2C** | Business to Consumer - venda para pessoa física |
