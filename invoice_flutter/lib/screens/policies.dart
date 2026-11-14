import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/utils.dart';
import '../widgets/common.dart';

class PoliciesPage extends StatefulWidget {
  final InvoiceState state;
  const PoliciesPage({super.key, required this.state});
  @override
  State<PoliciesPage> createState() => _PoliciesPageState();
}
class _PoliciesPageState extends State<PoliciesPage> {
  final empty = const {'customerId': '', 'policyNo': '', 'type': '', 'startDate': '', 'endDate': '', 'premium': ''};
  late Map<String, dynamic> form = Map.from(empty);
  int? editing;
  bool formVisible = false, saving = false;
  final types = const ['تأمين طبي جماعي', 'تأمين طبي مميز', 'تأمين طبي شامل', 'تأمين طبي أساسي', 'تأمين طبي تكميلي'];
  void reset() => setState(() { form = Map.from(empty); editing = null; formVisible = false; });
  void edit(Map<String, dynamic> policy) => setState(() {
    editing = idValue(policy['id']);
    form = {for (final key in empty.keys) key: txt(policy[key])};
    formVisible = true;
  });
  void change(String name, dynamic value) => setState(() => form[name] = value);
  Future<void> save() async {
    setState(() => saving = true);
    try {
      await widget.state.save('policy_save', {
        ...form,
        'id': editing,
        'customerId': idValue(form['customerId']),
        'premium': numValue(form['premium']),
      }, verifyKey: 'policy');
      if (mounted) { inform(context, editing == null ? 'تمت إضافة الوثيقة' : 'تم تعديل الوثيقة'); reset(); }
    } catch (e) { if (mounted) inform(context, e.toString(), error: true); }
    finally { if (mounted) setState(() => saving = false); }
  }
  Future<void> delete(Map<String, dynamic> p) async {
    if (!await confirmDelete(context, 'هل تريد حذف هذه الوثيقة؟')) return;
    try {
      await widget.state.save('policy_delete', {'id': p['id']});
      if (mounted) inform(context, 'تم حذف الوثيقة من قاعدة البيانات');
    } catch (e) { if (mounted) inform(context, e.toString(), error: true); }
  }
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Wrap(spacing: 14, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
      heading('إدارة وثائق التأمين'),
      FilledButton.icon(icon: const Icon(Icons.add), label: const Text('إضافة وثيقة'), onPressed: () {
        if (formVisible) { reset(); } else { setState(() { formVisible = true; editing = null; form = Map.from(empty); }); }
      }),
    ]), gap(15),
    if (formVisible) ...[
      panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        section(editing == null ? 'إضافة وثيقة جديدة' : 'تعديل الوثيقة'),
        note('جميع بيانات الوثيقة اختيارية.'),
        responsiveFields(context, [
          AppSelect(label: 'العميل', value: txt(form['customerId']),
            items: widget.state.customers.map((c) => DropdownMenuItem(value: '${c['id']}', child: Text(txt(c['name'], 'بدون اسم')))).toList(),
            onChanged: (v) => change('customerId', v ?? '')),
          AppInput(label: 'رقم الوثيقة', value: form['policyNo'], onChanged: (v) => change('policyNo', v)),
          AppSelect(label: 'نوع التأمين', value: txt(form['type']),
            items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => change('type', v ?? '')),
          AppInput(label: 'قسط التأمين (ريال)', value: form['premium'], keyboard: TextInputType.number, onChanged: (v) => change('premium', v)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: DateInput(label: 'تاريخ البداية', value: txt(form['startDate']), onChanged: (v) => change('startDate', v))),
            IconButton(tooltip: 'مسح التاريخ', onPressed: () => change('startDate', ''), icon: const Icon(Icons.clear)),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: DateInput(label: 'تاريخ النهاية', value: txt(form['endDate']), onChanged: (v) => change('endDate', v))),
            IconButton(tooltip: 'مسح التاريخ', onPressed: () => change('endDate', ''), icon: const Icon(Icons.clear)),
          ]),
        ], wideColumns: 3),
        Wrap(spacing: 10, children: [
          FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'جاري الحفظ...' : 'حفظ')),
          OutlinedButton(onPressed: reset, child: const Text('إلغاء')),
        ]),
      ])), gap(17),
    ],
    if (widget.state.policies.isEmpty) panel(child: const Text('لا توجد وثائق')) else appTable(
      ['رقم الوثيقة','العميل','نوع التأمين','تاريخ البداية','تاريخ النهاية','القسط','الإجراءات'],
      widget.state.policies.map((p) => [
        cell(p['policyNo'], bold: true), cell(widget.state.customerById(p['customerId'])['name']), cell(p['type']),
        cell(p['startDate']), cell(p['endDate']), cell(money(p['premium'])),
        Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(tooltip: 'تعديل', onPressed: () => edit(p), icon: const Icon(Icons.edit, color: brand)),
          IconButton(tooltip: 'حذف', onPressed: () => delete(p), icon: const Icon(Icons.delete, color: Colors.red)),
        ]),
      ]).toList(),
    ),
  ]);
}
