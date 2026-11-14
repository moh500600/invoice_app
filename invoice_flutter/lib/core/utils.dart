import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';

String txt(dynamic value, [String fallback = '']) =>
    value == null || value.toString().trim().isEmpty ? fallback : value.toString();
double numValue(dynamic value, [double fallback = 0]) =>
    double.tryParse('${value ?? ''}') ?? fallback;
int? idValue(dynamic value) {
  final id = int.tryParse('${value ?? ''}');
  return id != null && id > 0 ? id : null;
}
String money(dynamic amount) => '${NumberFormat('#,##0.00', 'en_US').format(numValue(amount))} ر.س';
String today() => DateFormat('yyyy-MM-dd').format(DateTime.now());
String dateDisplay(dynamic value) => txt(value, '-');

// ZATCA Phase 1 TLV tags 1..5, UTF-8 encoded. QR is truly scannable, not pseudorandom.
String invoiceQrPayload(Map<String, dynamic> invoice, Map<String, dynamic> company) {
  final date = txt(invoice['date'], today());
  final timestamp = (DateTime.tryParse(date) ?? DateTime.now()).toUtc().toIso8601String();
  final tags = <int, String>{
    1: txt(company['nameAr']),
    2: txt(company['vat']),
    3: timestamp,
    4: numValue(invoice['total']).toStringAsFixed(2),
    5: numValue(invoice['vatAmount']).toStringAsFixed(2),
  };
  final out = BytesBuilder();
  for (final entry in tags.entries) {
    final bytes = utf8.encode(entry.value);
    // TLV length uses a single byte; truncate to 255 bytes if necessary.
    final limited = bytes.length <= 255 ? bytes : bytes.sublist(0, 255);
    out.add([entry.key, limited.length]);
    out.add(limited);
  }
  return base64Encode(out.toBytes());
}

String csvCell(dynamic value) => '"${txt(value).replaceAll('"', '""')}"';
String csvLines(List<List<dynamic>> rows) => '\uFEFF${rows.map((r) => r.map(csvCell).join(',')).join('\r\n')}';

Uint8List? imageData(dynamic source) {
  final text = txt(source);
  if (text.isEmpty) return null;
  try {
    return base64Decode(text.contains(',') ? text.split(',').last : text);
  } catch (_) {
    return null;
  }
}
