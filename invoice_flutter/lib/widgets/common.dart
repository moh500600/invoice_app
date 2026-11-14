import 'package:flutter/material.dart';
import '../core/utils.dart';

// لوحة الألوان الاحترافية (Modern Enterprise Palette)
const brand = Color(0xFF0F2B48);
const brandLight = Color(0xFF1E3A8A);
const brandAccent = Color(0xFF0284C7);
const pale = Color(0xFFF8FAFC);
const success = Color(0xFF10B981);
const warning = Color(0xFFF59E0B);
const danger = Color(0xFFEF4444);
const textDark = Color(0xFF0F172A);
const textMuted = Color(0xFF64748B);
const borderColor = Color(0xFFE2E8F0);

Widget section(String title) => Padding(
  padding: const EdgeInsets.only(top: 20, bottom: 14),
  child: Row(
    children: [
      Container(
        width: 4,
        height: 20,
        decoration: BoxDecoration(
          color: brandAccent,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: brand),
      ),
    ],
  ),
);

Widget panel({required Widget child, EdgeInsets padding = const EdgeInsets.all(22)}) => Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderColor, width: 1),
    boxShadow: const [
      BoxShadow(
        color: Color(0x06000000),
        blurRadius: 14,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Padding(padding: padding, child: child),
);

Widget gap([double h = 14]) => SizedBox(height: h);

Widget heading(String text) => Text(
  text,
  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: textDark, letterSpacing: -0.5),
);

Widget note(String text, {bool green = true}) => Container(
  width: double.infinity,
  margin: const EdgeInsets.only(bottom: 16),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    color: green ? const Color(0xFFECFDF5) : const Color(0xFFF0F9FF),
    border: Border.all(color: green ? success.withOpacity(0.3) : brandAccent.withOpacity(0.3)),
  ),
  child: Row(
    children: [
      Icon(green ? Icons.check_circle_outline : Icons.info_outline, size: 20, color: green ? success : brandAccent),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: green ? const Color(0xFF065F46) : const Color(0xFF0369A1))),
      ),
    ],
  ),
);

class AppInput extends StatefulWidget {
  final String label;
  final dynamic value;
  final ValueChanged<String> onChanged;
  final String hint;
  final int lines;
  final bool password;
  final TextInputType keyboard;
  final IconData? prefixIcon;

  const AppInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint = '',
    this.lines = 1,
    this.password = false,
    this.keyboard = TextInputType.text,
    this.prefixIcon,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late final TextEditingController controller;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: txt(widget.value));
    _obscured = widget.password;
  }

  @override
  void didUpdateWidget(covariant AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (controller.text != txt(widget.value)) {
      controller.value = TextEditingValue(
        text: txt(widget.value),
        selection: TextSelection.collapsed(offset: txt(widget.value).length),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: controller,
      onChanged: widget.onChanged,
      maxLines: widget.password ? 1 : widget.lines,
      obscureText: widget.password && _obscured,
      keyboardType: widget.keyboard,
      style: const TextStyle(fontSize: 14, color: textDark),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        hintStyle: const TextStyle(fontSize: 13, color: textMuted),
        labelStyle: const TextStyle(fontSize: 14, color: textMuted),
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, size: 20, color: brandAccent) : null,
        suffixIcon: widget.password
            ? IconButton(
                icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility, size: 20, color: textMuted),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: brandAccent, width: 2)),
      ),
    ),
  );
}

class AppSelect extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final IconData? prefixIcon;

  const AppSelect({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final choices = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: '', child: Text('-- بدون اختيار --', style: TextStyle(color: textMuted))),
      ...items,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: choices.any((element) => element.value == value) ? value : '',
        isExpanded: true,
        style: const TextStyle(fontSize: 14, color: textDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14, color: textMuted),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: brandAccent) : null,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: brandAccent, width: 2)),
        ),
        items: choices,
        onChanged: onChanged,
      ),
    );
  }
}

class DateInput extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const DateInput({super.key, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final initial = DateTime.tryParse(value) ?? DateTime.now();
        final d = await showDatePicker(
          context: context,
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          initialDate: initial,
        );
        if (d != null) {
          onChanged('${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: brandAccent),
            const SizedBox(width: 10),
            Text(
              '$label: ',
              style: const TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.w600),
            ),
            Text(
              value.isEmpty ? 'اختر التاريخ' : value,
              style: TextStyle(
                fontSize: 14,
                color: value.isEmpty ? textMuted : textDark,
                fontWeight: value.isEmpty ? FontWeight.normal : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget responsiveFields(BuildContext context, List<Widget> fields, {int wideColumns = 2}) {
  final width = MediaQuery.sizeOf(context).width;
  final cols = width >= 1100 ? wideColumns : width >= 730 ? 2 : 1;
  return LayoutBuilder(builder: (context, constraints) {
    final effective = constraints.maxWidth;
    final columns = effective.isFinite && effective < 550 ? 1 : cols;
    const spacing = 14.0;
    return Wrap(
      spacing: spacing,
      runSpacing: 0,
      children: fields.map((field) => SizedBox(
        width: effective.isFinite ? (effective - (columns - 1) * spacing) / columns : null,
        child: field,
      )).toList(),
    );
  });
}

Future<bool> confirmDelete(BuildContext context, String content) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: danger, size: 28),
            SizedBox(width: 10),
            Text('تأكيد الحذف', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(content, style: const TextStyle(fontSize: 14, color: textMuted)),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    ) ?? false;

void inform(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          Icon(error ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
      backgroundColor: error ? danger : success,
    ),
  );
}

Widget appTable(List<String> columns, List<List<Widget>> rows) => Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: borderColor),
    boxShadow: const [
      BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 3)),
    ],
  ),
  clipBehavior: Clip.antiAlias,
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
      dataRowMinHeight: 48,
      dataRowMaxHeight: 56,
      horizontalMargin: 20,
      columnSpacing: 24,
      columns: columns.map((c) => DataColumn(
        label: Text(
          c,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      )).toList(),
      rows: rows.map((cells) => DataRow(
        cells: cells.map((w) => DataCell(w)).toList(),
      )).toList(),
      showCheckboxColumn: false,
    ),
  ),
);

Widget cell(dynamic value, {Color? color, bool bold = false}) => Text(
  txt(value, '-'),
  style: TextStyle(
    color: color ?? textDark,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    fontSize: 13,
  ),
);
