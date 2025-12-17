/**
 * Script para verificar e diagnosticar o estado dos embeddings
 * Executar: bun run scripts/check-embeddings.ts
 */

import { PrismaClient } from '@prisma/client';

// Cliente sem logs para saída limpa
const prisma = new PrismaClient({ log: [] });

async function checkEmbeddings() {
    console.log('🔍 Verificando estado dos embeddings...\n');

    try {
        // Verificar vídeos
        console.log('=== VÍDEOS ===');
        const [videoStats] = await prisma.$queryRawUnsafe<any[]>(`
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN status = 'READY' THEN 1 ELSE 0 END) as ready,
                SUM(CASE WHEN embedding IS NOT NULL THEN 1 ELSE 0 END) as with_embedding
            FROM videos
        `);
        console.log(`  Total de vídeos: ${videoStats.total}`);
        console.log(`  Vídeos READY: ${videoStats.ready}`);
        console.log(`  Vídeos com embedding: ${videoStats.with_embedding}`);
        console.log(`  ❌ Vídeos READY sem embedding: ${Number(videoStats.ready) - Number(videoStats.with_embedding)}`);

        // Listar vídeos sem embedding
        const videosWithoutEmbedding = await prisma.$queryRawUnsafe<any[]>(`
            SELECT id, title, description, status, type
            FROM videos 
            WHERE status = 'READY' AND embedding IS NULL
            LIMIT 10
        `);

        if (videosWithoutEmbedding.length > 0) {
            console.log('\n  📋 Vídeos READY sem embedding (até 10):');
            videosWithoutEmbedding.forEach((v, i) => {
                console.log(`    ${i + 1}. ID: ${v.id}`);
                console.log(`       Título: ${v.title || '(sem título)'}`);
                console.log(`       Descrição: ${v.description?.substring(0, 50) || '(sem descrição)'}...`);
                console.log(`       Status: ${v.status}, Tipo: ${v.type}`);
            });
        }

        // Verificar usuários
        console.log('\n=== USUÁRIOS ===');
        const [userStats] = await prisma.$queryRawUnsafe<any[]>(`
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN interest_vector IS NOT NULL THEN 1 ELSE 0 END) as with_vector
            FROM users
        `);
        console.log(`  Total de usuários: ${userStats.total}`);
        console.log(`  Usuários com vetor de interesse: ${userStats.with_vector}`);
        console.log(`  ❌ Usuários sem vetor: ${Number(userStats.total) - Number(userStats.with_vector)}`);

        // Verificar extensão pgvector
        console.log('\n=== EXTENSÃO PGVECTOR ===');
        try {
            const [ext] = await prisma.$queryRawUnsafe<any[]>(`
                SELECT * FROM pg_extension WHERE extname = 'vector'
            `);
            if (ext) {
                console.log(`  ✅ pgvector instalado (versão: ${ext.extversion})`);
            } else {
                console.log('  ❌ pgvector NÃO está instalado!');
            }
        } catch (e) {
            console.log('  ❌ Erro ao verificar pgvector:', e);
        }

        // Verificar índices vetoriais
        console.log('\n=== ÍNDICES VETORIAIS ===');
        const indexes = await prisma.$queryRawUnsafe<any[]>(`
            SELECT indexname, indexdef 
            FROM pg_indexes 
            WHERE indexname LIKE '%ivf%' OR indexdef LIKE '%vector%'
        `);
        if (indexes.length > 0) {
            indexes.forEach(idx => {
                console.log(`  ✅ ${idx.indexname}`);
            });
        } else {
            console.log('  ⚠️ Nenhum índice vetorial encontrado');
        }

        console.log('\n✅ Diagnóstico concluído!');

    } catch (error) {
        console.error('❌ Erro durante diagnóstico:', error);
    } finally {
        await prisma.$disconnect();
    }
}

checkEmbeddings();
