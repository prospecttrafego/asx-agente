# Teste 02 - Path 2: Volume Baixo + GO (Distribuidor)

**Data:** 2026-03-01
**Execution ID:** 800
**Status:** SUCCESS (23/23 nodes)

## Cenario

Lead com CNPJ valido + volume baixo (< R$4k) + estado GO. Esperado: Path 2, envia mensagem com distribuidores + telefone + justificativa + URL.

## Dados de Entrada

| Campo | Valor |
|-------|-------|
| facebook_lead_id | TEST_E2E_PATH2_001 |
| nome | Ana Distribuidora Teste |
| email | ana@teste.com |
| telefone | +5562998621000 |
| perfil | Loja de autopecas |
| volume_faixa | Abaixo de 2.000 |
| cnpj_raw | 12345678000195 |
| estado_envio | GO |

## Resultado

### Nodes Executados (23/23)

| Node | Status |
|------|--------|
| Webhook1 | SUCCESS |
| Acknowledge FB Event | SUCCESS |
| Extract Form Fields | SUCCESS |
| Normalize Phone | SUCCESS |
| Phone Valid? | SUCCESS |
| Clean CNPJ | SUCCESS |
| CNPJ 14 Digits? | SUCCESS |
| Prepare Enrich | SUCCESS |
| 02A Company Enrich | SUCCESS |
| CNPJ Valid? | SUCCESS |
| Classify Lead | SUCCESS (path=2, volume < R$4k) |
| Save fb_lead | SUCCESS |
| Search Chatwoot Contact | SUCCESS |
| Contact Found? | SUCCESS (contato ja existia) |
| Use Existing Contact | SUCCESS |
| Create Conversation | SUCCESS |
| Switch Path | SUCCESS (Path 2) |
| Find Distributors | SUCCESS (3 distribuidores em GO) |
| Compose Message P2 | SUCCESS |
| Send WhatsApp P2 | SUCCESS |
| Save Recommendations | SUCCESS |
| Update fb_lead P2 | SUCCESS |
| Add Labels P2 | SUCCESS |

### Distribuidores Encontrados

| # | Razao Social | Cidade | Telefone |
|---|-------------|--------|----------|
| 1 | SOLIDA DISTRIBUIDORA DE EQUIPAMENTOS E ACESSORIOS | Aparecida de Goiania | 62-30889602 |
| 2 | SOCIAL DISTRIBUIDORA | Goiania | (62) 4008-1010 |
| 3 | VR ELETRO DISTRIBUIDORA AUTOMOTIVA | Goiania | (64) 3051-6000 |

### Mensagem Enviada via WhatsApp

```
Ola Ana! Aqui e o Joao da ASX Iluminacao.

Vi que a *ROBERIO JOSE DOS SANTOS 16952477870* se cadastrou pelo nosso formulario para conhecer nossos produtos.

Analisamos o perfil da sua empresa e, para a sua regiao (*GO*), o canal mais agil para adquirir nossos produtos e atraves dos nossos distribuidores parceiros. Eles tem estoque pronto e podem te atender rapidamente!

Na sua regiao, recomendo:

1. *SOLIDA DISTRIBUIDORA DE EQUIPAMENTOS E ACESSORIOS* - Aparecida de Goiania
   Tel: 62-30889602

2. *SOCIAL DISTRIBUIDORA* - Goiania
   Tel: (62) 4008-1010

3. *VR ELETRO DISTRIBUIDORA AUTOMOTIVA* - Goiania
   Tel: (64) 3051-6000

Voce tambem pode consultar todos os nossos distribuidores em: asx.com.br/distribuidores

Qualquer duvida, estou por aqui!
```

### WhatsApp Response

- Status: PENDING (enviado com sucesso)
- Message ID: 3EB0506CB70884555A8716

## Observacoes

- O nome da empresa veio da Receita Federal (CNPJ enrichment): "ROBERIO JOSE DOS SANTOS 16952477870" - este e o CNPJ de teste, nao uma empresa real
- A mensagem contém justificativa, telefones dos distribuidores e link asx.com.br/distribuidores
- Os 3 distribuidores sao todos de GO, priorizados por proximidade com Goiania

## Conclusao

PASSOU - Path 2 funcionou corretamente com a nova mensagem (justificativa + telefone + URL).
