
import React, { useRef, useState } from 'react';
import { Video } from '../types';
import { Heart, Bookmark, Music2, UserPlus, UserCheck, Share2, MessageCircle, Instagram, Link, MoreHorizontal, Twitter, BadgeCheck } from 'lucide-react';

interface VideoCardProps {
  video: Video;
  isActive: boolean;
  onSwipeUp: () => void;
  onSwipeDown: () => void;
  onShare: () => void;
  onClick: () => void;
}

const VideoCard: React.FC<VideoCardProps> = ({ video, isActive, onSwipeUp, onSwipeDown, onShare, onClick }) => {
  const touchStartX = useRef<number>(0);
  const touchStartY = useRef<number>(0);
  const lastTapTime = useRef<number>(0);
  
  const [isLiked, setIsLiked] = useState(false);
  const [isSaved, setIsSaved] = useState(false);
  const [isFollowing, setIsFollowing] = useState(false);
  const [showBigHeart, setShowBigHeart] = useState(false);
  
  // Controls the avatar menu expansion
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  // Controls the nested share menu
  const [isShareMenuOpen, setIsShareMenuOpen] = useState(false);

  const handleTouchStart = (e: React.TouchEvent) => {
    touchStartX.current = e.touches[0].clientX;
    touchStartY.current = e.touches[0].clientY;
  };

  const handleTouchEnd = (e: React.TouchEvent) => {
    const touchEndX = e.changedTouches[0].clientX;
    const touchEndY = e.changedTouches[0].clientY;

    const deltaX = touchStartX.current - touchEndX;
    const deltaY = touchStartY.current - touchEndY;

    // Double Tap Detection
    if (Math.abs(deltaX) < 20 && Math.abs(deltaY) < 20) {
        const now = Date.now();
        if (now - lastTapTime.current < 300) {
            handleDoubleTap();
        }
        lastTapTime.current = now;
        return;
    }

    // Swipe Detection
    if (Math.abs(deltaY) > Math.abs(deltaX)) {
      if (deltaY > 30) {
        onSwipeUp(); // Swipe Up opens comments
      } else if (deltaY < -30) {
        onSwipeDown(); // Swipe Down opens stats
      }
    }
  };

  const handleDoubleTap = () => {
    setIsLiked(true);
    setShowBigHeart(true);
    setTimeout(() => setShowBigHeart(false), 1000);
  };

  const toggleMenu = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (isMenuOpen) {
        // Closing everything
        setIsMenuOpen(false);
        setIsShareMenuOpen(false);
    } else {
        setIsMenuOpen(true);
    }
  };

  // --- Main Actions ---

  const handleLikeAction = (e: React.MouseEvent) => {
    e.stopPropagation();
    setIsLiked(!isLiked);
  };

  const handleSaveAction = (e: React.MouseEvent) => {
    e.stopPropagation();
    setIsSaved(!isSaved);
  };

  const handleFollowAction = (e: React.MouseEvent) => {
    e.stopPropagation();
    setIsFollowing(!isFollowing);
  };

  const handleOpenShareMenu = (e: React.MouseEvent) => {
    e.stopPropagation();
    setIsShareMenuOpen(true);
  };

  // --- Share Sub-actions ---
  
  const handleShareTo = (platform: string) => (e: React.MouseEvent) => {
      e.stopPropagation();
      console.log(`Sharing to ${platform}`);
      // Simulate close after action
      setIsMenuOpen(false);
      setIsShareMenuOpen(false);
  };

  const handleMoreShare = (e: React.MouseEvent) => {
    e.stopPropagation();
    onShare(); // Opens the full drawer
    // We keep the menu open or close it depending on preference. 
    // Usually opening a drawer should close the radial menu visually.
    setIsMenuOpen(false);
    setIsShareMenuOpen(false);
  };

  // Click on background closes the menu if open, otherwise triggers normal click
  const handleBackgroundClick = () => {
    if (isMenuOpen) {
        setIsMenuOpen(false);
        setIsShareMenuOpen(false);
    } else {
        onClick();
    }
  };

  return (
    <div 
      className="relative w-screen h-full snap-center flex-shrink-0 bg-black overflow-hidden select-none touch-pan-x"
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}
      onClick={handleBackgroundClick}
    >
      {/* Background/Video Simulation */}
      <img 
        src={video.url} 
        alt={video.description} 
        className={`w-full h-full object-cover transition-transform duration-700 ${isActive ? 'scale-100' : 'scale-105 opacity-50'}`} 
      />
      
      {/* Big Heart Animation for Double Tap */}
      <div 
        className={`absolute inset-0 flex items-center justify-center pointer-events-none z-30 transition-all duration-500 ${showBigHeart ? 'opacity-100 scale-125' : 'opacity-0 scale-50'}`}
      >
         <Heart size={120} className="fill-white text-white drop-shadow-2xl" />
      </div>

      {/* Overlay Gradient */}
      <div className="absolute inset-0 bg-gradient-to-b from-black/10 via-transparent to-black/60 pointer-events-none" />

      {/* Bottom Content with Avatar */}
      <div className="absolute bottom-6 left-4 right-4 z-20 pointer-events-none flex items-center justify-between gap-4">
        
        {/* Text Section (Left) */}
        <div className={`flex-1 transition-opacity duration-300 ${isMenuOpen ? 'opacity-30' : 'opacity-100'}`}>
            <div className="flex items-center gap-1.5 mb-2">
                <h3 className="text-white font-bold text-lg drop-shadow-md tracking-wide">
                    {video.user.handle}
                </h3>
                {video.user.isVerified && (
                  <BadgeCheck size={18} className="text-white fill-rhema-gold" />
                )}
            </div>
            
            <p className="text-white/90 text-sm leading-relaxed mb-3 drop-shadow-md line-clamp-2 font-light max-w-[90%]">
              {video.description}
            </p>

            <div className="flex items-center gap-2 text-white/80 animate-pulse">
                <Music2 size={14} />
                <span className="text-xs font-medium">Som original - {video.user.name}</span>
            </div>
        </div>

        {/* Avatar Section with Expandable Menu (Right) */}
        <div className="pointer-events-auto flex-shrink-0 relative w-16 h-16 flex items-center justify-center">
             
             {/* --- LEVEL 1: MAIN ACTIONS --- */}
             
             {/* 1. Like (Top - 90deg) */}
             <button 
                onClick={handleLikeAction}
                className={`absolute w-10 h-10 rounded-full flex items-center justify-center shadow-lg transition-all duration-300 ease-out border border-white/20
                    ${isLiked ? 'bg-red-500 text-white' : 'bg-black/40 backdrop-blur-md text-white'}
                    ${(isMenuOpen && !isShareMenuOpen) ? '-translate-y-[80px] opacity-100 scale-100' : 'translate-y-0 opacity-0 scale-50'}
                    ${isShareMenuOpen ? 'pointer-events-none' : ''}
                `}
             >
                <Heart size={18} className={isLiked ? 'fill-current' : ''} />
             </button>

             {/* 2. Share Trigger (Top-Left - 60deg) */}
             <button 
                onClick={handleOpenShareMenu}
                className={`absolute w-10 h-10 rounded-full flex items-center justify-center shadow-lg transition-all duration-300 ease-out delay-[25ms] border border-white/20 bg-black/40 backdrop-blur-md text-white
                    ${(isMenuOpen && !isShareMenuOpen) ? '-translate-y-[65px] -translate-x-[45px] opacity-100 scale-100' : 'translate-y-0 translate-x-0 opacity-0 scale-50'}
                    ${isShareMenuOpen ? 'pointer-events-none' : ''}
                `}
             >
                <Share2 size={18} />
             </button>

             {/* 3. Follow (Left-Top - 30deg) */}
             <button 
                onClick={handleFollowAction}
                className={`absolute w-10 h-10 rounded-full flex items-center justify-center shadow-lg transition-all duration-300 ease-out delay-[50ms] border border-white/20
                    ${isFollowing ? 'bg-rhema-gold text-white' : 'bg-black/40 backdrop-blur-md text-white'}
                    ${(isMenuOpen && !isShareMenuOpen) ? '-translate-y-[35px] -translate-x-[70px] opacity-100 scale-100' : 'translate-y-0 translate-x-0 opacity-0 scale-50'}
                    ${isShareMenuOpen ? 'pointer-events-none' : ''}
                `}
             >
                {isFollowing ? <UserCheck size={18} /> : <UserPlus size={18} />}
             </button>

             {/* 4. Save (Left - 0deg) */}
             <button 
                onClick={handleSaveAction}
                className={`absolute w-10 h-10 rounded-full flex items-center justify-center shadow-lg transition-all duration-300 ease-out delay-[75ms] border border-white/20
                    ${isSaved ? 'bg-rhema-gold text-white' : 'bg-black/40 backdrop-blur-md text-white'}
                    ${(isMenuOpen && !isShareMenuOpen) ? '-translate-x-[80px] opacity-100 scale-100' : 'translate-x-0 opacity-0 scale-50'}
                    ${isShareMenuOpen ? 'pointer-events-none' : ''}
                `}
             >
                <Bookmark size={18} className={isSaved ? 'fill-current' : ''} />
             </button>


             {/* --- LEVEL 2: SHARE ACTIONS (Replaces Level 1) --- */}

             {/* 1. WhatsApp (Top) */}
             <button 
                onClick={handleShareTo('whatsapp')}
                className={`absolute w-10 h-10 rounded-full flex items-center justify-center shadow-lg transition-all duration-300 ease-out border border-white/20 bg-[#25D366] text-white
                    ${(isMenuOpen && isShareMenuOpen) ? '-translate-y-[80px] opacity-100 scale-100' : 'translate-y-0 opacity-0 scale-50'}
                `}
             >
                <MessageCircle size={18} />
             </button>

             {/* 2. Instagram (Top-Left) */}
             <button 
                onClick={handleShareTo('instagram')}
                className={`absolute w-10 h-10 rounded-full flex items-center justify-center shadow-lg transition-all duration-300 ease-out delay-[25ms] border border-white/20 bg-gradient-to-tr from-yellow-500 via-red-500 to-purple-600 text-white
                    ${(isMenuOpen && isShareMenuOpen) ? '-translate-y-[65px] -translate-x-[45px] opacity-100 scale-100' : 'translate-y-0 translate-x-0 opacity-0 scale-50'}
                `}
             >
                <Instagram size={18} />
             </button>

             {/* 3. Twitter/X (Left-Top) */}
             <button 
                onClick={handleShareTo('twitter')}
                className={`absolute w-10 h-10 rounded-full flex items-center justify-center shadow-lg transition-all duration-300 ease-out delay-[50ms] border border-white/20 bg-black text-white
                    ${(isMenuOpen && isShareMenuOpen) ? '-translate-y-[35px] -translate-x-[70px] opacity-100 scale-100' : 'translate-y-0 translate-x-0 opacity-0 scale-50'}
                `}
             >
                <Twitter size={18} />
             </button>

             {/* 4. More (Left) */}
             <button 
                onClick={handleMoreShare}
                className={`absolute w-10 h-10 rounded-full flex items-center justify-center shadow-lg transition-all duration-300 ease-out delay-[75ms] border border-white/20 bg-gray-600 text-white
                    ${(isMenuOpen && isShareMenuOpen) ? '-translate-x-[80px] opacity-100 scale-100' : 'translate-x-0 opacity-0 scale-50'}
                `}
             >
                <MoreHorizontal size={18} />
             </button>

             {/* Main Avatar Trigger */}
             <div 
                onClick={toggleMenu}
                className={`relative z-10 transition-transform duration-300 ${isMenuOpen ? 'scale-90' : 'active:scale-95'}`}
             >
                <img 
                    src={video.user.avatar} 
                    className={`w-14 h-14 rounded-full object-cover shadow-2xl transition-all duration-300 ${isMenuOpen ? 'border-2 border-rhema-gold' : 'border-2 border-white'}`}
                    alt="User" 
                />
                {!isMenuOpen && (
                    <div className="absolute -bottom-1 -right-1 bg-rhema-gold rounded-full p-0.5 border-2 border-black">
                         <div className="w-2.5 h-2.5 bg-red-500 rounded-full"></div>
                    </div>
                )}
                {isMenuOpen && (
                    <div className="absolute inset-0 rounded-full bg-black/20" />
                )}
             </div>
        </div>

      </div>
    </div>
  );
};

export default VideoCard;
