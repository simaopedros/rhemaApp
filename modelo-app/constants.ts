
import { Video, User, Comment } from './types';

export const CURRENT_USER: User = {
  id: 'me',
  name: 'Ana Silva',
  handle: '@anasilva_23',
  avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop',
  bio: 'Amante da palavra | Salmos 23 🌿',
  followers: 1205,
  following: 340,
  isVerified: true 
};

export const MOCK_VIDEOS: Video[] = [
  {
    id: '1',
    url: 'https://images.unsplash.com/photo-1438232992991-995b7058bbb3?q=80&w=1920&auto=format&fit=crop', // Landscape/Nature
    thumbnail: 'https://images.unsplash.com/photo-1438232992991-995b7058bbb3?q=80&w=600&auto=format&fit=crop',
    description: "A paz que excede todo o entendimento. 🙏✨ #paz #natureza #criacao",
    tags: ['#paz', '#natureza', '#deus'],
    user: {
      id: 'u1',
      name: 'Devocional Diário',
      handle: '@devocional_hoje',
      avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&h=100&fit=crop',
      followers: 45000,
      following: 12,
      isVerified: true
    },
    likes: 12400,
    comments: 342,
    shares: 1500,
    views: '45.2k',
    postedAt: '2 horas atrás'
  },
  {
    id: '2',
    url: 'https://images.unsplash.com/photo-1510936111840-65e151ad71bb?q=80&w=1920&auto=format&fit=crop', // Guitar/Worship
    thumbnail: 'https://images.unsplash.com/photo-1510936111840-65e151ad71bb?q=80&w=600&auto=format&fit=crop',
    description: "Trecho do louvor de ontem. Foi sobrenatural! 🙌🎸 #worship #louvor #igreja",
    tags: ['#worship', '#musica'],
    user: {
      id: 'u2',
      name: 'Lucas Guitar',
      handle: '@lucas_worship',
      avatar: 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=100&h=100&fit=crop',
      followers: 8200,
      following: 400,
      isVerified: false
    },
    likes: 5600,
    comments: 120,
    shares: 400,
    views: '12.8k',
    postedAt: '1 dia atrás'
  },
  {
    id: '3',
    url: 'https://images.unsplash.com/photo-1507692049790-de58293a469d?q=80&w=1920&auto=format&fit=crop', // Bible Study
    thumbnail: 'https://images.unsplash.com/photo-1507692049790-de58293a469d?q=80&w=600&auto=format&fit=crop',
    description: "Estudo rápido sobre Romanos 8. Nada pode nos separar do amor de Deus. ❤️📖",
    tags: ['#biblia', '#estudo'],
    user: {
      id: 'u3',
      name: 'Pastora Helena',
      handle: '@helena.pastora',
      avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=100&h=100&fit=crop',
      followers: 98000,
      following: 50,
      isVerified: true
    },
    likes: 22100,
    comments: 890,
    shares: 3200,
    views: '89.1k',
    postedAt: '3 dias atrás'
  },
  {
    id: '4',
    url: 'https://images.unsplash.com/photo-1510590337019-5ef2d39aa7bf?q=80&w=1920&auto=format&fit=crop', // Abstract/Light
    thumbnail: 'https://images.unsplash.com/photo-1510590337019-5ef2d39aa7bf?q=80&w=600&auto=format&fit=crop',
    description: "Bom dia! Que a luz de Cristo brilhe sobre você hoje. ☀️",
    tags: ['#bomdia', '#fe'],
    user: {
      id: 'u4',
      name: 'Jovem Cristão',
      handle: '@jovemcristao',
      avatar: 'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=100&h=100&fit=crop',
      followers: 12000,
      following: 1200,
      isVerified: false
    },
    likes: 300,
    comments: 20,
    shares: 5,
    views: '1.2k',
    postedAt: '5 horas atrás'
  }
];

export const MOCK_COMMENTS: Comment[] = [
  {
    id: 'c1',
    userId: 'u10',
    userName: 'Marcos Souza',
    userAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop',
    text: 'Amém! Estava precisando ouvir isso hoje. 🙌',
    likes: 24,
    timestamp: '2h'
  },
  {
    id: 'c2',
    userId: 'u11',
    userName: 'Julia Ferreira',
    userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop',
    text: 'Glória a Deus!',
    likes: 12,
    timestamp: '1h'
  },
  {
    id: 'c3',
    userId: 'u12',
    userName: 'Pedro H.',
    userAvatar: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100&h=100&fit=crop',
    text: 'Lindo demais esse lugar.',
    likes: 5,
    timestamp: '30m'
  }
];
