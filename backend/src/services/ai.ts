import { pipeline } from '@xenova/transformers';

/**
 * AI Service for RHEMA
 * Handles generation of embeddings using local ONNX models via transformers.js
 * Model: Xenova/all-MiniLM-L6-v2 (384 dimensions)
 */
class AIService {
    private static instance: AIService;
    private extractor: any;
    private modelName = 'Xenova/all-MiniLM-L6-v2';

    private constructor() { }

    public static getInstance(): AIService {
        if (!AIService.instance) {
            AIService.instance = new AIService();
        }
        return AIService.instance;
    }

    /**
     * Initializes the model pipeline. Lazy loaded.
     */
    private async getExtractor() {
        if (!this.extractor) {
            console.log(`🧠 Carregando modelo de IA (${this.modelName})...`);
            this.extractor = await pipeline('feature-extraction', this.modelName);
            console.log('✅ Modelo de IA carregado!');
        }
        return this.extractor;
    }

    /**
     * Generates a vector embedding for the given text.
     * @param text Input text (e.g. video title + description)
     * @returns Array of 384 numbers
     */
    public async generateEmbedding(text: string): Promise<number[]> {
        try {
            const extractor = await this.getExtractor();

            // Generate embedding with mean pooling and normalization
            const output = await extractor(text, { pooling: 'mean', normalize: true });

            // Convert Tensor to standard array
            return Array.from(output.data);
        } catch (error) {
            console.error('❌ Erro na geração de embedding:', error);
            // Fallback: return zero vector or throw
            return new Array(384).fill(0);
        }
    }

    /**
     * Formats a vector array as a PostgreSQL vector string format "[1,2,3...]"
     */
    public formatVectorForDb(vector: number[]): string {
        return `[${vector.join(',')}]`;
    }
}

export const aiService = AIService.getInstance();
