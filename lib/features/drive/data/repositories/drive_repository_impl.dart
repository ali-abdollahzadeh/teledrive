import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/drive_file.dart';
import '../../domain/entities/drive_folder.dart';
import '../../domain/repositories/drive_repository.dart';
import '../../../../services/platform/native_telegram_channel.dart';

/// Real implementation of DriveRepository using TDLib via NativeTelegramChannel.
class DriveRepositoryImpl implements DriveRepository {
  static const String savedMessagesId = 'saved_messages';

  /// Cached user ID for Saved Messages chat
  int? _myUserId;

  String _getExtension(String fileName) {
    if (fileName.isEmpty) return '';

    final cleanName = fileName.split('?').first.split('#').first;

    final lastSlashIndex = cleanName.lastIndexOf('/');
    final baseName = lastSlashIndex == -1
        ? cleanName
        : cleanName.substring(lastSlashIndex + 1);

    final dotIndex = baseName.lastIndexOf('.');

    if (dotIndex == -1 || dotIndex == baseName.length - 1) {
      return '';
    }

    return baseName.substring(dotIndex + 1).toLowerCase();
  }

  DriveFileType _resolveType(Map<String, dynamic> map) {
    final rawType = (map['type'] ?? 'other').toString().toLowerCase();

    final fileName = (map['fileName'] ??
            map['name'] ??
            map['title'] ??
            map['localPath'] ??
            '')
        .toString()
        .toLowerCase();

    final extension = _getExtension(fileName);

    const imageExtensions = {
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'bmp',
      'heic',
      'heif',
      'svg',
    };

    const videoExtensions = {
      'mp4',
      'mkv',
      'mov',
      'webm',
      'avi',
      'flv',
      'wmv',
      'm4v',
      '3gp',
    };

    const audioExtensions = {
      'mp3',
      'm4a',
      'wav',
      'aac',
      'ogg',
      'flac',
      'opus',
      'wma',
    };

    const archiveExtensions = {
      'zip',
      'rar',
      '7z',
      'tar',
      'gz',
      'bz2',
      'xz',
      'iso',
    };

    const documentExtensions = {
      'doc',
      'docx',
      'ppt',
      'pptx',
      'xls',
      'xlsx',
      'txt',
      'rtf',
      'odt',
      'ods',
      'odp',
      'pages',
      'numbers',
      'key',
      'csv',
      'md',
    };

    if (imageExtensions.contains(extension)) {
      return DriveFileType.image;
    }

    if (videoExtensions.contains(extension)) {
      return DriveFileType.video;
    }

    if (audioExtensions.contains(extension)) {
      return DriveFileType.audio;
    }

    if (extension == 'pdf') {
      return DriveFileType.pdf;
    }

    if (archiveExtensions.contains(extension)) {
      return DriveFileType.archive;
    }

    if (documentExtensions.contains(extension)) {
      return DriveFileType.document;
    }

    // Only trust raw Telegram type for clear media types.
    // Telegram "document" means generic file, not necessarily a real document.
    if (rawType == 'image' || rawType == 'photo') {
      return DriveFileType.image;
    }

    if (rawType == 'video') {
      return DriveFileType.video;
    }

    if (rawType == 'audio' || rawType == 'voice') {
      return DriveFileType.audio;
    }

    if (rawType == 'pdf') {
      return DriveFileType.pdf;
    }

    if (rawType == 'archive') {
      return DriveFileType.archive;
    }

    return DriveFileType.other;
  }

  Future<int> _getMyUserId() async {
    if (_myUserId != null) return _myUserId!;

    final me = await NativeTelegramChannel.getMe();
    _myUserId = (me['id'] as num).toInt();

    return _myUserId!;
  }

  @override
  Future<List<DriveFolder>> getFolders() async {
    final me = await NativeTelegramChannel.getMe();
    final myId = (me['id'] as num).toInt();
    _myUserId = myId;

    final chats = await NativeTelegramChannel.getMyChats(limit: 50);

    final folders = <DriveFolder>[];

    folders.add(
      DriveFolder(
        id: savedMessagesId,
        title: 'Saved Messages',
        telegramChannelId: myId.toString(),
        createdAt: DateTime.now(),
        fileCount: 0,
        isSavedMessages: true,
      ),
    );

    final seenIds = <String>{myId.toString(), savedMessagesId};

    for (final chat in chats) {
      final chatId = (chat['id'] as num).toInt();
      final title = chat['title'] as String? ?? 'Untitled';
      final type = chat['type'] as String? ?? '';

      if (chatId == myId) continue;

      if (type == 'channel' || type == 'supergroup') {
        final idStr = chatId.toString();
        seenIds.add(idStr);
        folders.add(
          DriveFolder(
            id: idStr,
            title: title,
            telegramChannelId: idStr,
            createdAt: DateTime.now(),
            fileCount: 0,
          ),
        );
      }
    }

    // Load custom linked/imported channels from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final imported = prefs.getStringList('imported_folders') ?? [];
      for (final entry in imported) {
        final parts = entry.split(':');
        if (parts.length >= 2) {
          final chatId = parts[0];
          final title = parts.sublist(1).join(':');
          if (!seenIds.contains(chatId)) {
            seenIds.add(chatId);
            folders.add(
              DriveFolder(
                id: chatId,
                title: title,
                telegramChannelId: chatId,
                createdAt: DateTime.now(),
                fileCount: 0,
              ),
            );
          }
        }
      }
    } catch (e) {
      // SharedPreferences load failed, log or silently ignore
    }

