// RHEMA Backend - Entry Point
// Bun + Elysia API Server

import { Elysia } from 'elysia';
import { cors } from '@elysiajs/cors';
import { jwt } from '@elysiajs/jwt';
import { authRoutes } from './routes/auth';
import { videosRoutes } from './routes/videos';
import { feedRoutes } from './routes/feed';
import { userRoutes } from './routes/users';
import { interactionRoutes } from './routes/interactions';
import { searchRoutes } from './routes/search';
import { processingWorker } from './services/processing-worker';

const app = new Elysia({
    serve: {
        maxRequestBodySize: 1024 * 1024 * 1024, // 1GB
    }
})
    .use(cors({
        origin: '*',
        methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
        allowedHeaders: ['Content-Type', 'Authorization'],
    }))
    .use(jwt({
        name: 'jwt',
        secret: process.env.JWT_SECRET || 'rhema-super-secret-key-2024',
        exp: '7d'
    }))
    // Health check
    .get('/', () => ({
        status: 'ok',
        name: 'RHEMA API',
        version: '1.0.0',
        timestamp: new Date().toISOString()
    }))
    .get('/health', () => ({
        status: 'healthy',
        uptime: process.uptime()
    }))
    // Routes
    .use(authRoutes)
    .use(videosRoutes)
    .use(feedRoutes)
    .use(userRoutes)
    .use(interactionRoutes)
    .use(searchRoutes)
    // Error handling
    .onError(({ code, error }) => {
        const errMsg = (error as any)?.message || 'Unknown error';
        console.error(`[${code}] ${errMsg}`);
        return {
            success: false,
            error: errMsg,
            code
        };
    })
    .listen({
        port: Number(process.env.PORT) || 3000,
        hostname: '0.0.0.0'
    });

console.log(`
🔥 RHEMA API Server iniciado!
📍 URL: http://${app.server?.hostname}:${app.server?.port}
📦 Ambiente: ${process.env.NODE_ENV || 'development'}
`);

// Iniciar worker de processamento de vídeo em background
if (process.env.ENABLE_VIDEO_WORKER === 'true') {
    processingWorker.start();
    console.log('🎬 Video Processing Worker ativado');
}

export type App = typeof app;

