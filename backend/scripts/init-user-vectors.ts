/**
 * Script para inicializar vetores de interesse dos usuários (Cold Start)
 * Calcula a média dos embeddings dos vídeos existentes para dar um ponto de partida
 * 
 * Executar: bun run scripts/init-user-vectors.ts
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({ log: [] });

async function initUserVectors() {
    console.log('🚀 Inicializando vetores de interesse dos usuários...\n');

    try {
        // Buscar usuários sem vetor de interesse
        const usersWithoutVector = await prisma.$queryRawUnsafe<any[]>(`
            SELECT id, name, handle FROM users WHERE interest_vector IS NULL
        `);

        console.log(`👤 Encontrados ${usersWithoutVector.length} usuários sem vetor\n`);

        if (usersWithoutVector.length === 0) {
            console.log('✅ Todos os usuários já têm vetor de interesse!');
            return;
        }

        // Calcular vetor médio de todos os vídeos (cold start universal)
        // Isso dá a cada novo usuário um ponto de partida neutro
        console.log('📊 Calculando vetor médio dos vídeos...');
        const [avgVector] = await prisma.$queryRawUnsafe<any[]>(`
            SELECT AVG(embedding)::text as avg_vector 
            FROM videos 
            WHERE embedding IS NOT NULL
        `);

        if (!avgVector?.avg_vector) {
            console.log('❌ Nenhum vídeo com embedding encontrado. Execute primeiro:');
            console.log('   bun run scripts/generate-missing-embeddings.ts');
            return;
        }

        console.log('✅ Vetor médio calculado\n');

        // Atualizar cada usuário
        let success = 0;
        for (const user of usersWithoutVector) {
            try {
                await prisma.$executeRawUnsafe(`
                    UPDATE users 
                    SET interest_vector = '${avgVector.avg_vector}'::vector 
                    WHERE id = '${user.id}'
                `);
                console.log(`✅ ${user.name || user.handle} - vetor inicializado`);
                success++;
            } catch (error) {
                console.log(`❌ ${user.name || user.handle} - erro: ${error}`);
            }
        }

        console.log(`\n📊 RESUMO:`);
        console.log(`   ✅ Usuários atualizados: ${success}`);
        console.log(`   📝 Nota: Os vetores serão personalizados conforme os usuários interagem`);

    } catch (error) {
        console.error('❌ Erro durante inicialização:', error);
    } finally {
        await prisma.$disconnect();
    }
}

initUserVectors();
