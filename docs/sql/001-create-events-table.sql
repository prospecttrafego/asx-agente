-- ============================================================
-- ASX-Agente: Tabela de eventos para monitoramento
-- Executar no Supabase SQL Editor
-- ============================================================

CREATE TABLE IF NOT EXISTS events (
  id BIGSERIAL PRIMARY KEY,
  type TEXT NOT NULL,
  payload JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes para queries do Metabase
CREATE INDEX IF NOT EXISTS idx_events_type ON events (type);
CREATE INDEX IF NOT EXISTS idx_events_created ON events (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_type_created ON events (type, created_at DESC);

-- Verificacao: rodar apos criar
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'events';
