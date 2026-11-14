import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_state.dart';
import '../core/utils.dart';
import '../widgets/common.dart';

class SettingsPage extends StatefulWidget {
  final InvoiceState state;
  const SettingsPage({super.key, required this.state});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage> {
  late Map<String, dynamic> f;
  bool saving = false;
  @override
  void initState() { super.initState(); f = Map<String, dynamic>.from(widget.state.company); }
  void change(String key, dynamic value) => setState(() => f[key] = value);
  Future<void> pick(String field) async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      final lower = picked.name.toLowerCase();
      final type = lower.endsWith('.png') ? 'image/png' : lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg';
      change(field, 'data:$type;base64,${base64Encode(bytes)}');
    } catch (e) { if (mounted) inform(context, e.toString(), error: true); }
  }
  Widget imageField(String field, String title, String sizeKey, String enableKey) {
    final data = imageData(f[field]);
    return panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      section(title),
      Wrap(spacing: 10, children: [
        FilledButton.icon(onPressed: () => pick(field), icon: const Icon(Icons.upload_file), label: Text('رفع $title')),
        OutlinedButton.icon(onPressed: () => change(field, null), icon: const Icon(Icons.delete_outline), label: const Text('إزالة الصورة')),
      ]), gap(),
      if (data != null) ...[
        Container(padding: const EdgeInsets.all(10), height: 140, width: 200,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
          child: Image.memory(data, fit: BoxFit.contain)), gap(),
      ],
      AppInput(label: 'الحجم (px)', value: f[sizeKey], keyboard: TextInputType.number, onChanged: (v) => change(sizeKey, v)),
      SwitchListTile(title: Text('تفعيل $title'), value: f[enableKey] == true || f[enableKey] == 1,
        onChanged: (v) => change(enableKey, v)),
      if (field == 'stamp') responsiveFields(context, [
        AppInput(label: 'موضع أفقي (%)', value: f['stampX'], keyboard: TextInputType.number, onChanged: (v) => change('stampX', v)),
        AppInput(label: 'موضع رأسي (%)', value: f['stampY'], keyboard: TextInputType.number, onChanged: (v) => change('stampY', v)),
      ]),
    ]));
  }
  Future<void> save() async {
    setState(() => saving = true);
    try {
      final fields = Map<String, dynamic>.from(f);
      for (final key in ['vatRate', 'logoSize', 'stampSize', 'stampX', 'stampY']) {
        fields[key] = numValue(fields[key], key == 'vatRate' ? 0 : key == 'stampX' ? 70 : key == 'stampY' ? 60 : key == 'stampSize' ? 100 : 80);
      }
      final response = await widget.state.save('settings_save', fields, verifyKey: 'company');
      if (!mounted) return;
      setState(() => f = Map<String, dynamic>.from(response['company'] as Map));
      inform(context, 'تم حفظ إعدادات الشركة في قاعدة البيانات بنجاح');
    } catch (e) { if (mounted) inform(context, e.toString(), error: true); }
    finally { if (mounted) setState(() => saving = false); }
  }
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    heading('إعدادات الشركة'), gap(14),
    panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      note('جميع إعدادات الشركة اختيارية ويمكن حفظها فارغة.'),
      section('معلومات الشركة'),
      responsiveFields(context, [
        AppInput(label: 'اسم الشركة (عربي)', value: f['nameAr'], onChanged: (v) => change('nameAr', v)),
        AppInput(label: 'اسم الشركة (إنجليزي)', value: f['nameEn'], onChanged: (v) => change('nameEn', v)),
        AppInput(label: 'الرقم الضريبي', value: f['vat'], onChanged: (v) => change('vat', v)),
        AppInput(label: 'السجل التجاري', value: f['cr'], onChanged: (v) => change('cr', v)),
        AppInput(label: 'رقم الهاتف', value: f['phone'], keyboard: TextInputType.phone, onChanged: (v) => change('phone', v)),
        AppInput(label: 'البريد الإلكتروني', value: f['email'], onChanged: (v) => change('email', v)),
        AppInput(label: 'الموقع الإلكتروني', value: f['website'], onChanged: (v) => change('website', v)),
        AppInput(label: 'نسبة ضريبة القيمة المضافة (%)', value: f['vatRate'], keyboard: TextInputType.number, onChanged: (v) => change('vatRate', v)),
      ]),
      AppInput(label: 'العنوان', value: f['address'], onChanged: (v) => change('address', v)),
      AppInput(label: 'نص تذييل الفاتورة', value: f['footerText'], lines: 2, onChanged: (v) => change('footerText', v)),
    ])), gap(12),
    imageField('logo', 'الشعار (Logo)', 'logoSize', 'logoEnabled'), gap(12),
    imageField('stamp', 'الختم الرسمي (Stamp)', 'stampSize', 'stampEnabled'), gap(14),
    FilledButton.icon(onPressed: saving ? null : save, icon: const Icon(Icons.save),
      label: Text(saving ? 'جاري الحفظ...' : 'حفظ الإعدادات')),
  ]);
}
