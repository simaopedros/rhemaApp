/**
 * Middleware de Autenticação JWT
 * Centraliza a validação de tokens e proteção de rotas
 * 
 * IMPORTANTE: Este arquivo define helpers para autenticação.
 * O JWT é configurado globalmente no index.ts e está disponível em todas as rotas.
 */
import { Elysia } from 'elysia';
import prisma from './prisma';

// Tipos para o payload do JWT
export interface JWTPayload {
    userId: string;
    email: string;
}

// Tipos para contexto autenticado
export interface AuthContext {
    userId: string;
    user?: {
        id: string;
        email: string;
        name: string;
        handle: string;
        avatar: string | null;
        isVerified: boolean;
    };
}

/**
 * Extrai e valida o token JWT do header Authorization
 * Retorna null se não houver token ou se for inválido
 */
export async function extractAndVerifyToken(
    authHeader: string | undefined,
    jwt: { verify: (token: string) => Promise<JWTPayload | false> }
): Promise<JWTPayload | null> {
    if (!authHeader?.startsWith('Bearer ')) {
        return null;
    }

    const token = authHeader.slice(7);

    try {
        const payload = await jwt.verify(token);
        if (!payload || typeof payload.userId !== 'string') {
            return null;
        }
        return payload as JWTPayload;
    } catch {
        return null;
    }
}

/**
 * Helper function para extrair userId de forma segura
 * Uso: const userId = await getUserIdFromHeader(headers.authorization, jwt);
 */
export async function getUserIdFromHeader(
    authHeader: string | undefined,
    jwt: { verify: (token: string) => Promise<JWTPayload | false> }
): Promise<string | null> {
    const payload = await extractAndVerifyToken(authHeader, jwt);
    return payload?.userId ?? null;
}

/**
 * Valida autenticação e retorna userId
 * Lança erro se não autenticado
 * 
 * Uso para rotas que REQUEREM autenticação:
 * const userId = await requireAuth(headers.authorization, jwt, set);
 */
export async function requireAuthHeader(
    authHeader: string | undefined,
    jwt: { verify: (token: string) => Promise<JWTPayload | false> },
    set: { status: number }
): Promise<string> {
    const payload = await extractAndVerifyToken(authHeader, jwt);

    if (!payload) {
        set.status = 401;
        throw new Error('Não autorizado - Token JWT inválido ou ausente');
    }

    return payload.userId;
}

/**
 * Valida autenticação e retorna dados do usuário
 * Lança erro se não autenticado ou usuário não encontrado
 */
export async function requireAuthWithUserData(
    authHeader: string | undefined,
    jwt: { verify: (token: string) => Promise<JWTPayload | false> },
    set: { status: number }
): Promise<AuthContext> {
    const userId = await requireAuthHeader(authHeader, jwt, set);

    const user = await prisma.user.findUnique({
        where: { id: userId },
        select: {
            id: true,
            email: true,
            name: true,
            handle: true,
            avatar: true,
            isVerified: true,
        }
    });

    if (!user) {
        set.status = 401;
        throw new Error('Usuário não encontrado');
    }

    return { userId, user };
}

/**
 * Guard decorator para validação de AuthContext
 * Uso: if (!guardAuth(auth)) return unauthorizedResponse();
 */
export function guardAuth(auth: AuthContext | null): auth is AuthContext {
    return auth !== null && typeof auth.userId === 'string';
}

/**
 * Resposta padrão para não autorizado
 */
export function unauthorizedResponse() {
    return { success: false, error: 'Não autorizado' };
}
