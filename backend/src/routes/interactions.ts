// Rotas de Interações - Curtidas, Views, Compartilhamentos
import { Elysia, t } from 'elysia';
import prisma from '../lib/prisma';
import { InteractionType } from '@prisma/client';

// Pontuação para cálculo do score do vídeo
const POINTS = {
    VIEW: 1,
    LIKE: 10,
    SHARE: 20,
    SAVE: 5,
    COMMENT: 5,
    COMPLETION_BONUS: 5, // >80% assistido
};

// Pesos para atualização do vetor de interesse do usuário
// Valor = quanto o vetor do vídeo influencia o perfil do usuário
// Valores negativos = repulsão (afastar o perfil deste conteúdo)
const INTEREST_WEIGHTS = {
    LIKE: 0.10,         // 10% - Sinal claro de interesse
    SHARE: 0.15,        // 15% - Compartilhou = gostou muito
    SAVE: 0.08,         // 8% - Interesse moderado
    VIEW_COMPLETE: 0.03, // 3% - Assistiu >80%
    VIEW_SKIP: -0.05,   // -5% - Pulou rápido (<20%) = não gostou
};

/**
 * Atualiza o vetor de interesse do usuário baseado em uma interação.
 * 
 * Peso POSITIVO: Atração (mover perfil em direção ao vídeo)
 *   Fórmula: NovoPerfil = (1-peso)*PerfilAntigo + peso*VetorVideo
 * 
 * Peso NEGATIVO: Repulsão (afastar perfil do vídeo)
 *   Fórmula: NovoPerfil = (1+|peso|)*PerfilAntigo - |peso|*VetorVideo
 *   Isso "empurra" o vetor na direção oposta.
 */
async function updateUserInterest(userId: string, videoId: string, weight: number) {
    try {
        // Buscar vetor do vídeo
        const [video] = await prisma.$queryRawUnsafe<any[]>(
            `SELECT embedding::text as vector FROM videos WHERE id = '${videoId}'`
        );

        if (video?.vector) {
            let sql: string;

            if (weight >= 0) {
                // ATRAÇÃO: Mover em direção ao vídeo
                const oldWeight = 1 - weight;
                sql = `UPDATE users 
                       SET interest_vector = 
                          CASE 
                              WHEN interest_vector IS NULL THEN '${video.vector}'::vector
                              ELSE (interest_vector * ${oldWeight} + '${video.vector}'::vector * ${weight})
                          END
                       WHERE id = '${userId}'`;
                console.log(`✅ Interesse atualizado: ATRAÇÃO ${weight * 100}%`);
            } else {
                // REPULSÃO: Afastar do vídeo (só se já tiver vetor)
                const absWeight = Math.abs(weight);
                const oldWeight = 1 + absWeight; // > 1 para compensar subtração
                sql = `UPDATE users 
                       SET interest_vector = 
                          CASE 
                              WHEN interest_vector IS NULL THEN NULL -- Não inicializa com repulsão
                              ELSE (interest_vector * ${oldWeight} - '${video.vector}'::vector * ${absWeight})
                          END
                       WHERE id = '${userId}'`;
                console.log(`⛔ Interesse atualizado: REPULSÃO ${absWeight * 100}%`);
            }

            await prisma.$executeRawUnsafe(sql);
        }
    } catch (e) {
        console.error('Erro ao atualizar interesse:', e);
    }
}

