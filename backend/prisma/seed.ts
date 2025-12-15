import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('Iniciando seed...');

    // Limpar dados existentes
    await prisma.video.deleteMany();
    await prisma.user.deleteMany();

    // Criar Usuários (Evangélicos e Católicos)
    const user1 = await prisma.user.create({
        data: {
            email: 'padre.marcelo@exemplo.com',
            name: 'Padre Marcelo',
            handle: '@padremarcelo',
            avatar: 'https://i.pravatar.cc/200?img=1',
            bio: 'Sacerdote católico, cantor e escritor. Evangelizando através da música.',
            isVerified: true,
            followersCount: 50000,
        }
    });

    const user2 = await prisma.user.create({
        data: {
            email: 'aline.barros@exemplo.com',
            name: 'Aline Barros',
            handle: '@alinebarros',
            avatar: 'https://i.pravatar.cc/200?img=5',
            bio: 'Cantora de música cristã contemporânea.',
            isVerified: true,
            followersCount: 120000,
        }
    });

    const user3 = await prisma.user.create({
        data: {
            email: 'papa.francisco@exemplo.com',
            name: 'Papa Francisco',
            handle: '@pontifex_br',
            avatar: 'https://i.pravatar.cc/200?img=3',
            bio: 'Bispo de Roma.',
            isVerified: true,
            followersCount: 5000000,
        }
    });

    const user4 = await prisma.user.create({
        data: {
            email: 'deive.leonardo@exemplo.com',
            name: 'Deive Leonardo',
            handle: '@deiveleonardo',
            avatar: 'https://i.pravatar.cc/200?img=8',
            bio: 'Evangelista.',
            isVerified: true,
            followersCount: 800000,
        }
    });

    const user5 = await prisma.user.create({
        data: {
            email: 'comunidade.shalom@exemplo.com',
            name: 'Comunidade Shalom',
            handle: '@comshalom',
            avatar: 'https://i.pravatar.cc/200?img=12',
            bio: 'Comunidade Católica Shalom.',
            isVerified: true,
            followersCount: 300000,
        }
    });

    // Criar Vídeos (Shorts) - URLs de vídeos que funcionam

    // 1. Católico - Padre
    await prisma.video.create({
        data: {
            userId: user1.id,
            title: 'Benção do Dia',
            description: 'Que a paz de Cristo esteja em seus corações hoje e sempre. Amém! 🙏🕊️ #catolico #fé #benção',
            videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
            thumbnailUrl: 'https://picsum.photos/seed/v1/400/600',
            duration: 45,
            status: 'READY',
            type: 'SHORT',
            tags: ['catolico', 'oração', 'benção'],
            likesCount: 1540,
            commentsCount: 120,
            sharesCount: 500,
            viewsCount: 12000,
        }
    });

    // 2. Evangélico - Louvor
    await prisma.video.create({
        data: {
            userId: user2.id,
            title: 'Ressuscita-me - Ao Vivo',
            description: 'Um momento de adoração profunda. Nada é impossível para o nosso Deus! ✨🙌 #louvor #adoração #milagre',
            videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
            thumbnailUrl: 'https://picsum.photos/seed/v2/400/600',
            duration: 58,
            status: 'READY',
            type: 'SHORT',
            tags: ['louvor', 'musica', 'evangelico'],
            likesCount: 3200,
            commentsCount: 450,
            sharesCount: 1200,
            viewsCount: 45000,
        }
    });

    // 3. Católico - Papa/Vaticano
    await prisma.video.create({
        data: {
            userId: user3.id,
            title: 'Angelus no Vaticano',
            description: 'Uma mensagem de esperança para todos os povos. O amor vence o ódio. 🇻🇦❤️ #vaticano #papa #igreja',
            videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
            thumbnailUrl: 'https://picsum.photos/seed/v3/400/600',
            duration: 60,
            status: 'READY',
            type: 'SHORT',
            tags: ['papa', 'vaticano', 'catolico'],
            likesCount: 50000,
            commentsCount: 2000,
            sharesCount: 15000,
            viewsCount: 200000,
        }
    });

    // 4. Evangélico - Pregação
    await prisma.video.create({
        data: {
            userId: user4.id,
            title: 'Não desista agora!',
            description: 'A sua vitória está mais perto do que você imagina. Escute essa palavra! 🔥📖 #pregação #motivação #fé',
            videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
            thumbnailUrl: 'https://picsum.photos/seed/v4/400/600',
            duration: 55,
            status: 'READY',
            type: 'SHORT',
            tags: ['pregação', 'palavra', 'evangelico'],
            likesCount: 8900,
            commentsCount: 340,
            sharesCount: 2100,
            viewsCount: 78000,
        }
    });

    // 5. Católico - Jovem/Shalom
    await prisma.video.create({
        data: {
            userId: user5.id,
            title: 'Acampamento de Jovens',
            description: 'A alegria de ser de Deus! Juventude santa! ⛺🔥🎸 #shalom #juventude #catolico',
            videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
            thumbnailUrl: 'https://picsum.photos/seed/v5/400/600',
            duration: 30,
            status: 'READY',
            type: 'SHORT',
            tags: ['jovens', 'acampamento', 'alegria'],
            likesCount: 4100,
            commentsCount: 230,
            sharesCount: 400,
            viewsCount: 22000,
        }
    });

    console.log('Seed finalizado com sucesso! (Dados Católicos e Evangélicos inseridos)');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
