/**
 * Script para testar se a atualização do vetor de interesse está funcionando
 * Executar: bun run scripts/test-interest-update.ts
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({ log: ['error'] });

// Helper para log síncrono
const log = (msg: string) => {
    console.log(msg);
    // Force flush
};

async function testInterestUpdate() {
    log('🧪 Testando atualização do vetor de interesse...\n');

    try {
        // 1. Buscar um usuário com vetor
        const [user] = await prisma.$queryRawUnsafe<any[]>(`
            SELECT id, name, interest_vector::text as vector 
            FROM users 
            WHERE interest_vector IS NOT NULL 
            LIMIT 1
        `);

        if (!user) {
            console.log('❌ Nenhum usuário com vetor encontrado');
            return;
        }

        console.log(`👤 Usuário: ${user.name} (${user.id})`);
        console.log(`   Vetor atual (primeiros 5 valores): ${user.vector?.substring(0, 100)}...`);

        // 2. Buscar um vídeo com embedding
        const [video] = await prisma.$queryRawUnsafe<any[]>(`
            SELECT id, title, embedding::text as vector 
            FROM videos 
            WHERE embedding IS NOT NULL 
            LIMIT 1
        `);

        if (!video) {
            console.log('❌ Nenhum vídeo com embedding encontrado');
            return;
        }

        console.log(`\n🎥 Vídeo: ${video.title} (${video.id})`);
        console.log(`   Embedding (primeiros 5 valores): ${video.vector?.substring(0, 100)}...`);

        // 3. Simular uma interação (LIKE) - peso 10%
        console.log('\n🔄 Simulando LIKE (peso 10%)...');

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
            console.log('✅ Query executada com sucesso!');
        } catch (error) {
            console.log('❌ Erro na query:', error);
            return;
        }

        // 4. Verificar se o vetor mudou
        const [updatedUser] = await prisma.$queryRawUnsafe<any[]>(`
            SELECT interest_vector::text as vector 
            FROM users 
            WHERE id = '${user.id}'
        `);

        console.log(`\n📊 Vetor após atualização:`);
        console.log(`   Novo vetor (primeiros 5 valores): ${updatedUser.vector?.substring(0, 100)}...`);

        // 5. Comparar
        if (user.vector === updatedUser.vector) {
            console.log('\n⚠️ PROBLEMA: O vetor NÃO mudou!');
        } else {
            console.log('\n✅ SUCESSO: O vetor FOI atualizado!');
        }

        // 6. Verificar interações existentes
        console.log('\n📋 Verificando interações registradas...');
        const interactions = await prisma.interaction.findMany({
            take: 10,
            orderBy: { createdAt: 'desc' },
            include: {
                user: { select: { name: true } },
                video: { select: { title: true } }
            }
        });

        if (interactions.length === 0) {
            console.log('   ⚠️ Nenhuma interação encontrada no banco!');
            console.log('   Isso explica por que os vetores não estão sendo atualizados.');
        } else {
            console.log(`   Encontradas ${interactions.length} interações:`);
            interactions.forEach((i, idx) => {
                console.log(`   ${idx + 1}. ${i.type}: ${i.user.name} → ${i.video.title || '(sem título)'}`);
            });
        }

    } catch (error) {
        console.error('❌ Erro durante teste:', error);
    } finally {
        await prisma.$disconnect();
    }
}

testInterestUpdate();
