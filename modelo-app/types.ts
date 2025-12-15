
export interface User {
  id: string;
  name: string;
  handle: string;
  avatar: string;
  bio?: string;
  followers: number;
  following: number;
  isVerified?: boolean; // Added for authentic official account status
}

export interface Comment {
  id: string;
  userId: string;
  userName: string;
  userAvatar: string;
  text: string;
  likes: number;
  timestamp: string;
}

export interface Video {
  id: string;
  url: string; // Using Image URL as video placeholder for demo
  thumbnail: string;
  description: string;
  tags: string[];
  user: User;
  likes: number;
  comments: number;
  shares: number;
  views: string;     
  postedAt: string;  
  isLiked?: boolean;
  isSaved?: boolean;
}

export enum ViewState {
  AUTH = 'AUTH',
  FEED = 'FEED',
  PROFILE = 'PROFILE',
  UPLOAD = 'UPLOAD',
  SEARCH = 'SEARCH'
}

export type FeedType = 'sugeridos' | 'seguindo';
