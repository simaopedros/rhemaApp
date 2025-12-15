import React from 'react';
import { Mail } from 'lucide-react';

interface AuthProps {
  onLogin: () => void;
}

const Auth: React.FC<AuthProps> = ({ onLogin }) => {
  return (
    <div className="h-screen w-screen bg-[#F7F6F4] flex flex-col items-center justify-center p-8 relative overflow-hidden">
      {/* Background Decor */}
      <div className="absolute -top-20 -right-20 w-64 h-64 bg-rhema-200 rounded-full blur-3xl opacity-30" />
      <div className="absolute bottom-10 -left-10 w-80 h-80 bg-rhema-300 rounded-full blur-3xl opacity-20" />

      <div className="z-10 flex flex-col items-center w-full max-w-sm">
        <div className="mb-10 text-center">
             <h1 className="font-serif text-5xl text-rhema-800 italic mb-2">Rhēma</h1>
             <p className="text-rhema-600 font-light tracking-widest text-sm uppercase">Conectando em Espírito</p>
        </div>

        <div className="w-full space-y-4">
             <button 
                onClick={onLogin}
                className="w-full flex items-center justify-center gap-3 bg-white border border-gray-200 py-3.5 rounded-xl shadow-sm hover:bg-gray-50 transition-colors"
             >
                <img src="https://www.svgrepo.com/show/475656/google-color.svg" className="w-5 h-5" alt="Google" />
                <span className="text-gray-700 font-medium">Continuar com Google</span>
             </button>

             <button 
                onClick={onLogin}
                className="w-full flex items-center justify-center gap-3 bg-rhema-800 text-white py-3.5 rounded-xl shadow-lg shadow-rhema-800/20 hover:bg-rhema-900 transition-colors"
             >
                <Mail size={20} />
                <span className="font-medium">Entrar com Email</span>
             </button>
        </div>

        <div className="mt-8 text-center">
            <p className="text-xs text-gray-400">
                Ao entrar, você concorda com nossos <br/>
                <span className="underline cursor-pointer">Termos de Serviço</span> e <span className="underline cursor-pointer">Política de Privacidade</span>.
            </p>
        </div>
      </div>
    </div>
  );
};

export default Auth;
