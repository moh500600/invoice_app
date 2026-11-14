import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../widgets/common.dart';

class PasswordPage extends StatefulWidget {
  final InvoiceState state;
  const PasswordPage({super.key, required this.state});
  @override
  State<PasswordPage> createState() => _PasswordPageState();
}
class _PasswordPageState extends State<PasswordPage> {
  String current = '', next = '', confirm = '';
  bool saving = false;
  int generation = 0;
  Future<void> save() async {
    setState(() => saving = true);
    try {
      await widget.state.api.request('change_password', data: {
        'currentPassword': current, 'newPassword': next, 'confirmPassword': confirm,
      });
      if (!mounted) return;
      setState(() { current = ''; next = ''; confirm = ''; generation++; });
      inform(context, 'تم تغيير كلمة المرور بنجاح');
    } catch (e) { if (mounted) inform(context, e.toString(), error: true); }
    finally { if (mounted) setState(() => saving = false); }
  }
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    heading('تغيير كلمة المرور'), gap(18),
    ConstrainedBox(constraints: const BoxConstraints(maxWidth: 650), child: panel(child: Column(
      key: ValueKey(generation), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        note('استخدم هذه الصفحة لتغيير كلمة المرور الافتراضية مباشرة بعد تشغيل النظام.', green: false),
        AppInput(label: 'كلمة المرور الحالية', value: current, password: true, onChanged: (v) => current = v),
        AppInput(label: 'كلمة المرور الجديدة', value: next, password: true, onChanged: (v) => next = v),
        AppInput(label: 'تأكيد كلمة المرور الجديدة', value: confirm, password: true, onChanged: (v) => confirm = v),
        FilledButton.icon(onPressed: saving ? null : save, icon: const Icon(Icons.key), label: Text(saving ? 'جاري التغيير...' : 'تغيير كلمة المرور')),
      ],
    ))),
  ]);
}
