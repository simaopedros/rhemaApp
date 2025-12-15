/**
 * Bunny.net Stream Service
 * Gerencia upload, streaming e gerenciamento de vídeos na Bunny.net
 */

const BUNNY_API_KEY = process.env.BUNNY_API_KEY || '';
const BUNNY_LIBRARY_ID = process.env.BUNNY_LIBRARY_ID || '';
const BUNNY_CDN_URL = process.env.BUNNY_CDN_URL || '';
const BUNNY_API_URL = 'https://video.bunnycdn.com/library';

interface CreateVideoResponse {
    guid: string;
    title: string;
    dateUploaded: string;
    views: number;
    isPublic: boolean;
    length: number;
    status: number;
    framerate: number;
    width: number;
    height: number;
    availableResolutions: string;
    thumbnailCount: number;
    encodeProgress: number;
    storageSize: number;
    captions: any[];
    hasMP4Fallback: boolean;
    collectionId: string;
    thumbnailFileName: string;
    averageWatchTime: number;
    totalWatchTime: number;
    category: string;
    chapters: any[];
    moments: any[];
    metaTags: any[];
    transcodingMessages: any[];
}

interface VideoInfo {
    guid: string;
    libraryId: number;
    title: string;
    dateUploaded: string;
    views: number;
    isPublic: boolean;
    length: number;
    status: number; // 0=Created, 1=Uploaded, 2=Processing, 3=Transcoding, 4=Finished, 5=Error
    framerate: number;
    width: number;
    height: number;
    availableResolutions: string;
    thumbnailCount: number;
    encodeProgress: number;
    storageSize: number;
    hasMP4Fallback: boolean;
    thumbnailFileName: string;
}

export class BunnyService {
    private apiKey: string;
    private libraryId: string;
    private cdnUrl: string;

    constructor() {
        this.apiKey = BUNNY_API_KEY;
        this.libraryId = BUNNY_LIBRARY_ID;
        this.cdnUrl = BUNNY_CDN_URL;

        if (!this.apiKey || !this.libraryId) {
            console.warn('⚠️ Bunny.net credentials not configured. Video uploads will fail.');
        }
    }

    /**
     * Cria um novo vídeo na biblioteca Bunny.net (passo 1 do upload)
     */
    async createVideo(title: string, collectionId?: string): Promise<CreateVideoResponse> {
        const response = await fetch(`${BUNNY_API_URL}/${this.libraryId}/videos`, {
            method: 'POST',
            headers: {
                'AccessKey': this.apiKey,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                title,
                collectionId: collectionId || undefined,
            }),
        });

        if (!response.ok) {
            const error = await response.text();
            throw new Error(`Failed to create video on Bunny.net: ${error}`);
        }

        return response.json();
    }

    /**
     * Gera a URL de upload direto (TUS) para o cliente fazer upload sem passar pelo servidor
     */
    getUploadUrl(videoId: string): string {
        return `https://video.bunnycdn.com/tusupload?libraryId=${this.libraryId}&videoId=${videoId}&expiration=3600&signature=${this.generateSignature(videoId)}`;
    }

    /**
     * Gera assinatura para upload TUS (simplificado - em produção usar SHA256)
     */
    private generateSignature(videoId: string): string {
        // Em produção: usar crypto para gerar HMAC-SHA256
        // Por enquanto, retorna uma assinatura simplificada
        const timestamp = Math.floor(Date.now() / 1000) + 3600;
        return `${this.libraryId}${videoId}${timestamp}`.slice(0, 32);
    }

    /**
     * Faz upload de um arquivo diretamente (para uso no servidor/worker)
     */
    async uploadVideo(videoId: string, fileBuffer: Uint8Array): Promise<void> {
        const response = await fetch(`${BUNNY_API_URL}/${this.libraryId}/videos/${videoId}`, {
            method: 'PUT',
            headers: {
                'AccessKey': this.apiKey,
                'Content-Type': 'application/octet-stream',
            },
            body: fileBuffer as unknown as BodyInit,
        });

        if (!response.ok) {
            const error = await response.text();
            throw new Error(`Failed to upload video to Bunny.net: ${error}`);
        }
    }

    /**
     * Obtém informações do vídeo (status de processamento, duração, etc.)
     */
    async getVideoInfo(videoId: string): Promise<VideoInfo> {
        const response = await fetch(`${BUNNY_API_URL}/${this.libraryId}/videos/${videoId}`, {
            method: 'GET',
            headers: {
                'AccessKey': this.apiKey,
            },
        });

        if (!response.ok) {
            throw new Error(`Failed to get video info from Bunny.net`);
        }

        return response.json();
    }

    /**
     * Aguarda o vídeo terminar de processar (polling)
     */
    async waitForProcessing(videoId: string, maxAttempts = 60): Promise<VideoInfo> {
        for (let i = 0; i < maxAttempts; i++) {
            const info = await this.getVideoInfo(videoId);

            if (info.status === 4) { // 4 = Finished
                return info;
            }

            if (info.status === 5) { // 5 = Error
                throw new Error('Video processing failed on Bunny.net');
            }

            // Aguardar 5 segundos antes de verificar novamente
            await new Promise(resolve => setTimeout(resolve, 5000));
        }

        throw new Error('Video processing timeout');
    }

    /**
     * Obtém URL de streaming HLS
     */
    getHlsUrl(videoId: string): string {
        return `https://${this.cdnUrl}/${videoId}/playlist.m3u8`;
    }

    /**
     * Obtém URL de download MP4 (fallback)
     */
    getMp4Url(videoId: string, resolution = '720p'): string {
        return `https://${this.cdnUrl}/${videoId}/play_${resolution}.mp4`;
    }

    /**
     * Obtém URL da thumbnail
     */
    getThumbnailUrl(videoId: string, index = 1): string {
        return `https://${this.cdnUrl}/${videoId}/thumbnail_${index}.jpg`;
    }

    /**
     * Deleta um vídeo
     */
    async deleteVideo(videoId: string): Promise<void> {
        const response = await fetch(`${BUNNY_API_URL}/${this.libraryId}/videos/${videoId}`, {
            method: 'DELETE',
            headers: {
                'AccessKey': this.apiKey,
            },
        });

        if (!response.ok) {
            throw new Error(`Failed to delete video from Bunny.net`);
        }
    }

    /**
     * Obtém URL de download do vídeo original (para worker de processamento)
     */
    getOriginalDownloadUrl(videoId: string): string {
        return `https://${this.cdnUrl}/${videoId}/original`;
    }
}

// Singleton
export const bunnyService = new BunnyService();
