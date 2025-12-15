# Cronograma Mestre de Desenvolvimento (Checklist Completo)

Este arquivo contém todas as etapas detalhadas para o desenvolvimento do projeto RHEMA (App Flutter + Backend Bun + Vídeos), organizado cronologicamente.

## FASE 1: Configuração & Arquitetura Inicial
- [ ] **Configuração do Ambiente**
    - [ ] Instalar Bun (Runtime Backend)
    - [ ] Instalar Flutter SDK (Stable Channel)
    - [ ] Configurar Banco de Dados PostgreSQL Local
    - [ ] Criar conta/projeto na Bunny.net (Stream)
- [ ] **Inicialização do Projeto (Repositórios)**
    - [ ] Criar monorepo ou repositórios separados (backend/mobile)
    - [ ] Inicializar projeto Bun (`bun init`)
    - [ ] Inicializar projeto Flutter (`flutter create`)
    - [ ] Configurar Git e `.gitignore`

## FASE 2: Backend (Bun + Elysia) & Banco de Dados
- [ ] **Banco de Dados (Prisma & Postgres)**
    - [ ] Instalar Prisma ORM
    - [ ] Definir Schema `User` (id, email, senha, perfil)
    - [ ] Definir Schema `Video` (id, url, status, duração)
    - [ ] Definir Schema `Interaction` (likes, views)
    - [ ] Rodar migração inicial (`prisma migrate dev`)
- [ ] **API de Autenticação (Google Only)**
    - [ ] Instalar biblioteca de validação Google Auth
    - [ ] Endpoint `POST /auth/google`:
        - [ ] Validar ID Token do Google
        - [ ] Verificar se email existe no Banco
        - [ ] Criar usuario se não existir (Auto-register)
        - [ ] Retornar JWT da aplicação
    - [ ] Middleware de Proteção de Rotas (Validar JWT App)
- [ ] **API de Vídeos (Básico)**
    - [ ] Endpoint `POST /videos/upload` (Gerar Assinatura Bunny.net)
    - [ ] Endpoint `GET /feed` (Lista simples inicial)
    - [ ] Endpoint `GET /videos/:id` (Detalhes)

## FASE 3: Infraestrutura de Vídeo & Processamento (Cortes)
- [ ] **Integração Bunny.net**
    - [ ] Configurar Webhooks (Vídeo processado, Falha)
    - [ ] Testar upload direto via API
- [ ] **Worker de Processamento (FFmpeg & AI)**
    - [ ] Configurar fila de tarefas (BullMQ + Redis)
    - [ ] Criar script de detecção de cenas com FFmpeg
    - [ ] **Implementar Detecção Facial** (OpenCV/TensorFlow Lite ou API externa)
    - [ ] Criar lógica de "Smart Crop" baseada na posição do rosto
    - [ ] Implementar pipeline: Download -> Detectar Rosto -> Cortar Vertical -> Upload Clipe
- [ ] **API de Cortes**
    - [ ] Endpoint `POST /videos/process` (Recebe ID vídeo longo)
    - [ ] Lógica para salvar os "Shorts" gerados no Banco de Dados

## FASE 4: Algoritmos de Recomendação
- [ ] **Sistema de Pontuação**
    - [ ] Criar função de cálculo de score (Likes * 10, Views * 1...)
    - [ ] Implementar "Decaimento de Tempo" (Vídeos velhos valem menos)
- [ ] **Endpoint de Feed Inteligente**
    - [ ] Alterar `GET /feed` para usar a query de recomendação
    - [ ] Implementar paginação (Cursor-based pagination)
    - [ ] Filtrar vídeos já assistidos

## FASE 5: Desenvolvimento Mobile (Flutter)
- [ ] **Estrutura Base**
    - [ ] Configurar Temas e Cores (Design System)
    - [ ] Configurar Navegação (GoRouter ou AutoRoute)
    - [ ] Configurar Gerenciamento de Estado (Riverpod/Bloc)
- [ ] **Autenticação UI**
    - [ ] Configurar Projeto no Firebase Console (apenas para obter config Google) ou Google Cloud Console
    - [ ] Instalar `google_sign_in` no Flutter
    - [ ] Botão "Entrar com Google"
    - [ ] Lógica de envio do Token para Backend
- [ ] **Feed Vertical (Shorts)**
    - [ ] Widget `VideoPlayer` (otimizado para loop)
    - [ ] Implementar `PageView` vertical
    - [ ] Sobreposição de UI (Botões de Like, Comentário)
    - [ ] Conectar ao endpoint `GET /feed`
- [ ] **Player Horizontal (Vídeos Longos)**
    - [ ] Criar tela de detalhes para vídeo longo
    - [ ] Habilitar controles (Seek, Play/Pause, Fullscreen)
    - [ ] Suporte a rotação de tela
- [ ] **Upload de Vídeo**
    - [ ] Selecionar vídeo da galeria
    - [ ] Tela de Upload com Barra de Progresso
    - [ ] Enviar metadados para Backend

## FASE 6: Web App (Flutter Web)
- [ ] **Adaptação Responsiva**
    - [ ] Layout grid para Desktop (Feed não é tela cheia)
    - [ ] Navegação lateral (Sidebar) para telas grandes
- [ ] **Otimização Web**
    - [ ] Configurar renderizador Canvas/HTML
    - [ ] SEO Básico (Meta tags dinâmicas no index.html se possível ou SSR wrapper)

## FASE 7: Social & Polimento
- [ ] **Interações**
    - [ ] Implementar Curtir (Optimistic UI update)
    - [ ] Implementar Comentários (Lista + Input)
    - [ ] Implementar Perfil de Usuário (Lista de vídeos publicados)
- [ ] **Testes & QA**
    - [ ] Teste de Carga no Backend
    - [ ] Teste de Usabilidade no App
    - [ ] Correção de Bugs (Scroll, Performance de Vídeo)

## FASE 8: Deploy
- [ ] **Backend Deploy**
    - [ ] Configurar Dockerfile para Bun
    - [ ] Deploy em VPS/Cloud
- [ ] **App Stores**
    - [ ] Gerar APK/AAB Assinado (Android)
    - [ ] Configurar projeto Xcode (iOS)
    - [ ] Deploy Web (Vercel/Netlify/Firebase Hosting)
