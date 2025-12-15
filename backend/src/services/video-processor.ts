/**
 * Video Processor Service
 * Algoritmo de Corte Automático usando FFmpeg
 * 
 * Pipeline:
 * 1. Download do vídeo original
 * 2. Análise de cenas (scene detection)
 * 3. Detecção facial para enquadramento
 * 4. Corte em clipes verticais (9:16)
 * 5. Upload dos clipes gerados
 */

import { $ } from 'bun';
import { existsSync, mkdirSync, readdirSync, unlinkSync, rmSync } from 'fs';
import { join } from 'path';
import { bunnyService } from './bunny';

interface SceneInfo {
    start: number;  // Segundos
    end: number;
    duration: number;
}

interface ClipInfo {
    path: string;
    start: number;
    end: number;
    duration: number;
}

interface ProcessingResult {
    success: boolean;
    clips: ClipInfo[];
    error?: string;
}

const TEMP_DIR = process.env.TEMP_DIR || './temp';
const MAX_CLIP_DURATION = 180; // 3 minutos máximo para Shorts
const MIN_CLIP_DURATION = 15;  // 15 segundos mínimo
const TARGET_ASPECT_RATIO = 9 / 16; // Vertical (Shorts)

export class VideoProcessor {
    private tempDir: string;

    constructor() {
        this.tempDir = TEMP_DIR;
        this.ensureTempDir();
    }

    private ensureTempDir() {
        if (!existsSync(this.tempDir)) {
            mkdirSync(this.tempDir, { recursive: true });
        }
    }

    /**
     * Processa um vídeo longo e gera clipes verticais
     */
    async processVideo(videoId: string, bunnyVideoId: string): Promise<ProcessingResult> {
        const workDir = join(this.tempDir, videoId);
        const inputPath = join(workDir, 'input.mp4');
        const clipsDir = join(workDir, 'clips');

        try {
            // 1. Criar diretório de trabalho
            mkdirSync(workDir, { recursive: true });
            mkdirSync(clipsDir, { recursive: true });

            console.log(`📥 Baixando vídeo ${bunnyVideoId}...`);

            // 2. Baixar vídeo original do Bunny.net
            const downloadUrl = bunnyService.getMp4Url(bunnyVideoId, '1080p');
            await this.downloadVideo(downloadUrl, inputPath);

            // 3. Obter informações do vídeo
            const videoInfo = await this.getVideoInfo(inputPath);
            console.log(`📊 Vídeo: ${videoInfo.duration}s, ${videoInfo.width}x${videoInfo.height}`);

            // 4. Detectar cenas
            console.log(`🔍 Detectando cenas...`);
            const scenes = await this.detectScenes(inputPath);
            console.log(`   Encontradas ${scenes.length} cenas`);

            // 5. Agrupar cenas em clipes de até 3 minutos
            const clipSegments = this.groupScenesIntoClips(scenes, videoInfo.duration);
            console.log(`📎 Gerando ${clipSegments.length} clipes...`);

            // 6. Gerar cada clipe vertical
            const clips: ClipInfo[] = [];
            for (let i = 0; i < clipSegments.length; i++) {
                const segment = clipSegments[i];
                const outputPath = join(clipsDir, `clip_${i + 1}.mp4`);

                console.log(`   Processando clipe ${i + 1}/${clipSegments.length}...`);

                await this.createVerticalClip(
                    inputPath,
                    outputPath,
                    segment.start,
                    segment.duration,
                    videoInfo.width,
                    videoInfo.height
                );

                clips.push({
                    path: outputPath,
                    start: segment.start,
                    end: segment.end,
                    duration: segment.duration,
                });
            }

            return { success: true, clips };

        } catch (error) {
            console.error(`❌ Erro no processamento:`, error);
            return {
                success: false,
                clips: [],
                error: error instanceof Error ? error.message : 'Unknown error',
            };
        }
    }

