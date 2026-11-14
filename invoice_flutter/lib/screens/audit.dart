import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../widgets/common.dart';

class AuditPage extends StatelessWidget {
  final InvoiceState state;
  const AuditPage({super.key, required this.state});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    heading('سجل التدقيق'), gap(20),
    state.auditLog.isEmpty ? panel(child: const Text('لا توجد سجلات بعد')) : appTable(
      ['المستخدم','الإجراء','التفاصيل','التاريخ والوقت'],
      state.auditLog.map((r) => [
        cell(r['user'], bold: true), cell(r['action'], color: brand), cell(r['detail']), cell(r['at']),
      ]).toList(),
    ),
  ]);
}
