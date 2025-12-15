
import { bunnyService } from '../src/services/bunny';
import { PrismaClient } from '@prisma/client';
import fs from 'fs';
import path from 'path';

const prisma = new PrismaClient();

// Crie um arquivo de teste de 5MB se não existir para testar
const TEST_FILE_PATH = 'test-video.mp4';

async function testUpload() {
    console.log('🚀 Iniciando teste de upload isolado...');

    if (!fs.existsSync(TEST_FILE_PATH)) {
        console.log('⚠️ Arquivo test-video.mp4 não encontrado. Criando arquivo dummy de 1MB...');
        const buffer = Buffer.alloc(1024 * 1024); // 1MB
        fs.writeFileSync(TEST_FILE_PATH, buffer);
    }

    try {
        // 1. Simular endpoint /videos/upload
        const title = 'Teste Upload Local';
        const fileBuffer = fs.readFileSync(TEST_FILE_PATH);
        const fileBlob = new Blob([fileBuffer]);

        console.log(`📦 Tamanho do arquivo: ${fileBuffer.length / 1024 / 1024} MB`);

        // Chamar endpoint via fetch local para testar servidor
        const formData = new FormData();
        formData.append('title', title);
        formData.append('type', 'SHORT');
        formData.append('file', fileBlob, 'test-video.mp4');

        console.log('📡 Enviando para http://localhost:3000/videos/upload...');

        const response = await fetch('http://localhost:3000/videos/upload', {
            method: 'POST',
            body: formData,
        });

        const result = await response.json();
        console.log('✅ Resposta do servidor:', result);

        if (!response.ok) {
            console.error('❌ Falha na requisição:', result);
        }

    } catch (error) {
        console.error('❌ Erro no teste:', error);
    } finally {
        // Limpeza opcional
        // fs.unlinkSync(TEST_FILE_PATH);
    }
}

testUpload();
