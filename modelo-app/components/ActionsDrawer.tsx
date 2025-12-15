import React, { useRef } from 'react';
import { X, Share2, Download, Flag, Copy, Instagram, Facebook, MessageCircle, Twitter } from 'lucide-react';

interface ActionsDrawerProps {
  isOpen: boolean;
  onClose: () => void;
}

const ActionsDrawer: React.FC<ActionsDrawerProps> = ({ isOpen, onClose }) => {
  const touchStartY = useRef<number>(0);

  if (!isOpen) return null;

  const handleTouchStart = (e: React.TouchEvent) => {
    touchStartY.current = e.touches[0].clientY;
  };

  const handleTouchEnd = (e: React.TouchEvent) => {
    const touchEndY = e.changedTouches[0].clientY;
    const deltaY = touchEndY - touchStartY.current;

    // Swipe Up to close
    if (deltaY < -30) {
      onClose();
    }
  };

  const socialApps = [
    { name: 'WhatsApp', icon: <MessageCircle className="text-green-500" />, color: 'bg-green-100' },
    { name: 'Instagram', icon: <Instagram className="text-pink-600" />, color: 'bg-pink-100' },
    { name: 'Facebook', icon: <Facebook className="text-blue-600" />, color: 'bg-blue-100' },
    { name: 'Twitter', icon: <Twitter className="text-sky-500" />, color: 'bg-sky-100' },
  ];

  const actions = [
      { name: 'Copiar Link', icon: <Copy size={20} /> },
      { name: 'Salvar Vídeo', icon: <Download size={20} /> },
      { name: 'Denunciar', icon: <Flag size={20} className="text-red-500" /> },
  ];

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center bg-black/40 backdrop-blur-sm transition-opacity duration-300 pt-10">
      <div 
        className="w-full max-w-md bg-white rounded-b-3xl flex flex-col shadow-2xl animate-slide-down pb-6"
        onClick={(e) => e.stopPropagation()}
        onTouchStart={handleTouchStart}
        onTouchEnd={handleTouchEnd}
      >
         {/* Handle for drag (visual) */}
         <div className="w-full flex justify-center pt-3 pb-1 cursor-grab">
            <div className="w-12 h-1.5 bg-gray-200 rounded-full" />
         </div>

         <div className="flex items-center justify-between px-6 pt-2 pb-4">
             <h3 className="text-lg font-serif font-medium text-rhema-800">Compartilhar a Palavra</h3>
             <button onClick={onClose} className="p-2 bg-gray-50 rounded-full">
                 <X size={18} className="text-gray-600"/>
             </button>
         </div>

         {/* Social Rows */}
         <div className="px-6 flex gap-6 overflow-x-auto no-scrollbar py-2">
            {socialApps.map((app) => (
                <div key={app.name} className="flex flex-col items-center gap-2 min-w-[70px]">
                    <div className={`w-14 h-14 rounded-full flex items-center justify-center ${app.color} shadow-sm`}>
                        {app.icon}
                    </div>
                    <span className="text-xs text-gray-600">{app.name}</span>
                </div>
            ))}
         </div>

         <div className="h-[1px] bg-gray-100 mx-6 my-4" />

         {/* Actions Grid */}
         <div className="px-6 grid grid-cols-3 gap-4">
            {actions.map((action) => (
                <button key={action.name} className="flex flex-col items-center gap-2 py-3 hover:bg-gray-50 rounded-xl transition-colors">
                    <div className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center text-gray-700">
                        {action.icon}
                    </div>
                    <span className="text-xs text-gray-600 font-medium">{action.name}</span>
                </button>
            ))}
         </div>

      </div>
       {/* Transparent click area to close */}
      <div className="flex-1 w-full" onClick={onClose}></div>
    </div>
  );
};

export default ActionsDrawer;