import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import 'web_storage_stub.dart' if (dart.library.html) 'web_storage_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  bool _useFileFallback = false;

  // ذاكرة تخزين محلية في حال تشغيل الويب أو سطح المكتب الاحتياطي
  final Map<String, List<Map<String, dynamic>>> _webStore = {
    'customers': [],
    'policies': [],
    'invoices': [],
    'company_settings': [],
    'audit_logs': [],
    'users': [],
  };

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb || _useFileFallback) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDB('invoice_app.db');
      return _database!;
    } catch (_) {
      _useFileFallback = true;
      return null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createDB(db, newVersion);
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NULL';
    const realType = 'REAL NULL';
    const intType = 'INTEGER NULL';

    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id $idType,
        name $textType,
        vat $textType,
        cr $textType,
        mobile $textType,
        email $textType,
        address $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS policies (
        id $idType,
        customerId $intType,
        policyNo $textType,
        type $textType,
        startDate $textType,
        endDate $textType,
        premium $realType
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id $idType,
        invoiceNo $textType,
        policyNo $textType,
        endorsementNo $textType,
        customerId $intType,
        date $textType,
        description $textType,
        amount $realType,
        vatRate $realType,
        vatAmount $realType,
        total $realType,
        mobile $textType,
        email $textType,
        address $textType,
        createdBy $textType,
        createdAt $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS company_settings (
        id INTEGER PRIMARY KEY,
        nameAr $textType,
        nameEn $textType,
        vat $textType,
        cr $textType,
        address $textType,
        phone $textType,
        email $textType,
        website $textType,
        vatRate $realType,
        footerText $textType,
        logo $textType,
        stamp $textType,
        logoSize $intType,
        logoEnabled $intType,
        stampSize $intType,
        stampX $realType,
        stampY $realType,
        stampEnabled $intType
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id $idType,
        user $textType,
        action $textType,
        detail $textType,
        at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id $idType,
        username $textType,
        password $textType,
        name $textType,
        role $textType
      )
    ''');

    // طابور المزامنة
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id $idType,
        action $textType,
        payload $textType,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  // ==========================================
  // معالجة تخزين الويب (Web LocalStorage)
  // ==========================================
  void _loadWebStore() {
    if (kIsWeb) {
      for (final table in _webStore.keys) {
        final jsonStr = WebStorage.getItem('sqlite_$table');
        if (jsonStr != null && jsonStr.isNotEmpty) {
          try {
            final list = jsonDecode(jsonStr);
            if (list is List) {
              _webStore[table] = list.map((e) => Map<String, dynamic>.from(e)).toList();
            }
          } catch (_) {}
        }
      }
    } else {
      try {
        final file = File('${Directory.systemTemp.path}/invoice_app_store.json');
        if (file.existsSync()) {
          final data = jsonDecode(file.readAsStringSync());
          if (data is Map) {
            for (final k in _webStore.keys) {
              if (data[k] is List) {
                _webStore[k] = (data[k] as List).map((e) => Map<String, dynamic>.from(e)).toList();
              }
            }
          }
        }
      } catch (_) {}
    }
  }

  void _saveWebStore(String table) {
    if (kIsWeb) {
      try {
        WebStorage.setItem('sqlite_$table', jsonEncode(_webStore[table]));
      } catch (_) {}
    } else {
      try {
        final file = File('${Directory.systemTemp.path}/invoice_app_store.json');
        file.writeAsStringSync(jsonEncode(_webStore));
      } catch (_) {}
    }
  }

  // ==========================================
  // تعبئة البيانات الافتراضية الأولية (Seed Data)
  // ==========================================
  Future<void> initDefaultDataIfNeeded() async {
    final db = await database;
    if (db == null) {
      _loadWebStore();
      if (_webStore['customers']!.isEmpty) {
        _webStore['customers'] = [
          {'id': 1, 'name': 'شركة الأفق للمقاولات', 'vat': '310111222333', 'cr': '1010234567', 'mobile': '0501234567', 'email': 'info@ufuq.com.sa', 'address': 'الرياض - حي العليا'},
          {'id': 2, 'name': 'مستشفى النور الطبي', 'vat': '310444555666', 'cr': '1010987654', 'mobile': '0509876543', 'email': 'billing@alnoor-hosp.com.sa', 'address': 'جدة - الحمراء'},
          {'id': 3, 'name': 'مجموعة الخليج للتجارة', 'vat': '310777888999', 'cr': '2050111222', 'mobile': '0555551111', 'email': 'accounts@gulf-group.sa', 'address': 'الدمام - العزيزية'},
        ];
        _saveWebStore('customers');
      }
      if (_webStore['policies']!.isEmpty) {
        _webStore['policies'] = [
          {'id': 1, 'customerId': 1, 'policyNo': 'POL-2025-001', 'type': 'تأمين طبي جماعي', 'startDate': '2025-01-01', 'endDate': '2025-12-31', 'premium': 85000.0},
          {'id': 2, 'customerId': 2, 'policyNo': 'POL-2025-002', 'type': 'تأمين طبي مميز', 'startDate': '2025-03-01', 'endDate': '2026-02-28', 'premium': 120000.0},
        ];
        _saveWebStore('policies');
      }
      if (_webStore['invoices']!.isEmpty) {
        _webStore['invoices'] = [
          {
            'id': 1,
            'invoiceNo': 'INV-2025-0001',
            'policyNo': 'POL-2025-001',
            'endorsementNo': 'END-001',
            'customerId': 1,
            'date': '2025-01-15',
            'description': 'قسط التأمين الطبي - الربع الأول',
            'amount': 21250.0,
            'vatRate': 15.0,
            'vatAmount': 3187.5,
            'total': 24437.5,
            'mobile': '0501234567',
            'email': 'info@ufuq.com.sa',
            'address': 'الرياض - حي العليا',
            'createdBy': 'admin',
            'createdAt': DateTime.now().toIso8601String(),
          },
        ];
        _saveWebStore('invoices');
      }
      if (_webStore['company_settings']!.isEmpty) {
        _webStore['company_settings'] = [
          {
            'id': 1,
            'nameAr': 'شركة الحماية للتأمين الطبي',
            'nameEn': 'Al Himaya Medical Insurance Co.',
            'vat': '310000000000003',
            'cr': '1010000001',
            'address': 'المملكة العربية السعودية',
            'phone': '920001234',
            'email': 'info@alhimaya.com.sa',
            'website': 'www.alhimaya.com.sa',
            'vatRate': 15.0,
            'footerText': 'شكراً لثقتكم بنا - فاتورة ضريبية معتمدة وفق متطلبات هيئة الزكاة والضريبة والجمارك',
            'logoSize': 80,
            'logoEnabled': 1,
            'stampSize': 100,
            'stampX': 70.0,
            'stampY': 60.0,
            'stampEnabled': 1,
          }
        ];
        _saveWebStore('company_settings');
      }
      return;
    }

    final customerCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM customers')) ?? 0;
    if (customerCount == 0) {
      await db.insert('customers', {'name': 'شركة الأفق للمقاولات', 'vat': '310111222333', 'cr': '1010234567', 'mobile': '0501234567', 'email': 'info@ufuq.com.sa', 'address': 'الرياض - حي العليا'});
      await db.insert('customers', {'name': 'مستشفى النور الطبي', 'vat': '310444555666', 'cr': '1010987654', 'mobile': '0509876543', 'email': 'billing@alnoor-hosp.com.sa', 'address': 'جدة - الحمراء'});
      await db.insert('customers', {'name': 'مجموعة الخليج للتجارة', 'vat': '310777888999', 'cr': '2050111222', 'mobile': '0555551111', 'email': 'accounts@gulf-group.sa', 'address': 'الدمام - العزيزية'});

      await db.insert('policies', {'customerId': 1, 'policyNo': 'POL-2025-001', 'type': 'تأمين طبي جماعي', 'startDate': '2025-01-01', 'endDate': '2025-12-31', 'premium': 85000.0});
      await db.insert('policies', {'customerId': 2, 'policyNo': 'POL-2025-002', 'type': 'تأمين طبي مميز', 'startDate': '2025-03-01', 'endDate': '2026-02-28', 'premium': 120000.0});

      await db.insert('invoices', {
        'invoiceNo': 'INV-2025-0001',
        'policyNo': 'POL-2025-001',
        'endorsementNo': 'END-001',
        'customerId': 1,
        'date': '2025-01-15',
        'description': 'قسط التأمين الطبي - الربع الأول',
        'amount': 21250.0,
        'vatRate': 15.0,
        'vatAmount': 3187.5,
        'total': 24437.5,
        'mobile': '0501234567',
        'email': 'info@ufuq.com.sa',
        'address': 'الرياض - حي العليا',
        'createdBy': 'admin',
        'createdAt': DateTime.now().toIso8601String(),
      });

      await db.insert('company_settings', {
        'id': 1,
        'nameAr': 'شركة الحماية للتأمين الطبي',
        'nameEn': 'Al Himaya Medical Insurance Co.',
        'vat': '310000000000003',
        'cr': '1010000001',
        'address': 'المملكة العربية السعودية',
        'phone': '920001234',
        'email': 'info@alhimaya.com.sa',
        'website': 'www.alhimaya.com.sa',
        'vatRate': 15.0,
        'footerText': 'شكراً لثقتكم بنا - فاتورة ضريبية معتمدة وفق متطلبات هيئة الزكاة والضريبة والجمارك',
        'logoSize': 80,
        'logoEnabled': 1,
        'stampSize': 100,
        'stampX': 70.0,
        'stampY': 60.0,
        'stampEnabled': 1,
      });
    }
  }

  // ==========================================
  // العمليات على العملاء (Customers)
  // ==========================================
  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await database;
    if (db == null) {
      _loadWebStore();
      return List.from(_webStore['customers']!);
    }
    return await db.query('customers', orderBy: 'id ASC');
  }

  Future<int> saveCustomer(Map<String, dynamic> data) async {
    final map = {
      'name': data['name']?.toString() ?? '',
      'vat': data['vat']?.toString() ?? '',
      'cr': data['cr']?.toString() ?? '',
      'mobile': data['mobile']?.toString() ?? '',
      'email': data['email']?.toString() ?? '',
      'address': data['address']?.toString() ?? '',
    };
    final id = data['id'] != null ? int.tryParse(data['id'].toString()) : null;

    final db = await database;
    if (db == null) {
      _loadWebStore();
      if (id != null && id > 0) {
        final index = _webStore['customers']!.indexWhere((c) => c['id'] == id);
        if (index != -1) {
          _webStore['customers']![index] = {'id': id, ...map};
          _saveWebStore('customers');
          return id;
        }
      }
      final newId = (_webStore['customers']!.isEmpty)
          ? 1
          : (_webStore['customers']!.map((e) => (e['id'] as int? ?? 0)).reduce((a, b) => a > b ? a : b) + 1);
      _webStore['customers']!.add({'id': newId, ...map});
      _saveWebStore('customers');
      return newId;
    }

    if (id != null && id > 0) {
      await db.update('customers', map, where: 'id = ?', whereArgs: [id]);
      return id;
    } else {
      return await db.insert('customers', map);
    }
  }

  Future<void> deleteCustomer(dynamic id) async {
    final intId = int.tryParse(id.toString()) ?? 0;
    final db = await database;
    if (db == null) {
      _loadWebStore();
      _webStore['customers']!.removeWhere((c) => c['id'] == intId);
      _saveWebStore('customers');
      return;
    }
    await db.delete('customers', where: 'id = ?', whereArgs: [intId]);
  }

  // ==========================================
  // العمليات على الوثائق (Policies)
  // ==========================================
  Future<List<Map<String, dynamic>>> getPolicies() async {
    final db = await database;
    if (db == null) {
      _loadWebStore();
      return List.from(_webStore['policies']!);
    }
    return await db.query('policies', orderBy: 'id ASC');
  }

  Future<int> savePolicy(Map<String, dynamic> data) async {
    final map = {
      'customerId': data['customerId'] != null ? int.tryParse(data['customerId'].toString()) : null,
      'policyNo': data['policyNo']?.toString() ?? '',
      'type': data['type']?.toString() ?? '',
      'startDate': data['startDate']?.toString() ?? '',
      'endDate': data['endDate']?.toString() ?? '',
      'premium': double.tryParse(data['premium']?.toString() ?? '0') ?? 0.0,
    };
    final id = data['id'] != null ? int.tryParse(data['id'].toString()) : null;

    final db = await database;
    if (db == null) {
      _loadWebStore();
      if (id != null && id > 0) {
        final index = _webStore['policies']!.indexWhere((p) => p['id'] == id);
        if (index != -1) {
          _webStore['policies']![index] = {'id': id, ...map};
          _saveWebStore('policies');
          return id;
        }
      }
      final newId = (_webStore['policies']!.isEmpty)
          ? 1
          : (_webStore['policies']!.map((e) => (e['id'] as int? ?? 0)).reduce((a, b) => a > b ? a : b) + 1);
      _webStore['policies']!.add({'id': newId, ...map});
      _saveWebStore('policies');
      return newId;
    }

    if (id != null && id > 0) {
      await db.update('policies', map, where: 'id = ?', whereArgs: [id]);
      return id;
    } else {
      return await db.insert('policies', map);
    }
  }

  Future<void> deletePolicy(dynamic id) async {
    final intId = int.tryParse(id.toString()) ?? 0;
    final db = await database;
    if (db == null) {
      _loadWebStore();
      _webStore['policies']!.removeWhere((p) => p['id'] == intId);
      _saveWebStore('policies');
      return;
    }
    await db.delete('policies', where: 'id = ?', whereArgs: [intId]);
  }

  // ==========================================
  // العمليات على الفواتير (Invoices)
  // ==========================================
  Future<List<Map<String, dynamic>>> getInvoices() async {
    final db = await database;
    if (db == null) {
      _loadWebStore();
      return List.from(_webStore['invoices']!);
    }
    return await db.query('invoices', orderBy: 'id ASC');
  }

  Future<int> saveInvoice(Map<String, dynamic> data) async {
    final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
    final vatRate = double.tryParse(data['vatRate']?.toString() ?? '0') ?? 0.0;
    final vatAmount = (amount * vatRate / 100);
    final total = amount + vatAmount;

    final map = {
      'invoiceNo': data['invoiceNo']?.toString() ?? '',
      'policyNo': data['policyNo']?.toString() ?? '',
      'endorsementNo': data['endorsementNo']?.toString() ?? '',
      'customerId': data['customerId'] != null ? int.tryParse(data['customerId'].toString()) : null,
      'date': data['date']?.toString() ?? '',
      'description': data['description']?.toString() ?? '',
      'amount': amount,
      'vatRate': vatRate,
      'vatAmount': vatAmount,
      'total': total,
      'mobile': data['mobile']?.toString() ?? '',
      'email': data['email']?.toString() ?? '',
      'address': data['address']?.toString() ?? '',
      'createdBy': data['createdBy']?.toString() ?? 'admin',
      'createdAt': DateTime.now().toIso8601String(),
    };

    final db = await database;
    if (db == null) {
      _loadWebStore();
      final newId = (_webStore['invoices']!.isEmpty)
          ? 1
          : (_webStore['invoices']!.map((e) => (e['id'] as int? ?? 0)).reduce((a, b) => a > b ? a : b) + 1);
      _webStore['invoices']!.add({'id': newId, ...map});
      _saveWebStore('invoices');
      return newId;
    }

    return await db.insert('invoices', map);
  }

  // ==========================================
  // إعدادات الشركة (Company Settings)
  // ==========================================
  Future<Map<String, dynamic>> getCompanySettings() async {
    final db = await database;
    if (db == null) {
      _loadWebStore();
      if (_webStore['company_settings']!.isNotEmpty) {
        return Map<String, dynamic>.from(_webStore['company_settings']!.first);
      }
      return {};
    }
    final list = await db.query('company_settings', where: 'id = ?', whereArgs: [1]);
    return list.isNotEmpty ? Map<String, dynamic>.from(list.first) : {};
  }

  Future<void> saveCompanySettings(Map<String, dynamic> data) async {
    final map = {
      'id': 1,
      'nameAr': data['nameAr']?.toString() ?? '',
      'nameEn': data['nameEn']?.toString() ?? '',
      'vat': data['vat']?.toString() ?? '',
      'cr': data['cr']?.toString() ?? '',
      'address': data['address']?.toString() ?? '',
      'phone': data['phone']?.toString() ?? '',
      'email': data['email']?.toString() ?? '',
      'website': data['website']?.toString() ?? '',
      'vatRate': double.tryParse(data['vatRate']?.toString() ?? '15') ?? 15.0,
      'footerText': data['footerText']?.toString() ?? '',
      'logo': data['logo']?.toString() ?? '',
      'stamp': data['stamp']?.toString() ?? '',
      'logoSize': int.tryParse(data['logoSize']?.toString() ?? '80') ?? 80,
      'logoEnabled': (data['logoEnabled'] == true || data['logoEnabled'] == 1) ? 1 : 0,
      'stampSize': int.tryParse(data['stampSize']?.toString() ?? '100') ?? 100,
      'stampX': double.tryParse(data['stampX']?.toString() ?? '70') ?? 70.0,
      'stampY': double.tryParse(data['stampY']?.toString() ?? '60') ?? 60.0,
      'stampEnabled': (data['stampEnabled'] == true || data['stampEnabled'] == 1) ? 1 : 0,
    };

    final db = await database;
    if (db == null) {
      _loadWebStore();
      _webStore['company_settings'] = [map];
      _saveWebStore('company_settings');
      return;
    }

    await db.insert('company_settings', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ==========================================
  // سجل التدقيق (Audit Logs)
  // ==========================================
  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    final db = await database;
    if (db == null) {
      _loadWebStore();
      return List.from(_webStore['audit_logs']!);
    }
    return await db.query('audit_logs', orderBy: 'id DESC', limit: 300);
  }

  Future<void> addAuditLog(String action, String detail, [String user = 'المدير']) async {
    final entry = {
      'user': user,
      'action': action,
      'detail': detail,
      'at': DateTime.now().toIso8601String().replaceAll('T', ' ').substring(0, 19),
    };
    final db = await database;
    if (db == null) {
      _loadWebStore();
      final newId = (_webStore['audit_logs']!.isEmpty) ? 1 : (_webStore['audit_logs']!.length + 1);
      _webStore['audit_logs']!.insert(0, {'id': newId, ...entry});
      _saveWebStore('audit_logs');
      return;
    }
    await db.insert('audit_logs', entry);
  }

  // ==========================================
  // دوال التوافق مع خدمة المزامنة (SyncService)
  // ==========================================
  Future<void> insertCustomer(Map<String, dynamic> customer) async {
    await saveCustomer(customer);
  }

  Future<void> enqueueSyncOperation(String action, Map<String, dynamic> data) async {
    final db = await database;
    if (db != null) {
      await db.insert('sync_queue', {
        'action': action,
        'payload': jsonEncode(data),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    if (db == null) return [];
    return await db.query('sync_queue', orderBy: 'id ASC');
  }

  Future<void> removeSyncOperation(int id) async {
    final db = await database;
    if (db != null) {
      await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> saveBootstrapData(Map<String, dynamic> data) async {
    if (data['customers'] is List) {
      for (final c in data['customers']) {
        await saveCustomer(Map<String, dynamic>.from(c));
      }
    }
    if (data['policies'] is List) {
      for (final p in data['policies']) {
        await savePolicy(Map<String, dynamic>.from(p));
      }
    }
    if (data['invoices'] is List) {
      for (final i in data['invoices']) {
        await saveInvoice(Map<String, dynamic>.from(i));
      }
    }
    if (data['company'] is Map) {
      await saveCompanySettings(Map<String, dynamic>.from(data['company']));
    }
  }
}
