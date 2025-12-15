import React, { useRef } from 'react';
import { X, Heart, Send } from 'lucide-react';
import { MOCK_COMMENTS } from '../constants';

interface CommentsDrawerProps {
  isOpen: boolean;
  onClose: () => void;
}

const CommentsDrawer: React.FC<CommentsDrawerProps> = ({ isOpen, onClose }) => {
  const touchStartY = useRef<number>(0);

  if (!isOpen) return null;

  const handleTouchStart = (e: React.TouchEvent) => {
    touchStartY.current = e.touches[0].clientY;
  };

  const handleTouchEnd = (e: React.TouchEvent) => {
    const touchEndY = e.changedTouches[0].clientY;
    const deltaY = touchEndY - touchStartY.current;

    // Swipe Down to close (Positive deltaY because finger moves down, so Y increases)
    if (deltaY > 30) {
      onClose();
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 backdrop-blur-sm transition-opacity duration-300">
      <div 
        className="w-full max-w-md bg-white rounded-t-3xl h-[70vh] flex flex-col shadow-2xl animate-slide-up"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header with Gesture Handle */}
        <div 
            className="flex flex-col items-center justify-between p-4 border-b border-gray-100 cursor-grab active:cursor-grabbing"
            onTouchStart={handleTouchStart}
            onTouchEnd={handleTouchEnd}
        >
            <div className="w-12 h-1.5 bg-gray-200 rounded-full mb-4" />
            <div className="flex w-full items-center justify-between">
                <div className="w-8" />
                <h3 className="font-serif font-semibold text-rhema-800">Comentários (342)</h3>
                <button onClick={onClose} className="p-1 rounded-full hover:bg-gray-100 text-gray-500">
                    <X size={20} />
                </button>
            </div>
        </div>

        {/* List */}
        <div className="flex-1 overflow-y-auto p-4 space-y-6 no-scrollbar">
            {MOCK_COMMENTS.map((comment) => (
                <div key={comment.id} className="flex gap-3">
                    <img src={comment.userAvatar} alt={comment.userName} className="w-9 h-9 rounded-full object-cover flex-shrink-0" />
                    <div className="flex-1">
                        <div className="flex items-start justify-between">
                             <span className="text-xs font-bold text-gray-700">{comment.userName}</span>
                             <div className="flex flex-col items-center">
                                 <Heart size={14} className="text-gray-400" />
                                 <span className="text-[10px] text-gray-400">{comment.likes}</span>
                             </div>
                        </div>
                        <p className="text-sm text-gray-800 font-light mt-0.5">{comment.text}</p>
                        <span className="text-xs text-gray-400 mt-1 block font-light">Responder • {comment.timestamp}</span>
                    </div>
                </div>
            ))}
             {/* Duplicate for scrolling */}
             {MOCK_COMMENTS.map((comment) => (
                <div key={comment.id + '_dup'} className="flex gap-3">
                    <img src={comment.userAvatar} alt={comment.userName} className="w-9 h-9 rounded-full object-cover flex-shrink-0" />
                    <div className="flex-1">
                        <div className="flex items-start justify-between">
                             <span className="text-xs font-bold text-gray-700">{comment.userName}</span>
                             <div className="flex flex-col items-center">
                                 <Heart size={14} className="text-gray-400" />
                                 <span className="text-[10px] text-gray-400">{comment.likes}</span>
                             </div>
                        </div>
                        <p className="text-sm text-gray-800 font-light mt-0.5">{comment.text}</p>
                        <span className="text-xs text-gray-400 mt-1 block font-light">Responder • {comment.timestamp}</span>
                    </div>
                </div>
            ))}
        </div>

        {/* Input */}
        <div className="p-4 border-t border-gray-100 bg-white pb-8">
            <div className="flex items-center gap-3">
                <img src="https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100" className="w-8 h-8 rounded-full" alt="Me" />
                <div className="flex-1 relative">
                    <input 
                        type="text" 
                        placeholder="Adicione um comentário com graça..." 
                        className="w-full bg-rhema-50 rounded-full py-2.5 px-4 text-sm focus:outline-none focus:ring-1 focus:ring-rhema-300 placeholder-gray-400"
                    />
                    <button className="absolute right-2 top-1/2 -translate-y-1/2 text-rhema-600 p-1">
                        <Send size={16} />
                    </button>
                </div>
            </div>
        </div>
      </div>
    </div>
  );
};

export default CommentsDrawer;