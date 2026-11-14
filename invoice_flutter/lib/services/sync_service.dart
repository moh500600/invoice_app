import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'services.dart';
import 'database_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  /// دالة للتحقق من وجود اتصال بالإنترنت
  Future<bool> hasInternet() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  /// تنفيذ عملية الإرسال (POST) مع التخزين المحلي في حال عدم توفر اتصال
  Future<dynamic> postData(String action, Map<String, dynamic> data) async {
    bool isOnline = await hasInternet();

    if (isOnline) {
      try {
        // الاتصال بالباك إند
        final response = await ApiService.post(action, data);
        
        // جلب البيانات من الباك إند (يفضل أن يتم تحديث قاعدة البيانات المحلية بعد الـ POST مباشرة)
        // لتحديث الجدول المعني بناءً على نوع العملية
        if (action == 'customer_save' && response['customer'] != null) {
          await DatabaseHelper.instance.insertCustomer(response['customer']);
        }
        
        return response;
      } catch (e) {
        // في حالة فشل الاتصال رغم وجود شبكة، نحفظ في الطابور المحلي
        await _saveLocally(action, data);
        throw Exception('تم الحفظ محلياً بسبب خطأ في الخادم: $e');
      }
    } else {
      // لا يوجد اتصال بالإنترنت، نقوم بتخزين العملية في طابور المزامنة
      await _saveLocally(action, data);
      return {'ok': true, 'message': 'تم الحفظ محلياً، ستتم المزامنة عند توفر الإنترنت'};
    }
  }

  Future<void> _saveLocally(String action, Map<String, dynamic> data) async {
    await DatabaseHelper.instance.enqueueSyncOperation(action, data);
    
    // إضافة البيانات محلياً لتظهر للمستخدم فوراً حتى بدون إنترنت (تحديث وهمي مؤقت)
    if (action == 'customer_save') {
      await DatabaseHelper.instance.insertCustomer(data);
    }
    // يمكن إضافة باقي الجداول (الفواتير، الوثائق) بنفس الطريقة
  }

  /// دالة رفع الملفات الجديدة والمزامنة مع الباك إند عند عودة الاتصال
  Future<void> syncOfflineData() async {
    bool isOnline = await hasInternet();
    if (!isOnline) return;

    final queue = await DatabaseHelper.instance.getSyncQueue();
    if (queue.isEmpty) return;

    for (var operation in queue) {
      try {
        String action = operation['action'];
        Map<String, dynamic> payload = jsonDecode(operation['payload']);

        final response = await ApiService.post(action, payload);
        if (response['ok'] == true) {
          // تم الرفع بنجاح، نحذف العملية من الطابور المحلي
          await DatabaseHelper.instance.removeSyncOperation(operation['id']);
        }
      } catch (e) {
        print('خطأ في مزامنة العملية ${operation["id"]}: $e');
        // يتم التخطي والمحاولة مرة أخرى لاحقاً
      }
    }
    
    // بعد نجاح المزامنة، نجلب أحدث البيانات من السيرفر لتحديث القاعدة المحلية
    await refreshLocalDatabase();
  }

  /// تحديث كامل لقاعدة البيانات المحلية من الباك إند (Bootstrap)
  Future<void> refreshLocalDatabase() async {
    bool isOnline = await hasInternet();
    if (!isOnline) return;

    try {
      final response = await ApiService.get('bootstrap');
      if (response['ok'] == true) {
        await DatabaseHelper.instance.saveBootstrapData(response);
      }
    } catch (e) {
      print('خطأ في جلب البيانات الأولية: $e');
    }
  }
}
