import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text.dart';
import '../../../../core/theme/app_colors.dart';

/// Bottom sheet allowing users to choose between uploading individual files
/// or an entire folder automatically compressed into a .zip archive.
class UploadOptionsSheet extends StatelessWidget {
  final VoidCallback onUploadFiles;
  final VoidCallback onUploadFolder;

  const UploadOptionsSheet({
    super.key,
    required this.onUploadFiles,
    required this.onUploadFolder,
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onUploadFiles,
    required VoidCallback onUploadFolder,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => UploadOptionsSheet(
        onUploadFiles: onUploadFiles,
        onUploadFolder: onUploadFolder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C2229) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          AppSpacing.gapLG,

          // Title
          Text(
            AppText.upload,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
          ),
          AppSpacing.gapMD,

          // Option 1: Upload Files
          _buildOptionTile(
            context: context,
            icon: Icons.upload_file_rounded,
            title: AppText.uploadFiles,
            subtitle: AppText.uploadFilesSubtitle,
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              onUploadFiles();
            },
          ),
          AppSpacing.gapSM,

          // Option 2: Upload Folder (.zip)
          _buildOptionTile(
            context: context,
            icon: Icons.folder_zip_rounded,
            title: AppText.uploadFolder,
            subtitle: AppText.uploadFolderSubtitle,
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              onUploadFolder();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
              AppSpacing.hGapMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    AppSpacing.gapXXS,
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
