import 'dart:convert';
import 'dart:io';

import 'package:gpth/album.dart';
import 'package:gpth/date_extractor.dart';
import 'package:gpth/duplicate.dart';
import 'package:gpth/media.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  /// this is 1x1 green jg image, with exif:
  /// DateTime Original: 2022:12:16 16:06:47
  const greenImgBase64 = """
/9j/4AAQSkZJRgABAQAAAQABAAD/4QC4RXhpZgAATU0AKgAAAAgABQEaAAUAAAABAAAASgEbAAUA
AAABAAAAUgEoAAMAAAABAAEAAAITAAMAAAABAAEAAIdpAAQAAAABAAAAWgAAAAAAAAABAAAAAQAA
AAEAAAABAAWQAAAHAAAABDAyMzKQAwACAAAAFAAAAJyRAQAHAAAABAECAwCgAAAHAAAABDAxMDCg
AQADAAAAAf//AAAAAAAAMjAyMjoxMjoxNiAxNjowNjo0NwD/2wBDAAMCAgICAgMCAgIDAwMDBAYE
BAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/2wBDAQMDAwQD
BAgEBAgQCwkLEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQ
EBD/wAARCAABAAEDAREAAhEBAxEB/8QAFAABAAAAAAAAAAAAAAAAAAAAA//EABQQAQAAAAAAAAAA
AAAAAAAAAAD/xAAUAQEAAAAAAAAAAAAAAAAAAAAI/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwD
AQACEQMRAD8AIcgXf//Z""";

  final albumDir = Directory('Vacation');
  final imgFileGreen = File('green.jpg');
  final imgFile1 = File('image.jpg');
  final jsonFile1 = File('image.jpg.json');
  final imgFile2 = File('verylongverylong.jpg');
  final jsonFile2 = File('verylongverylon.json');
  final media = [
    Media(imgFile1, dateTaken: DateTime(2020, 9, 1), dateTakenAccuracy: 1),
    Media(imgFile2, dateTaken: DateTime(2020), dateTakenAccuracy: 2),
  ];
  setUpAll(() {
    albumDir.createSync(recursive: true);
    imgFileGreen.createSync();
    imgFileGreen.writeAsBytesSync(
      base64.decode(greenImgBase64.replaceAll('\n', '')),
    );
    imgFile1.createSync();
    imgFile1.copySync('${albumDir.path}/${basename(imgFile1.path)}');
    imgFile2.createSync();
    jsonFile1.createSync();
    jsonFile1
        .writeAsStringSync('{"photoTakenTime": {"timestamp": "1599078832"}}');
    jsonFile2
        .writeAsStringSync('{"photoTakenTime": {"timestamp": "1683078832"}}');
  });
  test('test json extractor', () async {
    expect((await jsonExtractor(imgFile1))?.millisecondsSinceEpoch,
        1599078832 * 1000);
    expect((await jsonExtractor(imgFile2))?.millisecondsSinceEpoch,
        1683078832 * 1000);
  });
  test('test exif extractor', () async {
    expect(
      (await exifExtractor(imgFileGreen)),
      DateTime.parse('2022-12-16 16:06:47'),
    );
  });
  test('test guess extractor', () async {
    final files = [
      ['Screenshot_20190919-053857_Camera-edited.jpg', '2019-09-19 05:38:57'],
      ['MVIMG_20190215_193501.MP4', '2019-02-15 19:35:01'],
      ['Screenshot_2019-04-16-11-19-37-232_com.go.jpg', '2019-04-16 11:19:37']
    ];
    for (final f in files) {
      expect((await guessExtractor(File(f.first))), DateTime.parse(f.last));
    }
  });

  test('test duplicate removal', () {
    expect(removeDuplicates(media), 1);
    expect(media.length, 1);
    expect(media.first.file, imgFile1);
  });
  test('test album finding', () {
    expect(findAlbums([albumDir], media), [
      Album('Vacation', [media.first])
    ]);
  });
  tearDownAll(() {
    albumDir.deleteSync(recursive: true);
    imgFileGreen.deleteSync();
    imgFile1.deleteSync();
    imgFile2.deleteSync();
    jsonFile1.deleteSync();
    jsonFile2.deleteSync();
  });
}
