/// Constantes da API e configurações
class ApiConstants {
  // Base URL do backend
  static const String baseUrl = 'https://varied-whenever-men-consequently.trycloudflare.com';
  
  // Endpoints de Autenticação
  static const String authGoogle = '/auth/google';
  static const String authDev = '/auth/dev';
  static const String authMe = '/auth/me';
  
  // Endpoints de Feed
  static const String feed = '/feed';
  static const String feedLong = '/feed/long';
  static const String feedSearch = '/feed/search';
  
  // Endpoints de Vídeo
  static const String videos = '/videos';
  static const String videoUpload = '/videos/upload';
  
  // Endpoints de Usuário
  static const String users = '/users';
  static const String usersSearch = '/users/search';
  
  // Endpoints de Interações
  static const String interactions = '/interactions';
  static const String interactionView = '/interactions/view';
  static const String interactionLike = '/interactions/like';
  static const String interactionShare = '/interactions/share';
  static const String interactionSave = '/interactions/save';
  static const String interactionComment = '/interactions/comment';
  
  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

/// Constantes de Assets
class AssetConstants {
  // Imagens
  static const String logo = 'assets/images/logo.png';
  static const String logoTransparent = 'assets/images/logo_transparent.png';
  static const String icon = 'assets/images/icon.png';
  static const String placeholder = 'assets/images/placeholder.png';
  
  // Ícones SVG
  static const String googleIcon = 'assets/icons/google.svg';
  static const String heartIcon = 'assets/icons/heart.svg';
  static const String commentIcon = 'assets/icons/comment.svg';
  static const String shareIcon = 'assets/icons/share.svg';
  
  // Animações Lottie
  static const String loadingAnimation = 'assets/animations/loading.json';
  static const String heartAnimation = 'assets/animations/heart.json';
}

/// Constantes de Storage
class StorageKeys {
  static const String authToken = 'auth_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String onboardingComplete = 'onboarding_complete';
}
