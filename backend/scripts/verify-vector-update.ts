/**
 * Script para verificar se o vetor do usuário está sendo atualizado após interações
 * Executar: bun run scripts/verify-vector-update.ts
 */

import { PrismaClient } from '@prisma/client';
import { writeFileSync } from 'fs';

const prisma = new PrismaClient({ log: ['error'] });

async function verify() {
    const lines: string[] = [];
    const log = (msg: string) => {
        lines.push(msg);
        console.log(msg);
    };

    log('='.repeat(60));
    log('🔬 VERIFICANDO ATUALIZAÇÃO DO VETOR DE INTERESSE');
    log('='.repeat(60));

    // 1. Pegar usuário "Simão Pedro" que tem interações
    log('\n1️⃣ Buscando usuário com interações...');

    const user = await prisma.user.findFirst({
        where: { name: { contains: 'Simão Pedro' } },
        select: { id: true, name: true }
    });

    if (!user) {
        log('❌ Usuário não encontrado');
        return;
    }

    log(`   👤 Usuário: ${user.name} (${user.id})`);

    // 2. Buscar vetor atual do usuário
    log('\n2️⃣ Vetor atual do usuário:');
    const [userVector] = await prisma.$queryRawUnsafe<any[]>(`
        SELECT 
            interest_vector[1:5]::text as preview,
            pg_column_size(interest_vector) as size_bytes
        FROM users 
        WHERE id = '${user.id}'
    `);
    log(`   Preview: ${userVector?.preview}`);
    log(`   Tamanho: ${userVector?.size_bytes} bytes`);

    // 3. Buscar os vídeos que o usuário curtiu
    log('\n3️⃣ Vídeos curtidos pelo usuário:');
    const likedVideos = await prisma.interaction.findMany({
        where: {
            userId: user.id,
            type: 'LIKE'
        },
        include: {
            video: {
                select: { id: true, title: true }
            }
        }
    });

    likedVideos.forEach((i, idx) => {
        log(`   ${idx + 1}. ${i.video.title} (${i.video.id})`);
    });

    // 4. Buscar embeddings dos vídeos curtidos
    log('\n4️⃣ Embeddings dos vídeos curtidos:');
    for (const interaction of likedVideos) {
        const [video] = await prisma.$queryRawUnsafe<any[]>(`
            SELECT 
                embedding[1:5]::text as preview,
                CASE WHEN embedding IS NOT NULL THEN 'SIM' ELSE 'NAO' END as tem_embedding
            FROM videos 
            WHERE id = '${interaction.video.id}'
        `);
        log(`   ${interaction.video.title}: ${video?.tem_embedding} ${video?.preview || ''}`);
    }

    // 5. TESTAR - Simular uma atualização manual
    log('\n5️⃣ TESTANDO atualização manual do vetor...');

    // Pegar um vídeo curtido que tenha embedding
    const videoId = likedVideos[0]?.video.id;
    if (!videoId) {
        log('   ❌ Nenhum vídeo curtido encontrado');
        await prisma.$disconnect();
        return;
    }

    // Buscar embedding do vídeo
    const [video] = await prisma.$queryRawUnsafe<any[]>(`
        SELECT embedding::text as vector FROM videos WHERE id = '${videoId}'
    `);

    if (!video?.vector) {
        log('   ❌ Vídeo não tem embedding');
        await prisma.$disconnect();
        return;
    }

    // Capturar vetor ANTES
    const [beforeUpdate] = await prisma.$queryRawUnsafe<any[]>(`
        SELECT interest_vector::text as vector FROM users WHERE id = '${user.id}'
    `);
    log(`   Vetor ANTES (hash): ${hashVector(beforeUpdate?.vector)}`);

    // Executar a mesma lógica do updateUserInterest
    const weight = 0.10;
    const oldWeight = 1 - weight;

    try {
        await prisma.$executeRawUnsafe(`
            UPDATE users 
            SET interest_vector = 
                CASE 
                    WHEN interest_vector IS NULL THEN '${video.vector}'::vector
                    ELSE (interest_vector * ${oldWeight} + '${video.vector}'::vector * ${weight})
                END
            WHERE id = '${user.id}'
        `);
        log('   ✅ Query executada com sucesso!');
    } catch (error: any) {
        log(`   ❌ ERRO na query: ${error.message}`);
        await prisma.$disconnect();
        return;
    }

    // Capturar vetor DEPOIS
    const [afterUpdate] = await prisma.$queryRawUnsafe<any[]>(`
        SELECT interest_vector::text as vector FROM users WHERE id = '${user.id}'
    `);
    log(`   Vetor DEPOIS (hash): ${hashVector(afterUpdate?.vector)}`);

    // 6. Comparar
    log('\n6️⃣ RESULTADO:');
    if (beforeUpdate?.vector === afterUpdate?.vector) {
        log('   ❌ PROBLEMA: O vetor NÃO mudou!');
        log('   Isso indica um problema na operação de vetor.');
    } else {
        log('   ✅ SUCESSO: O vetor FOI atualizado!');
        log('   A operação de vetor está funcionando corretamente.');
        log('\n   ⚠️ Se os vetores não estavam sendo atualizados antes,');
        log('   o problema pode estar no FLUXO (não está chamando a função).');
    }

    log('\n' + '='.repeat(60));

    writeFileSync('verify-output.txt', lines.join('\n'));
    console.log('\n📁 Output salvo em verify-output.txt');

    await prisma.$disconnect();
}

// Helper para criar hash de vetor (para comparação visual)
function hashVector(vector: string | null): string {
    if (!vector) return 'NULL';
    // Pegar primeiros e últimos valores
    const nums = vector.replace(/[\[\]]/g, '').split(',').map(n => parseFloat(n));
    const first3 = nums.slice(0, 3).map(n => n.toFixed(4)).join(',');
    const last3 = nums.slice(-3).map(n => n.toFixed(4)).join(',');
    return `[${first3}...${last3}]`;
}

verify().catch(console.error);
