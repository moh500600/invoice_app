import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_state.dart';
import 'widgets/common.dart';
import 'screens/dashboard.dart';
import 'screens/invoices.dart';
import 'screens/customers.dart';
import 'screens/policies.dart';
import 'screens/settings.dart';
import 'screens/password.dart';
import 'screens/audit.dart';
import 'widgets/backend_status_badge.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InvoiceFlutterApp());
}

class InvoiceFlutterApp extends StatefulWidget {
  const InvoiceFlutterApp({super.key});
  @override
  State<InvoiceFlutterApp> createState() => _InvoiceFlutterAppState();
}

class _InvoiceFlutterAppState extends State<InvoiceFlutterApp> {
  final state = InvoiceState();

  @override
  void initState() {
    super.initState();
    state.addListener(refresh);
    state.start();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    state.removeListener(refresh);
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'نظام إدارة الفواتير - التأمين الطبي',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brand,
        primary: brand,
        secondary: brandAccent,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: pale,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand,
          side: const BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
      ),
    ),
    home: state.loading
        ? const Scaffold(
            backgroundColor: pale,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: brandAccent),
                  SizedBox(height: 16),
                  Text('جاري تحميل النظام...', style: TextStyle(color: textMuted, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          )
        : state.connectionError != null
            ? Scaffold(
                backgroundColor: pale,
                body: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 550),
                    child: panel(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: danger.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cloud_off_rounded, color: danger, size: 48),
                          ),
                          gap(16),
                          heading('تعذر الاتصال بقاعدة البيانات'),
                          gap(8),
                          Text(
                            state.connectionError!,
                            style: const TextStyle(color: textMuted),
                            textAlign: TextAlign.center,
                          ),
                          gap(20),
                          FilledButton.icon(
                            onPressed: state.start,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : state.user == null
                ? LoginPage(state: state)
                : HomePage(state: state),
  );
}

class LoginPage extends StatefulWidget {
  final InvoiceState state;
  const LoginPage({super.key, required this.state});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String username = 'admin', password = 'admin123', error = '';
  bool saving = false;

