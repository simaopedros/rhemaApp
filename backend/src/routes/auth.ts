// Autenticação Google OAuth
import { OAuth2Client } from 'google-auth-library';
import { Elysia, t } from 'elysia';
import prisma from '../lib/prisma';

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// Gera um handle único baseado no nome
function generateHandle(name: string): string {
    const base = name
        .toLowerCase()
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/[^a-z0-9]/g, '')
        .slice(0, 15);
    const random = Math.floor(Math.random() * 9999);
    return `@${base}${random}`;
}

export const authRoutes = new Elysia({ prefix: '/auth' })
    // Login/Registro com Google
    .post('/google', async ({ jwt, body }) => {
        const { idToken } = body;

        try {
            // Verificar token do Google
            const ticket = await googleClient.verifyIdToken({
                idToken,
                audience: process.env.GOOGLE_CLIENT_ID,
            });

            const payload = ticket.getPayload();
            if (!payload || !payload.email) {
                throw new Error('Token inválido');
            }

            const { email, name, picture, sub: googleId } = payload;

            // Buscar ou criar usuário
            let user = await prisma.user.findUnique({
                where: { email }
            });

            if (!user) {
                // Novo usuário - registrar
                user = await prisma.user.create({
                    data: {
                        email,
                        googleId,
                        name: name || 'Usuário RHEMA',
                        handle: generateHandle(name || 'user'),
                        avatar: picture,
                    }
                });
                console.log(`✅ Novo usuário registrado: ${user.email}`);
            } else if (!user.googleId) {
                // Usuário existe mas sem googleId - vincular
                user = await prisma.user.update({
                    where: { id: user.id },
                    data: { googleId }
                });
            }

            // Gerar JWT da aplicação
            const token = await jwt.sign({
                userId: user.id,
                email: user.email
            });

            return {
                success: true,
                token,
                user: {
                    id: user.id,
                    email: user.email,
                    name: user.name,
                    handle: user.handle,
                    avatar: user.avatar,
                    bio: user.bio,
                    followersCount: user.followersCount,
                    followingCount: user.followingCount,
                    isVerified: user.isVerified,
                }
            };
        } catch (error) {
            console.error('Erro na autenticação Google:', error);
            throw new Error('Falha na autenticação com Google');
        }
    }, {
        body: t.Object({
            idToken: t.String()
        })
    })

    // Verificar token JWT
    .get('/me', async ({ jwt, headers }) => {
        const authHeader = headers.authorization;
        if (!authHeader?.startsWith('Bearer ')) {
            throw new Error('Token não fornecido');
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
                email: true,
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

    // Logout (invalidação no cliente)
    .post('/logout', () => {
        return { success: true, message: 'Logout realizado' };
    });
