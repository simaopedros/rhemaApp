// Rotas de Usuário e Perfil
import { Elysia, t } from 'elysia';
import prisma from '../lib/prisma';

export const userRoutes = new Elysia({ prefix: '/users' })

    // Obter meu perfil
    .get('/me', async ({ jwt, headers }) => {
        const authHeader = headers.authorization;
        if (!authHeader?.startsWith('Bearer ')) {
            throw new Error('Não autorizado');
        }

        const token = authHeader.slice(7);
        const payload = await jwt.verify(token);
        if (!payload || typeof payload.userId !== 'string') {
            throw new Error('Token inválido');
        }

        const user = await prisma.user.findUnique({
            where: { id: payload.userId },
            select: {
                id: true,
                name: true,
                handle: true,
                avatar: true,
                bio: true,
                followersCount: true,
                followingCount: true,
                isVerified: true,
                createdAt: true,
                _count: {
                    select: { videos: true }
                }
            }
        });

        if (!user) {
            throw new Error('Usuário não encontrado');
        }

        return {
            success: true,
            user: {
                ...user,
                videosCount: user._count.videos,
            }
        };
    })

    // Obter perfil de usuário
    .get('/:id', async ({ params }) => {
        const user = await prisma.user.findUnique({
            where: { id: params.id },
            select: {
                id: true,
                name: true,
                handle: true,
                avatar: true,
                bio: true,
                followersCount: true,
                followingCount: true,
                isVerified: true,
                createdAt: true,
                _count: {
                    select: { videos: true }
                }
            }
        });

        if (!user) {
            throw new Error('Usuário não encontrado');
        }

        return {
            success: true,
            user: {
                ...user,
                videosCount: user._count.videos,
            }
        };
    })

    // Buscar usuário por handle
    .get('/handle/:handle', async ({ params }) => {
        const handle = params.handle.startsWith('@')
            ? params.handle
            : `@${params.handle}`;

        const user = await prisma.user.findUnique({
            where: { handle },
            select: {
                id: true,
                name: true,
                handle: true,
                avatar: true,
                bio: true,
                followersCount: true,
                followingCount: true,
                isVerified: true,
            }
        });

        if (!user) {
            throw new Error('Usuário não encontrado');
        }

        return { success: true, user };
    })

    // Atualizar perfil
    .patch('/me', async ({ jwt, headers, body }) => {
        const authHeader = headers.authorization;
        if (!authHeader?.startsWith('Bearer ')) {
            throw new Error('Não autorizado');
        }

        const token = authHeader.slice(7);
        const payload = await jwt.verify(token);
        if (!payload || typeof payload.userId !== 'string') {
            throw new Error('Token inválido');
        }

        const { name, bio, avatar } = body;

        const user = await prisma.user.update({
            where: { id: payload.userId },
            data: {
                ...(name && { name }),
                ...(bio !== undefined && { bio }),
                ...(avatar && { avatar }),
            },
            select: {
                id: true,
                name: true,
                handle: true,
                avatar: true,
                bio: true,
            }
        });

        return { success: true, user };
    }, {
        body: t.Object({
            name: t.Optional(t.String()),
            bio: t.Optional(t.String()),
            avatar: t.Optional(t.String()),
        })
    })

    // Seguir usuário
    .post('/:id/follow', async ({ jwt, headers, params }) => {
        const authHeader = headers.authorization;
        if (!authHeader?.startsWith('Bearer ')) {
            throw new Error('Não autorizado');
        }

        const token = authHeader.slice(7);
        const payload = await jwt.verify(token);
        if (!payload || typeof payload.userId !== 'string') {
            throw new Error('Token inválido');
        }

        const followerId = payload.userId;
        const followingId = params.id;

        if (followerId === followingId) {
            throw new Error('Você não pode seguir a si mesmo');
        }

        // Verificar se já segue
        const existingFollow = await prisma.follow.findUnique({
            where: {
                followerId_followingId: {
                    followerId,
                    followingId,
                }
            }
        });

        if (existingFollow) {
            throw new Error('Você já segue este usuário');
        }

        // Criar follow e atualizar contadores
        await prisma.$transaction([
            prisma.follow.create({
                data: { followerId, followingId }
            }),
            prisma.user.update({
                where: { id: followerId },
                data: { followingCount: { increment: 1 } }
            }),
            prisma.user.update({
                where: { id: followingId },
                data: { followersCount: { increment: 1 } }
            })
        ]);

        return { success: true, message: 'Usuário seguido' };
    })

    // Deixar de seguir
    .delete('/:id/follow', async ({ jwt, headers, params }) => {
        const authHeader = headers.authorization;
        if (!authHeader?.startsWith('Bearer ')) {
            throw new Error('Não autorizado');
        }

        const token = authHeader.slice(7);
        const payload = await jwt.verify(token);
        if (!payload || typeof payload.userId !== 'string') {
            throw new Error('Token inválido');
        }

        const followerId = payload.userId;
        const followingId = params.id;

        const follow = await prisma.follow.findUnique({
            where: {
                followerId_followingId: {
                    followerId,
                    followingId,
                }
            }
        });

        if (!follow) {
            throw new Error('Você não segue este usuário');
        }

        await prisma.$transaction([
            prisma.follow.delete({
                where: { id: follow.id }
            }),
            prisma.user.update({
                where: { id: followerId },
                data: { followingCount: { decrement: 1 } }
            }),
            prisma.user.update({
                where: { id: followingId },
                data: { followersCount: { decrement: 1 } }
            })
        ]);

        return { success: true, message: 'Deixou de seguir' };
    })

    // Verificar se segue
    .get('/:id/following', async ({ jwt, headers, params }) => {
        const authHeader = headers.authorization;
        if (!authHeader?.startsWith('Bearer ')) {
            return { success: true, isFollowing: false };
        }

        const token = authHeader.slice(7);
        const payload = await jwt.verify(token);
        if (!payload || typeof payload.userId !== 'string') {
            return { success: true, isFollowing: false };
        }

        const follow = await prisma.follow.findUnique({
            where: {
                followerId_followingId: {
                    followerId: payload.userId,
                    followingId: params.id,
                }
            }
        });

        return { success: true, isFollowing: !!follow };
    })

    // Listar seguidores
    .get('/:id/followers', async ({ params, query }) => {
        const { page = '1', limit = '20' } = query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        const followers = await prisma.follow.findMany({
            where: { followingId: params.id },
            include: {
                follower: {
                    select: {
                        id: true,
                        name: true,
                        handle: true,
                        avatar: true,
                        isVerified: true,
                    }
                }
            },
            skip,
            take: parseInt(limit),
        });

        return {
            success: true,
            users: followers.map(f => f.follower),
        };
    })

    // Listar seguindo
    .get('/:id/following-list', async ({ params, query }) => {
        const { page = '1', limit = '20' } = query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        const following = await prisma.follow.findMany({
            where: { followerId: params.id },
            include: {
                following: {
                    select: {
                        id: true,
                        name: true,
                        handle: true,
                        avatar: true,
                        isVerified: true,
                    }
                }
            },
            skip,
            take: parseInt(limit),
        });

        return {
            success: true,
            users: following.map(f => f.following),
        };
    })

    // Listar vídeos do usuário (com status para o dono)
    .get('/:id/videos', async ({ jwt, headers, params, query }) => {
        const { page = '1', limit = '20', type } = query;
        const skip = (parseInt(page) - 1) * parseInt(limit);
        const { id } = params;

        let isOwner = false;
        const authHeader = headers.authorization;
        if (authHeader?.startsWith('Bearer ')) {
            const token = authHeader.slice(7);
            const payload = await jwt.verify(token);
            if (payload && payload.userId === id) {
                isOwner = true;
            }
        }

        // Se for o dono, mostra tudo (útil para dashboard de status)
        // Se for visitante, mostra apenas READY
        const statusFilter = isOwner ? undefined : { status: 'READY' as const };
        const typeFilter = type ? { type: type as any } : undefined;

        const videos = await prisma.video.findMany({
            where: {
                userId: id,
                ...statusFilter,
                ...typeFilter,
            },
            orderBy: { createdAt: 'desc' },
            skip,
            take: parseInt(limit),
            select: {
                id: true,
                title: true,
                thumbnailUrl: true,
                videoUrl: true,
                viewsCount: true,
                status: true, // Importante para o dono
                type: true,
                createdAt: true,
            }
        });

        return {
            success: true,
            videos: videos.map(v => ({
                ...v,
                views: v.viewsCount, // Alias
            })),
            isOwner,
        };
    })

    // Buscar usuários
    .get('/search', async ({ query }) => {
        const { q, limit = '10' } = query;

        if (!q || q.length < 2) {
            return { success: true, users: [] };
        }

        const users = await prisma.user.findMany({
            where: {
                OR: [
                    { name: { contains: q, mode: 'insensitive' } },
                    { handle: { contains: q, mode: 'insensitive' } },
                ]
            },
            select: {
                id: true,
                name: true,
                handle: true,
                avatar: true,
                isVerified: true,
                followersCount: true,
            },
            take: parseInt(limit),
            orderBy: { followersCount: 'desc' }
        });

        return { success: true, users };
    });
