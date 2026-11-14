import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/app_state.dart';
import '../core/utils.dart';
import '../widgets/common.dart';

Future<void> showInvoice(BuildContext context, {
  required InvoiceState state, required Map<String, dynamic> invoice, bool openPrint = false,
}) async {
  final customer = state.customerById(invoice['customerId']);
  final company = state.company;
  if (openPrint) {
    try {
      await Printing.layoutPdf(onLayout: (_) => generateInvoicePdf(invoice, customer, company));
    } catch (e) { if (context.mounted) inform(context, e.toString(), error: true); }
    return;
  }
  if (!context.mounted) return;
  await showDialog<void>(context: context, builder: (ctx) => Dialog(
    insetPadding: const EdgeInsets.all(12),
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 860, maxHeight: 900), child: Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 12), color: brand,
        child: Row(children: [
          Expanded(child: Text('عرض الفاتورة - ${txt(invoice['invoiceNo'], '-')}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          TextButton.icon(onPressed: () async {
            try { await Printing.layoutPdf(onLayout: (_) => generateInvoicePdf(invoice, customer, company)); }
            catch (e) { if (ctx.mounted) inform(ctx, e.toString(), error: true); }
          }, icon: const Icon(Icons.print, color: Colors.white), label: const Text('طباعة', style: TextStyle(color: Colors.white))),
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
        ]),
      ),
      Expanded(child: SingleChildScrollView(child: InvoicePreview(invoice: invoice, customer: customer, company: company))),
    ])),
  ));
}

class InvoicePreview extends StatelessWidget {
  final Map<String, dynamic> invoice, customer, company;
  const InvoicePreview({super.key, required this.invoice, required this.customer, required this.company});
  @override
  Widget build(BuildContext context) {
    final logo = company['logoEnabled'] == true ? imageData(company['logo']) : null;
    final stamp = company['stampEnabled'] == true ? imageData(company['stamp']) : null;
    final qr = invoiceQrPayload(invoice, company);
    final customerItems = {
      'اسم العميل': customer['name'], 'الرقم الضريبي': customer['vat'], 'السجل التجاري': customer['cr'],
      'رقم الجوال': txt(invoice['mobile'], txt(customer['mobile'])),
      'البريد الإلكتروني': txt(invoice['email'], txt(customer['email'])),
      'العنوان': txt(invoice['address'], txt(customer['address'])),
    };
    final invoiceItems = {
      'رقم الفاتورة': invoice['invoiceNo'], 'تاريخ الفاتورة': invoice['date'],
      'رقم الوثيقة': invoice['policyNo'], 'رقم التأشيرة': invoice['endorsementNo'],
    };
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final stampSize = numValue(company['stampSize'], 100).clamp(10, 260).toDouble();
      final left = (w * numValue(company['stampX'], 70) / 100 - stampSize / 2).clamp(0, (w - stampSize).clamp(0, w)).toDouble();
      final top = (850 * numValue(company['stampY'], 60) / 100 - stampSize / 2).clamp(0, 850).toDouble();
      return Container(color: Colors.white, constraints: const BoxConstraints(minHeight: 900), padding: const EdgeInsets.all(20), child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.start, spacing: 14, runSpacing: 15, children: [
            SizedBox(width: w >= 620 ? w * .56 : w - 40, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (logo != null) Image.memory(logo, height: numValue(company['logoSize'],80).clamp(25, 200).toDouble(), width: 180, fit: BoxFit.contain)
                else const Icon(Icons.local_hospital, size: 55, color: brand),
              Text(txt(company['nameAr']), style: const TextStyle(color: brand, fontSize: 19, fontWeight: FontWeight.bold)),
              Text(txt(company['nameEn']), style: const TextStyle(fontSize: 12)), gap(8),
              Text('📍 ${txt(company['address'], '-')}'),
              Text('☎ ${txt(company['phone'], '-')} | ✉ ${txt(company['email'], '-')}'),
              Text('🌐 ${txt(company['website'], '-')}'),
              Text('رقم السجل التجاري: ${txt(company['cr'], '-')}'),
              Text('الرقم الضريبي: ${txt(company['vat'], '-')}'),
            ])),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9), decoration: BoxDecoration(color: brand, borderRadius: BorderRadius.circular(8)),
                child: const Text('فاتورة ضريبية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              const Text('Tax Invoice'), gap(8),
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(border: Border.all(color: brand)),
                child: QrImageView(data: qr, size: 105, backgroundColor: Colors.white)),
              const Text('رمز الاستجابة السريعة', style: TextStyle(fontSize: 10)),
              const Text('ZATCA TLV QR', style: TextStyle(fontSize: 10)),
            ]),
          ]), gap(12),
          const Divider(thickness: 3, color: brand), gap(12),
          Wrap(spacing: 14, runSpacing: 12, children: [
            SizedBox(width: w >= 600 ? (w - 50) / 2 : w - 40, child: _infoPanel('بيانات العميل', customerItems)),
            SizedBox(width: w >= 600 ? (w - 50) / 2 : w - 40, child: _infoPanel('بيانات الفاتورة', invoiceItems)),
          ]), gap(20),
          Table(border: TableBorder.all(color: Colors.grey.shade300), columnWidths: const {0: FixedColumnWidth(35), 2: FixedColumnWidth(130)},
            children: [
              TableRow(decoration: const BoxDecoration(color: brand), children: ['م','البيان','المبلغ (ريال)']
                .map((s) => Padding(padding: const EdgeInsets.all(10), child: Text(s, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))).toList()),
              TableRow(children: [cell('1'), cell(invoice['description']), cell(money(invoice['amount']), bold: true)]
                .map((c) => Padding(padding: const EdgeInsets.all(10), child: c)).toList()),
            ],
          ), gap(17),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 390), child: Column(children: [
            _amountLine('المبلغ قبل الضريبة', money(invoice['amount'])),
            _amountLine('ضريبة القيمة المضافة (${numValue(invoice['vatRate'])}%)', money(invoice['vatAmount'])),
            _amountLine('الإجمالي شامل الضريبة', money(invoice['total']), highlighted: true),
          ])), gap(55),
          const Divider(thickness: 2, color: brand),
          Center(child: Text(txt(company['footerText']), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
        ]),
        if (stamp != null) Positioned(left: left, top: top, child: Opacity(opacity: .5, child: Image.memory(stamp, width: stampSize, height: stampSize, fit: BoxFit.contain))),
      ]));
    });
  }
  Widget _infoPanel(String title, Map<String, dynamic> items) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE0E0E0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: brand, fontWeight: FontWeight.bold)), const Divider(),
      ...items.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text('${e.key}: ${txt(e.value, '-')}'))),
    ]),
  );
  Widget _amountLine(String title, String value, {bool highlighted = false}) => Container(
    color: highlighted ? brand : null,
    padding: const EdgeInsets.all(12),
    child: Row(children: [
      Expanded(child: Text(title, style: TextStyle(color: highlighted ? Colors.white : Colors.black87, fontWeight: highlighted ? FontWeight.bold : FontWeight.normal))),
      Text(value, style: TextStyle(color: highlighted ? Colors.white : brand, fontWeight: FontWeight.bold)),
    ]),
  );
}