export const interactionRoutes = new Elysia({ prefix: '/interactions' })

    // Registrar visualização
    .post('/view', async ({ jwt, headers, body }) => {
        const { videoId, watchTime, duration } = body;

        // Autenticação opcional para views
        let userId: string | null = null;
        const authHeader = headers.authorization;
        if (authHeader?.startsWith('Bearer ')) {
            try {
                const token = authHeader.slice(7);
                const payload = await jwt.verify(token);
                if (payload && typeof payload.userId === 'string') {
                    userId = payload.userId;
                }
            } catch { }
        }

        // Calcular taxa de conclusão
        const completionRate = duration > 0 ? (watchTime / duration) : 0;
        const hasCompleted = completionRate >= 0.8;

        // Incrementar contador de views
        const pointsToAdd = POINTS.VIEW + (hasCompleted ? POINTS.COMPLETION_BONUS : 0);

        await prisma.video.update({
            where: { id: videoId },
            data: {
                viewsCount: { increment: 1 },
                score: { increment: pointsToAdd }
            }
        });

        // Registrar interação se autenticado
        if (userId) {
            await prisma.interaction.upsert({
                where: {
                    userId_videoId_type: {
                        userId,
                        videoId,
                        type: InteractionType.VIEW,
                    }
                },
                update: {
                    watchTime,
                    completionRate,
                },
                create: {
                    userId,
                    videoId,
                    type: InteractionType.VIEW,
                    watchTime,
                    completionRate,
                }
            });

            // ATUALIZAR VETOR baseado no comportamento
            if (hasCompleted) {
                // Assistiu >80% = interesse positivo (peso 3%)
                updateUserInterest(userId, videoId, INTEREST_WEIGHTS.VIEW_COMPLETE);
            } else if (completionRate < 0.2 && duration > 5) {
                // Pulou rápido (<20% e vídeo tem >5s) = desinteresse (peso -5%)
                updateUserInterest(userId, videoId, INTEREST_WEIGHTS.VIEW_SKIP);
            }
        }

        return { success: true };
    }, {
        body: t.Object({
            videoId: t.String(),
            watchTime: t.Number(),
            duration: t.Number(),
        })
    })

    // Curtir vídeo
    .post('/like', async ({ jwt, headers, body, set }) => {
        const authHeader = headers.authorization;
        if (!authHeader?.startsWith('Bearer ')) {
            set.status = 401;
            return { success: false, error: 'Não autorizado' };
        }

        const token = authHeader.slice(7);
        const payload = await jwt.verify(token);
        if (!payload || typeof payload.userId !== 'string') {
            set.status = 401;
            return { success: false, error: 'Token inválido' };
        }

        const { videoId } = body;

        try {
            // Verificar se usuário existe (sanidade)
            // const user = await prisma.user.findUnique({ where: { id: payload.userId } });
            // Não é estritamente necessário se o token é válido, mas ajuda a evitar FK errors

            // Verificar se já curtiu
            const existing = await prisma.interaction.findUnique({
                where: {
                    userId_videoId_type: {
                        userId: payload.userId,
                        videoId,
                        type: InteractionType.LIKE,
                    }
                }
            });

            if (existing) {
                // Descurtir
                await prisma.$transaction([
                    prisma.interaction.delete({
                        where: { id: existing.id }
                    }),
                    prisma.video.update({
                        where: { id: videoId },
                        data: {
                            likesCount: { decrement: 1 },
                            score: { decrement: POINTS.LIKE }
                        }
                    })
                ]);

                return { success: true, liked: false };
            }

            // Curtir
            await prisma.$transaction([
                prisma.interaction.create({
                    data: {
                        userId: payload.userId,
                        videoId,
                        type: InteractionType.LIKE,
                    }
                }),
                prisma.video.update({
                    where: { id: videoId },
                    data: {
                        likesCount: { increment: 1 },
                        score: { increment: POINTS.LIKE }
                    }
                })
            ]);

            // ATUALIZAR VETOR (peso 10% - Like é sinal claro)
            // Fire and forget, don't await blocking response
            updateUserInterest(payload.userId, videoId, INTEREST_WEIGHTS.LIKE).catch(err => {
                console.error('Background vector update failed:', err);
            });

            return { success: true, liked: true };
        } catch (e: any) {
            console.error('Erro ao curtir vídeo:', e);
            set.status = 500;
            return {
                success: false,
                error: e.message || 'Erro interno ao processar curtida'
            };
        }
    }, {
        body: t.Object({
            videoId: t.String()
        })
    })

    // Compartilhar vídeo
    .post('/share', async ({ jwt, headers, body }) => {
        const { videoId } = body;

        let userId: string | null = null;
        const authHeader = headers.authorization;
        if (authHeader?.startsWith('Bearer ')) {
            try {
                const token = authHeader.slice(7);
                const payload = await jwt.verify(token);
                if (payload && typeof payload.userId === 'string') {
                    userId = payload.userId;
                }
            } catch { }
        }

        // Incrementar contador
        await prisma.video.update({
            where: { id: videoId },
            data: {
                sharesCount: { increment: 1 },
                score: { increment: POINTS.SHARE }
            }
        });

        // Registrar se autenticado
        if (userId) {
            await prisma.interaction.create({
                data: {
                    userId,
                    videoId,
                    type: InteractionType.SHARE,
                }
            });

            // ATUALIZAR VETOR (peso 15% - compartilhar é sinal forte)
            updateUserInterest(userId, videoId, INTEREST_WEIGHTS.SHARE);
        }

        return { success: true };
    }, {
        body: t.Object({
            videoId: t.String()
        })
    })

    // Salvar vídeo
    .post('/save', async ({ jwt, headers, body }) => {
        const authHeader = headers.authorization;
        if (!authHeader?.startsWith('Bearer ')) {
            throw new Error('Não autorizado');
        }

        const token = authHeader.slice(7);
        const payload = await jwt.verify(token);
        if (!payload || typeof payload.userId !== 'string') {
            throw new Error('Token inválido');
        }

        const { videoId } = body;

        // Toggle save
        const existing = await prisma.interaction.findUnique({
            where: {
                userId_videoId_type: {
                    userId: payload.userId,
                    videoId,
                    type: InteractionType.SAVE,
                }
            }
        });

        if (existing) {
            await prisma.interaction.delete({
                where: { id: existing.id }
            });
            return { success: true, saved: false };
        }

        await prisma.interaction.create({
            data: {
                userId: payload.userId,
                videoId,
                type: InteractionType.SAVE,
            }
        });

        // ATUALIZAR VETOR (peso 8% - salvar indica interesse)
        updateUserInterest(payload.userId, videoId, INTEREST_WEIGHTS.SAVE);

        return { success: true, saved: true };
    }, {
        body: t.Object({
            videoId: t.String()
        })
    })

    // Verificar status de interação
    .get('/status/:videoId', async ({ jwt, headers, params }) => {
        const authHeader = headers.authorization;
        if (!authHeader?.startsWith('Bearer ')) {
            return {
                success: true,
                isLiked: false,
                isSaved: false
            };
        }

        const token = authHeader.slice(7);
        const payload = await jwt.verify(token);
        if (!payload || typeof payload.userId !== 'string') {
            return {
                success: true,
                isLiked: false,
                isSaved: false
            };
        }

        const [like, save] = await Promise.all([
            prisma.interaction.findUnique({
                where: {
                    userId_videoId_type: {
                        userId: payload.userId,
                        videoId: params.videoId,
                        type: InteractionType.LIKE,
                    }
                }
            }),
            prisma.interaction.findUnique({
                where: {
                    userId_videoId_type: {
                        userId: payload.userId,
                        videoId: params.videoId,
                        type: InteractionType.SAVE,
                    }
                }
            })
        ]);

        return {
            success: true,
            isLiked: !!like,
            isSaved: !!save,
        };
    })

    // Comentários
    .post('/comment', async ({ jwt, headers, body }) => {
        const authHeader = headers.authorization;
        if (!authHeader?.startsWith('Bearer ')) {
            throw new Error('Não autorizado');
        }

        const token = authHeader.slice(7);
        const payload = await jwt.verify(token);
        if (!payload || typeof payload.userId !== 'string') {
            throw new Error('Token inválido');
        }

        const { videoId, text, parentId } = body;

        if (!text || text.trim().length === 0) {
            throw new Error('Comentário não pode estar vazio');
        }

        const comment = await prisma.comment.create({
            data: {
                userId: payload.userId,
                videoId,
                text: text.trim(),
                parentId,
            },
            include: {
                user: {
                    select: {
                        id: true,
                        name: true,
                        handle: true,
                        avatar: true,
                    }
                }
            }
        });

        // Incrementar contador
        await prisma.video.update({
            where: { id: videoId },
            data: {
                commentsCount: { increment: 1 },
                score: { increment: POINTS.COMMENT }
            }
        });

        return {
            success: true,
            comment: {
                id: comment.id,
                text: comment.text,
                user: comment.user,
                createdAt: comment.createdAt,
                likesCount: 0,
            }
        };
    }, {
        body: t.Object({
            videoId: t.String(),
            text: t.String(),
            parentId: t.Optional(t.String()),
        })
    })

    // Listar comentários
    .get('/comments/:videoId', async ({ params, query }) => {
        const { page = '1', limit = '20' } = query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        const comments = await prisma.comment.findMany({
            where: {
                videoId: params.videoId,
                parentId: null, // Apenas comentários raiz
            },
            include: {
                user: {
                    select: {
                        id: true,
                        name: true,
                        handle: true,
                        avatar: true,
                    }
                },
                _count: {
                    select: { replies: true }
                }
            },
            orderBy: { createdAt: 'desc' },
            skip,
            take: parseInt(limit),
        });

        return {
            success: true,
            comments: comments.map(c => ({
                id: c.id,
                text: c.text,
                user: c.user,
                likesCount: c.likesCount,
                repliesCount: c._count.replies,
                createdAt: c.createdAt,
            }))
        };
    })

    // Listar vídeos curtidos pelo usuário
    .get('/liked', async ({ jwt, headers, query, set }) => {
        const authHeader = headers.authorization;
        if (!authHeader?.startsWith('Bearer ')) {
            set.status = 401;
            return { success: false, error: 'Não autorizado' };
        }

        const token = authHeader.slice(7);
        const payload = await jwt.verify(token);
        if (!payload || typeof payload.userId !== 'string') {
            set.status = 401;
            return { success: false, error: 'Token inválido' };
        }

        const { page = '1', limit = '20' } = query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        const likedInteractions = await prisma.interaction.findMany({
            where: {
                userId: payload.userId,
                type: InteractionType.LIKE,
            },
            include: {
                video: {
                    select: {
                        id: true,
                        title: true,
                        thumbnailUrl: true,
                        videoUrl: true,
                        viewsCount: true,
                        type: true,
                    }
                }
            },
            orderBy: { createdAt: 'desc' },
            skip,
            take: parseInt(limit),
        });

        return {
            success: true,
            videos: likedInteractions
                .filter(i => i.video !== null)
                .map(i => ({
                    id: i.video!.id,
                    title: i.video!.title,
                    thumbnailUrl: i.video!.thumbnailUrl,
                    videoUrl: i.video!.videoUrl,
                    views: i.video!.viewsCount,
                    type: i.video!.type,
                    likedAt: i.createdAt,
                })),
        };
    });

