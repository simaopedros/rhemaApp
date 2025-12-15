/**
 * Video Upload & Processing Routes
 * Endpoints para upload de vídeos e disparo de processamento automático
 */

import { Elysia, t } from 'elysia';
import { PrismaClient } from '@prisma/client';
import { bunnyService } from '../services/bunny';
import { aiService } from '../services/ai';

const prisma = new PrismaClient();

export const videosRoutes = new Elysia({ prefix: '/videos' })
    // ============================================
    // UPLOAD
    // ============================================

    /**
     * Cria um novo vídeo e retorna URL de upload direto
     * O cliente faz upload diretamente para Bunny.net (TUS protocol)
     */
    /**
     * Upload de vídeo direto (Proxy)
     * Recebe o arquivo e envia para o Bunny.net
     */
    .post('/upload', async ({ body, set }) => {
        // MVP: Usar primeiro usuário disponível
        const defaultUser = await prisma.user.findFirst();
        const userId = defaultUser?.id;

        if (!userId) {
            set.status = 401;
            return { success: false, error: 'Nenhum usuário configurado' };
        }

        const { title, description, tags, type, file } = body;

        try {
            console.log('📦 Iniciando upload...', { title, size: file.size, type: file.type });

            // 1. Criar vídeo na Bunny.net
            const bunnyVideo = await bunnyService.createVideo(title || 'Sem título');
            console.log('✅ Vídeo criado no Bunny:', bunnyVideo.guid);

            // 2. Fazer upload do arquivo binário para o Bunny
            // Converter File para ArrayBuffer e depois Uint8Array
            const arrayBuffer = await file.arrayBuffer();
            const buffer = new Uint8Array(arrayBuffer);

            await bunnyService.uploadVideo(bunnyVideo.guid, buffer);
            console.log('✅ Arquivo enviado para o Bunny');

            // 3. Criar registro no banco de dados
            const video = await prisma.video.create({
                data: {
                    userId,
                    type: type === 'LONG' ? 'LONG' : 'SHORT',
                    status: 'READY', // Assume pronto após upload direto (ou PROCESSING se o Bunny demorar)
                    bunnyVideoId: bunnyVideo.guid,
                    title: title || null,
                    description: description || null,
                    tags: tags ? JSON.parse(tags) : [], // Tags vem como string no multipart
                    videoUrl: `https://${process.env.BUNNY_CDN_URL}/${bunnyVideo.guid}/playlist.m3u8`, // URL simulada HLS
                    thumbnailUrl: `https://${process.env.BUNNY_CDN_URL}/${bunnyVideo.guid}/thumbnail.jpg`,
                },
            });

            return {
                success: true,
                video,
            };

        } catch (error) {
            console.error('❌ Erro no upload:', error);
            set.status = 500;
            return { success: false, error: 'Falha ao processar upload' };
        }
    }, {
        body: t.Object({
            title: t.Optional(t.String()),
            description: t.Optional(t.String()),
            tags: t.Optional(t.String()), // FormData envia arrays como string json ou multiplos campos, vamos simplificar json string
            type: t.Optional(t.String()), // 'SHORT' | 'LONG'
            file: t.File(),
        }),
    })

    /**
     * Confirma que o upload foi concluído
     */
    .post('/upload/:videoId/complete', async ({ params, body, set }) => {
        const { videoId } = params;
        const { autoProcess } = body;

        try {
            const video = await prisma.video.findUnique({
                where: { id: videoId },
            });

            if (!video) {
                set.status = 404;
                return { success: false, error: 'Vídeo não encontrado' };
            }

            if (!video.bunnyVideoId) {
                set.status = 400;
                return { success: false, error: 'Vídeo sem ID Bunny' };
            }

            const bunnyInfo = await bunnyService.getVideoInfo(video.bunnyVideoId);

            const updatedVideo = await prisma.video.update({
                where: { id: videoId },
                data: {
                    status: bunnyInfo.status === 4 ? 'READY' : 'PROCESSING',
                    videoUrl: bunnyService.getMp4Url(video.bunnyVideoId),
                    thumbnailUrl: bunnyService.getThumbnailUrl(video.bunnyVideoId),
                    hlsUrl: bunnyService.getHlsUrl(video.bunnyVideoId),
                    duration: Math.floor(bunnyInfo.length),
                },
            });

            if (video.type === 'LONG' && autoProcess) {
                await prisma.videoProcessingJob.create({
                    data: {
                        videoId: video.id,
                        status: 'PENDING',
                    },
                });

                return {
                    success: true,
                    video: updatedVideo,
                    processing: {
                        queued: true,
                        message: 'Vídeo na fila para geração automática de Shorts',
                    },
                };
            }

            // ----------------------------------------------------
            // Geração de Embedding (Recomendação)
            // ----------------------------------------------------
            const textToEmbed = [
                video.title,
                video.description,
                (video.tags || []).join(' ')
            ].filter(Boolean).join(' ');

            if (textToEmbed) {
                // Executar em background para não bloquear response
                aiService.generateEmbedding(textToEmbed).then(async (vector) => {
                    if (vector.length > 0) {
                        const vectorStr = aiService.formatVectorForDb(vector);
                        await prisma.$executeRawUnsafe(
                            `UPDATE videos SET embedding = '${vectorStr}'::vector WHERE id = '${video.id}'`
                        ).catch(e => console.error('Erro ao salvar embedding:', e));
                        console.log('✅ Embedding gerado e salvo para vídeo:', videoId);
                    }
                });
            }

            return { success: true, video: updatedVideo };

        } catch (error) {
            console.error('Erro ao completar upload:', error);
            set.status = 500;
            return { success: false, error: 'Falha ao processar upload' };
        }
    }, {
        params: t.Object({ videoId: t.String() }),
        body: t.Object({ autoProcess: t.Optional(t.Boolean()) }),
    })

    // ============================================
    // PROCESSAMENTO
    // ============================================

    .post('/process/:videoId', async ({ params, set }) => {
        const { videoId } = params;

        try {
            const video = await prisma.video.findUnique({
                where: { id: videoId },
            });

            if (!video) {
                set.status = 404;
                return { success: false, error: 'Vídeo não encontrado' };
            }

            if (video.type !== 'LONG') {
                set.status = 400;
                return { success: false, error: 'Apenas vídeos longos podem ser processados' };
            }

            const existingJob = await prisma.videoProcessingJob.findFirst({
                where: {
                    videoId,
                    status: { in: ['PENDING', 'PROCESSING'] },
                },
            });

            if (existingJob) {
                return { success: true, job: existingJob, message: 'Job já existe' };
            }

            const job = await prisma.videoProcessingJob.create({
                data: { videoId, status: 'PENDING' },
            });

            return { success: true, job, message: 'Processamento iniciado' };

        } catch (error) {
            console.error('Erro ao iniciar processamento:', error);
            set.status = 500;
            return { success: false, error: 'Falha ao iniciar processamento' };
        }
    }, {
        params: t.Object({ videoId: t.String() }),
    })

    .get('/process/:videoId/status', async ({ params, set }) => {
        const { videoId } = params;

        try {
            const job = await prisma.videoProcessingJob.findFirst({
                where: { videoId },
                orderBy: { createdAt: 'desc' },
            });

            if (!job) {
                return { success: true, status: 'NOT_STARTED', progress: 0 };
            }

            const clips = await prisma.video.findMany({
                where: { parentVideoId: videoId },
                select: {
                    id: true,
                    title: true,
                    thumbnailUrl: true,
                    duration: true,
                    status: true,
                },
            });

            return {
                success: true,
                job: {
                    id: job.id,
                    status: job.status,
                    progress: job.progress,
                    error: job.errorMessage,
                    startedAt: job.startedAt,
                    completedAt: job.completedAt,
                },
                clips,
            };

        } catch (error) {
            set.status = 500;
            return { success: false, error: 'Falha ao obter status' };
        }
    }, {
        params: t.Object({ videoId: t.String() }),
    })

    // ============================================
    // DETALHES
    // ============================================

    .get('/:videoId', async ({ params, set }) => {
        const { videoId } = params;

        try {
            const video = await prisma.video.findUnique({
                where: { id: videoId },
                include: {
                    user: {
                        select: {
                            id: true,
                            name: true,
                            handle: true,
                            avatar: true,
                            isVerified: true,
                        },
                    },
                    clips: {
                        select: {
                            id: true,
                            title: true,
                            thumbnailUrl: true,
                            duration: true,
                        },
                    },
                },
            });

            if (!video) {
                set.status = 404;
                return { success: false, error: 'Vídeo não encontrado' };
            }

            return { success: true, video };

        } catch (error) {
            set.status = 500;
            return { success: false, error: 'Falha ao buscar vídeo' };
        }
    }, {
        params: t.Object({ videoId: t.String() }),
    });
