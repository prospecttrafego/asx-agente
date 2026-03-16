# ASX SDR - Monitor Tecnico (Metabase)

Dashboard de monitoramento tecnico do sistema ASX-Agente para a equipe Convert.

**URL:** `https://monitor.agenciaprospect.space`

---

## Cards do Dashboard

### Card 1 — Taxa de Erros por Hora (Line Chart)

```sql
SELECT
  date_trunc('hour', created_at) AS hora,
  COUNT(*) AS erros
FROM events
WHERE type = 'infra_error'
  AND created_at >= NOW() - INTERVAL '7 days'
GROUP BY 1
ORDER BY 1;
```

- Tipo: Line chart
- Eixo X: hora
- Eixo Y: erros
- Cor: vermelho (#E74C3C)

---

### Card 2 — Erros por Workflow (Bar Chart)

```sql
SELECT
  COALESCE(payload->>'workflow_name', 'desconhecido') AS workflow,
  COUNT(*) AS erros
FROM events
WHERE type = 'infra_error'
  AND created_at >= NOW() - INTERVAL '7 days'
GROUP BY 1
ORDER BY 2 DESC;
```

- Tipo: Bar chart horizontal
- Cor: laranja (#F39C12)

---

### Card 3 — Ultimos Erros (Tabela)

```sql
SELECT
  created_at AS "Data/Hora",
  payload->>'workflow_name' AS "Workflow",
  payload->>'last_node' AS "Ultimo Node",
  payload->>'error_message' AS "Erro",
  payload->>'execution_id' AS "Execucao"
FROM events
WHERE type = 'infra_error'
ORDER BY created_at DESC
LIMIT 50;
```

- Tipo: Tabela
- Colunas: Data/Hora, Workflow, Ultimo Node, Erro, Execucao

---

### Card 4 — Latencia do Agente (Line Chart, 2 series)

```sql
SELECT
  hora,
  avg_latency_seconds AS "Media (s)",
  p95_latency_seconds AS "P95 (s)"
FROM v_agent_latency
WHERE hora >= NOW() - INTERVAL '7 days';
```

- Tipo: Line chart
- Serie 1: Media (azul)
- Serie 2: P95 (vermelho tracejado)
- Eixo Y: Segundos

---

### Card 5 — Eventos por Tipo (Donut Chart)

```sql
SELECT tipo, total FROM v_events_by_type;
```

- Tipo: Donut/Pie chart
- Dimensao: tipo
- Medida: total

---

### Card 6 — Handoffs Hoje (Number Card)

```sql
SELECT COUNT(*) AS handoffs
FROM events
WHERE type = 'handoff_complete'
  AND created_at >= CURRENT_DATE;
```

- Tipo: Number card
- Label: "Handoffs Hoje"
- Cor: verde (#27AE60)

---

### Cards 7a-d — Fluxo de Leads Hoje (4 Number Cards)

**7a — Total:**
```sql
SELECT COUNT(*) AS total FROM fb_leads WHERE created_at >= CURRENT_DATE;
```

**7b — Path 1 (Desqualificados):**
```sql
SELECT COUNT(*) AS desqualificados FROM fb_leads WHERE path = 1 AND created_at >= CURRENT_DATE;
```

**7c — Path 2 (Distribuidores):**
```sql
SELECT COUNT(*) AS distribuidores FROM fb_leads WHERE path = 2 AND created_at >= CURRENT_DATE;
```

**7d — Path 3 (Qualificados):**
```sql
SELECT COUNT(*) AS qualificados FROM fb_leads WHERE path = 3 AND created_at >= CURRENT_DATE;
```

- Tipo: Number cards
- Cores: 7a cinza, 7b vermelho, 7c laranja, 7d verde

---

## Layout

```
+----------------------------+----------------------------+
| Card 1: Erros por Hora     | Card 4: Latencia           |
| (line chart, 6 cols)       | (line chart, 6 cols)       |
+----------------------------+----------------------------+
| Card 2: Erros por Workflow | Card 5: Eventos por Tipo   |
| (bar chart, 6 cols)        | (donut chart, 6 cols)      |
+------+------+------+------+----------------------------+
| C6   | C7a  | C7b  | C7c  | Card 3: Ultimos Erros      |
| Hand | Total| P1   | P2   | (tabela, 6 cols)           |
| 1.5  | 1.5  | 1.5  | C7d  |                            |
|      |      |      | P3   |                            |
+------+------+------+------+----------------------------+
```

---

## Alertas

### Alerta 1 — Spike de Erros

```sql
SELECT COUNT(*) AS erros_ultima_hora
FROM events
WHERE type = 'infra_error'
  AND created_at >= NOW() - INTERVAL '1 hour';
```

- Condicao: resultado > 3
- Frequencia: a cada hora
- Canal: email

### Alerta 2 — Falha de Envio

```sql
SELECT COUNT(*) AS falhas_envio
FROM fb_leads
WHERE status = 'send_failed'
  AND updated_at >= NOW() - INTERVAL '1 hour';
```

- Condicao: resultado > 0
- Frequencia: a cada hora
- Canal: email

### Alerta 3 — Sem Atividade (dia util)

```sql
SELECT
  CASE
    WHEN EXTRACT(DOW FROM NOW()) IN (0, 6) THEN -1
    ELSE COALESCE(
      (SELECT COUNT(*) FROM fb_leads WHERE created_at >= NOW() - INTERVAL '24 hours'),
      0
    )
  END AS leads_24h;
```

- Condicao: resultado = 0
- Frequencia: diario as 9h (BRT)
- Canal: email

---

## Como criar os alertas no Metabase

1. Salve cada query de alerta como uma "Question" separada (nao no dashboard)
2. Abra a question salva
3. Clique no icone de sino (alertas) no canto superior direito
4. Configure a condicao (ex: "quando resultado for maior que 3")
5. Defina a frequencia e o email de destino
6. Salve o alerta
