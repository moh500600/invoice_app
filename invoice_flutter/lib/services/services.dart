import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {
  // الرابط مأخوذ تلقائياً من ملف api_config.dart
  static String get baseUrl => ApiConfig.baseUrl;
  
  static String? _cookie;
  static String? _csrfToken;

  /// دالة تقوم بتخزين الكوكيز للتعرف على جلسة المستخدم
  static void _updateCookie(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      _cookie = (index == -1) ? rawCookie : rawCookie.substring(0, index);
    }
  }

  /// إعداد الهيدرز اللازمة بما في ذلك كود الحماية (CSRF) وجلسة المستخدم
  static Map<String, String> _getHeaders() {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_cookie != null) {
      headers['Cookie'] = _cookie!;
    }
    if (_csrfToken != null) {
      headers['X-CSRF-TOKEN'] = _csrfToken!;
    }
    return headers;
  }

  /// دالة تسجيل الدخول - تُستخدم لجلب الكوكيز ورمز الحماية (CSRF Token)
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=login'),
        headers: _getHeaders(),
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );
      
      _updateCookie(response);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true && data['csrfToken'] != null) {
          _csrfToken = data['csrfToken'];
        }
        return data;
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'فشل تسجيل الدخول');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  /// دالة جلب البيانات (GET) للإجراءات المختلفة
  static Future<dynamic> get(String action) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=$action'),
        headers: _getHeaders(),
      );
      
      _updateCookie(response);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['csrfToken'] != null) {
          _csrfToken = data['csrfToken'];
        }
        return data;
      } else {
        throw Exception('فشل جلب البيانات: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  /// دالة إرسال البيانات (POST) مثل حفظ عميل، فاتورة، وغيرها
  static Future<dynamic> post(String action, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=$action'),
        headers: _getHeaders(),
        body: json.encode(data),
      );

      _updateCookie(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'فشل إرسال البيانات');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }
}
