// Feed de Vídeos - Algoritmo de Recomendação
import { Elysia, t } from 'elysia';
import prisma from '../lib/prisma';
import { VideoStatus, VideoType } from '@prisma/client';

// Constantes do algoritmo
const LIKE_POINTS = 10;
const SHARE_POINTS = 20;
const COMMENT_POINTS = 5;
const COMPLETION_BONUS = 5;
const FRESHNESS_DECAY = 0.1; // 10% por dia

// Inserir anúncio a cada N vídeos
const AD_SLOT_INTERVAL = 5;

export const feedRoutes = new Elysia({ prefix: '/feed' })

    // Feed principal (Sugeridos)
    .get('/', async ({ jwt, headers, query }) => {
        const { page = '1', limit = '10', type = 'sugeridos' } = query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        // Tentar autenticar (opcional para feed público)
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

        let recommendedIds: string[] = [];
        let isRecommendation = false;

        // Se usuário logado, buscar vetor de interesse para recomendação
        if (userId && type === 'sugeridos') {
            try {
                // Obter vetor do usuário
                const [user] = await prisma.$queryRawUnsafe<any[]>(
                    `SELECT interest_vector::text as vector FROM users WHERE id = '${userId}'`
                );

                if (user?.vector) {
                    // Busca vetorial (RAG/Recomendação)
                    // Encontra vídeos mais próximos do vetor do usuário
                    // Exclui vídeos já vistos (MVP: ignora exclusion por performance agora ou usa NOT IN)
                    const vectorStr = user.vector; // Já vem formatado do banco

                    // Ajuste: Prisma Raw retorna array de objetos
                    const recs = await prisma.$queryRawUnsafe<any[]>(
                        `SELECT id FROM videos 
                         WHERE status = 'READY' 
                         AND type = 'SHORT' 
                         ORDER BY embedding <=> '${vectorStr}'::vector ASC 
                         LIMIT ${limit} OFFSET ${skip}`
                    );

                    if (recs.length > 0) {
                        recommendedIds = recs.map(r => r.id);
                        isRecommendation = true;
                    }
                }
            } catch (e) {
                console.error('Erro na recomendação:', e);
            }
        }

        let videos;
        if (isRecommendation && recommendedIds.length > 0) {
            // Buscar detalhes dos vídeos recomendados
            const unorderedVideos = await prisma.video.findMany({
                where: { id: { in: recommendedIds } },
                include: {
                    user: {
                        select: {
                            id: true,
                            name: true,
                            handle: true,
                            avatar: true,
                            isVerified: true,
                        }
                    },
                    parentVideo: {
                        select: {
                            id: true,
                            videoUrl: true,
                            thumbnailUrl: true,
                            title: true,
                            description: true,
                            duration: true,
                        }
                    }
                }
            });

            // Reordenar conforme relevância (ordem dos IDs)
            videos = recommendedIds
                .map(id => unorderedVideos.find(v => v.id === id))
                .filter(Boolean) as typeof unorderedVideos;

        } else {
            // Fallback: Feed cronológico ou Trending
            // IDs dos vídeos já vistos pelo usuário
            const viewedVideoIds: string[] = [];
            if (userId) {
                const viewedInteractions = await prisma.interaction.findMany({
                    where: {
                        userId,
                        type: 'VIEW',
                    },
                    select: { videoId: true },
                    take: 100, // Limitar para performance
                });
                viewedVideoIds.push(...viewedInteractions.map(i => i.videoId));
            }

            // Query base para vídeos
            const whereClause = {
                status: VideoStatus.READY,
                type: VideoType.SHORT,
                ...(viewedVideoIds.length > 0 && {
                    id: { notIn: viewedVideoIds }
                }),
                ...(type === 'seguindo' && userId && {
                    user: {
                        followers: {
                            some: { followerId: userId }
                        }
                    }
                })
            };

            // Buscar vídeos
            const isFollowing = type === 'seguindo';

            videos = await prisma.video.findMany({
                where: whereClause,
                include: {
                    user: {
                        select: {
                            id: true,
                            name: true,
                            handle: true,
                            avatar: true,
                            isVerified: true,
                        }
                    },
                    parentVideo: {
                        select: {
                            id: true,
                            videoUrl: true,
                            thumbnailUrl: true,
                            title: true,
                            description: true,
                            duration: true,
                        }
                    }
                },
                orderBy: isFollowing
                    ? { createdAt: 'desc' } // Seguindo: Cronológico
                    : [{ score: 'desc' }, { createdAt: 'desc' }], // Sugeridos: Relevância
                skip,
                take: parseInt(limit),
            });
        }

        // Formatar resposta
        const formattedVideos = videos.map(video => ({
            id: video.id,
            type: video.type,
            videoUrl: video.videoUrl,
            thumbnailUrl: video.thumbnailUrl,
            hlsUrl: video.hlsUrl,
            title: video.title,
            description: video.description,
            tags: video.tags,
            duration: video.duration,
            likes: video.likesCount,
            comments: video.commentsCount,
            shares: video.sharesCount,
            views: formatViews(video.viewsCount),
            user: video.user,
            postedAt: formatTimeAgo(video.createdAt),
            isAd: false,
            parentVideoId: video.parentVideoId,
            parentVideo: video.parentVideo ? {
                id: video.parentVideo.id,
                videoUrl: video.parentVideo.videoUrl,
                thumbnailUrl: video.parentVideo.thumbnailUrl,
                title: video.parentVideo.title,
                description: video.parentVideo.description,
                duration: video.parentVideo.duration,
            } : null,
        }));

        // Inserir anúncios no feed (a cada N vídeos)
        // TODO: Implementar busca de anúncios com leilão

        return {
            success: true,
            videos: formattedVideos,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                hasMore: videos.length === parseInt(limit),
            }
        };
    })

    // Feed de vídeos longos
    .get('/long', async ({ query }) => {
        const { page = '1', limit = '10' } = query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        const videos = await prisma.video.findMany({
            where: {
                status: VideoStatus.READY,
                type: VideoType.LONG,
            },
            include: {
                user: {
                    select: {
                        id: true,
                        name: true,
                        handle: true,
                        avatar: true,
                        isVerified: true,
                    }
                },
                parentVideo: {
                    select: {
                        id: true,
                        videoUrl: true,
                        thumbnailUrl: true,
                        title: true,
                        description: true,
                        duration: true,
                    }
                }
            },
            orderBy: { createdAt: 'desc' },
            skip,
            take: parseInt(limit),
        });

        const formattedVideos = videos.map(video => ({
            id: video.id,
            type: video.type,
            videoUrl: video.videoUrl,
            thumbnailUrl: video.thumbnailUrl,
            hlsUrl: video.hlsUrl,
            title: video.title,
            description: video.description,
            duration: video.duration,
            views: formatViews(video.viewsCount),
            user: video.user,
            postedAt: formatTimeAgo(video.createdAt),
        }));

        return {
            success: true,
            videos: formattedVideos,
        };
    })

    // Busca de vídeos
    .get('/search', async ({ query }) => {
        const { q, page = '1', limit = '20' } = query;

        if (!q || q.length < 2) {
            return { success: true, videos: [] };
        }

        const skip = (parseInt(page) - 1) * parseInt(limit);
        const searchTerm = `%${q}%`;

        const videos = await prisma.video.findMany({
            where: {
                status: VideoStatus.READY,
                OR: [
                    { title: { contains: q, mode: 'insensitive' } },
                    { description: { contains: q, mode: 'insensitive' } },
                    { tags: { hasSome: [q] } },
                ]
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
                parentVideo: {
                    select: {
                        id: true,
                        videoUrl: true,
                        thumbnailUrl: true,
                        title: true,
                        description: true,
                        duration: true,
                    }
                }
            },
            orderBy: { viewsCount: 'desc' },
            skip,
            take: parseInt(limit),
        });

        return {
            success: true,
            videos: videos.map(v => ({
                id: v.id,
                thumbnailUrl: v.thumbnailUrl,
                title: v.title,
                views: formatViews(v.viewsCount),
                user: v.user,
            }))
        };
    });

// Helpers
function formatViews(count: number): string {
    if (count >= 1000000) {
        return `${(count / 1000000).toFixed(1)}M`;
    }
    if (count >= 1000) {
        return `${(count / 1000).toFixed(1)}k`;
    }
    return count.toString();
}

function formatTimeAgo(date: Date): string {
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffMins < 60) {
        return `${diffMins} min atrás`;
    }
    if (diffHours < 24) {
        return `${diffHours} horas atrás`;
    }
    if (diffDays < 7) {
        return `${diffDays} dias atrás`;
    }
    return date.toLocaleDateString('pt-BR');
}
