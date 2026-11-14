import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/utils.dart';
import '../widgets/common.dart';

class CustomersPage extends StatefulWidget {
  final InvoiceState state;
  const CustomersPage({super.key, required this.state});
  @override
  State<CustomersPage> createState() => _CustomersPageState();
}
class _CustomersPageState extends State<CustomersPage> {
  final empty = const {'name': '', 'vat': '', 'cr': '', 'mobile': '', 'email': '', 'address': ''};
  late Map<String, dynamic> form = Map.from(empty);
  int? editing;
  bool formVisible = false, saving = false;
  void reset() => setState(() { form = Map.from(empty); editing = null; formVisible = false; });
  void edit(Map<String, dynamic> customer) {
    setState(() {
      editing = idValue(customer['id']);
      form = {for (final key in empty.keys) key: txt(customer[key])};
      formVisible = true;
    });
  }
  void change(String field, String value) => setState(() => form[field] = value);
  Future<void> save() async {
    setState(() => saving = true);
    try {
      await widget.state.save('customer_save', {...form, 'id': editing}, verifyKey: 'customer');
      if (mounted) { inform(context, editing != null ? 'تم تعديل العميل في قاعدة البيانات' : 'تمت إضافة العميل إلى قاعدة البيانات'); reset(); }
    } catch (e) { if (mounted) inform(context, e.toString(), error: true); }
    finally { if (mounted) setState(() => saving = false); }
  }
  Future<void> delete(Map<String, dynamic> c) async {
    if (!await confirmDelete(context, 'هل تريد حذف العميل؟ ستبقى فواتيره ووثائقه محفوظة بدون ربط بالعميل.')) return;
    try {
      await widget.state.save('customer_delete', {'id': c['id']});
      if (mounted) inform(context, 'تم حذف العميل من قاعدة البيانات');
    } catch (e) { if (mounted) inform(context, e.toString(), error: true); }
  }
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Wrap(spacing: 14, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
      heading('إدارة العملاء'),
      FilledButton.icon(icon: Icon(formVisible ? Icons.close : Icons.add),
        onPressed: () { if (formVisible) { reset(); } else { setState(() { form = Map.from(empty); editing = null; formVisible = true; }); } },
        label: const Text('إضافة عميل')),
    ]), gap(16),
    if (formVisible) ...[
      panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        section(editing == null ? 'إضافة عميل جديد' : 'تعديل عميل'),
        note('جميع بيانات العميل اختيارية.'),
        responsiveFields(context, [
          AppInput(label: 'اسم العميل', value: form['name'], onChanged: (v) => change('name', v)),
          AppInput(label: 'الرقم الضريبي', value: form['vat'], onChanged: (v) => change('vat', v)),
          AppInput(label: 'السجل التجاري', value: form['cr'], onChanged: (v) => change('cr', v)),
          AppInput(label: 'رقم الجوال', value: form['mobile'], keyboard: TextInputType.phone, onChanged: (v) => change('mobile', v)),
          AppInput(label: 'البريد الإلكتروني', value: form['email'], keyboard: TextInputType.emailAddress, onChanged: (v) => change('email', v)),
          AppInput(label: 'العنوان', value: form['address'], onChanged: (v) => change('address', v)),
        ], wideColumns: 3),
        Wrap(spacing: 10, children: [
          FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'جاري الحفظ...' : 'حفظ')),
          OutlinedButton(onPressed: reset, child: const Text('إلغاء')),
        ]),
      ])), gap(18),
    ],
    if (widget.state.customers.isEmpty) panel(child: const Text('لا يوجد عملاء')) else appTable(
      ['الاسم', 'الرقم الضريبي', 'السجل التجاري', 'الجوال', 'البريد', 'العنوان', 'الإجراءات'],
      widget.state.customers.map((c) => [
        cell(c['name'], bold: true), cell(c['vat']), cell(c['cr']), cell(c['mobile']), cell(c['email']), cell(c['address']),
        Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(tooltip: 'تعديل', onPressed: () => edit(c), icon: const Icon(Icons.edit, color: brand)),
          IconButton(tooltip: 'حذف', onPressed: () => delete(c), icon: const Icon(Icons.delete, color: Colors.red)),
        ]),
      ]).toList(),
    ),
  ]);
}
