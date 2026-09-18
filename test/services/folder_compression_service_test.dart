import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tele_drive/services/compression/folder_compression_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempBaseDir;
  late Directory sourceFolder;

  setUp(() async {
    tempBaseDir = await Directory.systemTemp.createTemp('teledrive_test_');

    sourceFolder = Directory(p.join(tempBaseDir.path, 'MySampleFolder'));
    await sourceFolder.create(recursive: true);

    // Create some nested files
    final subFolder = Directory(p.join(sourceFolder.path, 'sub'));
    await subFolder.create(recursive: true);

    await File(p.join(sourceFolder.path, 'file1.txt')).writeAsString('Hello World 1');
    await File(p.join(sourceFolder.path, 'file2.bin')).writeAsBytes([0, 1, 2, 3, 4, 5]);
    await File(p.join(subFolder.path, 'nested.txt')).writeAsString('Nested content here');
  });

  tearDown(() async {
    try {
      if (await tempBaseDir.exists()) {
        await tempBaseDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('successfully compresses a directory and creates a valid zip', () async {
    final result = await FolderCompressionService.instance.compressDirectory(
      directoryPath: sourceFolder.path,
      outputDirPath: tempBaseDir.path,
    );

    expect(result.zipFileName, 'MySampleFolder.zip');
    expect(result.totalFiles, 3);
    expect(File(result.zipPath).existsSync(), isTrue);
    expect(result.compressedSizeBytes, greaterThan(0));

    // Verify zip contents using archive decoder
    final bytes = await File(result.zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final fileNamesInArchive = archive.files.map((f) => f.name.replaceAll('\\', '/')).toList();
    expect(fileNamesInArchive, contains('file1.txt'));
    expect(fileNamesInArchive, contains('file2.bin'));
    expect(fileNamesInArchive, contains('sub/nested.txt'));

    // Test deleteTempZip
    await FolderCompressionService.instance.deleteTempZip(result.zipPath);
    expect(File(result.zipPath).existsSync(), isFalse);
  });

  test('throws EmptyFolderException when folder contains no files', () async {
    final emptyDir = Directory(p.join(tempBaseDir.path, 'EmptyFolder'));
    await emptyDir.create();

    expect(
      () => FolderCompressionService.instance.compressDirectory(
        directoryPath: emptyDir.path,
        outputDirPath: tempBaseDir.path,
      ),
      throwsA(isA<EmptyFolderException>()),
    );
  });
}
