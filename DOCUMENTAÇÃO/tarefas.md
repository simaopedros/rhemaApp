# Plano de Projeto: App Flutter & Web com Backend Bun

- [x] Analisar App de Referência (`modelo-app`) <!-- id: 0 -->
    - [x] Analisar `App.tsx` e componentes principais <!-- id: 1 -->
    - [x] Entender modelos de dados em `types.ts` <!-- id: 2 -->
    - [x] Analisar padrões de UI/UX <!-- id: 3 -->
- [x] Design de Arquitetura do Sistema <!-- id: 4 -->
    - [x] Definir Arquitetura Backend (Bun + Elysia + Prisma) <!-- id: 5 -->
    - [x] Design do Esquema do Banco de Dados (PostgreSQL) <!-- id: 6 -->
    - [x] Infraestrutura de Vídeo (Bunny.net Stream) <!-- id: 7 -->
- [x] Design de Algoritmos <!-- id: 8 -->
    - [x] Projetar Algoritmo de Recomendação (pgvector) <!-- id: 9 -->
    - [x] Projetar Algoritmo de Cortes Automáticos (Lógica FFmpeg) <!-- id: 10 -->
- [x] Planejamento de Implementação <!-- id: 11 -->
    - [x] Criar `plano_implementacao.md` detalhado <!-- id: 12 -->
    - [x] Criar Fluxogramas e Diagramas <!-- id: 13 -->

## FASE 1: Configuração & Arquitetura Inicial
- [x] **Configuração do Ambiente**
    - [x] Criar estrutura de diretórios (backend/mobile)
    - [x] Inicializar projeto Bun (`bun init`)
    - [x] Inicializar projeto Flutter (`flutter create`)
- [x] **Backend Base**
    - [x] package.json com dependências
    - [x] tsconfig.json
    - [x] Prisma schema completo com pgvector
    - [x] Entry point do servidor (index.ts)

## FASE 2: Backend (Bun + Elysia)
- [x] **Rotas de API**
    - [x] Autenticação Google (`/auth/google`)
    - [x] Feed de Vídeos (`/feed`)
    - [x] Upload de Vídeos (`/videos`)
    - [x] Perfil de Usuário (`/users`)
    - [x] Interações (`/interactions`)
- [ ] **Integração Bunny.net**
    - [ ] Configurar webhooks
    - [ ] Testar upload direto

## FASE 3: Mobile (Flutter)
- [x] **Estrutura Base**
    - [x] Design System (Cores, Tipografia)
    - [x] Router (GoRouter)
    - [x] Cliente HTTP (Dio)
    - [x] Constants centralizadas
- [x] **Telas Implementadas**
    - [x] Splash Screen (animada)
    - [x] Auth Screen (Google Sign-In)
    - [x] Feed Screen (PageView vertical)
    - [x] Video Card (com ações)
    - [x] Profile Screen (com tabs)
    - [x] Search Screen
    - [x] Upload Screen
    - [x] Video Player Screen (horizontal)
- [ ] **Integrações**
    - [x] Conectar com API backend
    - [ ] Google Sign-In real
    - [x] Video Player real (video_player)

## FASE 4: Próximos Passos
- [x] Instalar dependências do backend (`bun install`)
- [x] Configurar PostgreSQL local
- [x] Rodar migrações do Prisma
- [x] Instalar dependências do Flutter (`flutter pub get`)
- [x] Baixar fontes (Plus Jakarta Sans, Playfair Display)
- [x] Testar app no emulador

## NOTAS
- Logo e ícone já copiados para `mobile/assets/images/`
- Backend usa JWT para autenticação
- Feed usa algoritmo de pontuação baseado em interações
- Suporte a pgvector para recomendações futuras
