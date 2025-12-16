import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rhema_app/core/constants/constants.dart';
import 'dart:math' as math;

/// Provider do cliente HTTP Dio
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  
  // Interceptor para logs em desenvolvimento
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => print('🌐 DIO: $o'),
    ),
  );
  
  // Interceptor para adicionar token de autenticação
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final storage = const FlutterSecureStorage();
        final token = await storage.read(key: StorageKeys.authToken);
        
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Tratar erros de autenticação
        if (error.response?.statusCode == 401) {
          // Token expirado - limpar storage e redirecionar para login
          final storage = const FlutterSecureStorage();
          await storage.deleteAll();
          // O AuthNotifier vai detectar a mudança e redirecionar
        }
        return handler.next(error);
      },
    ),
  );
  
  return dio;
});

/// Provider do Secure Storage
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
});

/// Classe base para serviços de API
abstract class ApiService {
  final Dio dio;
  
  ApiService(this.dio);
  
  /// Trata erros da API e retorna mensagem amigável
  String handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tempo de conexão esgotado. Verifique sua internet.';
      case DioExceptionType.connectionError:
        return 'Sem conexão com a internet.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        if (data is Map && data['error'] != null) {
          return data['error'];
        }
        // Fallback with debug info
        return 'Erro ($statusCode) no servidor. ${data != null ? data.toString().substring(0, math.min(50, data.toString().length)) : ''}';
      default:
        return 'Erro inesperado: ${e.message}';
    }
  }
}
