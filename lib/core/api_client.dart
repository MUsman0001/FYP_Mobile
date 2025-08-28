import 'package:dio/dio.dart';
import 'app_config.dart';
import 'secure_storage.dart';

class ApiClient {
  final Dio dio;
  final SecureStorage secureStorage;

  ApiClient({SecureStorage? storage})
    : secureStorage = storage ?? SecureStorage(),
      dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.baseUrl,
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }
}
