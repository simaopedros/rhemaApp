import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rhema_app/core/theme/app_theme.dart';
import 'package:rhema_app/features/upload/presentation/providers/upload_controller.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(uploadControllerProvider);
    final controller = ref.read(uploadControllerProvider.notifier);
    final theme = Theme.of(context);

    // Listener para feedback
    ref.listen(uploadControllerProvider, (previous, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vídeo enviado com sucesso! Processando...'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        controller.clearSelection();
        // TODO: Navegar para Home/Feed
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    // TELA DE SELEÇÃO (ESTADO VAZIO)
    if (state.selectedFile == null) {
      return Scaffold(
        backgroundColor: RhemaColors.primary50,
        appBar: AppBar(
          title: const Text('Criar Publicação', style: TextStyle(color: Colors.black87)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Compartilhe seu momento',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ).animate().fadeIn().moveY(begin: -20, end: 0),
              
              const SizedBox(height: 8),
              
              Text(
                'Escolha como deseja enviar seu vídeo',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ).animate().fadeIn(delay: 200.ms).moveY(begin: -20, end: 0),
              
              const SizedBox(height: 48),

              // Botão Câmera
              _buildOptionCard(
                context,
                icon: Icons.camera_alt_rounded,
                title: 'Gravar Agora',
                subtitle: 'Use sua câmera para gravar um short',
                color: const Color(0xFFE1306C), // Gradient like Instagram/TikTok
                onTap: () => controller.pickVideo(ImageSource.camera),
                delay: 400.ms,
              ),

              const SizedBox(height: 20),

              // Botão Galeria
              _buildOptionCard(
                context,
                icon: Icons.photo_library_rounded,
                title: 'Galeria',
                subtitle: 'Escolha um vídeo existente',
                color: const Color(0xFF405DE6),
                onTap: () => controller.pickVideo(ImageSource.gallery),
                delay: 600.ms,
              ),
            ],
          ),
        ),
      );
    }

    // TELA DE FORMULÁRIO (VÍDEO SELECIONADO)
    return Scaffold(
      backgroundColor: RhemaColors.primary50,
      appBar: AppBar(
        title: const Text('Detalhes', style: TextStyle(color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => controller.clearSelection(),
        ),
        actions: [
          if (!state.isUploading)
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  controller.uploadVideo(
                    title: _titleController.text,
                    description: _descController.text,
                  );
                }
              },
              child: const Text('PUBLICAR', style: TextStyle(fontWeight: FontWeight.bold, color: RhemaColors.gold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview Area
              Hero(
                tag: 'video_preview',
                child: Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Video Info
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.movie_creation, size: 48, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              state.selectedFile?.name ?? '',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatFileSize(File(state.selectedFile!.path).lengthSync()),
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                      
                      // Play Button Overlay
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 32),

              // Upload Progress
              if (state.isUploading || state.isLoading) ...[
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: state.isLoading ? null : state.progress,
                      backgroundColor: Colors.grey[200],
                      color: theme.colorScheme.primary,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.isLoading 
                        ? 'Preparando vídeo...' 
                        : 'Enviando sua mensagem: ${(state.progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                  ],
                ).animate().fadeIn(),
                const SizedBox(height: 32),
              ],

              // Fields
              TextFormField(
                controller: _titleController,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Título',
                  labelStyle: const TextStyle(color: Colors.black54),
                  hintText: 'Ex: Meu vídeo incrível',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.title_rounded, color: RhemaColors.gold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: RhemaColors.gold, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => value == null || value.isEmpty ? 'Por favor, dê um título.' : null,
                enabled: !state.isUploading,
              ).animate().fadeIn(delay: 200.ms).moveX(begin: -20, end: 0),

              const SizedBox(height: 20),

              TextFormField(
                controller: _descController,
                maxLines: 5,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  labelStyle: const TextStyle(color: Colors.black54),
                  hintText: 'Conte mais sobre esse vídeo, use #hashtags...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.description_rounded, color: RhemaColors.gold),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: RhemaColors.gold, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                enabled: !state.isUploading,
              ).animate().fadeIn(delay: 300.ms).moveX(begin: -20, end: 0),

              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Política de Conteúdo: Mantenha o ambiente respeitoso e edificante.',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.primary.withOpacity(0.8)),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required Duration delay,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 100), // Altura mínima flexível
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13, // Levemente menor
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 16),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (bytes.toString().length - 1) ~/ 3; // Logaritmo base 1000 aproximado
    // Ajuste simples para divisão
    double size = bytes / (1.0 * (1 << (i * 10))); // Use 1024 base
    
    // Na verdade, a lógica acima para potências de 1024 (que é o padrão geralmente) seria:
    // double size = bytes / math.pow(1024, i);
    // Mas simplificando:
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
