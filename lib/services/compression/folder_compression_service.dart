import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Exception thrown when a selected directory contains no readable files.
class EmptyFolderException implements Exception {
  final String message;
  const EmptyFolderException([this.message = 'The folder contains no files to upload.']);

  @override
  String toString() => message;
}

/// Exception thrown when accessing directory files is blocked by OS storage permissions.
class StoragePermissionException implements Exception {
  final String message;
  const StoragePermissionException([this.message = 'Storage permission denied.']);

  @override
  String toString() => message;
}

/// Metadata result of a completed folder compression.
class CompressedFolderResult {
  /// Absolute path to the generated .zip file.
  final String zipPath;

  /// Display name of the .zip file (e.g. "MyProject.zip").
  final String zipFileName;

  /// Total number of files included in the zip archive.
  final int totalFiles;

  /// Total uncompressed size of the files in bytes.
  final int uncompressedSizeBytes;

  /// Final compressed size of the .zip archive in bytes.
  final int compressedSizeBytes;

  const CompressedFolderResult({
    required this.zipPath,
    required this.zipFileName,
    required this.totalFiles,
    required this.uncompressedSizeBytes,
    required this.compressedSizeBytes,
  });
}

/// Parameters passed to the background isolate for compression.
class _IsolateCompressionParams {
  final String directoryPath;
  final String outputZipPath;
  final List<String> fileRelativePaths;
  final List<String> fileAbsolutePaths;

  const _IsolateCompressionParams({
    required this.directoryPath,
    required this.outputZipPath,
    required this.fileRelativePaths,
    required this.fileAbsolutePaths,
  });
}

/// Service to handle recursive folder scanning, validation, and background ZIP compression.
class FolderCompressionService {
  FolderCompressionService._();
  static final FolderCompressionService instance = FolderCompressionService._();

  /// Scans the given directory, ensures it contains valid files, and compresses it
  /// into a .zip archive inside the app's temporary cache directory.
  ///
  /// Compression runs in a background isolate via [Isolate.run] to ensure the UI
  /// remains smooth and responsive.
  Future<CompressedFolderResult> compressDirectory({
    required String directoryPath,
    String? customZipName,
    String? outputDirPath,
  }) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      throw FileSystemException('Directory does not exist', directoryPath);
    }

    // Recursively collect all files
    final List<File> files = [];
    int totalBytes = 0;

    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          // Skip common system / junk hidden files
          final basename = p.basename(entity.path);
          if (basename == '.DS_Store' || basename == 'Thumbs.db') {
            continue;
          }
          try {
            final stat = await entity.stat();
            if (stat.type == FileSystemEntityType.file) {
              files.add(entity);
              totalBytes += stat.size;
            }
          } catch (_) {
            // Ignore files that cannot be accessed
          }
        }
      }
    } on FileSystemException catch (e) {
      throw StoragePermissionException(
        'Storage access restricted by OS: ${e.message}',
      );
    }

    if (files.isEmpty) {
      throw const EmptyFolderException();
    }

    // Determine zip file name
    String baseName = customZipName ?? p.basename(directoryPath);
    if (baseName.isEmpty || baseName == '/' || baseName == '\\' || baseName == '.') {
      baseName = 'Folder_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Sanitize file name for filesystem compatibility
    final sanitizedName = baseName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final zipFileName = sanitizedName.toLowerCase().endsWith('.zip')
        ? sanitizedName
        : '$sanitizedName.zip';

    // Prepare destination in temp directory
    final uploadDir = outputDirPath != null
        ? Directory(p.join(outputDirPath, 'folder_uploads'))
        : Directory(p.join((await getTemporaryDirectory()).path, 'folder_uploads'));
    if (!await uploadDir.exists()) {
      await uploadDir.create(recursive: true);
    }

    final outputZipPath = p.join(
      uploadDir.path,
      '${DateTime.now().millisecondsSinceEpoch}_$zipFileName',
    );

    // Calculate relative paths from base directory
    final List<String> relPaths = [];
    final List<String> absPaths = [];

    for (final file in files) {
      final relative = p.relative(file.path, from: directoryPath);
      relPaths.add(relative);
      absPaths.add(file.path);
    }

    // Run compression in a separate isolate
    final params = _IsolateCompressionParams(
      directoryPath: directoryPath,
      outputZipPath: outputZipPath,
      fileRelativePaths: relPaths,
      fileAbsolutePaths: absPaths,
    );

    await Isolate.run(() => _performZip(params));

    final outputFile = File(outputZipPath);
    final compressedSize = await outputFile.length();

    return CompressedFolderResult(
      zipPath: outputZipPath,
      zipFileName: zipFileName,
      totalFiles: files.length,
      uncompressedSizeBytes: totalBytes,
      compressedSizeBytes: compressedSize,
    );
  }

  /// Worker function executed inside the background isolate.
  static Future<void> _performZip(_IsolateCompressionParams params) async {
    final encoder = ZipFileEncoder();
    encoder.create(params.outputZipPath);

    for (int i = 0; i < params.fileAbsolutePaths.length; i++) {
      final file = File(params.fileAbsolutePaths[i]);
      if (file.existsSync()) {
        final relPath = params.fileRelativePaths[i].replaceAll('\\', '/');
        await encoder.addFile(file, relPath);
      }
    }

    await encoder.close();
  }

  /// Deletes a temporary zip file once uploaded or if cancelled.
  Future<void> deleteTempZip(String zipPath) async {
    try {
      final file = File(zipPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignored
    }
  }

  /// Cleans up any stale temporary zip uploads in cache.
  Future<void> cleanTempFolderUploads({Duration maxAge = const Duration(hours: 6)}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final uploadDir = Directory(p.join(tempDir.path, 'folder_uploads'));
      if (await uploadDir.exists()) {
        final now = DateTime.now();
        await for (final entity in uploadDir.list()) {
          if (entity is File && entity.path.endsWith('.zip')) {
            final stat = await entity.stat();
            if (now.difference(stat.modified) > maxAge) {
              await entity.delete().catchError((_) => entity);
            }
          }
        }
      }
    } catch (_) {
      // Ignored
    }
  }
}
