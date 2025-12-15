/**
 * Script para aplicar índices IVFFlat no PostgreSQL
 * Otimiza busca vetorial para o sistema de recomendação
 * 
 * Executar: bun run scripts/apply-vector-indexes.ts
 */

import prisma from '../src/lib/prisma';

async function applyVectorIndexes() {
    console.log('🚀 Aplicando índices IVFFlat para otimização de busca vetorial...\n');

    try {
        // Verificar se extensão pgvector está ativa
        console.log('1️⃣ Verificando extensão pgvector...');
        await prisma.$executeRawUnsafe(`CREATE EXTENSION IF NOT EXISTS vector;`);
        console.log('   ✅ Extensão pgvector ativa\n');

        // Criar índice para vídeos
        console.log('2️⃣ Criando índice IVFFlat para tabela VIDEOS...');
        await prisma.$executeRawUnsafe(`DROP INDEX IF EXISTS idx_videos_embedding_ivfflat;`);
        await prisma.$executeRawUnsafe(`
            CREATE INDEX idx_videos_embedding_ivfflat 
            ON videos USING ivfflat (embedding vector_cosine_ops)
            WITH (lists = 100);
        `);
        console.log('   ✅ Índice idx_videos_embedding_ivfflat criado\n');

        // Criar índice para usuários
        console.log('3️⃣ Criando índice IVFFlat para tabela USERS...');
        await prisma.$executeRawUnsafe(`DROP INDEX IF EXISTS idx_users_interest_vector_ivfflat;`);
        await prisma.$executeRawUnsafe(`
            CREATE INDEX idx_users_interest_vector_ivfflat 
            ON users USING ivfflat (interest_vector vector_cosine_ops)
            WITH (lists = 50);
        `);
        console.log('   ✅ Índice idx_users_interest_vector_ivfflat criado\n');

        // Analisar tabelas
        console.log('4️⃣ Atualizando estatísticas das tabelas...');
        await prisma.$executeRawUnsafe(`ANALYZE videos;`);
        await prisma.$executeRawUnsafe(`ANALYZE users;`);
        console.log('   ✅ Estatísticas atualizadas\n');

        // Verificar índices criados
        console.log('5️⃣ Verificando índices criados...');
        const indexes = await prisma.$queryRawUnsafe<any[]>(`
            SELECT indexname, indexdef 
            FROM pg_indexes 
            WHERE tablename IN ('videos', 'users') 
            AND indexname LIKE '%ivfflat%';
        `);

        if (indexes.length > 0) {
            console.log('   📊 Índices encontrados:');
            indexes.forEach((idx: any) => {
                console.log(`      - ${idx.indexname}`);
            });
        }

        console.log('\n✅ SUCESSO! Índices IVFFlat aplicados com sucesso.');
        console.log('📈 A busca vetorial agora está otimizada para melhor performance.\n');

        // Dicas de uso
        console.log('💡 DICAS:');
        console.log('   - Para ajustar precisão vs velocidade, configure: SET ivfflat.probes = 10;');
        console.log('   - Mais probes = mais preciso, porém mais lento');
        console.log('   - Recomendado: 10-50 probes para boa precisão');
        console.log('   - Quando tiver >100k vídeos, aumente "lists" para sqrt(total_videos)\n');

    } catch (error) {
        console.error('❌ ERRO ao aplicar índices:', error);
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
}

applyVectorIndexes();
