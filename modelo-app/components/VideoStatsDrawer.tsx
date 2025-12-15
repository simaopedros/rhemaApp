
import React, { useRef } from 'react';
import { X, Eye, Heart, MessageCircle, Share2, Calendar, TrendingUp } from 'lucide-react';
import { Video } from '../types';

interface VideoStatsDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  video: Video | null;
}

const VideoStatsDrawer: React.FC<VideoStatsDrawerProps> = ({ isOpen, onClose, video }) => {
  const touchStartY = useRef<number>(0);

  if (!isOpen || !video) return null;

  const handleTouchStart = (e: React.TouchEvent) => {
    touchStartY.current = e.touches[0].clientY;
  };

  const handleTouchEnd = (e: React.TouchEvent) => {
    const touchEndY = e.changedTouches[0].clientY;
    const deltaY = touchEndY - touchStartY.current;

    // Swipe Up (negative deltaY) to close, since this drawer comes from top
    if (deltaY < -30) {
      onClose();
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center bg-black/60 backdrop-blur-sm transition-opacity duration-300">
      <div 
        className="w-full bg-white rounded-b-3xl shadow-2xl animate-slide-down overflow-hidden"
        onClick={(e) => e.stopPropagation()}
        onTouchStart={handleTouchStart}
        onTouchEnd={handleTouchEnd}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-6 pt-12 pb-4 border-b border-gray-100">
             <div className="flex items-center gap-2 text-rhema-800">
                <TrendingUp size={20} />
                <h3 className="text-lg font-serif font-bold">Insights do Vídeo</h3>
             </div>
             <button onClick={onClose} className="p-2 bg-gray-50 rounded-full hover:bg-gray-100">
                 <X size={18} className="text-gray-600"/>
             </button>
        </div>

        {/* Content */}
        <div className="p-6">
            <h2 className="text-sm font-medium text-gray-500 uppercase tracking-widest mb-6">Performance</h2>
            
            <div className="grid grid-cols-2 gap-4 mb-8">
                {/* Views */}
                <div className="bg-rhema-50 p-4 rounded-2xl flex flex-col gap-2">
                    <div className="flex items-center gap-2 text-gray-500">
                        <Eye size={18} />
                        <span className="text-xs font-medium">Visualizações</span>
                    </div>
                    <span className="text-2xl font-bold text-gray-900">{video.views}</span>
                </div>

                {/* Likes */}
                <div className="bg-red-50 p-4 rounded-2xl flex flex-col gap-2">
                    <div className="flex items-center gap-2 text-red-400">
                        <Heart size={18} />
                        <span className="text-xs font-medium">Curtidas</span>
                    </div>
                    <span className="text-2xl font-bold text-gray-900">{video.likes.toLocaleString()}</span>
                </div>

                {/* Comments */}
                <div className="bg-blue-50 p-4 rounded-2xl flex flex-col gap-2">
                    <div className="flex items-center gap-2 text-blue-400">
                        <MessageCircle size={18} />
                        <span className="text-xs font-medium">Comentários</span>
                    </div>
                    <span className="text-2xl font-bold text-gray-900">{video.comments.toLocaleString()}</span>
                </div>

                {/* Shares */}
                <div className="bg-green-50 p-4 rounded-2xl flex flex-col gap-2">
                    <div className="flex items-center gap-2 text-green-500">
                        <Share2 size={18} />
                        <span className="text-xs font-medium">Compartilhamentos</span>
                    </div>
                    <span className="text-2xl font-bold text-gray-900">{video.shares.toLocaleString()}</span>
                </div>
            </div>

            <div className="border-t border-gray-100 pt-6">
                <div className="flex items-center gap-2 text-gray-400 mb-2">
                    <Calendar size={14} />
                    <span className="text-xs">Postado {video.postedAt}</span>
                </div>
                <p className="text-gray-600 text-sm leading-relaxed italic">
                    "{video.description}"
                </p>
                
                <div className="mt-4 flex flex-wrap gap-2">
                    {video.tags.map(tag => (
                        <span key={tag} className="text-xs px-2 py-1 bg-gray-100 text-gray-600 rounded-md">
                            {tag}
                        </span>
                    ))}
                </div>
            </div>
        </div>

        {/* Handle Visual */}
        <div className="w-full flex justify-center pb-4 pt-2 cursor-grab" onClick={onClose}>
            <div className="w-12 h-1.5 bg-gray-200 rounded-full" />
        </div>

      </div>
       {/* Transparent click area to close */}
      <div className="flex-1 w-full" onClick={onClose}></div>
    </div>
  );
};

export default VideoStatsDrawer;
