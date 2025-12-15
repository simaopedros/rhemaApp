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
    .post('/like', async ({ jwt, headers, body }) => {
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

        // ATUALIZAR VETOR DE INTERESSE DO USUÁRIO (Background)
        (async () => {
            try {
                // Buscar vetor do vídeo
                const [video] = await prisma.$queryRawUnsafe<any[]>(
                    `SELECT embedding::text as vector FROM videos WHERE id = '${videoId}'`
                );

                if (video?.vector) {
                    // Atualizar vetor do usuário (Média Móvel: 90% antigo + 10% novo)
                    // Se usuário não tiver vetor (NULL), usa o do vídeo (COALESCE)
                    await prisma.$executeRawUnsafe(
                        `UPDATE users 
                         SET interest_vector = 
                            CASE 
                                WHEN interest_vector IS NULL THEN '${video.vector}'::vector
                                ELSE (interest_vector * 0.9 + '${video.vector}'::vector * 0.1)
                            END
                         WHERE id = '${payload.userId}'`
                    );
                    console.log('✅ Interesse do usuário atualizado base no Like');
                }
            } catch (e) {
                console.error('Erro ao atualizar interesse:', e);
            }
        })();

        return { success: true, liked: true };
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
    });
