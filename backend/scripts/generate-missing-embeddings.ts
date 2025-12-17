/**
 * Script para gerar embeddings para vídeos existentes que não têm
 * Executar: bun run scripts/generate-missing-embeddings.ts
 */

import { PrismaClient } from '@prisma/client';
import { pipeline } from '@xenova/transformers';

const prisma = new PrismaClient({ log: [] });

// AI Service inline para evitar problemas de importação
let extractor: any = null;

async function getExtractor() {
    if (!extractor) {
        console.log('🧠 Carregando modelo de IA (Xenova/all-MiniLM-L6-v2)...');
        extractor = await pipeline('feature-extraction', 'Xenova/all-MiniLM-L6-v2');
        console.log('✅ Modelo de IA carregado!\n');
    }
    return extractor;
}

async function generateEmbedding(text: string): Promise<number[]> {
    try {
        const ext = await getExtractor();
        const output = await ext(text, { pooling: 'mean', normalize: true });
        return Array.from(output.data);
    } catch (error) {
        console.error('❌ Erro na geração de embedding:', error);
        return [];
    }
}

function formatVectorForDb(vector: number[]): string {
    return `[${vector.join(',')}]`;
}

async function generateMissingEmbeddings() {
    console.log('🚀 Gerando embeddings para vídeos que não têm...\n');

    try {
        // Buscar vídeos READY sem embedding
        const videosWithoutEmbedding = await prisma.$queryRawUnsafe<any[]>(`
            SELECT id, title, description, tags
            FROM videos 
            WHERE status = 'READY' AND embedding IS NULL
        `);

        console.log(`📋 Encontrados ${videosWithoutEmbedding.length} vídeos sem embedding\n`);

        if (videosWithoutEmbedding.length === 0) {
            console.log('✅ Todos os vídeos já têm embedding!');
            return;
        }

        // Pré-carregar o modelo
        await getExtractor();

        let success = 0;
        let failed = 0;

        for (const video of videosWithoutEmbedding) {
            const textToEmbed = [
                video.title,
                video.description,
                (video.tags || []).join(' ')
            ].filter(Boolean).join(' ');

            if (!textToEmbed || textToEmbed.trim() === '') {
                console.log(`⚠️  Vídeo ${video.id}: Sem texto para gerar embedding (título/descrição vazios)`);
                failed++;
                continue;
            }

            console.log(`🔄 Processando: ${video.id}`);
            console.log(`   Texto: "${textToEmbed.substring(0, 60)}..."`);

            try {
                const vector = await generateEmbedding(textToEmbed);

                if (vector.length === 384) {
                    const vectorStr = formatVectorForDb(vector);
                    await prisma.$executeRawUnsafe(
                        `UPDATE videos SET embedding = '${vectorStr}'::vector WHERE id = '${video.id}'`
                    );
                    console.log(`   ✅ Embedding salvo (${vector.length} dimensões)`);
                    success++;
                } else {
                    console.log(`   ❌ Vetor inválido (${vector.length} dimensões)`);
                    failed++;
                }
            } catch (error) {
                console.log(`   ❌ Erro: ${error}`);
                failed++;
            }
        }

        console.log(`\n📊 RESUMO:`);
        console.log(`   ✅ Sucesso: ${success}`);
        console.log(`   ❌ Falha: ${failed}`);

    } catch (error) {
        console.error('❌ Erro durante geração:', error);
    } finally {
        await prisma.$disconnect();
    }
}

generateMissingEmbeddings();
