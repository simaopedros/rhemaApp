import { Elysia, t } from 'elysia';
import prisma from '../lib/prisma';

export const searchRoutes = new Elysia({ prefix: '/search' })
    // Global Search (users and videos)
    .get('/', async ({ query }) => {
        const { q, limit = '20' } = query;
        const take = parseInt(limit);

        if (!q || q.length < 2) {
            return {
                success: true,
                users: [],
                videos: []
            };
        }

        const [users, videos] = await Promise.all([
            prisma.user.findMany({
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
                take,
                orderBy: { followersCount: 'desc' }
            }),
            prisma.video.findMany({
                where: {
                    OR: [
                        { title: { contains: q, mode: 'insensitive' } },
                        { description: { contains: q, mode: 'insensitive' } },
                        { tags: { has: q } } // Exact match for tag if searched
                    ],
                    status: 'READY'
                },
                select: {
                    id: true,
                    title: true,
                    thumbnailUrl: true,
                    videoUrl: true,
                    viewsCount: true,
                    likesCount: true,
                    commentsCount: true,
                    sharesCount: true,
                    description: true,
                    tags: true,
                    createdAt: true,
                    user: {
                        select: {
                            id: true,
                            name: true,
                            handle: true,
                            avatar: true,
                            isVerified: true
                        }
                    }
                },
                take,
                orderBy: { viewsCount: 'desc' }
            })
        ]);

        const mappedVideos = videos.map(v => ({
            ...v,
            views: v.viewsCount,
            likes: v.likesCount,
            comments: v.commentsCount,
            shares: v.sharesCount,
            postedAt: v.createdAt.toISOString()
        }));

        return {
            success: true,
            users,
            videos: mappedVideos
        };
    })

    // Trending Content
    .get('/trending', async () => {
        // Popular Users
        const popularUsers = await prisma.user.findMany({
            take: 5,
            orderBy: { followersCount: 'desc' },
            select: {
                id: true,
                name: true,
                handle: true,
                avatar: true,
                followersCount: true,
                isVerified: true
            }
        });

        // Popular Videos (Trending)
        const trendingVideos = await prisma.video.findMany({
            where: { status: 'READY' },
            take: 10,
            orderBy: [
                { viewsCount: 'desc' },
                { likesCount: 'desc' }
            ],
            select: {
                id: true,
                title: true,
                description: true,
                thumbnailUrl: true,
                videoUrl: true,
                viewsCount: true,
                likesCount: true,
                commentsCount: true,
                sharesCount: true,
                tags: true,
                createdAt: true,
                user: {
                    select: {
                        id: true,
                        name: true,
                        handle: true,
                        avatar: true,
                        isVerified: true
                    }
                }
            }
        });

        const mappedTrendingVideos = trendingVideos.map(v => ({
            ...v,
            views: v.viewsCount,
            likes: v.likesCount,
            comments: v.commentsCount,
            shares: v.sharesCount,
            postedAt: v.createdAt.toISOString()
        }));


        // Get tags from recent/popular videos to make it dynamic
        const recentVideos = await prisma.video.findMany({
            where: { status: 'READY' },
            take: 50,
            orderBy: { createdAt: 'desc' },
            select: { tags: true }
        });

        const tagCounts = new Map<string, number>();
        recentVideos.forEach(v => {
            v.tags.forEach(tag => {
                const t = tag.trim();
                if (t.startsWith('#')) {
                    tagCounts.set(t, (tagCounts.get(t) || 0) + 1);
                } else {
                    const hashTag = '#' + t;
                    tagCounts.set(hashTag, (tagCounts.get(hashTag) || 0) + 1);
                }
            });
        });

        // Sort by frequency and take top 15
        const sortedTags = Array.from(tagCounts.entries())
            .sort((a, b) => b[1] - a[1])
            .slice(0, 15)
            .map(entry => entry[0]);

        // Fallback default tags if empty
        const finalTags = sortedTags.length > 0 ? sortedTags : [
            '#louvor', '#adoracao', '#jesus', '#evangelho', '#fé',
            '#biblia', '#igreja', '#pregacao', '#vida', '#paz'
        ];

        return {
            success: true,
            trendingTags: finalTags,
            popularUsers,
            trendingVideos: mappedTrendingVideos
        };
    });
