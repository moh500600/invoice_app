import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/utils.dart';
import '../widgets/common.dart';

class DashboardPage extends StatelessWidget {
  final InvoiceState state;
  const DashboardPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final invoices = state.invoices;
    final revenue = invoices.fold<double>(0, (sum, item) => sum + numValue(item['amount']));
    final vat = invoices.fold<double>(0, (sum, item) => sum + numValue(item['vatAmount']));
    final total = invoices.fold<double>(0, (sum, item) => sum + numValue(item['total']));

    final stats = [
      (
        'إجمالي الفواتير',
        '${invoices.length}',
        Icons.receipt_long_rounded,
        const Color(0xFF0284C7),
        const Color(0xFFE0F2FE),
      ),
      (
        'إجمالي الإيرادات',
        money(revenue),
        Icons.trending_up_rounded,
        const Color(0xFF10B981),
        const Color(0xFFD1FAE5),
      ),
      (
        'ضريبة القيمة المضافة',
        money(vat),
        Icons.account_balance_rounded,
        const Color(0xFF8B5CF6),
        const Color(0xFFEDE9FE),
      ),
      (
        'الإجمالي مع الضريبة',
        money(total),
        Icons.wallet_rounded,
        const Color(0xFFF59E0B),
        const Color(0xFFFEF3C7),
      ),
      (
        'قاعدة العملاء',
        '${state.customers.length}',
        Icons.groups_rounded,
        const Color(0xFF0D9488),
        const Color(0xFFCCFBF1),
      ),
      (
        'وثائق التأمين',
        '${state.policies.length}',
        Icons.security_rounded,
        const Color(0xFF6366F1),
        const Color(0xFFEEF2FF),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // بانر ترحيبي علوي أنيق
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [brand, brandLight],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x180F2B48),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً بك، ${state.user?['name'] ?? 'المستخدم'} 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'متابعة وإدارة الفواتير والوثائق والعملاء في نظام التأمين الطبي',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.medical_services_outlined,
                size: 48,
                color: Colors.white24,
              ),
            ],
          ),
        ),
        gap(24),

        // عنوان قسم الإحصائيات
        Row(
          children: [
            const Icon(Icons.analytics_outlined, color: brandAccent, size: 24),
            const SizedBox(width: 8),
            heading('نظرة عامة على الإحصائيات'),
          ],
        ),
        gap(16),

        // بطاقات الإحصائيات الست
        LayoutBuilder(builder: (_, constraints) {
          final width = constraints.maxWidth;
          final colWidth = width >= 1000
              ? (width - 28) / 3
              : width >= 650
                  ? (width - 14) / 2
                  : width;

          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: stats.map((stat) {
              return SizedBox(
                width: colWidth,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: stat.$5,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(stat.$3, color: stat.$4, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stat.$1,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stat.$2,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: stat.$4,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
        gap(28),

        // قسم أحدث الفواتير
        section('أحدث الفواتير الصادرة'),
        invoices.isEmpty
            ? panel(
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('لا توجد فواتير بعد، قم بإنشاء أول فاتورة'),
                  ),
                ),
              )
            : appTable(
                ['رقم الفاتورة', 'العميل', 'التاريخ', 'المبلغ', 'الضريبة', 'الإجمالي'],
                invoices.reversed.take(5).map((i) => [
                  cell(i['invoiceNo'], color: brandAccent, bold: true),
                  cell(state.customerById(i['customerId'])['name']),
                  cell(i['date']),
                  cell(money(i['amount'])),
                  cell(money(i['vatAmount'])),
                  cell(money(i['total']), color: success, bold: true),
                ]).toList(),
              ),
      ],
    );
  }
}
