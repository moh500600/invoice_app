import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_flutter/core/utils.dart';

void main() {
  test('ZATCA QR contains five TLV tags and UTF-8 Arabic text', () {
    final bytes = base64Decode(invoiceQrPayload({'date':'2026-10-09','total':115, 'vatAmount':15}, {'nameAr':'شركة', 'vat':'123456789'}));
    final tags = <int, String>{};
    for (var i=0; i<bytes.length;) {
      final tag = bytes[i++], len = bytes[i++];
      tags[tag] = utf8.decode(bytes.sublist(i,i+len));
      i+=len;
    }
    expect(tags.length, 5);
    expect(tags[1], 'شركة');
    expect(tags[2], '123456789');
    expect(tags[4], '115.00');
    expect(tags[5], '15.00');
  });
  test('CSV protects commas and quotes', () {
    final csv = csvLines([['الاسم', 'الوصف'], ['أحمد', '"قسط", 10']]);
    expect(csv.startsWith('\uFEFF'), isTrue);
    expect(csv, contains('""قسط"", 10'));
  });
  test('null-safe optional fields', () {
    expect(txt(null, '-'), '-');
    expect(idValue(''), null);
    expect(numValue('12.5'), 12.5);
  });
}
