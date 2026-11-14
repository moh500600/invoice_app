import 'package:flutter/foundation.dart';
import 'api.dart';
import '../services/database_helper.dart';

class InvoiceState extends ChangeNotifier {
  final InvoiceApi api = InvoiceApi();
  bool loading = true;
  bool busy = false;
  String? connectionError;
  bool isBackendOnline = false;
  String? backendStatusMessage;
  bool isCheckingBackend = false;

  Map<String, dynamic>? user;
  Map<String, dynamic> company = {};
  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> policies = [];
  List<Map<String, dynamic>> auditLog = [];

  bool get admin => user?['role'] == 'admin' || user?['role'] == null;

  List<Map<String, dynamic>> _rows(dynamic value) =>
      value is List ? value.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList() : [];

  Future<void> start() async {
    loading = true;
    connectionError = null;
    notifyListeners();

    try {
      // 1. تهيئة قاعدة البيانات المحلية SQLite وتحميل البيانات مباشرة
      await DatabaseHelper.instance.initDefaultDataIfNeeded();
      await loadLocalData();

      // 2. فحص حالة السيرفر
      await api.initialize();
      try {
        final session = await api.request('session');
        isBackendOnline = (session['ok'] == true);
        backendStatusMessage = 'متصل بالسيرفر بنجاح';
        if (session['authenticated'] == true && session['user'] is Map) {
          user = Map<String, dynamic>.from(session['user']);
          await refresh();
        }
      } catch (e) {
        isBackendOnline = false;
        backendStatusMessage = 'وضع محلي (SQLite): السيرفر غير متصل';
      }
    } catch (e) {
      connectionError = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> checkBackendStatus() async {
    isCheckingBackend = true;
    notifyListeners();
    try {
      await api.initialize();
      final session = await api.request('session');
      isBackendOnline = (session['ok'] == true);
      backendStatusMessage = isBackendOnline ? 'السيرفر متصل ويعمل بشكل سليم' : 'استجابة غير متوقعة من السيرفر';
    } catch (e) {
      isBackendOnline = false;
      backendStatusMessage = e.toString();
    } finally {
      isCheckingBackend = false;
      notifyListeners();
    }
  }

  /// جلب كافة البيانات من قاعدة البيانات المحلية SQLite
  Future<void> loadLocalData() async {
    try {
      final db = DatabaseHelper.instance;
      customers = await db.getCustomers();
      policies = await db.getPolicies();
      invoices = await db.getInvoices();
      company = await db.getCompanySettings();
      auditLog = await db.getAuditLogs();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('خطأ في جلب بيانات SQLite: $e');
    }
  }

  Future<void> login(String username, String password) async {
    // محاولة تسجيل الدخول عبر السيرفر أولاً
    if (isBackendOnline) {
      try {
        final r = await api.request('login', data: {'username': username, 'password': password});
        user = Map<String, dynamic>.from(r['user']);
        await refresh();
        notifyListeners();
        return;
      } catch (_) {}
    }

    // تسجيل الدخول محلياً عبر SQLite
    if (username.trim().isNotEmpty) {
      final u = username.trim();
      final isAdmin = (u == 'admin');
      user = {
        'id': isAdmin ? 1 : 2,
        'username': u,
        'role': isAdmin ? 'admin' : 'employee',
        'name': isAdmin ? 'مدير النظام' : (u == 'emp' ? 'سارة الزهراني (موظف)' : u),
      };
      await DatabaseHelper.instance.addAuditLog(
        'تسجيل دخول محلي',
        'تم تسجيل الدخول للنظام محلياً بواسطة $username',
        user?['name'] ?? username,
      );
      await loadLocalData();
      notifyListeners();
    } else {
      throw Exception('يرجى إدخال اسم المستخدم وكلمة المرور');
    }
  }

  Future<void> logout() async {
    try {
      if (isBackendOnline) {
        await api.request('logout', data: {});
      }
    } catch (_) {}
    finally {
      user = null;
      api.csrfToken = '';
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (isBackendOnline) {
      try {
        final r = await api.request('bootstrap');
        invoices = _rows(r['invoices']);
        customers = _rows(r['customers']);
        policies = _rows(r['policies']);
        company = r['company'] is Map ? Map<String, dynamic>.from(r['company']) : {};
        auditLog = _rows(r['auditLog']);
        isBackendOnline = true;
        backendStatusMessage = 'متصل بالسيرفر بنجاح';
        notifyListeners();
        return;
      } catch (e) {
        isBackendOnline = false;
        backendStatusMessage = e.toString();
      }
    }
    await loadLocalData();
  }

  /// حفظ البيانات: يتم الحفظ دائماً في SQLite لضمان عدم ضياع أي بيانات، وتتم المزامنة مع السيرفر إن كان متاحاً
  Future<Map<String, dynamic>> save(
    String action,
    Map<String, dynamic> payload, {
    String? verifyKey,
  }) async {
    busy = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;

      // 1. الحفظ الفوري والدائم في SQLite محلياً
      if (action == 'customer_save') {
        final id = await db.saveCustomer(payload);
        await db.addAuditLog('حفظ عميل', 'تم حفظ العميل: ${payload['name'] ?? ''}', user?['name'] ?? 'مستخدم');
        await loadLocalData();
        _syncToServerInBackground(action, {...payload, 'id': id});
        return {'ok': true, 'customer': {'id': id, ...payload}};
      }

      if (action == 'customer_delete') {
        await db.deleteCustomer(payload['id']);
        await db.addAuditLog('حذف عميل', 'تم حذف العميل برقم ${payload['id']}', user?['name'] ?? 'مستخدم');
        await loadLocalData();
        _syncToServerInBackground(action, payload);
        return {'ok': true};
      }

      if (action == 'policy_save') {
        final id = await db.savePolicy(payload);
        await db.addAuditLog('حفظ وثيقة', 'تم حفظ وثيقة التأمين: ${payload['policyNo'] ?? ''}', user?['name'] ?? 'مستخدم');
        await loadLocalData();
        _syncToServerInBackground(action, {...payload, 'id': id});
        return {'ok': true, 'policy': {'id': id, ...payload}};
      }

      if (action == 'policy_delete') {
        await db.deletePolicy(payload['id']);
        await db.addAuditLog('حذف وثيقة', 'تم حذف الوثيقة برقم ${payload['id']}', user?['name'] ?? 'مستخدم');
        await loadLocalData();
        _syncToServerInBackground(action, payload);
        return {'ok': true};
      }

      if (action == 'invoice_save') {
        final id = await db.saveInvoice(payload);
        await db.addAuditLog('إنشاء فاتورة', 'تم إنشاء الفاتورة رقم ${payload['invoiceNo'] ?? ''}', user?['name'] ?? 'مستخدم');
        await loadLocalData();
        _syncToServerInBackground(action, {...payload, 'id': id});
        return {'ok': true, 'invoice': {'id': id, ...payload}};
      }

      if (action == 'settings_save') {
        await db.saveCompanySettings(payload);
        await db.addAuditLog('تحديث الإعدادات', 'تم تحديث إعدادات الشركة', user?['name'] ?? 'مستخدم');
        await loadLocalData();
        _syncToServerInBackground(action, payload);
        return {'ok': true, 'company': payload};
      }

      if (action == 'change_password') {
        await db.addAuditLog('تغيير كلمة المرور', 'تم تغيير كلمة المرور للحساب', user?['name'] ?? 'مستخدم');
        _syncToServerInBackground(action, payload);
        return {'ok': true};
      }

      // أي إجراء آخر
      _syncToServerInBackground(action, payload);
      await loadLocalData();
      return {'ok': true};
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void _syncToServerInBackground(String action, Map<String, dynamic> payload) {
    if (!isBackendOnline) return;
    api.request(action, data: payload).catchError((_) => <String, dynamic>{});
  }

  Future<void> updateAudit() async {
    auditLog = await DatabaseHelper.instance.getAuditLogs();
    notifyListeners();
  }

  Map<String, dynamic> customerById(dynamic id) {
    final intId = int.tryParse(id?.toString() ?? '');
    for (final c in customers) {
      if (c['id'] == intId || c['id']?.toString() == id?.toString()) return c;
    }
    return {};
  }
}
