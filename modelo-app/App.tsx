
import React, { useState, useEffect, useRef } from 'react';
import { ViewState, FeedType, Video } from './types';
import { CURRENT_USER, MOCK_VIDEOS } from './constants';
import VideoCard from './components/VideoCard';
import Profile from './components/Profile';
import Auth from './components/Auth';
import CommentsDrawer from './components/CommentsDrawer';
import ActionsDrawer from './components/ActionsDrawer';
import VideoStatsDrawer from './components/VideoStatsDrawer';
import HorizontalView from './components/HorizontalView';
import Search from './components/Search';
import { Search as SearchIcon, User as UserIcon, PlusCircle } from 'lucide-react';

const App: React.FC = () => {
  const [viewState, setViewState] = useState<ViewState>(ViewState.AUTH);
  const [feedType, setFeedType] = useState<FeedType>('sugeridos');
  const [activeVideoIndex, setActiveVideoIndex] = useState(0);
  
  // Drawer States
  const [showComments, setShowComments] = useState(false);
  const [showActions, setShowActions] = useState(false);
  const [showStats, setShowStats] = useState(false);
  
  // Detailed View State
  const [selectedVideo, setSelectedVideo] = useState<Video | null>(null);

  const feedRef = useRef<HTMLDivElement>(null);

  // Intersection Observer for Feed to detect active video
  useEffect(() => {
    const container = feedRef.current;
    if (viewState !== ViewState.FEED || !container) return;

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const index = Number(entry.target.getAttribute('data-index'));
            setActiveVideoIndex(index);
          }
        });
      },
      { root: container, threshold: 0.6 }
    );

    const elements = container.querySelectorAll('[data-index]');
    elements.forEach((el) => observer.observe(el));

    return () => observer.disconnect();
  }, [viewState]);

  const handleVideoClick = (video: Video) => {
    setSelectedVideo(video);
  };

  const handleBackFromHorizontal = () => {
    setSelectedVideo(null);
  };

  if (viewState === ViewState.AUTH) {
    return <Auth onLogin={() => setViewState(ViewState.FEED)} />;
  }

  // Render Horizontal Detail View
  if (selectedVideo) {
    return <HorizontalView video={selectedVideo} onBack={handleBackFromHorizontal} />;
  }

  // Helper to get current video for stats
  const currentVideo = (activeVideoIndex < MOCK_VIDEOS.length) 
        ? MOCK_VIDEOS[activeVideoIndex] 
        : MOCK_VIDEOS[activeVideoIndex - MOCK_VIDEOS.length]; // Handle duplicate set logic

  return (
    <div className="relative h-screen w-screen overflow-hidden bg-black font-sans">
      
      {/* Top Bar (Navigation & Tabs) - Only visible in FEED */}
      {viewState === ViewState.FEED && (
        <div className="absolute top-0 left-0 right-0 z-20 grid grid-cols-3 items-center px-5 pt-12 pb-4 pointer-events-none bg-gradient-to-b from-black/40 to-transparent">
          
          {/* Left: Search */}
          <div className="justify-self-start pointer-events-auto">
             <button 
                onClick={() => setViewState(ViewState.SEARCH)} 
                className="text-white/90 hover:text-white transition-transform active:scale-90"
             >
                <SearchIcon size={26} strokeWidth={2} />
             </button>
          </div>

          {/* Center: Feed Tabs */}
          <div className="justify-self-center pointer-events-auto flex gap-4">
            <button 
              onClick={() => setFeedType('seguindo')}
              className={`text-base font-medium transition-all drop-shadow-md ${feedType === 'seguindo' ? 'text-white font-bold scale-105' : 'text-white/60'}`}
            >
              Seguindo
            </button>
            <div className="w-[1px] h-4 bg-white/20 my-auto" />
            <button 
              onClick={() => setFeedType('sugeridos')}
              className={`text-base font-medium transition-all drop-shadow-md ${feedType === 'sugeridos' ? 'text-white font-bold scale-105' : 'text-white/60'}`}
            >
              Sugeridos
            </button>
          </div>

          {/* Right: Upload & Profile */}
          <div className="justify-self-end pointer-events-auto flex items-center gap-5">
             <button 
                onClick={() => setViewState(ViewState.UPLOAD)}
                className="text-white/90 hover:text-white transition-transform active:scale-90"
             >
                <PlusCircle size={26} strokeWidth={2} />
             </button>
             <button 
                onClick={() => setViewState(ViewState.PROFILE)}
                className="text-white/90 hover:text-white transition-transform active:scale-90"
             >
                <UserIcon size={26} strokeWidth={2} />
             </button>
          </div>
        </div>
      )}

      {/* Main Content Area */}
      <main className="h-full w-full">
        {viewState === ViewState.FEED && (
          // Horizontal Scroll Container
          <div 
            ref={feedRef}
            className="flex h-full w-full overflow-x-scroll overflow-y-hidden snap-x snap-mandatory no-scrollbar"
          >
            {MOCK_VIDEOS.map((video, index) => (
              <div key={video.id} data-index={index} className="w-full h-full flex-shrink-0 snap-center">
                <VideoCard 
                  video={video} 
                  isActive={index === activeVideoIndex}
                  onSwipeUp={() => setShowComments(true)}
                  onSwipeDown={() => setShowStats(true)}
                  onShare={() => setShowActions(true)}
                  onClick={() => handleVideoClick(video)}
                />
              </div>
            ))}
            {/* Duplicates for scroll feel */}
            {MOCK_VIDEOS.map((video, index) => (
              <div key={video.id + '_dup'} data-index={MOCK_VIDEOS.length + index} className="w-full h-full flex-shrink-0 snap-center">
                <VideoCard 
                  video={video} 
                  isActive={(MOCK_VIDEOS.length + index) === activeVideoIndex}
                  onSwipeUp={() => setShowComments(true)}
                  onSwipeDown={() => setShowStats(true)}
                  onShare={() => setShowActions(true)}
                  onClick={() => handleVideoClick(video)}
                />
              </div>
            ))}
          </div>
        )}

        {viewState === ViewState.PROFILE && (
          <Profile user={CURRENT_USER} onBack={() => setViewState(ViewState.FEED)} />
        )}

        {viewState === ViewState.SEARCH && (
            <Search onClose={() => setViewState(ViewState.FEED)} />
        )}

        {viewState === ViewState.UPLOAD && (
             <div className="h-full w-full bg-black flex flex-col items-center justify-center text-white animate-fade-in">
                 <div className="w-16 h-16 border-4 border-red-500 rounded-full mb-4"></div>
                 <p className="font-serif italic">Gravar Testemunho</p>
                 <button onClick={() => setViewState(ViewState.FEED)} className="mt-12 text-sm text-gray-400 uppercase tracking-widest border border-gray-800 px-6 py-2 rounded-full">
                     Cancelar
                 </button>
             </div>
        )}
      </main>

      {/* Overlays */}
      <CommentsDrawer isOpen={showComments} onClose={() => setShowComments(false)} />
      <ActionsDrawer isOpen={showActions} onClose={() => setShowActions(false)} />
      
      {/* Stats Drawer (triggered by swipe down) */}
      <VideoStatsDrawer 
        isOpen={showStats} 
        onClose={() => setShowStats(false)} 
        video={currentVideo} 
      />

    </div>
  );
};

export default App;
