import React from 'react';
import { Home, Search, PlusSquare, MessageSquare, User } from 'lucide-react';
import { ViewState } from '../types';

interface NavigationProps {
  currentView: ViewState;
  onNavigate: (view: ViewState) => void;
  isDark?: boolean;
}

const Navigation: React.FC<NavigationProps> = ({ currentView, onNavigate, isDark }) => {
  const textColor = isDark ? 'text-white' : 'text-gray-500';
  const activeColor = isDark ? 'text-white border-b-2 border-white pb-1' : 'text-rhema-800';

  return (
    <div className={`fixed bottom-0 left-0 right-0 py-3 px-6 flex justify-between items-end z-30 transition-colors duration-300 ${isDark ? 'bg-gradient-to-t from-black/80 to-transparent' : 'bg-white border-t border-gray-100'}`}>
      <button 
        onClick={() => onNavigate(ViewState.FEED)} 
        className={`flex flex-col items-center gap-1 ${currentView === ViewState.FEED ? activeColor : textColor}`}
      >
        <Home size={26} strokeWidth={currentView === ViewState.FEED ? 2.5 : 2} />
        <span className="text-[10px] font-medium">Início</span>
      </button>

      <button 
        onClick={() => onNavigate(ViewState.SEARCH)}
        className={`flex flex-col items-center gap-1 ${currentView === ViewState.SEARCH ? activeColor : textColor}`}
      >
        <Search size={26} strokeWidth={currentView === ViewState.SEARCH ? 2.5 : 2} />
        <span className="text-[10px] font-medium">Descobrir</span>
      </button>

      {/* Upload Button */}
      <button 
        onClick={() => onNavigate(ViewState.UPLOAD)}
        className="flex items-center justify-center -mt-4 transform transition-transform active:scale-95"
      >
        <div className="bg-gradient-to-tr from-rhema-300 to-rhema-100 p-1 rounded-xl shadow-lg">
             <div className="bg-white rounded-lg p-1.5">
                <PlusSquare size={28} className="text-rhema-900" />
             </div>
        </div>
      </button>

      <button className={`flex flex-col items-center gap-1 ${textColor}`}>
        <MessageSquare size={26} />
        <span className="text-[10px] font-medium">Chat</span>
      </button>

      <button 
        onClick={() => onNavigate(ViewState.PROFILE)}
        className={`flex flex-col items-center gap-1 ${currentView === ViewState.PROFILE ? activeColor : textColor}`}
      >
        <User size={26} strokeWidth={currentView === ViewState.PROFILE ? 2.5 : 2} />
        <span className="text-[10px] font-medium">Perfil</span>
      </button>
    </div>
  );
};

export default Navigation;
