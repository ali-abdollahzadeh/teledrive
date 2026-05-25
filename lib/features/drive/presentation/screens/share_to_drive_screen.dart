import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/drive_folder.dart';
import '../providers/drive_provider.dart';

/// Full-page screen shown when the user shares files into TeleDrive from the
/// system file manager (or any other Android share-sheet trigger).
///
/// Flow:
///   1. Display the list of TeleDrive folders (loaded from [driveProvider]).
///   2. User taps a folder → uploads begin via [uploadProvider].
///   3. Inline progress is shown for every active upload task.
///   4. When all tasks finish the screen automatically navigates to [AppRoutes.drive].
class ShareToDriveScreen extends ConsumerStatefulWidget {
  /// The files that were received from the share intent.
  final List<SharedMediaFile> sharedFiles;

  const ShareToDriveScreen({super.key, required this.sharedFiles});

  @override
  ConsumerState<ShareToDriveScreen> createState() => _ShareToDriveScreenState();
}

class _ShareToDriveScreenState extends ConsumerState<ShareToDriveScreen>
    with SingleTickerProviderStateMixin {
  DriveFolder? _selectedFolder;
  bool _uploading = false;
  bool _navigatedAway = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    // Make sure folders are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driveState = ref.read(driveProvider);
      if (driveState.folders.isEmpty && !driveState.isLoadingFolders) {
        ref.read(driveProvider.notifier).loadFolders();
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String get _filesLabel {
    if (widget.sharedFiles.length == 1) {
      return '"${p.basename(widget.sharedFiles.first.path)}"';
    }
    return '${widget.sharedFiles.length} files';
  }

  Future<void> _startUpload(DriveFolder folder) async {
    setState(() {
      _selectedFolder = folder;
      _uploading = true;
    });

    for (final file in widget.sharedFiles) {
      final fileName = p.basename(file.path);
      ref.read(uploadProvider.notifier).uploadFile(
            localPath: file.path,
            fileName: fileName,
            folderId: folder.id,
          );
    }

    // Reset the intent so it doesn't fire again on resume
    ReceiveSharingIntent.instance.reset();
  }

  /// Checks whether all tasks for the current upload batch are done.
  bool _allTasksDone(UploadState uploadState) {
    if (!_uploading || _selectedFolder == null) return false;
    final tasks = uploadState.tasks
        .where((t) => t.folderId == _selectedFolder!.id)
        .toList();
    if (tasks.isEmpty) return false;
    return tasks.every((t) => t.isComplete || t.hasError);
  }

  void _goHome() {
    if (_navigatedAway) return;
    _navigatedAway = true;
    context.go(AppRoutes.drive);
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final driveState = ref.watch(driveProvider);
    final uploadState = ref.watch(uploadProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Auto-navigate when upload completes
    if (_uploading && _allTasksDone(uploadState) && !_navigatedAway) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goHome());
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ────────────────────────────────────────────────────
              _buildHeader(isDark, colorScheme),

              // ── Body ──────────────────────────────────────────────────────
              Expanded(
                child: _uploading
                    ? _buildProgressView(uploadState, isDark)
                    : _buildFolderPicker(driveState, isDark, colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
      child: Row(
        children: [
          // TeleDrive icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.cloud_upload_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          AppSpacing.hGapSM,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Save to TeleDrive',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.defaultBlackText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _filesLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!_uploading)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Cancel',
              onPressed: () => context.go(AppRoutes.drive),
            ),
        ],
      ),
    );
  }

  // ── Folder Picker ──────────────────────────────────────────────────────────

  Widget _buildFolderPicker(
      DriveState driveState, bool isDark, ColorScheme colorScheme) {
    if (driveState.isLoadingFolders) {
      return _buildLoadingState(isDark);
    }
    if (driveState.folders.isEmpty) {
      return _buildEmptyFoldersState(isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xs),
          child: Text(
            'Choose a folder',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.lightTextSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            itemCount: driveState.folders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final folder = driveState.folders[index];
              return _FolderTile(
                folder: folder,
                isDark: isDark,
                onTap: () => _startUpload(folder),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Progress View ──────────────────────────────────────────────────────────

  Widget _buildProgressView(UploadState uploadState, bool isDark) {
    final folderTasks = _selectedFolder == null
        ? uploadState.tasks
        : uploadState.tasks
            .where((t) => t.folderId == _selectedFolder!.id)
            .toList();

    final completed = folderTasks.where((t) => t.isComplete).length;
    final errored = folderTasks.where((t) => t.hasError).length;
    final total = folderTasks.length;
    final allDone = total > 0 && folderTasks.every((t) => t.isComplete || t.hasError);

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Destination info ──
          _DestinationBadge(
            folder: _selectedFolder!,
            isDark: isDark,
          ),
          AppSpacing.gapXL,

          // ── Overall progress bar ──
          if (total > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  allDone ? 'All done!' : 'Uploading…',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.defaultBlackText,
                  ),
                ),
                Text(
                  '$completed / $total',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            AppSpacing.gapXS,
            ClipRRect(
              borderRadius: AppRadius.fullBR,
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : completed / total,
                minHeight: 6,
                backgroundColor:
                    isDark ? AppColors.dividerDark : AppColors.lightDivider,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            AppSpacing.gapLG,
          ],

          // ── Per-file list ──
          Expanded(
            child: ListView.separated(
              itemCount: folderTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) =>
                  _UploadTaskRow(task: folderTasks[i], isDark: isDark),
            ),
          ),

          // ── Error summary ──
          if (errored > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                '$errored file(s) failed to upload.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),

          // ── Done button (shows when all finished) ──
          if (allDone) ...[
            AppSpacing.gapLG,
            FilledButton.icon(
              onPressed: _goHome,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Go to TeleDrive'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.lgBR),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Auxiliary states ───────────────────────────────────────────────────────

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          AppSpacing.gapMD,
          Text(
            'Loading your folders…',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFoldersState(bool isDark) {
    return Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off_outlined,
                size: 64,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.lightTextSecondary),
            AppSpacing.gapMD,
            Text(
              'No folders found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.defaultBlackText,
              ),
            ),
            AppSpacing.gapXS,
            Text(
              'Please open TeleDrive first and create a folder, then try sharing again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.lightTextSecondary),
            ),
            AppSpacing.gapXL,
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.drive),
              child: const Text('Open TeleDrive'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Folder tile ──────────────────────────────────────────────────────────────

class _FolderTile extends StatelessWidget {
  final DriveFolder folder;
  final bool isDark;
  final VoidCallback onTap;

  const _FolderTile({
    required this.folder,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.cardDark : Colors.white,
      borderRadius: AppRadius.lgBR,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgBR,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              // Folder icon badge
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: folder.isSavedMessages
                      ? AppColors.avatarSaved.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  folder.isSavedMessages
                      ? Icons.bookmark_rounded
                      : Icons.folder_rounded,
                  color: folder.isSavedMessages
                      ? AppColors.avatarSaved2
                      : AppColors.primary,
                  size: 24,
                ),
              ),
              AppSpacing.hGapSM,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white : AppColors.defaultBlackText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${folder.fileCount} files',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.lightTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Destination badge ────────────────────────────────────────────────────────

class _DestinationBadge extends StatelessWidget {
  final DriveFolder folder;
  final bool isDark;
  const _DestinationBadge({required this.folder, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgBR,
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              folder.isSavedMessages
                  ? Icons.bookmark_rounded
                  : Icons.folder_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          AppSpacing.hGapSM,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uploading to',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  folder.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.defaultBlackText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Per-task row ─────────────────────────────────────────────────────────────

class _UploadTaskRow extends StatelessWidget {
  final UploadTask task;
  final bool isDark;
  const _UploadTaskRow({required this.task, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final Color statusColor = task.hasError
        ? AppColors.error
        : task.isComplete
            ? AppColors.success
            : AppColors.primary;

    final IconData statusIcon = task.hasError
        ? Icons.error_outline_rounded
        : task.isComplete
            ? Icons.check_circle_rounded
            : Icons.upload_rounded;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.lightSurface,
        borderRadius: AppRadius.mdBR,
      ),
      child: Row(
        children: [
          // Status icon
          Icon(statusIcon, color: statusColor, size: 22),
          AppSpacing.hGapSM,
          // File name + progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.defaultBlackText,
                  ),
                ),
                if (!task.isComplete && !task.hasError) ...[
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: AppRadius.fullBR,
                    child: LinearProgressIndicator(
                      value: task.progress,
                      minHeight: 4,
                      backgroundColor: isDark
                          ? AppColors.dividerDark
                          : AppColors.lightDivider,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ] else if (task.hasError) ...[
                  const SizedBox(height: 3),
                  Text(
                    task.error ?? 'Upload failed',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.error),
                  ),
                ],
              ],
            ),
          ),
          // Percentage label
          if (!task.isComplete && !task.hasError)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                '${(task.progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
