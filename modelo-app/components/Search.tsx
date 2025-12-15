import React from 'react';
import { X, Search as SearchIcon, TrendingUp, Play } from 'lucide-react';

interface SearchProps {
  onClose: () => void;
}

const SEARCH_MOCK_DATA = [
  {
    id: 1,
    title: "Conferência Jovens 2024",
    author: "Igreja Local",
    views: "15k",
    image: "https://images.unsplash.com/photo-1519389950473-47ba0277781c?q=80&w=600&auto=format&fit=crop",
    tag: "Evento"
  },
  {
    id: 2,
    title: "Como ler a Bíblia todo dia?",
    author: "Teologia Descomplicada",
    views: "89k",
    image: "https://images.unsplash.com/photo-1491841550275-ad7854e35ca6?q=80&w=600&auto=format&fit=crop",
    tag: "Ensino"
  },
  {
    id: 3,
    title: "Melhores momentos Worship",
    author: "Som do Reino",
    views: "230k",
    image: "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?q=80&w=600&auto=format&fit=crop",
    tag: "Música"
  },
  {
    id: 4,
    title: "Testemunho Impactante",
    author: "Missões África",
    views: "45k",
    image: "https://images.unsplash.com/photo-1489659639091-8b687bc4386e?q=80&w=600&auto=format&fit=crop",
    tag: "Missões"
  },
  {
    id: 5,
    title: "Paz em meio à tempestade",
    author: "Devocional Diário",
    views: "12k",
    image: "https://images.unsplash.com/photo-1469474968028-56623f02e42e?q=80&w=600&auto=format&fit=crop",
    tag: "Reflexão"
  },
  {
    id: 6,
    title: "Tour pelo estúdio de gravação",
    author: "Podcast Cristão",
    views: "5k",
    image: "https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?q=80&w=600&auto=format&fit=crop",
    tag: "Vlog"
  }
];

const TRENDING_TAGS = [
  "#Louvor2025",
  "#JejumColetivo",
  "#EstudoRomanos",
  "#ConferenciaRhēma",
  "#WorshipNoQuarto"
];

const Search: React.FC<SearchProps> = ({ onClose }) => {
  return (
    <div className="h-full w-full bg-white flex flex-col animate-fade-in overflow-hidden">
      {/* Header Fixo */}
      <div className="pt-12 px-4 pb-2 border-b border-gray-100 bg-white z-10">
        <div className="flex items-center justify-between mb-4">
            <h1 className="text-2xl font-bold font-serif text-rhema-800">Descobrir</h1>
            <button onClick={onClose} className="p-2 bg-gray-50 rounded-full text-gray-500 hover:bg-gray-100">
            <X size={20} />
            </button>
        </div>
        
        {/* Barra de Busca */}
        <div className="relative mb-2">
            <SearchIcon className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
            <input 
                type="text" 
                placeholder="Busque por pessoas, igrejas ou temas..." 
                className="w-full bg-rhema-50 text-gray-800 rounded-xl py-3 pl-10 pr-4 text-sm focus:outline-none focus:ring-2 focus:ring-rhema-200"
            />
        </div>
      </div>

      <div className="flex-1 overflow-y-auto no-scrollbar pb-20">
        {/* Tags em Alta */}
        <div className="px-4 py-4">
            <div className="flex items-center gap-2 mb-3">
                <TrendingUp size={16} className="text-rhema-600" />
                <span className="text-xs font-bold uppercase tracking-wider text-gray-500">Em Alta no Rhēma</span>
            </div>
            <div className="flex gap-2 overflow-x-auto no-scrollbar pb-2">
                {TRENDING_TAGS.map(tag => (
                    <button key={tag} className="whitespace-nowrap px-4 py-1.5 bg-white border border-gray-200 rounded-full text-sm font-medium text-gray-600 hover:border-rhema-400 hover:text-rhema-800 transition-colors">
                        {tag}
                    </button>
                ))}
            </div>
        </div>

        {/* Banner Destaque */}
        <div className="px-4 mb-6">
            <div className="relative aspect-[2/1] rounded-2xl overflow-hidden shadow-sm">
                <img 
                    src="https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=800&auto=format&fit=crop" 
                    className="w-full h-full object-cover"
                    alt="Banner"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/80 to-transparent flex flex-col justify-end p-4">
                    <span className="bg-rhema-gold text-white text-[10px] px-2 py-0.5 rounded w-fit font-bold mb-1">AO VIVO</span>
                    <h3 className="text-white font-serif font-bold text-lg">Vigília Global de Oração</h3>
                    <p className="text-white/80 text-xs">Junte-se a 10.000 adoradores agora.</p>
                </div>
            </div>
        </div>

        {/* Grid de Conteúdo */}
        <div className="px-4">
            <h3 className="text-lg font-bold text-gray-800 mb-4">Para Você</h3>
            <div className="grid grid-cols-2 gap-3">
                {SEARCH_MOCK_DATA.map((item) => (
                    <div key={item.id} className="relative aspect-[9/14] rounded-xl overflow-hidden bg-gray-100 group cursor-pointer">
                        <img src={item.image} alt={item.title} className="w-full h-full object-cover" />
                        <div className="absolute inset-0 bg-black/20 group-hover:bg-black/10 transition-colors" />
                        
                        {/* Tag Category */}
                        <div className="absolute top-2 right-2">
                             <span className="text-[10px] font-bold bg-black/40 text-white backdrop-blur-sm px-2 py-0.5 rounded">
                                {item.tag}
                             </span>
                        </div>

                        {/* Info Bottom */}
                        <div className="absolute bottom-0 left-0 right-0 p-3 bg-gradient-to-t from-black/80 to-transparent pt-8">
                            <h4 className="text-white text-sm font-semibold leading-tight line-clamp-2 mb-1">{item.title}</h4>
                            <div className="flex items-center justify-between">
                                <span className="text-white/80 text-xs truncate mr-2">{item.author}</span>
                                <div className="flex items-center gap-1 text-white/70 text-[10px]">
                                    <Play size={8} fill="currentColor" />
                                    <span>{item.views}</span>
                                </div>
                            </div>
                        </div>
                    </div>
                ))}
            </div>
        </div>

        <div className="h-10"></div>
      </div>
    </div>
  );
};

export default Search;