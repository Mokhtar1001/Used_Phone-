import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../utils/file_download.dart';

/// تصدير سجل المبيعات لملف Excel (.xlsx).
class SalesExportService {
  static const _mime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  /// يبني الملف وينزّله/يشاركه. بيرجّع مسار الملف على الديسكتوب، أو null (ويب/موبايل).
  static Future<String?> exportToExcel(List<Product> sold, {required bool isArabic}) {
    final bytes = buildWorkbook(sold, isArabic: isArabic);
    final fileName = 'Merchnt_Sales_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.xlsx';
    return saveBytesAsFile(bytes, fileName, _mime);
  }

  static Uint8List buildWorkbook(List<Product> sold, {required bool isArabic}) {
    String t(String ar, String en) => isArabic ? ar : en;

    final excel = Excel.createExcel();
    final sheetName = t('المبيعات', 'Sales');
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    final headers = [
      t('تاريخ البيع', 'Sold date'),
      t('المنتج', 'Product'),
      t('الماركة', 'Brand'),
      t('المساحة', 'Storage'),
      t('الرام (GB)', 'RAM (GB)'),
      t('اللون', 'Color'),
      t('الدرجة', 'Grade'),
      t('صحة البطارية %', 'Battery health %'),
      t('السعر الأصلي', 'Original price'),
      t('سعر البيع (ج.م)', 'Sale price (EGP)'),
      t('الضمان (شهور)', 'Warranty (months)'),
      t('رقم المنتج', 'Product ID'),
    ];
    sheet.appendRow(headers.map<CellValue?>((h) => TextCellValue(h)).toList());

    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#1C1C1C'),
      horizontalAlign: HorizontalAlign.Center,
    );
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).cellStyle = headerStyle;
    }

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    var total = 0.0;
    for (final p in sold) {
      total += p.price;
      sheet.appendRow(<CellValue?>[
        TextCellValue(p.soldAt != null ? dateFormat.format(p.soldAt!.toLocal()) : ''),
        TextCellValue(p.name(isArabic)),
        TextCellValue(p.brand ?? ''),
        TextCellValue(p.storage ?? ''),
        p.ramGb != null ? IntCellValue(p.ramGb!) : null,
        TextCellValue(p.color ?? ''),
        TextCellValue(p.gradeLetter ?? ''),
        p.batteryHealth != null ? IntCellValue(p.batteryHealth!) : null,
        p.originalPrice != null ? DoubleCellValue(p.originalPrice!) : null,
        DoubleCellValue(p.price),
        IntCellValue(p.warrantyMonths),
        TextCellValue(p.id),
      ]);
    }

    // صف الإجمالي
    final totalRow = sold.length + 1;
    sheet.appendRow(<CellValue?>[
      TextCellValue(t('الإجمالي', 'Total')),
      TextCellValue('${sold.length} ${t('قطعة', 'items')}'),
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      DoubleCellValue(total),
    ]);
    final totalStyle = CellStyle(bold: true);
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: totalRow)).cellStyle = totalStyle;
    }

    const widths = [18.0, 32.0, 14.0, 12.0, 11.0, 14.0, 9.0, 16.0, 15.0, 17.0, 15.0, 38.0];
    for (var c = 0; c < widths.length; c++) {
      sheet.setColumnWidth(c, widths[c]);
    }

    return Uint8List.fromList(excel.save()!);
  }
}
