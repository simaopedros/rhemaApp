/**
 * Webhooks Routes
 * Endpoints para receber callbacks de serviços externos (Bunny.net, etc.)
 */

import { Elysia, t } from 'elysia';
import prisma from '../lib/prisma';
import { bunnyService } from '../services/bunny';
import { aiService } from '../services/ai';

// Status codes do Bunny.net Stream
const BUNNY_STATUS = {
    QUEUED: 0,
    PROCESSING: 1,
    ENCODING: 2,
    FINISHED: 3,
    RESOLUTION_FINISHED: 4,
    FAILED: 5,
    PRESIGNED_UPLOAD_STARTED: 6,
    PRESIGNED_UPLOAD_FINISHED: 7,
    PRESIGNED_UPLOAD_FAILED: 8,
    CAPTIONS_GENERATED: 9,
    TITLE_DESCRIPTION_GENERATED: 10,
};

export const webhooksRoutes = new Elysia({ prefix: '/webhooks' })

    /**
     * Webhook do Bunny.net Stream
     * Chamado automaticamente quando o status de um vídeo muda
     */
    .post('/bunny', async ({ body, set }) => {
        const { VideoLibraryId, VideoGuid, Status } = body;

        console.log('📬 Webhook Bunny.net recebido:', { VideoLibraryId, VideoGuid, Status });

        try {
            // Buscar o vídeo no banco pelo bunnyVideoId
            const video = await prisma.video.findFirst({
                where: { bunnyVideoId: VideoGuid },
            });

            if (!video) {
                console.warn(`⚠️ Vídeo não encontrado para bunnyVideoId: ${VideoGuid}`);
                // Retornar 200 para não causar retries desnecessários
                return { success: true, message: 'Video not found in database' };
            }

            // Processar baseado no status
            switch (Status) {
                case BUNNY_STATUS.FINISHED:
                case BUNNY_STATUS.RESOLUTION_FINISHED:
                    console.log(`✅ Vídeo ${VideoGuid} terminou de processar!`);

                    // Buscar informações atualizadas do vídeo
                    const bunnyInfo = await bunnyService.getVideoInfo(VideoGuid);

                    // Atualizar o vídeo no banco
                    await prisma.video.update({
                        where: { id: video.id },
                        data: {
                            status: 'READY',
                            videoUrl: bunnyService.getMp4Url(VideoGuid),
                            hlsUrl: bunnyService.getHlsUrl(VideoGuid),
                            thumbnailUrl: bunnyService.getThumbnailUrl(VideoGuid),
                            duration: Math.floor(bunnyInfo.length || 0),
                        },
                    });

                    // Gerar embedding para o vídeo (para recomendações)
                    const textToEmbed = [
                        video.title,
                        video.description,
                        (video.tags || []).join(' ')
                    ].filter(Boolean).join(' ');

                    if (textToEmbed) {
                        try {
                            const vector = await aiService.generateEmbedding(textToEmbed);
                            if (vector.length > 0) {
                                const vectorStr = aiService.formatVectorForDb(vector);
                                await prisma.$executeRawUnsafe(
                                    `UPDATE videos SET embedding = '${vectorStr}'::vector WHERE id = '${video.id}'`
                                );
                                console.log('✅ Embedding gerado para vídeo:', video.id);
                            }
                        } catch (e) {
                            console.error('❌ Erro ao gerar embedding:', e);
                        }
                    }

                    console.log(`✅ Vídeo ${video.id} atualizado para READY`);
                    break;

                case BUNNY_STATUS.FAILED:
                case BUNNY_STATUS.PRESIGNED_UPLOAD_FAILED:
                    console.error(`❌ Vídeo ${VideoGuid} falhou no processamento`);

                    await prisma.video.update({
                        where: { id: video.id },
                        data: {
                            status: 'FAILED',
                        },
                    });
                    break;

                case BUNNY_STATUS.PROCESSING:
                case BUNNY_STATUS.ENCODING:
                    console.log(`⏳ Vídeo ${VideoGuid} está processando...`);

                    await prisma.video.update({
                        where: { id: video.id },
                        data: {
                            status: 'PROCESSING',
                        },
                    });
                    break;

                case BUNNY_STATUS.CAPTIONS_GENERATED:
                    console.log(`📝 Legendas geradas para vídeo ${VideoGuid}`);
                    // Podemos buscar as legendas e salvar no banco se necessário
                    break;

                case BUNNY_STATUS.TITLE_DESCRIPTION_GENERATED:
                    console.log(`📋 Título/Descrição auto-gerados para vídeo ${VideoGuid}`);
                    // Bunny pode gerar título/descrição automaticamente
                    break;

                default:
                    console.log(`ℹ️ Status ${Status} não tratado para vídeo ${VideoGuid}`);
            }

            return { success: true };

        } catch (error) {
            console.error('❌ Erro ao processar webhook Bunny:', error);
            set.status = 500;
            return { success: false, error: 'Internal server error' };
        }
    }, {
        body: t.Object({
            VideoLibraryId: t.Number(),
            VideoGuid: t.String(),
            Status: t.Number(),
        }),
    })

    /**
     * Endpoint para verificar se webhooks estão funcionando
     */
    .get('/health', () => {
        return {
            success: true,
            message: 'Webhooks endpoint is healthy',
            timestamp: new Date().toISOString(),
        };
    });
