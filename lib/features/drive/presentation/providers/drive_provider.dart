import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/drive_file.dart';
import '../../domain/entities/drive_folder.dart';
import '../../domain/repositories/drive_repository.dart';
import '../../data/repositories/drive_repository_impl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final driveRepositoryProvider = Provider<DriveRepository>((ref) {
  return DriveRepositoryImpl();
});

final driveProvider = StateNotifierProvider<DriveNotifier, DriveState>((ref) {
  return DriveNotifier(ref.read(driveRepositoryProvider));
});

final uploadProvider =
    StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier(ref.read(driveRepositoryProvider), ref);
});

// ─── Drive State ──────────────────────────────────────────────────────────────

enum SortOption { newest, oldest, nameAZ, nameZA, sizeAsc, sizeDesc }

enum ViewMode { grid, list }

class DriveState {
  final List<DriveFile> files;
  final List<DriveFolder> folders;
  final String currentFolderId;
  final bool isLoadingFiles;
  final bool isLoadingFolders;
  final String? error;
  final String searchQuery;
  final DriveFileType? filterType;
  final SortOption sortOption;
  final ViewMode viewMode;
  final Set<String> selectedFileIds;
  final bool isSelectionMode;
  final Set<String> pendingDeleteFileIds;

  const DriveState({
    this.files = const [],
    this.folders = const [],
    this.currentFolderId = DriveRepositoryImpl.savedMessagesId,
    this.isLoadingFiles = false,
    this.isLoadingFolders = false,
    this.error,
    this.searchQuery = '',
    this.filterType,
    this.sortOption = SortOption.newest,
    this.viewMode = ViewMode.grid,
    this.selectedFileIds = const {},
    this.isSelectionMode = false,
    this.pendingDeleteFileIds = const {},
  });