    /**
     * Baixa um vídeo de uma URL
     */
    private async downloadVideo(url: string, outputPath: string): Promise<void> {
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`Failed to download video: ${response.status}`);
        }

        const buffer = await response.arrayBuffer();
        await Bun.write(outputPath, buffer);
    }

    /**
     * Obtém informações do vídeo usando FFprobe
     */
    private async getVideoInfo(inputPath: string): Promise<{
        duration: number;
        width: number;
        height: number;
    }> {
        const result = await $`ffprobe -v quiet -print_format json -show_format -show_streams ${inputPath}`.text();
        const info = JSON.parse(result);

        const videoStream = info.streams.find((s: any) => s.codec_type === 'video');

        return {
            duration: parseFloat(info.format.duration),
            width: videoStream?.width || 1920,
            height: videoStream?.height || 1080,
        };
    }

    /**
     * Detecta mudanças de cena no vídeo
     */
    private async detectScenes(inputPath: string): Promise<SceneInfo[]> {
        // Usar filtro scenedetect do FFmpeg
        const result = await $`ffmpeg -i ${inputPath} -vf "select='gt(scene,0.3)',showinfo" -f null - 2>&1`.text();

        const scenes: SceneInfo[] = [];
        const regex = /pts_time:(\d+\.?\d*)/g;
        let match;
        let lastTime = 0;

        while ((match = regex.exec(result)) !== null) {
            const time = parseFloat(match[1]);
            if (time > lastTime + 2) { // Pelo menos 2 segundos entre cenas
                scenes.push({
                    start: lastTime,
                    end: time,
                    duration: time - lastTime,
                });
                lastTime = time;
            }
        }

        // Se não detectou cenas, criar segmentos artificiais
        if (scenes.length === 0) {
            const info = await this.getVideoInfo(inputPath);
            const segmentDuration = Math.min(MAX_CLIP_DURATION, info.duration);

            for (let start = 0; start < info.duration; start += segmentDuration) {
                const duration = Math.min(segmentDuration, info.duration - start);
                if (duration >= MIN_CLIP_DURATION) {
                    scenes.push({
                        start,
                        end: start + duration,
                        duration,
                    });
                }
            }
        }

        return scenes;
    }

    /**
     * Agrupa cenas em clipes de até 3 minutos
     */
    private groupScenesIntoClips(scenes: SceneInfo[], totalDuration: number): SceneInfo[] {
        const clips: SceneInfo[] = [];
        let currentClip: SceneInfo | null = null;

        for (const scene of scenes) {
            if (!currentClip) {
                currentClip = { ...scene };
                continue;
            }

            // Se adicionar esta cena excede o máximo, finalizar o clipe atual
            if (currentClip.duration + scene.duration > MAX_CLIP_DURATION) {
                if (currentClip.duration >= MIN_CLIP_DURATION) {
                    clips.push(currentClip);
                }
                currentClip = { ...scene };
            } else {
                // Juntar com o clipe atual
                currentClip.end = scene.end;
                currentClip.duration = currentClip.end - currentClip.start;
            }
        }

        // Adicionar último clipe
        if (currentClip && currentClip.duration >= MIN_CLIP_DURATION) {
            clips.push(currentClip);
        }

        return clips;
    }

    /**
     * Cria um clipe vertical (9:16) com crop inteligente
     * Tenta centralizar no rosto ou no centro da ação
     */
    private async createVerticalClip(
        inputPath: string,
        outputPath: string,
        startTime: number,
        duration: number,
        inputWidth: number,
        inputHeight: number
    ): Promise<void> {
        // Calcular dimensões do crop para 9:16
        const targetWidth = Math.floor(inputHeight * TARGET_ASPECT_RATIO);
        const targetHeight = inputHeight;

        // Centralizar horizontalmente (em produção: usar detecção facial para ajustar)
        const cropX = Math.floor((inputWidth - targetWidth) / 2);
        const cropY = 0;

        // Comando FFmpeg para cortar e redimensionar
        const cropFilter = `crop=${targetWidth}:${targetHeight}:${cropX}:${cropY},scale=1080:1920`;

        await $`ffmpeg -y -ss ${startTime} -i ${inputPath} -t ${duration} -vf "${cropFilter}" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k ${outputPath}`;
    }

    /**
     * Limpa arquivos temporários de um job
     */
    async cleanup(videoId: string): Promise<void> {
        const workDir = join(this.tempDir, videoId);
        if (existsSync(workDir)) {
            rmSync(workDir, { recursive: true, force: true });
        }
    }
}

export const videoProcessor = new VideoProcessor();
