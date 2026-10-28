import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

/// موبايل/ديسكتوب (مش ويب).
/// - ويندوز/ماك/لينكس: بيحفظ الملف في مجلد Downloads وبيرجّع المسار.
/// - أندرويد/iOS: بيفتح قايمة المشاركة (احفظه في Files/Drive أو ابعته واتساب...) وبيرجّع null.
Future<String?> saveBytesAsFile(Uint8List bytes, String fileName, String mimeType) async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
    final dir = Directory('$home${Platform.pathSeparator}Downloads');
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  await Share.shareXFiles(
    [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
    fileNameOverrides: [fileName],
  );
  return null;
}
