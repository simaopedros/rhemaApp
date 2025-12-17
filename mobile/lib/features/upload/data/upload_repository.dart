import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rhema_app/core/constants/constants.dart';
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
      // Obter token de autenticação
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: StorageKeys.authToken);
      
      if (token == null) {
        throw Exception('Você precisa estar logado para enviar vídeos');
      }

      final Map<String, dynamic> dataMap = {
        'file': await MultipartFile.fromFile(file.path, filename: file.name),
        'type': 'SHORT',
      };
      
      if (title.isNotEmpty) dataMap['title'] = title;
      if (description != null && description.isNotEmpty) dataMap['description'] = description;
      
      final formData = FormData.fromMap(dataMap);

      // Criar instância isolada do Dio com token de autenticação
      final uploadDio = Dio(BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ));

      // Adicionar logger para debug
      uploadDio.interceptors.add(LogInterceptor(requestBody: false, responseBody: true));

      final response = await uploadDio.post(
        '/videos/upload',
        data: formData,
        onSendProgress: (count, total) {
          final progress = count / total;
          onProgress(progress);
        },
      );
      
      print('✅ Upload concluído: ${response.data}');
      
    } on DioException catch (e) {
      print('❌ Upload error: ${e.response?.statusCode} - ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception('Sessão expirada. Faça login novamente.');
      }
      throw Exception(e.response?.data?['error'] ?? 'Erro no upload: ${e.message}');
    }
  }
}

