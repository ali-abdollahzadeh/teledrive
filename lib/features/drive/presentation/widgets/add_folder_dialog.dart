import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text.dart';
import '../../../../services/platform/native_telegram_channel.dart';
import '../providers/drive_provider.dart';

class AddFolderDialog extends ConsumerStatefulWidget {
  const AddFolderDialog({super.key});

  @override
  ConsumerState<AddFolderDialog> createState() => _AddFolderDialogState();
}

class _AddFolderDialogState extends ConsumerState<AddFolderDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _createCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _manualIdCtrl = TextEditingController();
  final _manualTitleCtrl = TextEditingController();

  late Future<List<Map<String, dynamic>>> _chatsFuture;
  String _searchQuery = '';
  bool _isCreating = false;
  bool _showManualLink = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chatsFuture = NativeTelegramChannel.getMyChats(limit: 150);
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _createCtrl.dispose();
    _searchCtrl.dispose();
    _manualIdCtrl.dispose();
    _manualTitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _createCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isCreating = true;
    });

    try {
      await ref.read(driveProvider.notifier).createFolder(name);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Folder "$name" created successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create folder: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleManualLink() async {
    final id = _manualIdCtrl.text.trim();
    final title = _manualTitleCtrl.text.trim();

    if (id.isEmpty || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out both Chat ID and Title'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      await ref.read(driveProvider.notifier).importTelegramChannel(id, title);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Channel "$title" linked successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to link channel: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleLinkChannel(String chatId, String title) async {
    setState(() {
      _isCreating = true;
    });

    try {
      await ref
          .read(driveProvider.notifier)
          .importTelegramChannel(chatId, title);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Linked channel "$title" successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to link channel: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final driveState = ref.watch(driveProvider);
    final existingIds = driveState.folders.map((f) => f.id).toSet();

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xxlBR),
      backgroundColor: isDark ? AppColors.surfaceVariantDark : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Custom Header / Tabs ---
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: Row(
                children: [
                  Text(
                    AppText.createFolder,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor:
                  isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  icon: Icon(Icons.create_new_folder_rounded, size: 20),
                  text: 'Create New',
                ),
                Tab(
                  icon: Icon(Icons.link_rounded, size: 20),
                  text: 'Link Channel',
                ),
              ],
            ),
            const Divider(height: 1, thickness: 0.5),

            // --- Tab Views ---
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // --- TAB 1: CREATE NEW ---
                  _buildCreateTab(isDark),

                  // --- TAB 2: LINK TELEGRAM CHANNEL ---
                  _buildLinkTab(isDark, existingIds),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTab(bool isDark) {
    return Padding(
      padding: AppSpacing.allMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: AppSpacing.allSM,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.05),
              borderRadius: AppRadius.mdBR,
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 20),
                AppSpacing.hGapSM,
                Expanded(
                  child: Text(
                    AppText.createFolderTelegramNote,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapLG,
          const Text(
            'Folder Name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.gapXS,
          TextField(
            controller: _createCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: AppText.folderNameHint,
              prefixIcon: Icon(Icons.folder_rounded),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (_) => _isCreating ? null : _handleCreate(),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(AppText.cancel),
              ),
              AppSpacing.hGapSM,
              ElevatedButton(
                onPressed: _isCreating ? null : _handleCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(110, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(AppText.create),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTab(bool isDark, Set<String> existingIds) {
    if (_showManualLink) {
      return _buildManualLinkView(isDark);
    }

    return Column(
      children: [
        // --- Search bar ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search chats & channels...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => _searchCtrl.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),

        // --- List of Chats ---
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _chatsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: AppSpacing.allMD,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 40),
                        AppSpacing.gapSM,
                        Text(
                          'Failed to load chats:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                        ),
                        AppSpacing.gapMD,
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _chatsFuture =
                                  NativeTelegramChannel.getMyChats(limit: 150);
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final chats = snapshot.data ?? [];
              final filteredChats = chats.where((chat) {
                final type = chat['type'] as String? ?? '';
                final isEligible = type == 'channel' || type == 'supergroup';
                if (!isEligible) return false;

                final idStr = chat['id'].toString();
                if (existingIds.contains(idStr)) return false;

                final title = (chat['title'] as String? ?? '').toLowerCase();
                return title.contains(_searchQuery);
              }).toList();

              if (filteredChats.isEmpty) {
                return Center(
                  child: Padding(
                    padding: AppSpacing.allMD,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.speaker_notes_off_rounded,
                          size: 44,
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                        AppSpacing.gapSM,
                        const Text(
                          'No linkable channels found',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppSpacing.gapXS,
                        Text(
                          _searchCtrl.text.isNotEmpty
                              ? 'Try refining your search query'
                              : 'Channels must allow posting messages',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: filteredChats.length,
                separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.3),
                itemBuilder: (context, index) {
                  final chat = filteredChats[index];
                  final id = chat['id'].toString();
                  final title = chat['title'] as String? ?? 'Untitled';
                  final type = chat['type'] as String? ?? 'channel';

                  final initial = title.isNotEmpty ? title[0].toUpperCase() : 'C';

                  // Dynamic color based on title hash for premium look
                  final colorIndex = title.hashCode.abs() % 6;
                  final avatarColors = [
                    AppColors.avatarBlueGradient,
                    AppColors.avatarGreenGradient,
                    AppColors.avatarRedGradient,
                    const LinearGradient(colors: [AppColors.avatarViolet, AppColors.avatarViolet2]),
                    const LinearGradient(colors: [AppColors.avatarOrange, AppColors.avatarOrange2]),
                    const LinearGradient(colors: [AppColors.avatarCyan, AppColors.avatarCyan2]),
                  ];
                  final gradient = avatarColors[colorIndex];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      type == 'supergroup' ? 'Supergroup' : 'Channel',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    trailing: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: _isCreating ? null : () => _handleLinkChannel(id, title),
                      child: const Text(
                        'Link',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        const Divider(height: 1, thickness: 0.5),
        // --- Custom Manual Link trigger bar ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          width: double.infinity,
          color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
          child: TextButton.icon(
            icon: const Icon(Icons.add_link_rounded, size: 18),
            label: const Text('Link Channel Manually by ID'),
            onPressed: () {
              setState(() {
                _showManualLink = true;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildManualLinkView(bool isDark) {
    return Padding(
      padding: AppSpacing.allMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                onPressed: () {
                  setState(() {
                    _showManualLink = false;
                  });
                },
              ),
              const Text(
                'Link Channel Manually',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          AppSpacing.gapSM,
          const Text(
            'Telegram Channel / Chat ID',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.gapXXS,
          TextField(
            controller: _manualIdCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g., -1001948573627',
              prefixIcon: Icon(Icons.tag_rounded, size: 18),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            keyboardType: TextInputType.number,
          ),
          AppSpacing.gapMD,
          const Text(
            'Display Title',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.gapXXS,
          TextField(
            controller: _manualTitleCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g., My Telegram Backups',
              prefixIcon: Icon(Icons.folder_rounded, size: 18),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showManualLink = false;
                  });
                },
                child: const Text('Back'),
              ),
              AppSpacing.hGapSM,
              ElevatedButton(
                onPressed: _isCreating ? null : _handleManualLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(110, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Link'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
