import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhema_app/core/theme/app_theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implementar Google Sign-In real
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        context.go('/feed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer login: $e'),
            backgroundColor: RhemaColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RhemaColors.primary50,
      body: Stack(
        children: [
          // Círculos decorativos de fundo
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: RhemaColors.primary200.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: RhemaColors.primary300.withOpacity(0.2),
              ),
            ),
          ),

          // Conteúdo
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    
                    // Logo/Título
                    _buildHeader(),
                    
                    const Spacer(flex: 2),
                    
                    // Botões de Login
                    _buildAuthButtons(),
                    
                    const SizedBox(height: 32),
                    
                    // Termos
                    _buildTerms(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Ícone com gradiente
        Hero(
          tag: 'app_logo',
          child: Container(
            width: 120, // Slightly smaller than Splash
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/logo_transparent.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Slogan
        const SizedBox(height: 8),
        
        // Slogan
        Text(
          'CONECTANDO EM ESPÍRITO',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 12,
            fontWeight: FontWeight.w300,
            letterSpacing: 3,
            color: RhemaColors.primary600,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthButtons() {
    return Column(
      children: [
        // Botão Google
        _AuthButton(
          onPressed: _isLoading ? null : _handleGoogleSignIn,
          icon: Image.network(
            'https://www.svgrepo.com/show/475656/google-color.svg',
            width: 22,
            height: 22,
            errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
          ),
          label: 'Continuar com Google',
          backgroundColor: Colors.white,
          textColor: RhemaColors.primary700,
          borderColor: RhemaColors.primary200,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        
        // Botão Email
        _AuthButton(
          onPressed: _isLoading ? null : () {
            // TODO: Tela de login com email
            context.go('/feed');
          },
          icon: const Icon(Icons.mail_outline, size: 22, color: Colors.white),
          label: 'Entrar com Email',
          backgroundColor: RhemaColors.primary800,
          textColor: Colors.white,
          hasShadow: true,
        ),
      ],
    );
  }

  Widget _buildTerms() {
    return Text.rich(
      TextSpan(
        text: 'Ao entrar, você concorda com nossos\n',
        style: TextStyle(
          fontSize: 12,
          color: RhemaColors.primary400,
        ),
        children: [
          TextSpan(
            text: 'Termos de Serviço',
            style: TextStyle(
              decoration: TextDecoration.underline,
              color: RhemaColors.primary600,
            ),
          ),
          const TextSpan(text: ' e '),
          TextSpan(
            text: 'Política de Privacidade',
            style: TextStyle(
              decoration: TextDecoration.underline,
              color: RhemaColors.primary600,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _AuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final bool hasShadow;
  final bool isLoading;

  const _AuthButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.hasShadow = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: RhemaColors.primary800.withOpacity(0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: borderColor != null
                  ? Border.all(color: borderColor!)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(textColor),
                    ),
                  )
                else
                  icon,
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
