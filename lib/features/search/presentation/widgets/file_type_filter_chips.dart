import 'package:flutter/material.dart';

import '../../../../core/constants/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../drive/domain/entities/drive_file.dart';

class FileTypeFilterChips extends StatelessWidget {
  final DriveFileType? selected;
  final ValueChanged<DriveFileType?> onSelected;

  const FileTypeFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final types = [null, ...DriveFileType.values];

    final labels = {
      null: 'All',
      DriveFileType.image: 'Images',
      DriveFileType.video: 'Videos',
      DriveFileType.audio: 'Audio',
      DriveFileType.pdf: 'PDF',
      DriveFileType.document: 'Docs',
      DriveFileType.archive: 'Archives',
      DriveFileType.other: 'Other',
    };

    final icons = {
      DriveFileType.image: Icons.image_rounded,
      DriveFileType.video: Icons.movie_rounded,
      DriveFileType.audio: Icons.audiotrack_rounded,
      DriveFileType.pdf: Icons.picture_as_pdf_rounded,
      DriveFileType.document: Icons.description_rounded,
      DriveFileType.archive: Icons.folder_zip_rounded,
      DriveFileType.other: Icons.insert_drive_file_rounded,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: types.map((type) {
          final isSelected = selected == type;

          return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                showCheckmark: false,
                avatar: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                      size: 14, color: AppColors.primary)
                      : Icon(
                    icons[type] ??
                        Icons.insert_drive_file_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
                label: Text(
                  labels[type] ?? AppText.filterOther,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.primary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onSelected(type),
                backgroundColor: Colors.white,
                selectedColor: AppColors.primary,
              ));
        }).toList(),
      ),
    );
  }
}
