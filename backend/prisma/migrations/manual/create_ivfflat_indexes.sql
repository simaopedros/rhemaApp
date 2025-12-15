-- Migração para criar índices IVFFlat otimizados para busca vetorial
-- IVFFlat divide os vetores em "listas" (clusters) para busca mais rápida

-- Primeiro, garantir que a extensão pgvector está ativa
CREATE EXTENSION IF NOT EXISTS vector;

-- =============================================================
-- ÍNDICE PARA VÍDEOS (embedding)
-- Usado quando buscamos vídeos similares ao interesse do usuário
-- =============================================================

-- Remover índice antigo se existir
DROP INDEX IF EXISTS idx_videos_embedding_ivfflat;

-- Criar índice IVFFlat com distância de cosseno
-- lists = 100 é bom para até 100k vídeos
-- Para mais vídeos, aumentar proporcionalmente (sqrt do total)
CREATE INDEX idx_videos_embedding_ivfflat 
ON videos USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- =============================================================
-- ÍNDICE PARA USUÁRIOS (interest_vector) 
-- Usado se precisarmos buscar usuários com interesses similares
-- (útil para "Pessoas que você pode conhecer")
-- =============================================================

DROP INDEX IF EXISTS idx_users_interest_vector_ivfflat;

CREATE INDEX idx_users_interest_vector_ivfflat 
ON users USING ivfflat (interest_vector vector_cosine_ops)
WITH (lists = 50);

-- =============================================================
-- CONFIGURAÇÃO DE PERFORMANCE
-- =============================================================

-- Aumentar o número de probes durante a busca
-- Mais probes = mais precisão, mas mais lento
-- Default é 1, recomendado 10-50 para boa precisão
-- Pode ser ajustado por sessão: SET ivfflat.probes = 10;

-- Analisar tabelas para estatísticas atualizadas
ANALYZE videos;
ANALYZE users;

-- =============================================================
-- VERIFICAR ÍNDICES CRIADOS
-- =============================================================
-- SELECT indexname, indexdef FROM pg_indexes WHERE tablename IN ('videos', 'users');
