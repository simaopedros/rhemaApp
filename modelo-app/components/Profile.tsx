
import React from 'react';
import { User as UserType } from '../types';
import { Settings, Bookmark, Grid, ChevronLeft, BadgeCheck } from 'lucide-react';
import { MOCK_VIDEOS } from '../constants';

interface ProfileProps {
  user: UserType;
  onBack: () => void;
}

const Profile: React.FC<ProfileProps> = ({ user, onBack }) => {
  return (
    <div className="min-h-screen bg-white pb-0 overflow-y-auto animate-slide-up">
      {/* Header */}
      <div className="sticky top-0 bg-white/95 backdrop-blur-sm z-10 flex justify-between items-center px-4 py-3 border-b border-gray-100">
        <button 
            onClick={onBack}
            className="p-2 -ml-2 text-rhema-800 rounded-full hover:bg-gray-50 transition-colors"
        >
            <ChevronLeft size={24} />
        </button>
        <h2 className="text-base font-bold text-gray-800">{user.name}</h2>
        <button className="p-2 -mr-2 text-gray-600 rounded-full hover:bg-gray-50">
            <Settings size={22} />
        </button>
      </div>

      <div className="p-6 flex flex-col items-center">
        <div className="relative">
            <img 
                src={user.avatar} 
                alt={user.name} 
                className="w-24 h-24 rounded-full object-cover border-4 border-rhema-50"
            />
            <div className="absolute bottom-0 right-0 bg-rhema-500 text-white text-[10px] px-2 py-0.5 rounded-full border-2 border-white">
                PRO
            </div>
        </div>

        <h1 className="mt-3 text-xl font-bold text-rhema-900 flex items-center gap-1.5">
            {user.handle}
            {user.isVerified && (
                <BadgeCheck size={20} className="text-white fill-rhema-gold" />
            )}
        </h1>
        <p className="text-sm text-gray-500 font-light mt-1 text-center max-w-xs">{user.bio}</p>

        {/* Stats */}
        <div className="flex w-full justify-around mt-6 border-y border-gray-50 py-4">
            <div className="flex flex-col items-center cursor-pointer active:scale-95 transition-transform">
                <span className="font-bold text-lg text-gray-800">142</span>
                <span className="text-xs text-gray-400">Publicações</span>
            </div>
            <div className="flex flex-col items-center border-x border-gray-100 w-full cursor-pointer active:scale-95 transition-transform">
                <span className="font-bold text-lg text-gray-800">{user.followers}</span>
                <span className="text-xs text-gray-400">Seguidores</span>
            </div>
            <div className="flex flex-col items-center cursor-pointer active:scale-95 transition-transform">
                <span className="font-bold text-lg text-gray-800">{user.following}</span>
                <span className="text-xs text-gray-400">Seguindo</span>
            </div>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-3 mt-6 w-full px-4">
            <button className="flex-1 bg-rhema-800 text-white py-2.5 rounded-lg text-sm font-medium shadow-sm hover:bg-rhema-900 transition-colors">
                Editar Perfil
            </button>
             <button className="flex-1 bg-gray-100 text-gray-700 py-2.5 rounded-lg text-sm font-medium hover:bg-gray-200 transition-colors">
                Compartilhar
            </button>
        </div>
      </div>

      {/* Content Tabs */}
      <div className="mt-2 min-h-[50vh]">
        <div className="flex border-b border-gray-200 sticky top-[60px] bg-white z-10">
            <button className="flex-1 flex justify-center py-3 border-b-2 border-rhema-800 transition-colors">
                <Grid size={24} className="text-rhema-800" />
            </button>
            <button className="flex-1 flex justify-center py-3 text-gray-400 hover:text-gray-600 transition-colors">
                <Bookmark size={24} />
            </button>
        </div>

        <div className="grid grid-cols-3 gap-0.5 mt-0.5 pb-20">
            {/* Repeating mock videos to fill profile */}
            {[...MOCK_VIDEOS, ...MOCK_VIDEOS, ...MOCK_VIDEOS].map((video, idx) => (
                <div key={idx} className="aspect-[3/4] bg-gray-200 relative group cursor-pointer">
                    <img src={video.thumbnail} className="w-full h-full object-cover" alt="Post" />
                    <div className="absolute inset-0 bg-black/20 opacity-0 group-hover:opacity-100 transition-opacity" />
                    <div className="absolute bottom-1 left-1 flex items-center gap-1">
                        <span className="text-[10px] text-white font-medium drop-shadow-md flex items-center gap-0.5">
                             ▶ {video.likes}
                        </span>
                    </div>
                </div>
            ))}
        </div>
      </div>
    </div>
  );
};

export default Profile;
