import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    FirebaseAuth.instance,
    GoogleSignIn(
      serverClientId: '191691248376-tdrpdle8usephhljql7tk4315l8c5rbh.apps.googleusercontent.com',
    ),
  );
});

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthService(this._firebaseAuth, this._googleSignIn);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  /// Realiza o login com Google e Firebase.
  /// Retorna o `idToken` do Google para ser enviado ao backend.
  Future<String?> signInWithGoogle() async {
    try {
      // 1. Iniciar fluxo de login do Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Usuário cancelou

      // 2. Obter detalhes da autenticação
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Criar credencial para o Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Logar no Firebase
      await _firebaseAuth.signInWithCredential(credential);

      // 5. Retornar o ID Token do Google para enviar ao Backend
      // O backend atual valida o token nativo do Google
      return googleAuth.idToken;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