  Future<void> login() async {
    setState(() {
      saving = true;
      error = '';
    });
    try {
      await widget.state.login(username, password);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F2B48)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // أيقونة وشعار النظام
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [brand, brandLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x250F2B48),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 40),
                  ),
                  gap(18),
                  const Text(
                    'نظام إدارة الفواتير',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'بوابة التأمين الطبي وإدارة المطالبات',
                    style: TextStyle(color: textMuted, fontSize: 13),
                  ),
                  gap(28),

                  // حقول الإدخال
                  AppInput(
                    label: 'اسم المستخدم',
                    hint: 'أدخل اسم المستخدم (مثال: admin)',
                    value: username,
                    prefixIcon: Icons.person_outline_rounded,
                    onChanged: (v) => username = v,
                  ),
                  AppInput(
                    label: 'كلمة المرور',
                    hint: 'أدخل كلمة المرور',
                    value: password,
                    password: true,
                    prefixIcon: Icons.lock_outline_rounded,
                    onChanged: (v) => password = v,
                  ),

                  if (error.isNotEmpty) ...[
                    gap(6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: danger.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error,
                              style: const TextStyle(color: danger, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    gap(8),
                  ],

                  gap(10),

                  // زر الدخول
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: brand,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: saving ? null : login,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.login_rounded, size: 20),
                      label: Text(
                        saving ? 'جاري التحقق...' : 'تسجيل الدخول للنظام',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  gap(18),

                  // بطاقة بيانات الدخول الافتراضية بنقرة واحدة
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.vpn_key_outlined, size: 16, color: brandAccent),
                            SizedBox(width: 6),
                            Text(
                              'بيانات الدخول الافتراضية (انقر للملء):',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ActionChip(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: borderColor),
                              avatar: const Icon(Icons.admin_panel_settings_rounded, size: 16, color: brand),
                              label: const Text('المدير (admin / admin123)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              onPressed: () => setState(() {
                                username = 'admin';
                                password = 'admin123';
                              }),
                            ),
                            ActionChip(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: borderColor),
                              avatar: const Icon(Icons.badge_outlined, size: 16, color: brandAccent),
                              label: const Text('الموظف (emp / emp123)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              onPressed: () => setState(() {
                                username = 'emp';
                                password = 'emp123';
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  gap(20),

                  // شارة حالة الاتصال بالسيرفر
                  const Divider(color: borderColor),
                  const SizedBox(height: 10),
                  BackendStatusBadge(state: widget.state, isDarkText: true),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MenuItem {
  final String id, title;
  final IconData icon;
  const _MenuItem(this.id, this.title, this.icon);
}

class HomePage extends StatefulWidget {
  final InvoiceState state;
  const HomePage({super.key, required this.state});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String page = 'dashboard';
  final pages = const [
    _MenuItem('dashboard', 'لوحة التحكم', Icons.dashboard_rounded),
    _MenuItem('invoices', 'سجل الفواتير', Icons.receipt_long_rounded),
    _MenuItem('new-invoice', 'فاتورة جديدة', Icons.note_add_rounded),
    _MenuItem('customers', 'إدارة العملاء', Icons.groups_rounded),
    _MenuItem('policies', 'وثائق التأمين', Icons.verified_user_rounded),
    _MenuItem('password', 'تغيير كلمة المرور', Icons.key_rounded),
    _MenuItem('settings', 'إعدادات الشركة', Icons.settings_rounded),
    _MenuItem('audit', 'سجل التدقيق', Icons.history_rounded),
  ];

  void navigate(String name) {
    if (!widget.state.admin && (name == 'settings' || name == 'audit')) return;
    setState(() => page = name);
    if (name == 'audit') {
      widget.state.updateAudit().catchError((Object e) {
        if (mounted) inform(context, e.toString(), error: true);
      });
    }
  }

  Widget destination() {
    final state = widget.state;
    switch (page) {
      case 'invoices':
        return InvoicesPage(key: const ValueKey('invoices'), state: state, navigate: navigate);
      case 'new-invoice':
        return NewInvoicePage(key: const ValueKey('new-invoice'), state: state, navigate: navigate);
      case 'customers':
        return CustomersPage(state: state);
      case 'policies':
        return PoliciesPage(state: state);
      case 'settings':
        return state.admin ? SettingsPage(state: state) : DashboardPage(state: state);
      case 'password':
        return PasswordPage(state: state);
      case 'audit':
        return state.admin ? AuditPage(state: state) : DashboardPage(state: state);
      default:
        return DashboardPage(state: state);
    }
  }

  Future<void> logout() async {
    try {
      await widget.state.logout();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final allowed = pages.where((item) => widget.state.admin || !['settings', 'audit'].contains(item.id)).toList();
    final matched = allowed.where((item) => item.id == page);
    final _MenuItem? current = matched.isEmpty ? null : matched.first;
    final isWide = MediaQuery.sizeOf(context).width >= 1000;

    final menu = Container(
      color: const Color(0xFF0F172A), // Dark Slate
      child: Column(
        children: [
          // رأس القائمة الجانبية
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: brandAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نظام الفواتير',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'التأمين الطبي',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 12),

          // عناصر القائمة
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: allowed.map((item) {
                final isSelected = page == item.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF1E293B),
                    leading: Icon(
                      item.icon,
                      color: isSelected ? brandAccent : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    trailing: isSelected
                        ? Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: brandAccent,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: () {
                      if (!isWide) Navigator.pop(context);
                      navigate(item.id);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // قسم المستخدم وتسجيل الخروج
          const Divider(color: Color(0xFF1E293B), height: 1),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF1E293B),
                      child: Text(
                        (widget.state.user?['name']?.toString() ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: brandAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.state.user?['name'] ?? 'مستخدم',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: brandAccent.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.state.admin ? 'مدير النظام' : 'موظف',
                              style: const TextStyle(color: brandAccent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0x33EF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: logout,
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('تسجيل الخروج', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              current?.title ?? 'نظام الفواتير',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: textDark,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
        actions: [
          BackendStatusBadge(state: widget.state, isDarkText: true),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'تحديث ومزامنة البيانات',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              try {
                await widget.state.refresh();
                if (context.mounted) inform(context, 'تم تحديث البيانات بنجاح');
              } catch (e) {
                if (context.mounted) inform(context, e.toString(), error: true);
              }
            },
            icon: const Icon(Icons.sync_rounded, size: 20, color: brand),
          ),
          const SizedBox(width: 14),
        ],
      ),
      drawer: isWide ? null : Drawer(child: SafeArea(child: menu)),
      body: Row(
        children: [
          if (isWide) SizedBox(width: 250, child: menu),
          Expanded(
            child: SelectionArea(
              child: SingleChildScrollView(
                key: ValueKey(page),
                padding: const EdgeInsets.all(24),
                child: destination(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
