import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const API_KEY = process.env.BUNNY_API_KEY;
const LIBRARY_ID = process.env.BUNNY_LIBRARY_ID;

async function main() {
    // Pegar o último vídeo enviado
    const video = await prisma.video.findFirst({
        orderBy: { createdAt: 'desc' },
    });

    if (!video) {
        console.log('Nenhum vídeo encontrado no banco.');
        return;
    }

    console.log(`🎥 Verificando status no Bunny para o vídeo: ${video.title}`);
    console.log(`🆔 Bunny ID: ${video.bunnyVideoId}`);

    const url = `https://video.bunnycdn.com/library/${LIBRARY_ID}/videos/${video.bunnyVideoId}`;

    try {
        const response = await fetch(url, {
            method: 'GET',
            headers: {
                'AccessKey': API_KEY || '',
                'Accept': 'application/json',
            },
        });

        if (!response.ok) {
            console.error(`❌ Erro na API Bunny: ${response.status} ${response.statusText}`);
            const text = await response.text();
            console.error(text);
            return;
        }

        const data = await response.json();
        console.log('\n📊 Status do Vídeo no Bunny:');
        console.log(`   Status: ${data.status} (0=Created, 1=Uploaded, 2=Processing, 3=Transcoding, 4=Finished, 5=Error, 6=UploadFailed)`);
        console.log(`   Encode Progress: ${data.encodeProgress}%`);
        console.log(`   Storage Size: ${(data.storageSize / 1024 / 1024).toFixed(2)} MB`);
        console.log(`   Has MP4 Fallback: ${data.hasMP4Fallback}`);

        if (data.status !== 4) {
            console.log('\n⚠️ O vídeo ainda não está pronto para reprodução via stream!');
        } else {
            console.log('\n✅ Vídeo pronto para streaming!');
        }

    } catch (error) {
        console.error('Erro ao conectar com Bunny:', error);
    }
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
