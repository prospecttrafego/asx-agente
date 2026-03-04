# Teste 03 - Path 2: Volume Alto + SP (Fora N/NE - Distribuidor)

**Data:** 2026-03-01
**Execution ID:** 803
**Status:** SUCCESS (23/23 nodes)

## Cenario

Lead com CNPJ valido + volume alto (>= R$4k) + estado SP (fora N/NE). Esperado: Path 2 (distribuidor), mesmo com volume qualificavel, por estar fora da regiao N/NE.

## Dados de Entrada

| Campo | Valor |
|-------|-------|
| facebook_lead_id | TEST_E2E_PATH2_002 |
| nome | Marcos Teste SP |
| email | marcos@teste.com |
| telefone | +5562998621000 |
| perfil | Distribuidora |
| volume_faixa | Entre 4.000 e 10.000 |
| cnpj_raw | 12345678000195 |
| estado_envio | SP |

## Resultado

### Classificacao

- **Path:** 2
- **Motivo:** "Volume >= 4k mas fora N/NE - distribuidor"

### Nodes Executados (23/23) - Todos SUCCESS

### Distribuidores Encontrados (SP)

| # | Razao Social | Cidade | Telefone |
|---|-------------|--------|----------|
| 1 | PANHAN COMERCIO DE PECAS E ACESS. PARA VEICULOS LTDA | Bauru | 14996469207 |
| 2 | ROVELLI DISTRIBUIDORA AUTOMOTIVA LTDA | Cerquilho | 15 33845414 |
| 3 | ADRIPEL DISTRIBUIDORA DE PECAS | Franca | 16-37011555 |

### Mensagem Enviada via WhatsApp

```
Ola Marcos! Aqui e o Joao da ASX Iluminacao.

Vi que a *ROBERIO JOSE DOS SANTOS 16952477870* se cadastrou pelo nosso formulario para conhecer nossos produtos.

Analisamos o perfil da sua empresa e, para a sua regiao (*SP*), o canal mais agil para adquirir nossos produtos e atraves dos nossos distribuidores parceiros. Eles tem estoque pronto e podem te atender rapidamente!

Na sua regiao, recomendo:

1. *PANHAN COMERCIO DE PECAS E ACESS. PARA VEICULOS LTDA* - Bauru
   Tel: 14996469207

2. *ROVELLI DISTRIBUIDORA AUTOMOTIVA LTDA* - Cerquilho
   Tel: 15 33845414

3. *ADRIPEL DISTRIBUIDORA DE PECAS* - Franca
   Tel: 16-37011555

Voce tambem pode consultar todos os nossos distribuidores em: asx.com.br/distribuidores

Qualquer duvida, estou por aqui!
```

## Conclusao

PASSOU - Classificacao correta (Path 2 por estar fora N/NE apesar do volume alto). Mensagem com distribuidores de SP, telefones e URL.
