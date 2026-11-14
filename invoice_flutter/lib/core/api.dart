import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_config.dart';

const String _envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
final String apiBaseUrl = _envBaseUrl.isNotEmpty ? _envBaseUrl : ApiConfig.baseUrl;

class ApiException implements Exception {
  final String message;
  final int? status;
  const ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class InvoiceApi {
  late Dio dio;
  String csrfToken = '';
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      dio.options.baseUrl = ApiConfig.baseUrl;
      return;
    }

    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
      },
      extra: kIsWeb ? {'withCredentials': true} : {},
      responseType: ResponseType.plain,
      validateStatus: (status) => status != null && status < 600,
    ));
    
    // المتصفح (Web) يدير الكوكيز تلقائياً ومكتبة CookieManager ترمي خطأ إذا استُخدمت في بيئة Web
    if (!kIsWeb) {
      final dir = await getApplicationSupportDirectory();
      final cookieJar = PersistCookieJar(storage: FileStorage('${dir.path}/invoice_cookies'));
      dio.interceptors.add(CookieManager(cookieJar));
    }

    _initialized = true;
  }

  Future<Map<String, dynamic>> request(String action, {Map<String, dynamic>? data}) async {
    try {
      dio.options.baseUrl = ApiConfig.baseUrl;
      final response = await dio.request<String>(
        '',
        queryParameters: {'action': action},
        options: Options(
          method: data == null ? 'GET' : 'POST',
          headers: {
            if (data != null) 'Content-Type': 'application/json',
            if (data != null && action != 'login' && csrfToken.isNotEmpty)
              'X-CSRF-Token': csrfToken,
          },
        ),
        data: data == null ? null : jsonEncode(data),
      );
      final body = jsonDecode(response.data ?? '') as Map<String, dynamic>;
      if (body['csrfToken'] != null) csrfToken = body['csrfToken'].toString();
      if ((response.statusCode ?? 500) >= 400 || body['ok'] == false) {
        throw ApiException(body['message']?.toString() ?? 'فشلت العملية', response.statusCode);
      }
      return body;
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException('الخادم لم يرجع JSON. تحقق من تشغيل api.php وإعدادات الاستضافة (قد تحجب InfinityFree طلبات التطبيقات).');
    } on DioException catch (e) {
      throw ApiException('تعذر الاتصال بالخادم: ${e.message ?? 'تحقق من الشبكة وعنوان API'}');
    } catch (e) {
      throw ApiException('حدث خطأ غير متوقع: $e');
    }
  }
}
