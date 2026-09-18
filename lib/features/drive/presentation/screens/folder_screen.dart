import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tele_drive/services/compression/folder_compression_service.dart';
import '../../domain/entities/drive_file.dart';
import '../providers/drive_provider.dart';
import '../widgets/compression_progress_dialog.dart';
import '../widgets/file_grid_item.dart';
import '../widgets/file_list_item.dart';
import '../widgets/upload_options_sheet.dart';

class FolderScreen extends ConsumerStatefulWidget {
  final String folderId;
  final String folderName;
  const FolderScreen({super.key, required this.folderId, required this.folderName});

  @override
  ConsumerState<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends ConsumerState<FolderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driveProvider.notifier).loadFiles(folderId: widget.folderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final driveState = ref.watch(driveProvider);
    final files = driveState.filteredFiles;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: Icon(driveState.viewMode == ViewMode.grid
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded),
            onPressed: () => ref.read(driveProvider.notifier).toggleViewMode(),
          ),
        ],
      ),
      body: driveState.isLoadingFiles
          ? const LoadingView(message: AppText.loadingFiles)
          : files.isEmpty
              ? EmptyState(
                  icon: Icons.folder_open_rounded,
                  title: AppText.folderIsEmpty,
                  subtitle: '${AppText.uploadFilesToFolder}${widget.folderName}',
                  actionLabel: AppText.upload,
                  onAction: _showUploadOptions,
                )
              : driveState.viewMode == ViewMode.grid
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: files.length,
                        itemBuilder: (_, i) => FileGridItem(
                          file: files[i],
                          isSelectionMode: false,
                          isSelected: false,
                          onTap: () {},
                          onLongPress: () {},
                          onDelete: () => ref.read(driveProvider.notifier).deleteFile(files[i]),
                          onDownload: () => _downloadFile(files[i]),
                          onShare: () => _shareFile(files[i]),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: files.length,
                      itemBuilder: (_, i) => FileListItem(
                        file: files[i],
                        isSelectionMode: false,
                        isSelected: false,
                        onTap: () {},
                        onLongPress: () {},
                        onDelete: () => ref.read(driveProvider.notifier).deleteFile(files[i]),
                        onDownload: () => _downloadFile(files[i]),
                        onShare: () => _shareFile(files[i]),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadOptions,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_rounded),
        label: const Text(AppText.upload),
        elevation: 4,
      ),
    );
  }

  void _showUploadOptions() {
    UploadOptionsSheet.show(
      context: context,
      onUploadFiles: _pickAndUploadFiles,
      onUploadFolder: _pickAndUploadFolder,
    );
  }

  Future<void> _pickAndUploadFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    if (result.files.length > AppConstants.maxUploadBatchCount) {
      _showErrorDialog(
        AppText.tooManyFilesSelectedTitle,
        AppText.tooManyFilesSelectedContent,
      );
      return;
    }

    final tooLargeFiles = result.files
        .where((f) => f.size > AppConstants.maxUploadSizeBytes)
        .toList();
    if (tooLargeFiles.isNotEmpty) {
      final names = tooLargeFiles.map((f) => f.name).join(', ');
      _showErrorDialog(
        AppText.fileSizeExceededTitle,
        AppText.fileSizeExceededMultiple(names),
      );
      return;
    }

    for (final file in result.files) {
      if (file.path != null) {
        ref.read(uploadProvider.notifier).uploadFile(
              localPath: file.path!,
              fileName: file.name,
              folderId: widget.folderId,
            );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${AppText.uploadingN} ${result.files.length} ${AppText.uploadingFilesSuffix}',
        ),
      ),
    );
  }

  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.manageExternalStorage.status;
    if (status.isGranted) return true;

    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Storage Permission Needed'),
        content: const Text(
          'To compress and upload folders from your device, TeleDrive needs "All files access" permission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppText.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (shouldRequest != true) return false;

    final result = await Permission.manageExternalStorage.request();
    if (!result.isGranted) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'All files access is required to read and compress folders.',
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _pickAndUploadFolder() async {
    try {
      final hasPermission = await _ensureStoragePermission();
      if (!hasPermission) return;

      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null || selectedDirectory.isEmpty) return;
      if (!mounted) return;

      final folderName = p.basename(selectedDirectory);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CompressionProgressDialog(folderName: folderName),
      );

      CompressedFolderResult result;
      try {
        result = await FolderCompressionService.instance.compressDirectory(
          directoryPath: selectedDirectory,
        );
      } finally {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }

      if (!mounted) return;

      if (result.compressedSizeBytes > AppConstants.maxUploadSizeBytes) {
        _showErrorDialog(
          AppText.fileSizeExceededTitle,
          AppText.fileSizeExceededSingle(result.zipFileName),
        );
        await FolderCompressionService.instance.deleteTempZip(result.zipPath);
        return;
      }

      ref.read(uploadProvider.notifier).uploadFile(
            localPath: result.zipPath,
            fileName: result.zipFileName,
            folderId: widget.folderId,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '${AppText.uploadingN} 1 ${AppText.uploadingFilesSuffix}',
          ),
        ),
      );
    } on StoragePermissionException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    } on EmptyFolderException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppText.folderEmpty)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to compress folder: $e')),
      );
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppText.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(DriveFile file) async {
    try {
      await ref.read(driveRepositoryProvider).downloadFile(file: file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${file.name} ${AppText.downloadedSnack}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppText.downloadFailed}$e')),
      );
    }
  }

  Future<void> _shareFile(DriveFile file) async {
    var path = file.localPath;
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      try {
        path = await ref.read(driveRepositoryProvider).downloadFile(file: file);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppText.shareFailed}$e')),
        );
        return;
      }
    }
    await SharePlus.instance.share(ShareParams(files: [XFile(path)], text: file.name));
  }
}
