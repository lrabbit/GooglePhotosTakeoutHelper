import 'dart:io';
import 'dart:math';

import 'package:exif/exif.dart';

Future<DateTime?> exifExtractor(File file) async {
  final bytes = await file.readAsBytes();
  // this returns empty {} if file doesn't have exif so don't worry
  final tags = await readExifFromBytes(bytes);
  String? datetime;
  // try if any of these exists
  datetime ??= tags['Image DateTime']?.printable;
  datetime ??= tags['EXIF DateTimeOriginal']?.printable;
  datetime ??= tags['EXIF DateTimeDigitized']?.printable;
  if (datetime == null) return null;
  // replace all shitty separators that are sometimes met
  datetime = datetime
      .replaceAll('-', ':')
      .replaceAll('/', ':')
      .replaceAll('.', ':')
      .replaceAll('\\', ':')
      .replaceAll(': ', ':0')
      .substring(0, min(datetime.length, 19))
      .replaceFirst(':', '-') // replace two : year/month to comply with iso
      .replaceFirst(':', '-');
  // now date is like: "1999-06-23 23:55"
  return DateTime.tryParse(datetime);
}