    return folders;
  }

  @override
  Future<List<DriveFile>> getFiles({String? folderId}) async {
    int chatId;

    if (folderId == null || folderId == savedMessagesId) {
      chatId = await _getMyUserId();
    } else {
      chatId = int.tryParse(folderId) ?? 0;
    }

    if (chatId == 0) return [];

    final rawFiles = await NativeTelegramChannel.getDriveFiles(
      chatId: chatId,
      limit: 200,
    );

    return rawFiles.map((map) {
      final fileName = (map['fileName'] ??
              map['name'] ??
              map['title'] ??
              map['localPath'] ??
              'Unknown File')
          .toString();

      final type = _resolveType({
        ...map,
        'fileName': fileName,
      });

      final timestamp = map['date'] as int? ?? 0;

      final date = timestamp > 0
          ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
          : DateTime.now();

      final localPath = (map['localPath'] ?? '').toString();

      return DriveFile(
        id: map['fileId']?.toString() ?? '0',
        telegramMessageId: map['messageId']?.toString() ?? '0',
        folderId: folderId ?? savedMessagesId,
        name: fileName,
        type: type,
        size: map['size'] as int? ?? 0,
        uploadedAt: date,
        localPath: localPath.isNotEmpty ? localPath : null,
        isDownloaded: map['isDownloadingCompleted'] == true,
      );
    }).toList();
  }

  @override
  Future<String> downloadFile({
    required DriveFile file,
    void Function(double progress)? onProgress,
  }) async {
    final fileId = int.parse(file.id);

    final completer = Completer<String>();

    final sub = NativeTelegramChannel.fileUpdateStream.listen((event) {
      if (event['fileId'] == fileId) {
        final isCompleted = event['isDownloadingCompleted'] == true;
        final size = event['size'] as int? ?? 0;
        final downloaded = event['downloadedPrefixSize'] as int? ?? 0;
        final localPath = (event['localPath'] ?? '').toString();

        if (size > 0 && onProgress != null) {
          onProgress(downloaded / size);
        }

        if (isCompleted && localPath.isNotEmpty && !completer.isCompleted) {
          completer.complete(localPath);
        }
      }
    });

    try {
      final initialRes = await NativeTelegramChannel.downloadFile(
        fileId: fileId,
        priority: 32,
      );

      final initialPath = (initialRes['localPath'] ?? '').toString();

      if (initialRes['isDownloadingCompleted'] == true &&
          initialPath.isNotEmpty) {
        if (!completer.isCompleted) {
          completer.complete(initialPath);
        }
      }

      final result = await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw Exception('Download timed out'),
      );

      return result;
    } finally {
      await sub.cancel();
    }
  }

  @override
  Future<List<DriveFile>> searchFiles(
    String query, {
    String? folderId,
  }) async {
    final files = await getFiles(folderId: folderId);
    final q = query.toLowerCase();

    return files.where((file) {
      return file.name.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<DriveFile> uploadFile({
    required String localPath,
    required String fileName,
    required String folderId,
    void Function(double progress)? onProgress,
  }) async {
    int chatId;

    if (folderId == savedMessagesId) {
      chatId = await _getMyUserId();
    } else {
      chatId = int.tryParse(folderId) ?? 0;
    }

    if (chatId == 0) {
      throw Exception('Invalid folder ID');
    }

    final result = await NativeTelegramChannel.uploadFile(
      chatId: chatId,
      filePath: localPath,
    );

    final resolvedType = _resolveType({
      'fileName': fileName,
      'localPath': localPath,
      'type': result['type'] ?? 'other',
    });

    return DriveFile(
      id: result['fileId']?.toString() ?? '0',
      telegramMessageId: result['messageId']?.toString() ?? '0',
      folderId: folderId,
      name: fileName,
      type: resolvedType,
      size: result['size'] as int? ?? 0,
      uploadedAt: DateTime.now(),
      localPath: localPath,
      isDownloaded: true,
    );
  }

  @override
  Future<void> deleteFile(DriveFile file) async {
    await deleteFiles([file]);
  }

  @override
  Future<void> deleteFiles(List<DriveFile> files) async {
    if (files.isEmpty) return;

    final myId = await _getMyUserId();

    final map = <int, List<int>>{};

    for (final file in files) {
      final chatId = file.folderId == savedMessagesId
          ? myId
          : int.tryParse(file.folderId) ?? 0;

      final msgId = int.tryParse(file.telegramMessageId) ?? 0;

      if (chatId == 0) continue;
      if (msgId == 0) continue;

      map.putIfAbsent(chatId, () => []).add(msgId);
    }

    if (map.isEmpty) return;

    for (final entry in map.entries) {
      await NativeTelegramChannel.deleteMessages(
        chatId: entry.key,
        messageIds: entry.value,
        revoke: true,
      );
    }
  }

  @override
  Future<DriveFolder> createFolder(String name) async {
    final result = await NativeTelegramChannel.createFolder(title: name);

    final chatId = (result['id'] as num).toInt();
    final title = result['title'] as String? ?? name;

    return DriveFolder(
      id: chatId.toString(),
      title: title,
      telegramChannelId: chatId.toString(),
      createdAt: DateTime.now(),
      fileCount: 0,
    );
  }

  @override
  Future<void> deleteFolder(DriveFolder folder) async {
    throw UnimplementedError(
      'Folder deletion is pending native implementation.',
    );
  }
}
