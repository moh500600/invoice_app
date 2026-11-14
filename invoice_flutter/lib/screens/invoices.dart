import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/app_state.dart';
import '../core/utils.dart';
import '../widgets/common.dart';
import 'invoice_preview.dart';

class InvoicesPage extends StatefulWidget {
  final InvoiceState state;
  final ValueChanged<String> navigate;
  const InvoicesPage({super.key, required this.state, required this.navigate});
  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}
class _InvoicesPageState extends State<InvoicesPage> {
  String search = '', from = '', to = '';
  final searchController = TextEditingController();
  @override
  void dispose() { searchController.dispose(); super.dispose(); }
  List<Map<String, dynamic>> get filtered => widget.state.invoices.where((i) {
    final customer = widget.state.customerById(i['customerId']);
    final query = search.trim().toLowerCase();
    final text = [i['invoiceNo'], i['policyNo'], i['endorsementNo'], customer['name'], i['mobile']]
        .map((v) => txt(v).toLowerCase()).join('|');
    final date = txt(i['date']);
    return (query.isEmpty || text.contains(query)) &&
      (from.isEmpty || date.isNotEmpty && date.compareTo(from) >= 0) &&
      (to.isEmpty || date.isNotEmpty && date.compareTo(to) <= 0);
  }).toList();

  Future<void> exportCsv() async {
    try {
      final rows = <List<dynamic>>[
        ['رقم الفاتورة', 'رقم الوثيقة', 'العميل', 'التاريخ', 'المبلغ', 'الضريبة', 'الإجمالي'],
        ...filtered.map((i) => [i['invoiceNo'], i['policyNo'],
          widget.state.customerById(i['customerId'])['name'], i['date'],
          numValue(i['amount']), numValue(i['vatAmount']), numValue(i['total'])]),
      ];
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/invoices.csv');
      await file.writeAsBytes(utf8.encode(csvLines(rows)), flush: true);
      await Share.shareXFiles([XFile(file.path, mimeType: 'text/csv')], text: 'تصدير الفواتير');
      if (mounted) inform(context, 'تم تجهيز ملف CSV للمشاركة أو الحفظ');
    } catch (e) { if (mounted) inform(context, e.toString(), error: true); }
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
      heading('أرشيف الفواتير'),
      FilledButton.icon(onPressed: exportCsv, icon: const Icon(Icons.download), label: const Text('تصدير CSV'), style: FilledButton.styleFrom(backgroundColor: success)),
      FilledButton.icon(onPressed: () => widget.navigate('new-invoice'), icon: const Icon(Icons.add), label: const Text('فاتورة جديدة')),
    ]), gap(15),
    panel(child: Column(children: [
      TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: 'بحث سريع برقم الفاتورة، الوثيقة، العميل، الجوال...',
          labelStyle: const TextStyle(fontSize: 13, color: textMuted),
          prefixIcon: const Icon(Icons.search, color: brandAccent),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: brandAccent, width: 2)),
        ),
        onChanged: (v) => setState(() => search = v),
      ), gap(),
      Wrap(spacing: 12, children: [
        DateInput(label: 'من تاريخ', value: from, onChanged: (v) => setState(() => from = v)),
        DateInput(label: 'إلى تاريخ', value: to, onChanged: (v) => setState(() => to = v)),
        OutlinedButton.icon(onPressed: () { searchController.clear(); setState(() { from = ''; to = ''; search = ''; }); },
          icon: const Icon(Icons.clear), label: const Text('مسح التواريخ والبحث')),
      ]),
    ])), gap(16),
    if (filtered.isEmpty) panel(child: const Center(child: Text('لا توجد فواتير'))) else
      appTable(['رقم الفاتورة','رقم الوثيقة','رقم التأشيرة','العميل','التاريخ','المبلغ','الضريبة','الإجمالي','الإجراءات'],
        filtered.map((i) => [
          cell(i['invoiceNo'], color: Colors.blue, bold: true), cell(i['policyNo']), cell(i['endorsementNo']),
          cell(widget.state.customerById(i['customerId'])['name']), cell(i['date']),
          cell(money(i['amount'])), cell(money(i['vatAmount'])), cell(money(i['total']), color: success, bold: true),
          Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(tooltip: 'عرض', onPressed: () => showInvoice(context, state: widget.state, invoice: i), icon: const Icon(Icons.visibility, color: brand)),
            IconButton(tooltip: 'طباعة', onPressed: () => showInvoice(context, state: widget.state, invoice: i, openPrint: true), icon: const Icon(Icons.print, color: success)),
          ]),
        ]).toList()),
  ]);
}

