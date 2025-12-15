# Plano de Implementação: App Nativo Flutter & Web (Shorts/Vídeos Longos)

Este plano descreve o desenvolvimento de uma plataforma social de vídeos semelhante ao `modelo-app`, apresentando vídeos curtos (feed), vídeos longos (player horizontal) e processamento automatizado de vídeos.

## Arquitetura de Alto Nível

*   **Frontend**: Flutter (Mobile: iOS/Android, Web: PWA Responsivo).
*   **Backend**: Runtime Bun com framework ElysiaJS.
*   **Banco de Dados**: PostgreSQL (Gerenciado ou Genérico).
*   **ORM**: Prisma (rodando no Bun).
*   **Hospedagem de Vídeo**: Bunny.net Stream (Armazenamento e entrega HLS).
*   **Processamento**: Worker em Segundo Plano (BullMQ) para Algoritmo de Corte Automático (FFmpeg).

## Revisão do Usuário Necessária

> [!IMPORTANT]
> **Custos de Processamento de Vídeo**: O recurso de "Cortes Automáticos" requer processamento no servidor (FFmpeg). Isso efetivamente exige um VPS ou servidor dedicado (ex: Hetzner, AWS EC2), pois funções serverless podem exceder o tempo limite com vídeos longos.

> [!NOTE]
> **Configuração Bunny.net**: Você precisará de um ID de Biblioteca e Chave de API do Bunny.net Stream.

## Mudanças Propostas

### 1. Serviço Backend (Bun + Elysia)

O backend lidará com requisições de API, autenticação de usuário e gerenciamento de vídeos.

#### Design do Esquema (PostgreSQL)
*   **Usuarios**: `id`, `email`, `google_id`, `handle`, `avatar`, `contagem_seguidores`. (Removido: `hash_senha`)
*   **Videos**: `id`, `usuario_id`, `tipo` ('CURTO', 'LONGO'), `bunny_video_id`, `duracao`, `url_thumbnail`.
*   **Interacoes**: `id`, `usuario_id`, `video_id`, `tipo` ('CURTIDA', 'COMPARTILHAMENTO', 'VISUALIZACAO'), `tempo_assistido`.
*   **Comentarios**: `id`, `usuario_id`, `video_id`, `texto`.

#### Endpoints da API
*   `POST /auth/google` (Recebe ID Token, Verifica, Cria/Loga Usuário e Retorna Session/JWT)
*   `GET /feed` (Baseado em algoritmo)
*   `POST /videos/upload` (Gera URL pré-assinada do Bunny.net)
*   `POST /videos/process` (Dispara worker de Corte Automático para vídeos longos)
*   `POST /interaction` (Registra curtidas, visualizações)

### 2. Algoritmos

#### A. Mecanismo de Recomendação
*   **Objetivo**: Servir vídeos curtos relevantes no feed.
*   **Lógica**:
    *   **Pontuação**:
        *   Curtida: +10 pontos
        *   Compartilhamento: +20 pontos
        *   Comentário: +5 pontos
        *   Taxa de Conclusão (>80%): +5 pontos
        *   Frescor: Reduzir pontuação em 10% a cada 24h.
    *   **Consulta**: Selecionar vídeos com maior pontuação que o Usuário X NÃO viu.
    *   **Cold Start**: Mostrar vídeos mais populares globalmente.

#### B. Algoritmo de Corte Automático (Longo -> Shorts)
*   **Objetivo**: Extrair clipes verticais interessantes de <3min de vídeos horizontais longos, **focando no rosto do orador**.
*   **Pipeline**:
    1.  **Entrada**: Vídeo Horizontal 10min+ (16:9).
    2.  **Detecção de Cena**: Usar FFmpeg para encontrar mudanças de cena.
    3.  **Detecção Facial**: Utilizar bibliotecas (ex: OpenCV, MediaPipe ou filtros FFmpeg `cropdetect`) para identificar coordenadas do rosto.
    4.  **Smart Crop Dinâmico**: 
        *   Calcular o bounding box do rosto.
        *   Recortar vídeo para 9:16 mantendo o rosto centralizado (Pan & Scan automático).
    5.  **Atividade de Áudio**: Identificar segmentos com fala.
    6.  **Saída**: Gerar 3-5 clipes verticais focados no orador.

### 3. Aplicativo Flutter (Mobile & Web)

#### Funcionalidades Principais
*   **Autenticação**: Login Social (Google Sign-In apenas).
*   **Feed**: `PageView.builder` (Vertical) para Shorts.
    *   Pré-carregamento de 3 vídeos à frente.
    *   Interface de sobreposição (Corações, Comentários, Compartilhar).
    *   Gestos de deslizar (Direita -> Perfil Usuário, Esquerda -> Busca).
*   **Player**: Widget de Player de Vídeo Compartilhado.
    *   **Shorts**: Loop, Ajuste de capa (Cover fit).
    *   **Longos**: Controles habilitados, suporte a Paisagem.
*   **Upload**:
    *   Seletor de arquivos (Galeria/Câmera).
    *   Interface de Corte (Trim básico no cliente).
    *   Barra de progresso de upload.

#### Módulos (Arquitetura Modular)
*   `core`: DI, Networking, constantes, temas.
*   `features/auth`: Login, Registro.
*   `features/feed`: Lógica do feed vertical.
*   `features/video_details`: Player horizontal.
*   `features/profile`: Perfil do usuário, grade de vídeos.
*   `features/upload`: Câmera, seleção, upload.

## Plano de Verificação

### Testes Automatizados
*   **Backend**: Testes unitários para cálculo de recomendação usando `bun test`.
*   **Mobile**: Testes de widget para interações no Feed (Simulação de Swipe).

### Verificação Manual
1.  **Fluxo do Usuário**: Registrar -> Enviar Vídeo Longo -> Aguardar Corte Automático -> Verificar Feed para shorts gerados.
2.  **Algoritmo**: Curtir 5 vídeos da "Categoria A", atualizar feed, verificar se aparecem mais vídeos da "Categoria A".
3.  **Multi-Plataforma**: Verificar layout na Web (Desktop Chrome) e Emulador Android.
