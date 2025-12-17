/**
 * Script simples para testar atualização de vetor usando AVG()
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function test() {
    console.log('🧪 Teste de atualização de vetor (usando AVG)\n');

    // 1. Buscar um usuário
    const user = await prisma.user.findFirst({ where: { name: { contains: 'Simão' } } });
    console.log('👤 Usuário:', user?.name, user?.id);

    // 2. Buscar um vídeo com embedding
    const [video] = await prisma.$queryRawUnsafe<any[]>(`
        SELECT id, title, embedding::text as emb 
        FROM videos 
        WHERE embedding IS NOT NULL 
        LIMIT 1
    `);
    console.log('🎥 Vídeo:', video?.title, video?.id);
    console.log('   Embedding existe:', video?.emb ? 'SIM' : 'NAO');

    if (!user || !video?.emb) {
        console.log('❌ Falta dados para teste');
        await prisma.$disconnect();
        return;
    }

    // 3. Buscar vetor atual do usuário
    const [before] = await prisma.$queryRawUnsafe<any[]>(`
        SELECT interest_vector::text as vec FROM users WHERE id = '${user.id}'
    `);
    const beforeFirst = before?.vec?.substring(0, 50);
    console.log('\n📊 Vetor ANTES:', beforeFirst);

    // 4. Atualizar usando AVG() (peso 10% = 9 antigo + 1 novo)
    console.log('\n🔄 Executando UPDATE com AVG()...');
    const weight = 0.10;
    const repetitionsOld = Math.round((1 - weight) * 10); // 9
    const repetitionsNew = Math.round(weight * 10); // 1

    const oldVectors = Array(repetitionsOld).fill(`SELECT '${before.vec}'::vector as v`);
    const newVectors = Array(repetitionsNew).fill(`SELECT '${video.emb}'::vector as v`);
    const allVectors = [...oldVectors, ...newVectors].join(' UNION ALL ');

    try {
        await prisma.$executeRawUnsafe(`
            UPDATE users 
            SET interest_vector = (SELECT AVG(v) FROM (${allVectors}) sub)
            WHERE id = '${user.id}'
        `);
        console.log('✅ Query executada com sucesso!');
    } catch (e: any) {
        console.log('❌ Erro:', e.message);
        await prisma.$disconnect();
        return;
    }

    // 5. Verificar depois
    const [after] = await prisma.$queryRawUnsafe<any[]>(`
        SELECT interest_vector::text as vec FROM users WHERE id = '${user.id}'
    `);
    const afterFirst = after?.vec?.substring(0, 50);
    console.log('📊 Vetor DEPOIS:', afterFirst);

    // 6. Resultado
    console.log('\n' + '='.repeat(50));
    if (beforeFirst === afterFirst) {
        console.log('❌ VETOR NÃO MUDOU - Há um problema!');
    } else {
        console.log('✅ VETOR FOI ATUALIZADO - Operação OK!');
    }

    await prisma.$disconnect();
}

test().catch(e => {
    console.error('❌ ERRO:', e.message);
    process.exit(1);
});
