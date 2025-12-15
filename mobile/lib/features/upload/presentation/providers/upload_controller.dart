import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rhema_app/features/upload/data/upload_repository.dart';

class UploadState {
  final bool isLoading;
  final bool isUploading;
  final double progress;
  final XFile? selectedFile;
  final String? error;
  final bool isSuccess;

  UploadState({
    this.isLoading = false,
    this.isUploading = false,
    this.progress = 0.0,
    this.selectedFile,
    this.error,
    this.isSuccess = false,
  });

  UploadState copyWith({
    bool? isLoading,
    bool? isUploading,
    double? progress,
    XFile? selectedFile,
    String? error,
    bool? isSuccess,
  }) {
    return UploadState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      selectedFile: selectedFile ?? this.selectedFile,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

final uploadControllerProvider = StateNotifierProvider.autoDispose<UploadController, UploadState>((ref) {
  final repository = ref.watch(uploadRepositoryProvider);
  return UploadController(repository);
});

class UploadController extends StateNotifier<UploadState> {
  final UploadRepository _repository;
  final ImagePicker _picker = ImagePicker();

  UploadController(this._repository) : super(UploadState());

  Future<void> pickVideo(ImageSource source) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        state = state.copyWith(selectedFile: video, error: null);
      }
    } catch (e) {
      state = state.copyWith(error: 'Erro ao selecionar vídeo: $e');
    }
  }

  void clearSelection() {
    state = UploadState();
  }

  Future<void> uploadVideo({required String title, String? description}) async {
    if (state.selectedFile == null) return;

    state = state.copyWith(isLoading: true, isUploading: true, progress: 0.0, error: null);

    try {
      await _repository.uploadVideo(
        file: state.selectedFile!,
        title: title,
        description: description,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      state = state.copyWith(isLoading: false, isUploading: false, isSuccess: true, progress: 1.0);
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        isUploading: false, 
        error: 'Falha no upload: $e'
      );
    }
  }
}
