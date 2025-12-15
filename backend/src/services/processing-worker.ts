/**
 * Video Processing Queue Worker
 * Gerencia a fila de processamento de vídeos usando um sistema simples baseado em DB
 * (Em produção, pode ser substituído por BullMQ + Redis)
 */

import { PrismaClient } from '@prisma/client';
import { videoProcessor } from './video-processor';
import { bunnyService } from './bunny';

const prisma = new PrismaClient();

class VideoProcessingWorker {
    private isRunning = false;
    private pollInterval = 5000; // 5 segundos

    /**
     * Inicia o worker de processamento
     */
    async start() {
        if (this.isRunning) {
            console.log('⚠️ Worker já está rodando');
            return;
        }

        this.isRunning = true;
        console.log('🚀 Video Processing Worker iniciado');

        while (this.isRunning) {
            try {
                await this.processNextJob();
            } catch (error) {
                console.error('❌ Erro no worker:', error);
            }

            await this.sleep(this.pollInterval);
        }
    }

    /**
     * Para o worker
     */
    stop() {
        this.isRunning = false;
        console.log('⏹️ Video Processing Worker parado');
    }

    /**
     * Processa o próximo job na fila
     */
    private async processNextJob() {
        // Buscar próximo job pendente
        const job = await prisma.videoProcessingJob.findFirst({
            where: { status: 'PENDING' },
            orderBy: { createdAt: 'asc' },
        });

        if (!job) {
            return; // Sem jobs na fila
        }

        console.log(`📦 Processando job ${job.id} (video: ${job.videoId})`);

        // Atualizar status para PROCESSING
        await prisma.videoProcessingJob.update({
            where: { id: job.id },
            data: {
                status: 'PROCESSING',
                startedAt: new Date(),
            },
        });

        // Atualizar status do vídeo
        await prisma.video.update({
            where: { id: job.videoId },
            data: { status: 'PROCESSING' },
        });

        try {
            // Buscar informações do vídeo
            const video = await prisma.video.findUnique({
                where: { id: job.videoId },
                include: { user: true },
            });

            if (!video || !video.bunnyVideoId) {
                throw new Error('Vídeo não encontrado ou sem ID Bunny');
            }

            // Processar vídeo (gerar clipes)
            const result = await videoProcessor.processVideo(job.videoId, video.bunnyVideoId);

            if (!result.success) {
                throw new Error(result.error || 'Falha no processamento');
            }

            // Upload de cada clipe gerado
            let clipsCreated = 0;
            for (const clip of result.clips) {
                try {
                    // Ler arquivo do clipe
                    const clipFile = Bun.file(clip.path);
                    const clipBuffer = Buffer.from(await clipFile.arrayBuffer());

                    // Criar vídeo na Bunny.net
                    const bunnyVideo = await bunnyService.createVideo(
                        `${video.title || 'Short'} - Parte ${clipsCreated + 1}`
                    );

                    // Upload do clipe
                    await bunnyService.uploadVideo(bunnyVideo.guid, clipBuffer);

                    // Aguardar processamento na Bunny.net
                    await bunnyService.waitForProcessing(bunnyVideo.guid);

                    // Salvar clipe no banco de dados
                    await prisma.video.create({
                        data: {
                            userId: video.userId,
                            type: 'SHORT',
                            status: 'READY',
                            bunnyVideoId: bunnyVideo.guid,
                            videoUrl: bunnyService.getMp4Url(bunnyVideo.guid),
                            thumbnailUrl: bunnyService.getThumbnailUrl(bunnyVideo.guid),
                            hlsUrl: bunnyService.getHlsUrl(bunnyVideo.guid),
                            title: `${video.title || 'Short'} - Parte ${clipsCreated + 1}`,
                            description: video.description,
                            tags: video.tags,
                            duration: Math.floor(clip.duration),
                            parentVideoId: video.id,
                        },
                    });

                    clipsCreated++;

                    // Atualizar progresso
                    const progress = Math.floor((clipsCreated / result.clips.length) * 100);
                    await prisma.videoProcessingJob.update({
                        where: { id: job.id },
                        data: { progress },
                    });

                } catch (clipError) {
                    console.error(`❌ Erro ao processar clipe:`, clipError);
                    // Continua com os próximos clipes
                }
            }

            // Limpar arquivos temporários
            await videoProcessor.cleanup(job.videoId);

            // Marcar job como concluído
            await prisma.videoProcessingJob.update({
                where: { id: job.id },
                data: {
                    status: 'COMPLETED',
                    progress: 100,
                    completedAt: new Date(),
                },
            });

            // Atualizar vídeo original
            await prisma.video.update({
                where: { id: job.videoId },
                data: { status: 'READY' },
            });

            console.log(`✅ Job ${job.id} concluído! ${clipsCreated} clipes gerados.`);

        } catch (error) {
            console.error(`❌ Falha no job ${job.id}:`, error);

            // Marcar job como falho
            await prisma.videoProcessingJob.update({
                where: { id: job.id },
                data: {
                    status: 'FAILED',
                    errorMessage: error instanceof Error ? error.message : 'Unknown error',
                    completedAt: new Date(),
                },
            });

            // Atualizar vídeo
            await prisma.video.update({
                where: { id: job.videoId },
                data: { status: 'FAILED' },
            });

            // Limpar arquivos temporários
            await videoProcessor.cleanup(job.videoId);
        }
    }

    private sleep(ms: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

export const processingWorker = new VideoProcessingWorker();

// Iniciar worker se executado diretamente
if (import.meta.main) {
    processingWorker.start();
}
