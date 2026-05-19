import 'package:dio/dio.dart';

void main() async {
  print('=== Base URL WITHOUT trailing slash ===');
  final dio1 = Dio(BaseOptions(baseUrl: 'http://192.168.1.222:5008/api/v1'));
  dio1.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      print('Path: "${options.path}" -> Resolved: ${options.uri}');
      handler.reject(DioException(requestOptions: options, message: 'Stop'));
    },
  ));
  try { await dio1.post('/auth/login'); } catch (_) {}
  try { await dio1.post('auth/login'); } catch (_) {}

  print('=== Base URL WITH trailing slash ===');
  final dio2 = Dio(BaseOptions(baseUrl: 'http://192.168.1.222:5008/api/v1/'));
  dio2.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      print('Path: "${options.path}" -> Resolved: ${options.uri}');
      handler.reject(DioException(requestOptions: options, message: 'Stop'));
    },
  ));
  try { await dio2.post('/auth/login'); } catch (_) {}
  try { await dio2.post('auth/login'); } catch (_) {}
}