Future<Uint8List> generateInvoicePdf(
    Map<String, dynamic> invoice, Map<String, dynamic> customer, Map<String, dynamic> company) async {
  final pdf = pw.Document();
  // Cairo fonts are loaded by the printing package when printing; internet is required on first use.
  final regular = await PdfGoogleFonts.cairoRegular();
  final bold = await PdfGoogleFonts.cairoBold();
  pw.Text ptext(String text, {double size = 10, bool strong = false, PdfColor? color}) => pw.Text(
    text, style: pw.TextStyle(font: strong ? bold : regular, fontSize: size, color: color ?? PdfColors.black));
  final logo = company['logoEnabled'] == true ? imageData(company['logo']) : null;
  final stamp = company['stampEnabled'] == true ? imageData(company['stamp']) : null;
  final infoCustomer = {
    'اسم العميل': customer['name'], 'الرقم الضريبي': customer['vat'], 'السجل التجاري': customer['cr'],
    'رقم الجوال': txt(invoice['mobile'], txt(customer['mobile'])),
    'البريد الإلكتروني': txt(invoice['email'], txt(customer['email'])),
    'العنوان': txt(invoice['address'], txt(customer['address'])),
  };
  final infoInvoice = {
    'رقم الفاتورة': invoice['invoiceNo'], 'تاريخ الفاتورة': invoice['date'],
    'رقم الوثيقة': invoice['policyNo'], 'رقم التأشيرة': invoice['endorsementNo'],
  };
  pw.Widget info(String title, Map<String, dynamic> items) => pw.Container(
    padding: const pw.EdgeInsets.all(9), decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300), color: PdfColors.grey100,
    ), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      ptext(title, strong: true, color: PdfColor.fromHex('#0A3D62')), pw.Divider(),
      ...items.entries.map((entry) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3), child: ptext('${entry.key}: ${txt(entry.value, '-')}', size: 8))),
    ]),
  );
  pw.Widget numberRow(String title, String value, {bool highlighted = false}) => pw.Container(
    color: highlighted ? PdfColor.fromHex('#0A3D62') : PdfColors.white,
    padding: const pw.EdgeInsets.all(7),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      ptext(title, strong: highlighted, color: highlighted ? PdfColors.white : PdfColors.black),
      ptext(value, strong: true, color: highlighted ? PdfColors.white : PdfColors.black),
    ]),
  );
  final pageWidth = PdfPageFormat.a4.width - 48;
  final size = numValue(company['stampSize'], 100).clamp(30, 180).toDouble();
  final positionX = (pageWidth * numValue(company['stampX'], 70) / 100 - size / 2).clamp(0, pageWidth - size).toDouble();
  final positionY = (PdfPageFormat.a4.height * numValue(company['stampY'], 60) / 100 - size / 2).clamp(0, 620).toDouble();
  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(24),
    build: (_) => pw.Directionality(textDirection: pw.TextDirection.rtl,
      child: pw.Stack(children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(flex: 5, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              if (logo != null) pw.Image(pw.MemoryImage(logo), width: 85, height: numValue(company['logoSize'], 80).clamp(25, 100).toDouble()),
              ptext(txt(company['nameAr']), size: 15, strong: true, color: PdfColor.fromHex('#0A3D62')),
              ptext(txt(company['nameEn']), size: 8), pw.SizedBox(height: 5),
              ptext('العنوان: ${txt(company['address'], '-')}', size: 8),
              ptext('الهاتف: ${txt(company['phone'], '-')} • البريد: ${txt(company['email'], '-')}', size: 8),
              ptext('الموقع: ${txt(company['website'], '-')}', size: 8),
              ptext('السجل التجاري: ${txt(company['cr'], '-')}', size: 8),
              ptext('الرقم الضريبي: ${txt(company['vat'], '-')}', size: 8),
            ])),
            pw.SizedBox(width: 10),
            pw.Expanded(flex: 3, child: pw.Column(children: [
              pw.Container(padding: const pw.EdgeInsets.all(9), decoration: pw.BoxDecoration(color: PdfColor.fromHex('#0A3D62')),
                child: ptext('فاتورة ضريبية', size: 13, strong: true, color: PdfColors.white)),
              ptext('Tax Invoice', size: 9), pw.SizedBox(height: 5),
              pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: invoiceQrPayload(invoice, company), width: 84, height: 84),
              ptext('ZATCA TLV QR', size: 7),
            ])),
          ]), pw.SizedBox(height: 12), pw.Divider(thickness: 2, color: PdfColor.fromHex('#0A3D62')),
          pw.SizedBox(height: 12),
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(child: info('بيانات العميل', infoCustomer)), pw.SizedBox(width: 12),
            pw.Expanded(child: info('بيانات الفاتورة', infoInvoice)),
          ]), pw.SizedBox(height: 18),
          pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), columnWidths: {
            0: const pw.FixedColumnWidth(30), 1: const pw.FlexColumnWidth(), 2: const pw.FixedColumnWidth(110),
          }, children: [
            pw.TableRow(decoration: pw.BoxDecoration(color: PdfColor.fromHex('#0A3D62')), children: [
              'م', 'البيان', 'المبلغ (ريال)'].map((s) => pw.Padding(padding: const pw.EdgeInsets.all(8), child: ptext(s, strong: true, color: PdfColors.white))).toList()),
            pw.TableRow(children: [ptext('1'), ptext(txt(invoice['description'], '-')), ptext(money(invoice['amount']), strong: true)]
              .map((w) => pw.Padding(padding: const pw.EdgeInsets.all(8), child: w)).toList()),
          ]),
          pw.SizedBox(height: 17),
          pw.SizedBox(width: 310, child: pw.Column(children: [
            numberRow('المبلغ قبل الضريبة', money(invoice['amount'])),
            numberRow('ضريبة القيمة المضافة (${numValue(invoice['vatRate'])}%)', money(invoice['vatAmount'])),
            numberRow('الإجمالي شامل الضريبة', money(invoice['total']), highlighted: true),
          ])),
          pw.SizedBox(height: 65),
          pw.Divider(thickness: 2, color: PdfColor.fromHex('#0A3D62')),
          pw.Center(child: ptext(txt(company['footerText']), size: 8)),
        ]),
        if (stamp != null) pw.Positioned(left: positionX, top: positionY,
          child: pw.Opacity(opacity: .5, child: pw.Image(pw.MemoryImage(stamp), width: size, height: size))),
      ])),
  ));
  return pdf.save();
}
