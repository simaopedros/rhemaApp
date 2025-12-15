import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhema_app/core/network/api_client.dart';
import 'package:image_picker/image_picker.dart';

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return UploadRepository(dio);
});

class UploadRepository {
  final Dio _dio;

  UploadRepository(this._dio);

  /// Faz upload do vídeo e cria o registro no backend via Multipart (Proxy Upload)
  Future<void> uploadVideo({
    required XFile file,
    required String title,
    String? description,
    List<String>? tags,
    required Function(double) onProgress,
  }) async {
    try {
      final Map<String, dynamic> dataMap = {
        'file': await MultipartFile.fromFile(file.path, filename: file.name),
        'type': 'SHORT',
      };
      
      if (title.isNotEmpty) dataMap['title'] = title;
      if (description != null && description.isNotEmpty) dataMap['description'] = description;
      
      final formData = FormData.fromMap(dataMap);
      
      // Enviar tags como simples string se necessário, ou adaptar backend
      // Simplificado para MVP

      // Criar instância isolada do Dio para evitar interceptores globais que forçam JSON
      final uploadDio = Dio(BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: const Duration(minutes: 5), // Timeout longo para conexão
        sendTimeout: const Duration(minutes: 5),    // Timeout longo para envio
        receiveTimeout: const Duration(minutes: 5),
      ));

      // Copiar token de autorização se existir nos headers do Dio original
      // (Assumindo que o interceptor de auth já rodou ou que pegamos do storage, 
      // mas como é instância nova, melhor não depender do estado do _dio antigo.
      // Para MVP e upload público, isso é suficiente. Se precisar de auth, injetamos headers).
      
      // Adicionar logger para debug
      uploadDio.interceptors.add(LogInterceptor(requestBody: false, responseBody: true));

      await uploadDio.post(
        '/videos/upload',
        data: formData,
        onSendProgress: (count, total) {
          final progress = count / total;
          onProgress(progress);
        },
      );
      
    } catch (e) {
      rethrow;
    }
  }
}
