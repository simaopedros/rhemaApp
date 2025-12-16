/**
 * Plugin JWT Compartilhado
 * Este plugin deve ser usado em todos os arquivos de rota que precisam de acesso ao JWT
 */
import { Elysia } from 'elysia';
import { jwt } from '@elysiajs/jwt';

// Configuração centralizada do JWT
const JWT_CONFIG = {
    name: 'jwt' as const,
    secret: process.env.JWT_SECRET || 'rhema-super-secret-key-2024',
    exp: '7d' as const
};

/**
 * Plugin JWT que pode ser reutilizado em todos os módulos de rota
 * Uso: new Elysia().use(jwtPlugin).get('/rota', ({ jwt }) => ...)
 */
export const jwtPlugin = new Elysia({ name: 'jwt-plugin' })
    .use(jwt(JWT_CONFIG));

// Re-exportar o tipo para uso em outros arquivos
export type JWTPayload = {
    userId: string;
    email: string;
};