class NewInvoicePage extends StatefulWidget {
  final InvoiceState state;
  final ValueChanged<String> navigate;
  const NewInvoicePage({super.key, required this.state, required this.navigate});
  @override
  State<NewInvoicePage> createState() => _NewInvoicePageState();
}
class _NewInvoicePageState extends State<NewInvoicePage> {
  late Map<String, dynamic> f;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    f = {
      'invoiceNo': 'INV-${DateTime.now().year}-${(widget.state.invoices.length + 1).toString().padLeft(4,'0')}',
      'customerId': '', 'policyNo': '', 'endorsementNo': '', 'date': today(),
      'description': '', 'amount': '', 'vatRate': numValue(widget.state.company['vatRate']),
      'mobile': '', 'email': '', 'address': '',
    };
  }
  void change(String name, dynamic value) => setState(() => f[name] = value);
  void selectCustomer(String? value) {
    final customer = widget.state.customerById(idValue(value));
    setState(() {
      f['customerId'] = value ?? '';
      f['policyNo'] = '';
      if (customer.isNotEmpty) {
        f['mobile'] = txt(customer['mobile']);
        f['email'] = txt(customer['email']);
        f['address'] = txt(customer['address']);
      }
    });
  }
  Future<void> submit() async {
    setState(() => saving = true);
    try {
      final data = Map<String, dynamic>.from(f);
      data['customerId'] = idValue(f['customerId']);
      data['amount'] = numValue(f['amount']);
      data['vatRate'] = numValue(f['vatRate']);
      await widget.state.save('invoice_save', data, verifyKey: 'invoice');
      if (!mounted) return;
      inform(context, 'تم حفظ الفاتورة في قاعدة البيانات بنجاح');
      widget.navigate('invoices');
    } catch (e) { if (mounted) inform(context, e.toString(), error: true); }
    finally { if (mounted) setState(() => saving = false); }
  }
  @override
  Widget build(BuildContext context) {
    final amount = numValue(f['amount']), vatRate = numValue(f['vatRate']);
    final vatAmount = amount * vatRate / 100;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        heading('إنشاء فاتورة جديدة'),
        OutlinedButton(onPressed: () => widget.navigate('invoices'), child: const Text('العودة')),
      ]), gap(16),
      panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        note('رقم الفاتورة التلقائي: ${f['invoiceNo']}', green: false),
        note('جميع بيانات الفاتورة اختيارية، ويمكنك الحفظ حتى عند ترك الحقول فارغة.'),
        responsiveFields(context, [
          AppSelect(label: 'العميل', value: txt(f['customerId']),
            items: widget.state.customers.map((c) => DropdownMenuItem(value: '${c['id']}', child: Text(txt(c['name'], 'بدون اسم')))).toList(),
            onChanged: selectCustomer),
          AppSelect(label: 'رقم الوثيقة', value: txt(f['policyNo']),
            items: widget.state.policies.where((p) => idValue(f['customerId']) == null || p['customerId'] == idValue(f['customerId']))
              .where((p) => txt(p['policyNo']).isNotEmpty)
              .fold<Map<String, Map<String, dynamic>>>({}, (m, p) { m[txt(p['policyNo'])] = p; return m; })
              .values.map((p) => DropdownMenuItem(value: txt(p['policyNo']), child: Text('${txt(p['policyNo'])} - ${txt(p['type'])}'))).toList(),
            onChanged: (v) => change('policyNo', v ?? '')),
          AppInput(label: 'رقم التأشيرة / التوثيق', value: f['endorsementNo'], onChanged: (v) => change('endorsementNo', v)),
          DateInput(label: 'تاريخ الفاتورة', value: txt(f['date']), onChanged: (v) => change('date', v)),
        ]),
        AppInput(label: 'البيان / الوصف', value: f['description'], lines: 2, onChanged: (v) => change('description', v)),
        responsiveFields(context, [
          AppInput(label: 'المبلغ (ريال)', value: f['amount'], keyboard: TextInputType.number, onChanged: (v) => change('amount', v)),
          AppInput(label: 'نسبة ضريبة القيمة المضافة (%)', value: f['vatRate'], keyboard: TextInputType.number, onChanged: (v) => change('vatRate', v)),
        ]),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Wrap(
            spacing: 28,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('المبلغ قبل الضريبة: ${money(amount)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text('مبلغ الضريبة: ${money(vatAmount)}', style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w700, fontSize: 14)),
              Text('الإجمالي شامل الضريبة: ${money(amount + vatAmount)}', style: const TextStyle(color: success, fontWeight: FontWeight.w800, fontSize: 17)),
            ],
          ),
        ), gap(18),
        responsiveFields(context, [
          AppInput(label: 'رقم الجوال', value: f['mobile'], keyboard: TextInputType.phone, onChanged: (v) => change('mobile', v)),
          AppInput(label: 'البريد الإلكتروني', value: f['email'], keyboard: TextInputType.emailAddress, onChanged: (v) => change('email', v)),
        ]),
        AppInput(label: 'العنوان', value: f['address'], onChanged: (v) => change('address', v)),
        Wrap(spacing: 12, children: [
          OutlinedButton(onPressed: saving ? null : () => widget.navigate('invoices'), child: const Text('إلغاء')),
          FilledButton.icon(onPressed: saving ? null : submit, icon: const Icon(Icons.save), label: Text(saving ? 'جاري الحفظ...' : 'حفظ الفاتورة')),
        ]),
      ])),
    ]);
  }
}
