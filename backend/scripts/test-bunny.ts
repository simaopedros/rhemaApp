/**
 * Script de Teste - Bunny.net Integration
 * Testa a conexão e criação de vídeos na Bunny.net
 */

const BUNNY_API_KEY = process.env.BUNNY_API_KEY || '98d86f06-e22e-4aeb-9e546c0ab558-cbe3-4bd0';
const BUNNY_LIBRARY_ID = process.env.BUNNY_LIBRARY_ID || '563955';
const BUNNY_CDN_URL = process.env.BUNNY_CDN_URL || 'vz-2322c3c2-fde.b-cdn.net';

async function testBunnyConnection() {
    console.log('🐰 Testando conexão com Bunny.net Stream...\n');
    console.log(`   Library ID: ${BUNNY_LIBRARY_ID}`);
    console.log(`   CDN URL: ${BUNNY_CDN_URL}`);
    console.log('');

    try {
        // 1. Listar vídeos existentes
        console.log('📋 Listando vídeos existentes...');
        const listResponse = await fetch(
            `https://video.bunnycdn.com/library/${BUNNY_LIBRARY_ID}/videos?page=1&itemsPerPage=5`,
            {
                headers: { 'AccessKey': BUNNY_API_KEY },
            }
        );

        if (!listResponse.ok) {
            throw new Error(`Falha ao listar vídeos: ${listResponse.status} ${await listResponse.text()}`);
        }

        const listData = await listResponse.json();
        console.log(`   ✅ Conexão OK! ${listData.totalItems || 0} vídeos na biblioteca.`);

        if (listData.items && listData.items.length > 0) {
            console.log('\n   Últimos vídeos:');
            for (const video of listData.items.slice(0, 3)) {
                console.log(`   - ${video.title} (${video.guid}) - Status: ${video.status}`);
            }
        }

        // 2. Criar um vídeo de teste
        console.log('\n📝 Criando vídeo de teste...');
        const createResponse = await fetch(
            `https://video.bunnycdn.com/library/${BUNNY_LIBRARY_ID}/videos`,
            {
                method: 'POST',
                headers: {
                    'AccessKey': BUNNY_API_KEY,
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    title: `Teste RHEMA - ${new Date().toISOString()}`,
                }),
            }
        );

        if (!createResponse.ok) {
            throw new Error(`Falha ao criar vídeo: ${createResponse.status} ${await createResponse.text()}`);
        }

        const createData = await createResponse.json();
        console.log(`   ✅ Vídeo criado com sucesso!`);
        console.log(`   ID: ${createData.guid}`);
        console.log(`   Título: ${createData.title}`);

        // 3. Gerar URLs de exemplo
        console.log('\n🔗 URLs de exemplo para este vídeo:');
        console.log(`   HLS: https://${BUNNY_CDN_URL}/${createData.guid}/playlist.m3u8`);
        console.log(`   MP4: https://${BUNNY_CDN_URL}/${createData.guid}/play_720p.mp4`);
        console.log(`   Thumb: https://${BUNNY_CDN_URL}/${createData.guid}/thumbnail.jpg`);

        // 4. Deletar vídeo de teste
        console.log('\n🗑️ Limpando vídeo de teste...');
        const deleteResponse = await fetch(
            `https://video.bunnycdn.com/library/${BUNNY_LIBRARY_ID}/videos/${createData.guid}`,
            {
                method: 'DELETE',
                headers: { 'AccessKey': BUNNY_API_KEY },
            }
        );

        if (deleteResponse.ok) {
            console.log('   ✅ Vídeo de teste deletado.');
        }

        console.log('\n✨ Todos os testes passaram! A integração com Bunny.net está funcionando.');

    } catch (error) {
        console.error('\n❌ Erro no teste:', error);
        process.exit(1);
    }
}

testBunnyConnection();