  List<DriveFile> get filteredFiles {
    var result =
        files.where((f) => !pendingDeleteFileIds.contains(f.id)).toList();
    if (searchQuery.isNotEmpty) {
      result = result
          .where(
              (f) => f.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
    if (filterType != null) {
      result = result.where((f) => f.type == filterType).toList();
    }
    switch (sortOption) {
      case SortOption.newest:
        result.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      case SortOption.oldest:
        result.sort((a, b) => a.uploadedAt.compareTo(b.uploadedAt));
      case SortOption.nameAZ:
        result.sort((a, b) => a.name.compareTo(b.name));
      case SortOption.nameZA:
        result.sort((a, b) => b.name.compareTo(a.name));
      case SortOption.sizeAsc:
        result.sort((a, b) => a.size.compareTo(b.size));
      case SortOption.sizeDesc:
        result.sort((a, b) => b.size.compareTo(a.size));
    }
    return result;
  }

  DriveState copyWith({
    List<DriveFile>? files,
    List<DriveFolder>? folders,
    String? currentFolderId,
    bool? isLoadingFiles,
    bool? isLoadingFolders,
    String? error,
    String? searchQuery,
    DriveFileType? filterType,
    SortOption? sortOption,
    ViewMode? viewMode,
    Set<String>? selectedFileIds,
    bool? isSelectionMode,
    Set<String>? pendingDeleteFileIds,
    bool clearFilter = false,
    bool clearError = false,
  }) {
    return DriveState(
      files: files ?? this.files,
      folders: folders ?? this.folders,
      currentFolderId: currentFolderId ?? this.currentFolderId,
      isLoadingFiles: isLoadingFiles ?? this.isLoadingFiles,
      isLoadingFolders: isLoadingFolders ?? this.isLoadingFolders,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      filterType: clearFilter ? null : (filterType ?? this.filterType),
      sortOption: sortOption ?? this.sortOption,
      viewMode: viewMode ?? this.viewMode,
      selectedFileIds: selectedFileIds ?? this.selectedFileIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      pendingDeleteFileIds: pendingDeleteFileIds ?? this.pendingDeleteFileIds,
    );
  }
}

// ─── Drive Notifier ───────────────────────────────────────────────────────────

class DriveNotifier extends StateNotifier<DriveState> {
  final DriveRepository _repository;

  DriveNotifier(this._repository) : super(const DriveState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([loadFolders(), loadFiles()]);
  }

  Future<void> loadFiles({String? folderId}) async {
    state = state.copyWith(isLoadingFiles: true, clearError: true);
    try {
      final id = folderId ?? state.currentFolderId;
      var files = await _repository.getFiles(folderId: id);

      // Always retry once if TDLib returned an empty list
      // (happens on first launch and after folder switches while TDLib syncs)
      if (files.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        files = await _repository.getFiles(folderId: id);
      }

      state = state.copyWith(
          files: files, isLoadingFiles: false, currentFolderId: id);
    } catch (e) {
      state = state.copyWith(isLoadingFiles: false, error: e.toString());
    }
  }

  Future<void> loadFolders() async {
    state = state.copyWith(isLoadingFolders: true);
    try {
      final folders = await _repository.getFolders();
      state = state.copyWith(folders: folders, isLoadingFolders: false);
    } catch (e) {
      state = state.copyWith(isLoadingFolders: false, error: e.toString());
    }
  }

  void switchFolder(String folderId) {
    if (folderId == state.currentFolderId) return;
    // Clear current files immediately so the loading spinner shows
    state = state
        .copyWith(files: [], isLoadingFiles: true, currentFolderId: folderId);
    loadFiles(folderId: folderId);
  }

  void toggleViewMode() {
    final next =
        state.viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
    state = state.copyWith(viewMode: next);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilter(DriveFileType? type) {
    state = state.copyWith(filterType: type, clearFilter: type == null);
  }

  void setSort(SortOption option) {
    state = state.copyWith(sortOption: option);
  }

  // --- Selection Mode ---
  void toggleSelectionMode() {
    state = state
        .copyWith(isSelectionMode: !state.isSelectionMode, selectedFileIds: {});
  }

  void toggleFileSelection(String fileId) {
    final selected = Set<String>.from(state.selectedFileIds);
    if (selected.contains(fileId)) {
      selected.remove(fileId);
    } else {
      selected.add(fileId);
    }
    state = state.copyWith(
        selectedFileIds: selected, isSelectionMode: selected.isNotEmpty);
  }

  void clearSelection() {
    state = state.copyWith(isSelectionMode: false, selectedFileIds: {});
  }

  // --- Deletion & Undo ---
  void hideFilesPendingDeletion(List<DriveFile> files) {
    final pending = Set<String>.from(state.pendingDeleteFileIds);
    pending.addAll(files.map((e) => e.id));
    state = state.copyWith(
        pendingDeleteFileIds: pending,
        isSelectionMode: false,
        selectedFileIds: {});
  }

  void undoDeletion(List<DriveFile> files) {
    final pending = Set<String>.from(state.pendingDeleteFileIds);
    pending.removeAll(files.map((e) => e.id));
    state = state.copyWith(pendingDeleteFileIds: pending);
  }

  Future<void> confirmDeletion(List<DriveFile> files) async {
    try {
      await _repository.deleteFiles(files);

      final idsToRemove = files.map((e) => e.id).toSet();
      final updatedFiles =
          state.files.where((f) => !idsToRemove.contains(f.id)).toList();

      final pending = Set<String>.from(state.pendingDeleteFileIds);
      pending.removeAll(idsToRemove);

      state =
          state.copyWith(files: updatedFiles, pendingDeleteFileIds: pending);
    } catch (e) {
      // Revert the hide since delete failed
      undoDeletion(files);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteFile(DriveFile file) async {
    // Kept for backward compatibility or direct deletes
    await confirmDeletion([file]);
  }

  /// Called after a file is downloaded to update its localPath in state.
  void updateFileLocalPath(String fileId, String localPath) {
    final updatedFiles = state.files.map((f) {
      if (f.id == fileId) {
        return f.copyWith(localPath: localPath, isDownloaded: true);
      }
      return f;
    }).toList();
    state = state.copyWith(files: updatedFiles);
  }

  Future<DriveFolder> createFolder(String name) async {
    final folder = await _repository.createFolder(name);
    state = state.copyWith(folders: [...state.folders, folder]);
    return folder;
  }

  Future<void> importTelegramChannel(String chatId, String title) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imported = prefs.getStringList('imported_folders') ?? [];
      final entry = '$chatId:$title';
      if (!imported.any((e) => e.startsWith('$chatId:'))) {
        imported.add(entry);
        await prefs.setStringList('imported_folders', imported);
      }

      // Check if already exists in state to avoid duplicate UI entries
      final exists = state.folders.any((f) => f.id == chatId);
      if (!exists) {
        final newFolder = DriveFolder(
          id: chatId,
          title: title,
          telegramChannelId: chatId,
          createdAt: DateTime.now(),
          fileCount: 0,
        );
        state = state.copyWith(folders: [...state.folders, newFolder]);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to link channel: ${e.toString()}');
    }
  }

  Future<void> deleteFolder(DriveFolder folder) async {
    try {
      // If it's a custom/imported folder, also remove from imported list in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final imported = prefs.getStringList('imported_folders') ?? [];
      final updatedImported = imported.where((e) => !e.startsWith('${folder.id}:')).toList();
      if (imported.length != updatedImported.length) {
        await prefs.setStringList('imported_folders', updatedImported);
      }

      await _repository.deleteFolder(folder);
      final updated = state.folders.where((f) => f.id != folder.id).toList();
      state = state.copyWith(folders: updated);
    } catch (e) {
      // If native deletion fails but it was an imported folder, we still want to remove it locally from state and preferences!
      final prefs = await SharedPreferences.getInstance();
      final imported = prefs.getStringList('imported_folders') ?? [];
      final updatedImported = imported.where((e) => !e.startsWith('${folder.id}:')).toList();
      if (imported.length != updatedImported.length) {
        await prefs.setStringList('imported_folders', updatedImported);
        final updatedState = state.folders.where((f) => f.id != folder.id).toList();
        state = state.copyWith(folders: updatedState);
      } else {
        state = state.copyWith(error: e.toString());
      }
    }
  }
}

// ─── Upload State ─────────────────────────────────────────────────────────────

class UploadTask {
  final String id;
  final String fileName;
  final String folderId;
  final double progress;
  final bool isComplete;
  final bool hasError;
  final String? error;

  const UploadTask({
    required this.id,
    required this.fileName,
    required this.folderId,
    this.progress = 0,
    this.isComplete = false,
    this.hasError = false,
    this.error,
  });

  UploadTask copyWith({
    double? progress,
    bool? isComplete,
    bool? hasError,
    String? error,
  }) {
    return UploadTask(
      id: id,
      fileName: fileName,
      folderId: folderId,
      progress: progress ?? this.progress,
      isComplete: isComplete ?? this.isComplete,
      hasError: hasError ?? this.hasError,
      error: error ?? this.error,
    );
  }
}

class UploadState {
  final List<UploadTask> tasks;
  const UploadState({this.tasks = const []});

  bool get hasActiveTasks => tasks.any((t) => !t.isComplete && !t.hasError);
}

class UploadNotifier extends StateNotifier<UploadState> {
  final DriveRepository _repository;
  final Ref _ref;

  UploadNotifier(this._repository, this._ref) : super(const UploadState());

  Future<void> _uploadFileInternal(String taskId, String localPath, String fileName, String folderId) async {
    if (!localPath.startsWith('content://')) {
      final file = File(localPath);
      if (await file.exists()) {
        final size = await file.length();
        if (size > AppConstants.maxUploadSizeBytes) {
          throw Exception(AppText.fileExceedsTelegramLimit);
        }
      }
    }

    await _repository.uploadFile(
      localPath: localPath,
      fileName: fileName,
      folderId: folderId,
      onProgress: (progress) {
        _updateTask(taskId, progress: progress);
      },
    );
  }

  Future<void> uploadFile({
    required String localPath,
    required String fileName,
    required String folderId,
  }) async {
    final taskId = 'task_${DateTime.now().millisecondsSinceEpoch}_${fileName.hashCode}';
    final task = UploadTask(id: taskId, fileName: fileName, folderId: folderId);
    state = UploadState(tasks: [...state.tasks, task]);

    try {
      await _uploadFileInternal(taskId, localPath, fileName, folderId);
      _updateTask(taskId, progress: 1.0, isComplete: true);

      // Reload file list for the folder the file was uploaded to
      await _ref.read(driveProvider.notifier).loadFiles(folderId: folderId);
    } catch (e) {
      _updateTask(taskId, hasError: true, error: e.toString());
    }
  }

  void _updateTask(String taskId,
      {double? progress, bool? isComplete, bool? hasError, String? error}) {
    final updated = state.tasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(
            progress: progress,
            isComplete: isComplete,
            hasError: hasError,
            error: error);
      }
      return t;
    }).toList();
    state = UploadState(tasks: updated);
  }

  void clearCompleted() {
    final active = state.tasks.where((t) => !t.isComplete).toList();
    state = UploadState(tasks: active);
  }
}
