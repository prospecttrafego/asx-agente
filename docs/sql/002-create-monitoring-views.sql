-- ============================================================
-- ASX-Agente: Views para dashboard Metabase
-- Executar no Supabase SQL Editor APOS 001-create-events-table.sql
-- ============================================================

-- View 1: Erros por hora (Card 1 - Taxa de Erros por Hora)
CREATE OR REPLACE VIEW v_errors_per_hour AS
SELECT
  date_trunc('hour', created_at) AS hora,
  COUNT(*) AS erros
FROM events
WHERE type = 'infra_error'
  AND created_at >= NOW() - INTERVAL '7 days'
GROUP BY 1
ORDER BY 1;

-- View 2: Erros por workflow (Card 2 - Erros por Workflow)
CREATE OR REPLACE VIEW v_errors_by_workflow AS
SELECT
  COALESCE(payload->>'workflow_name', 'desconhecido') AS workflow,
  COUNT(*) AS erros,
  MAX(created_at) AS ultimo_erro
FROM events
WHERE type = 'infra_error'
  AND created_at >= NOW() - INTERVAL '7 days'
GROUP BY 1
ORDER BY 2 DESC;

-- View 3: Latencia do agente (Card 4 - Latencia do Agente)
-- Calcula tempo entre mensagem do usuario e resposta do assistente
CREATE OR REPLACE VIEW v_agent_latency AS
WITH user_msgs AS (
  SELECT
    id,
    phone,
    session_id,
    created_at AS user_sent_at,
    LEAD(created_at) OVER (PARTITION BY session_id ORDER BY created_at) AS next_msg_at,
    LEAD(direction) OVER (PARTITION BY session_id ORDER BY created_at) AS next_direction
  FROM ia_messages
  WHERE direction = 'user'
),
latencies AS (
  SELECT
    date_trunc('hour', user_sent_at) AS hora,
    EXTRACT(EPOCH FROM (next_msg_at - user_sent_at)) AS latency_seconds
  FROM user_msgs
  WHERE next_direction = 'assistant'
    AND next_msg_at IS NOT NULL
    AND user_sent_at >= NOW() - INTERVAL '7 days'
)
SELECT
  hora,
  ROUND(AVG(latency_seconds)::numeric, 1) AS avg_latency_seconds,
  ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY latency_seconds)::numeric, 1) AS p95_latency_seconds,
  COUNT(*) AS amostras
FROM latencies
GROUP BY 1
ORDER BY 1;

-- View 4: Eventos por tipo (Card 5 - Eventos por Tipo)
CREATE OR REPLACE VIEW v_events_by_type AS
SELECT
  type AS tipo,
  COUNT(*) AS total
FROM events
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY 1
ORDER BY 2 DESC;

-- View 5: Fluxo diario de leads (Card 7 - Fluxo de Leads)
CREATE OR REPLACE VIEW v_daily_lead_flow AS
SELECT
  DATE(created_at) AS dia,
  COUNT(*) AS total_leads,
  COUNT(*) FILTER (WHERE path = 1) AS path1,
  COUNT(*) FILTER (WHERE path = 2) AS path2,
  COUNT(*) FILTER (WHERE path = 3) AS path3,
  COUNT(*) FILTER (WHERE status = 'send_failed') AS falhas_envio
FROM fb_leads
GROUP BY 1
ORDER BY 1 DESC;

-- View 6: Status dos servicos (Health Check)
CREATE OR REPLACE VIEW v_health_check_latest AS
SELECT
  payload->>'service' AS servico,
  payload->>'status' AS status,
  payload->>'response_time_ms' AS tempo_resposta_ms,
  created_at AS verificado_em
FROM events
WHERE type = 'health_check'
  AND created_at >= NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;

-- Verificacao: rodar apos criar
-- SELECT * FROM v_daily_lead_flow LIMIT 5;
-- SELECT * FROM v_events_by_type;
