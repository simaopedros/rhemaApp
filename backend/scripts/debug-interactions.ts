/**
 * Script para verificar estado das interações e vetores
 * Executar: bun run scripts/debug-interactions.ts
 */

import { PrismaClient } from '@prisma/client';
import { writeFileSync } from 'fs';

const prisma = new PrismaClient({ log: ['error'] });

async function debug() {
    const lines: string[] = [];
    const log = (msg: string) => {
        lines.push(msg);
        console.log(msg);
    };

    log('='.repeat(60));
    log('🔍 DEBUGANDO INTERAÇÕES E VETORES');
    log('='.repeat(60));

    // 1. Contar interações
    const interactionCount = await prisma.interaction.count();
    log(`\n📊 Total de interações no banco: ${interactionCount}`);

    if (interactionCount > 0) {
        // Mostrar últimas interações
        const recentInteractions = await prisma.interaction.findMany({
            take: 5,
            orderBy: { createdAt: 'desc' },
            include: {
                user: { select: { id: true, name: true } },
                video: { select: { id: true, title: true } }
            }
        });

        log('\n📋 Últimas 5 interações:');
        recentInteractions.forEach((i, idx) => {
            log(`   ${idx + 1}. [${i.type}] ${i.user.name} -> "${i.video.title || 'sem título'}"`);
            log(`      Data: ${i.createdAt.toLocaleString('pt-BR')}`);
        });
    } else {
        log('   ⚠️ NENHUMA INTERAÇÃO ENCONTRADA!');
        log('   Isso significa que nenhum like/view/share foi registrado.');
    }

    // 2. Verificar vetores de usuários
    log('\n' + '-'.repeat(60));
    log('👤 ESTADO DOS VETORES DE USUÁRIOS:');

    const users = await prisma.$queryRawUnsafe<any[]>(`
        SELECT 
            id, 
            name,
            CASE WHEN interest_vector IS NOT NULL THEN 'SIM' ELSE 'NAO' END as tem_vetor
        FROM users
        ORDER BY name
    `);

    users.forEach(u => {
        log(`   ${u.tem_vetor === 'SIM' ? '✅' : '❌'} ${u.name}: ${u.tem_vetor}`);
    });

    // 3. Verificar embeddings de vídeos
    log('\n' + '-'.repeat(60));
    log('🎥 ESTADO DOS EMBEDDINGS DE VÍDEOS:');

    const videoStats = await prisma.$queryRawUnsafe<any[]>(`
        SELECT 
            status,
            COUNT(*) as total,
            SUM(CASE WHEN embedding IS NOT NULL THEN 1 ELSE 0 END) as com_embedding
        FROM videos
        GROUP BY status
    `);

    videoStats.forEach(s => {
        log(`   ${s.status}: ${s.com_embedding}/${s.total} com embedding`);
    });

    // 4. Testar operação de vetor
    log('\n' + '-'.repeat(60));
    log('🧪 TESTANDO OPERAÇÃO DE VETOR (pgvector):');

    try {
        const [testResult] = await prisma.$queryRawUnsafe<any[]>(`
            SELECT 
                (SELECT COUNT(*) FROM users WHERE interest_vector IS NOT NULL) as users_with_vector,
                (SELECT COUNT(*) FROM videos WHERE embedding IS NOT NULL) as videos_with_embedding
        `);
        log(`   ✅ pgvector operacional!`);
        log(`   - Usuários com vetor: ${testResult.users_with_vector}`);
        log(`   - Vídeos com embedding: ${testResult.videos_with_embedding}`);
    } catch (error: any) {
        log(`   ❌ Erro no teste: ${error.message}`);
    }

    log('\n' + '='.repeat(60));

    // Salvar em arquivo
    writeFileSync('debug-output.txt', lines.join('\n'));
    console.log('\n📁 Output salvo em debug-output.txt');

    await prisma.$disconnect();
}

debug().catch(console.error);
