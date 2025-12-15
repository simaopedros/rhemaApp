import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rhema_app/core/theme/app_theme.dart';
import 'package:rhema_app/features/feed/data/models/video_model.dart';
import 'package:intl/intl.dart';

class VideoStatsDrawer extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onClose;

  const VideoStatsDrawer({
    super.key,
    required this.video,
    required this.onClose,
  });

  static void show(BuildContext context, {required VideoModel video}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: Colors.black26, // Mais suave
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: VideoStatsDrawer(
              video: video,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutQuad, // Animação mais suave
          )),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final compactFormat = NumberFormat.compact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Cores baseadas no tema
    final backgroundColor = isDark ? RhemaColors.cardBackground : Colors.white;
    final primaryTextColor = isDark ? Colors.white : RhemaColors.primary900;
    final secondaryTextColor = isDark ? RhemaColors.primary300 : RhemaColors.primary600;

    return Dismissible(
      key: const Key('stats_drawer'),
      direction: DismissDirection.up,
      onDismissed: (_) => onClose(),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: topPadding + 12),
                
                // Header Compacto
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: RhemaColors.gold.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.analytics_rounded, color: RhemaColors.gold, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Insights',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: primaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Botão Fechar discreto
                      GestureDetector(
                        onTap: onClose,
                        child: Icon(Icons.close_rounded, color: secondaryTextColor, size: 20),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Grid de Estatísticas (Grid 4 colunas para ser mais compacto)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(
                        icon: Icons.play_arrow_rounded, 
                        value: video.views, 
                        label: 'Visualizações',
                        color: Colors.blueAccent,
                        textColor: primaryTextColor,
                        subTextColor: secondaryTextColor,
                      ),
                      _buildStatItem(
                        icon: Icons.favorite_rounded, 
                        value: compactFormat.format(video.likes), 
                        label: 'Curtidas',
                        color: Colors.pinkAccent,
                        textColor: primaryTextColor,
                        subTextColor: secondaryTextColor,
                      ),
                      _buildStatItem(
                        icon: Icons.comment_rounded, 
                        value: compactFormat.format(video.comments), 
                        label: 'Comentários',
                        color: Colors.amber,
                        textColor: primaryTextColor,
                        subTextColor: secondaryTextColor,
                      ),
                      _buildStatItem(
                        icon: Icons.share_rounded, 
                        value: compactFormat.format(video.shares), 
                        label: 'Compart.',
                        color: Colors.green,
                        textColor: primaryTextColor,
                        subTextColor: secondaryTextColor,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tags Horizontal Scroll (Compacto)
                if (video.tags.isNotEmpty)
                  SizedBox(
                    height: 28,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: video.tags.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: RhemaColors.primary200.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: RhemaColors.primary300.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '#${video.tags[index]}',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 12),

                // Drag Handle (Barra inferior indicando "puxar")
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: secondaryTextColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon, 
    required String value, 
    required String label,
    required Color color,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: subTextColor,
          ),
        ),
      ],
    );
  }
}
