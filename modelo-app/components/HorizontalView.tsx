
import React from 'react';
import { Video } from '../types';
import { ChevronLeft, MoreHorizontal, Heart, Play, BadgeCheck } from 'lucide-react';
import { MOCK_VIDEOS } from '../constants';

interface HorizontalViewProps {
  video: Video;
  onBack: () => void;
}

const HorizontalView: React.FC<HorizontalViewProps> = ({ video, onBack }) => {
  return (
    <div className="fixed inset-0 z-40 bg-rhema-50 flex flex-col overflow-y-auto animate-fade-in">
      {/* Header */}
      <div className="sticky top-0 bg-white/80 backdrop-blur-md px-4 py-3 flex items-center justify-between z-10 border-b border-gray-100">
        <button onClick={onBack} className="flex items-center text-rhema-800">
            <ChevronLeft size={24} />
            <span className="ml-1 font-medium">Voltar</span>
        </button>
        <span className="font-serif italic font-semibold text-rhema-800">Rhēma Player</span>
        <button>
            <MoreHorizontal size={24} className="text-rhema-800" />
        </button>
      </div>

      {/* Main Video Area */}
      <div className="w-full aspect-video bg-black relative">
         <img src={video.url} className="w-full h-full object-cover opacity-90" alt="Main content" />
         <div className="absolute inset-0 flex items-center justify-center">
            <div className="w-16 h-16 bg-white/20 backdrop-blur-sm rounded-full flex items-center justify-center pl-1 border border-white/40">
                <Play fill="white" className="text-white" size={32} />
            </div>
         </div>
         {/* Controls Bar Simulation */}
         <div className="absolute bottom-0 left-0 right-0 h-1 bg-gray-700">
            <div className="w-1/3 h-full bg-rhema-gold"></div>
         </div>
      </div>

      {/* Info Section */}
      <div className="p-5 bg-white mb-2 shadow-sm">
         <h1 className="text-xl font-serif font-bold text-gray-900 mb-2 leading-tight">{video.description}</h1>
         
         <div className="flex items-center justify-between mt-4">
            <div className="flex items-center gap-3">
                <img src={video.user.avatar} className="w-10 h-10 rounded-full object-cover" alt="User" />
                <div>
                    <div className="flex items-center gap-1">
                        <h3 className="font-bold text-sm text-gray-900">{video.user.name}</h3>
                        {video.user.isVerified && (
                             <BadgeCheck size={14} className="text-white fill-rhema-gold" />
                        )}
                    </div>
                    <p className="text-xs text-gray-500">{video.user.followers} seguidores</p>
                </div>
                <button className="bg-rhema-800 text-white text-xs px-3 py-1.5 rounded-full ml-2">Seguindo</button>
            </div>
            <div className="flex gap-4 text-gray-600">
                <div className="flex flex-col items-center">
                    <Heart size={20} />
                    <span className="text-xs mt-0.5">{video.likes}</span>
                </div>
            </div>
         </div>
         
         <div className="mt-4 flex gap-2 flex-wrap">
            {video.tags.map(tag => (
                <span key={tag} className="text-xs bg-rhema-50 text-rhema-600 px-2 py-1 rounded-md">
                    {tag}
                </span>
            ))}
         </div>
      </div>

      {/* Suggestions */}
      <div className="p-4">
        <h4 className="font-medium text-gray-500 text-sm mb-4 uppercase tracking-wider">Relacionados</h4>
        <div className="grid grid-cols-2 gap-4">
            {MOCK_VIDEOS.map((v) => (
                <div key={v.id} className="flex flex-col gap-2">
                    <div className="relative aspect-[16/9] rounded-lg overflow-hidden bg-gray-200">
                        <img src={v.url} className="w-full h-full object-cover" alt="Thumb" />
                        <span className="absolute bottom-1 right-1 bg-black/60 text-white text-[10px] px-1 rounded">2:45</span>
                    </div>
                    <div>
                        <p className="text-sm font-medium text-gray-800 line-clamp-2">{v.description}</p>
                        <p className="text-xs text-gray-500 mt-0.5">{v.user.name}</p>
                    </div>
                </div>
            ))}
             {MOCK_VIDEOS.map((v) => (
                <div key={'rel_' + v.id} className="flex flex-col gap-2">
                    <div className="relative aspect-[16/9] rounded-lg overflow-hidden bg-gray-200">
                        <img src={v.url} className="w-full h-full object-cover" alt="Thumb" />
                        <span className="absolute bottom-1 right-1 bg-black/60 text-white text-[10px] px-1 rounded">5:12</span>
                    </div>
                    <div>
                        <p className="text-sm font-medium text-gray-800 line-clamp-2">{v.description}</p>
                        <p className="text-xs text-gray-500 mt-0.5">{v.user.name}</p>
                    </div>
                </div>
            ))}
        </div>
      </div>
    </div>
  );
};

export default HorizontalView;
