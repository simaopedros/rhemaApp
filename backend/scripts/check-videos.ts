import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('🔍 Verificando últimos vídeos no banco de dados...');

    const videos = await prisma.video.findMany({
        take: 5,
        orderBy: { createdAt: 'desc' },
        include: { user: true }
    });

    if (videos.length === 0) {
        console.log('❌ Nenhum vídeo encontrado no banco.');
    } else {
        console.log(`✅ Encontrados ${videos.length} vídeos recentes:`);
        videos.forEach(v => {
            console.log(`\n📹 ID: ${v.id}`);
            console.log(`   Título: ${v.title}`);
            console.log(`   Type: ${v.type}`);
            console.log(`   Status: ${v.status}`);
            console.log(`   URL: ${v.videoUrl}`);
            console.log(`   Criado em: ${v.createdAt.toLocaleString()}`);
            console.log(`   Usuário: ${v.user?.name} (${v.userId})`);
        });
    }
}

main()
    .catch(e => console.error(e))
    .finally(async () => await prisma.$disconnect());
