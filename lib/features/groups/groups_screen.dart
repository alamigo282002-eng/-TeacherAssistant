import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/finance_pdf_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_scale_button.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/group_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/student_model.dart';
import '../attendance/attendance_screen.dart';
import '../exams/exams_screen.dart';
import 'add_edit_group_screen.dart';
import 'group_profile_screen.dart';
import 'groups_provider.dart';
import 'widgets/cancel_session_sheet.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with AutomaticKeepAliveClientMixin {
  String _selectedFilter = 'الكل';
  final _filters = ['الكل', 'سنتر', 'أونلاين', 'أخرى'];
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isFabVisible = true;
  bool _showTutorial = false;

  // Multi-selection state
  bool _isSelectionMode = false;
  final Set<String> _selectedGroupIds = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupsProvider>().loadGroups();
      _checkTutorial();
    });
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('groups_tutorial_shown') ?? false)) {
      setState(() => _showTutorial = true);
    }
  }

  Future<void> _dismissTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('groups_tutorial_shown', true);
    setState(() => _showTutorial = false);
  }

  void _handleScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isFabVisible) setState(() => _isFabVisible = false);
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isFabVisible) setState(() => _isFabVisible = true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String groupId) {
    setState(() {
      if (_selectedGroupIds.contains(groupId)) {
        _selectedGroupIds.remove(groupId);
        if (_selectedGroupIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedGroupIds.add(groupId);
      }
    });
  }

  void _selectAll(List<GroupModel> all) {
    setState(() {
      if (_selectedGroupIds.length == all.length) {
        _selectedGroupIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedGroupIds.clear();
        _selectedGroupIds.addAll(all.map((g) => g.id));
      }
    });
  }

  Future<void> _bulkPause(GroupsProvider provider) async {
    if (_selectedGroupIds.isEmpty) return;
    await provider.pauseBulkGroups(_selectedGroupIds.toList());
    setState(() {
      _selectedGroupIds.clear();
      _isSelectionMode = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إيقاف المجموعات المحددة ⏸️', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.orange,
        ),
      );
    }
  }

  Future<void> _bulkDelete(GroupsProvider provider) async {
    if (_selectedGroupIds.isEmpty) return;

    final count = _selectedGroupIds.length;
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'حذف المجموعات المحددة',
      message: 'هل أنت متأكد من حذف ($count) مجموعة؟ (المجموعات التي تحتوي على طلاب لن تُحذف حتى يتم نقلهم)',
      confirmLabel: 'حذف المحدد ($count)',
      danger: true,
    );

    if (confirmed == true && mounted) {
      final deleted = await provider.deleteBulkGroups(_selectedGroupIds.toList());
      setState(() {
        _selectedGroupIds.clear();
        _isSelectionMode = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleted == count
                  ? '🗑️ تم حذف ($deleted) مجموعة بنجاح'
                  : 'تم حذف ($deleted) مجموعة فارغة، وتخطي الباقي لاحتوائه على طلاب',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
            backgroundColor: deleted > 0 ? AppColors.green : AppColors.orange,
          ),
        );
      }
    }
  }

  List<GroupModel> _filterByQuery(List<GroupModel> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final query = _searchQuery.trim().toLowerCase();
    return list.where((g) {
      final nameMatches = g.name.toLowerCase().contains(query);
      final subjectMatches = (g.subject ?? '').toLowerCase().contains(query);
      final typeMatches = g.type.label.toLowerCase().contains(query);
      final daysMatches = g.days.any((d) => d.day.toLowerCase().contains(query));
      return nameMatches || subjectMatches || typeMatches || daysMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<GroupsProvider>();
    final allGroups = provider.getByType(_selectedFilter);
    final allPausedGroups = provider.getPausedByType(_selectedFilter);

    final groups = _filterByQuery(allGroups);
    final pausedGroups = _filterByQuery(allPausedGroups);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final combinedGroups = [...groups, ...pausedGroups];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedGroupIds.clear();
                  });
                },
                tooltip: 'إلغاء التحديد',
              ),
              title: Text(
                'تم تحديد ${ArabicNumbers.convert(_selectedGroupIds.length)} مجموعة',
                style: GoogleFonts.changa(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _selectedGroupIds.length == combinedGroups.length
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    color: Colors.white,
                  ),
                  tooltip: _selectedGroupIds.length == combinedGroups.length ? 'إلغاء تحديد الكل' : 'تحديد الكل',
                  onPressed: () => _selectAll(combinedGroups),
                ),
                IconButton(
                  icon: const Icon(Icons.pause_circle_outline_rounded, color: Color(0xFFF59E0B)),
                  tooltip: 'إيقاف المجموعات المحددة',
                  onPressed: () => _bulkPause(provider),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444)),
                  tooltip: 'حذف المجموعات المحددة',
                  onPressed: () => _bulkDelete(provider),
                ),
              ],
            )
          : AppBar(
              title: Text(
                'إدارة المجموعات',
                style: GoogleFonts.changa(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              actions: [
                // Selection Mode Button
                if (combinedGroups.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.checklist_rounded),
                    tooltip: 'تحديد متعدد وحذف',
                    onPressed: () {
                      setState(() => _isSelectionMode = true);
                    },
                  ),
                // Sort button
                PopupMenuButton<GroupSortType>(
                  icon: const Icon(Icons.sort_rounded),
                  tooltip: 'ترتيب المجموعات',
                  onSelected: (val) => provider.setSortType(val),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: GroupSortType.byDate,
                      child: Row(children: [
                        Icon(Icons.access_time, size: 18,
                            color: provider.sortType == GroupSortType.byDate
                                ? AppColors.primary : AppColors.muted),
                        const SizedBox(width: 8),
                        Text('حسب التاريخ', style: GoogleFonts.tajawal(
                          fontWeight: provider.sortType == GroupSortType.byDate
                              ? FontWeight.bold : FontWeight.normal,
                        )),
                      ]),
                    ),
                    PopupMenuItem(
                      value: GroupSortType.byName,
                      child: Row(children: [
                        Icon(Icons.sort_by_alpha, size: 18,
                            color: provider.sortType == GroupSortType.byName
                                ? AppColors.primary : AppColors.muted),
                        const SizedBox(width: 8),
                        Text('حسب الاسم', style: GoogleFonts.tajawal(
                          fontWeight: provider.sortType == GroupSortType.byName
                              ? FontWeight.bold : FontWeight.normal,
                        )),
                      ]),
                    ),
                    PopupMenuItem(
                      value: GroupSortType.byStudentCount,
                      child: Row(children: [
                        Icon(Icons.people, size: 18,
                            color: provider.sortType == GroupSortType.byStudentCount
                                ? AppColors.primary : AppColors.muted),
                        const SizedBox(width: 8),
                        Text('حسب عدد الطلاب', style: GoogleFonts.tajawal(
                          fontWeight: provider.sortType == GroupSortType.byStudentCount
                              ? FontWeight.bold : FontWeight.normal,
                        )),
                      ]),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: () => _openAddGroup(context),
                  tooltip: 'إضافة مجموعة جديدة',
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: _buildFilterChips(isDark),
              ),
            ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Dedicated, Smooth Full-Width Search Bar
                _buildSearchBar(isDark),

                // Groups List
                Expanded(
                  child: (groups.isEmpty && pausedGroups.isEmpty)
                      ? (_searchQuery.isNotEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off_rounded, size: 54, color: isDark ? AppColors.darkMuted : AppColors.muted),
                                    const SizedBox(height: 12),
                                    Text(
                                      'لا توجد نتائج بحث مطابقة لـ "$_searchQuery"',
                                      style: GoogleFonts.changa(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppColors.darkText : AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'تأكد من كتابة اسم المجموعة أو المادة بشكل صحيح',
                                      style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : EmptyState(
                              message: 'لا توجد مجموعات بعد',
                              subtitle: 'أضف مجموعتك الأولى لبدء إضافة الطلاب والحصص',
                              icon: Icons.groups_outlined,
                              action: AppButton(
                                label: 'إضافة مجموعة',
                                icon: Icons.add,
                                onPressed: () => _openAddGroup(context),
                              ),
                            ))
                      : RefreshIndicator(
                          onRefresh: () => provider.loadGroups(),
                          color: AppColors.primary,
                          child: ListView(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                            children: [
                              // Interactive tutorial
                              if (_showTutorial && !_isSelectionMode) _buildTutorialBanner(isDark),

                              // Active groups
                              ...groups.indexed.map((entry) =>
                                  _buildDismissibleGroupCard(context, entry.$2, provider, isDark)
                                      .animate()
                                      .fadeIn(duration: 250.ms, delay: Duration(milliseconds: 25 * (entry.$1 % 8)))
                                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic)),

                              // Paused groups section
                              if (pausedGroups.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurface.withValues(alpha: 0.5)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.pause_circle_outline,
                                          size: 18, color: AppColors.orange),
                                      const SizedBox(width: 8),
                                      Text(
                                        'المجموعات المتوقفة (${ArabicNumbers.convert(pausedGroups.length)})',
                                        style: GoogleFonts.changa(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...pausedGroups.indexed.map((entry) =>
                                    _buildDismissibleGroupCard(context, entry.$2, provider, isDark,
                                        isPaused: true)
                                        .animate()
                                        .fadeIn(duration: 250.ms, delay: Duration(milliseconds: 25 * (entry.$1 % 8)))
                                        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic)),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
      // Elevated FAB to sit properly above MainShell bottom navigation bar (only visible when at least 1 group exists)
      floatingActionButton: (_isSelectionMode || provider.groups.isEmpty)
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 96),
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 250),
                offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _isFabVisible ? 1.0 : 0.0,
                  child: FloatingActionButton.extended(
                    onPressed: () => _openAddGroup(context),
                    backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                    icon: Icon(Icons.add_rounded, color: isDark ? AppColors.darkBg : Colors.white),
                    label: Text(
                      'مجموعة جديدة',
                      style: GoogleFonts.changa(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkBg : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ── Search Bar ──
  Widget _buildSearchBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.tajawal(
          fontSize: 13.5,
          color: isDark ? Colors.white : AppColors.ink,
        ),
        onChanged: (val) {
          setState(() => _searchQuery = val);
        },
        decoration: InputDecoration(
          hintText: 'ابحث عن مجموعة، مادة، يوم، أو سنتر...',
          hintStyle: GoogleFonts.tajawal(
            fontSize: 12.5,
            color: isDark ? AppColors.darkMuted : AppColors.muted,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppColors.darkPrimary : AppColors.primary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
      ),
    );
  }

  // ── Tutorial Banner ──
  Widget _buildTutorialBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.1),
            AppColors.lime.withValues(alpha: isDark ? 0.15 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('👈', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'انقر لفتح بروفايل المجموعة',
                  style: GoogleFonts.changa(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: isDark ? AppColors.darkText : AppColors.ink,
                  ),
                ),
                Text(
                  'انقر لفتح البروفايل، أو انقر مطولاً للتحديد المتعدد، أو اسحب لليمين للإيقاف ولليسار للحذف',
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: AppColors.muted),
            onPressed: _dismissTutorial,
          ),
        ],
      ),
    );
  }

  // ── Dismissible Group Card (Swipe Left=Delete, Right=Pause/Resume) ──
  Widget _buildDismissibleGroupCard(BuildContext ctx, GroupModel group,
      GroupsProvider provider, bool isDark, {bool isPaused = false}) {
    if (_isSelectionMode) {
      return _buildModernCompactGroupCard(ctx, group, provider, isDark, isPaused: isPaused);
    }

    return Dismissible(
      key: Key('group_${group.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _confirmDeleteWithOptions(ctx, group, provider);
        } else {
          if (isPaused) {
            await provider.restoreGroup(group.id);
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text('تم تنشيط المجموعة ✅', style: GoogleFonts.tajawal()),
                  backgroundColor: AppColors.green,
                ),
              );
            }
          } else {
            await provider.pauseGroup(group.id);
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text('تم إيقاف المجموعة ⏸️', style: GoogleFonts.tajawal()),
                  backgroundColor: AppColors.orange,
                ),
              );
            }
          }
          return false;
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isPaused ? AppColors.green : AppColors.orange,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              isPaused ? 'تنشيط ▶️' : 'إيقاف ⏸️',
              style: GoogleFonts.changa(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(width: 6),
            Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              'حذف 🗑️',
              style: GoogleFonts.changa(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
      child: _buildModernCompactGroupCard(ctx, group, provider, isDark, isPaused: isPaused),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _filters.map((f) {
          final selected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: AppScaleButton(
              onTap: () => setState(() => _selectedFilter = f),
              child: AnimatedContainer(
                duration: AppConstants.animFast,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  f,
                  style: GoogleFonts.changa(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? AppColors.primary : Colors.white,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Modern Compact Group Card (Tapping opens Group Profile / Toggles Selection) ──
  Widget _buildModernCompactGroupCard(
    BuildContext ctx,
    GroupModel group,
    GroupsProvider provider,
    bool isDark, {
    bool isPaused = false,
  }) {
    final studentsCount = provider.getStudentCount(group.id);
    final daysSummary = group.days.map((d) => d.day).take(3).join(' · ');
    final isSelected = _selectedGroupIds.contains(group.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
              : (isPaused
                  ? AppColors.orange.withValues(alpha: 0.4)
                  : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0))),
          width: isSelected ? 1.8 : (isPaused ? 1.2 : 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
                _selectedGroupIds.add(group.id);
              });
            }
          },
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(group.id);
            } else {
              // Direct click opens Group Profile
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => GroupProfileScreen(group: group),
                ),
              ).then((_) {
                if (mounted) provider.loadGroups();
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Line: Group Name & Subject + Status Badge + Options Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Selection indicator or Type Icon
                    if (_isSelectionMode)
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        child: Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                          color: isSelected
                              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                              : Colors.grey,
                          size: 24,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: (isPaused ? AppColors.orange : (isDark ? AppColors.darkPrimary : AppColors.primary))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          group.type == GroupType.online
                              ? Icons.videocam_rounded
                              : (group.type == GroupType.center ? Icons.domain_rounded : Icons.groups_rounded),
                          size: 18,
                          color: isPaused ? AppColors.orange : (isDark ? AppColors.darkPrimary : AppColors.primary),
                        ),
                      ),
                    if (!_isSelectionMode) const SizedBox(width: 10),

                    // Name + Subject
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  group.name,
                                  style: GoogleFonts.changa(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: isPaused
                                        ? AppColors.muted
                                        : (isDark ? AppColors.darkText : AppColors.ink),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (group.type == GroupType.online) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkGreenSoft : AppColors.chipTeal,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'أونلاين',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.darkPrimary : AppColors.chipTealText,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (group.subject != null && group.subject!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '📖 ${group.subject!}',
                                style: GoogleFonts.tajawal(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    if (isPaused)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                          color: AppColors.orangeSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'متوقفة',
                          style: GoogleFonts.tajawal(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                          ),
                        ),
                      ),

                    if (!_isSelectionMode) ...[
                      // Direct WhatsApp Button
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 20),
                        tooltip: group.hasWhatsAppLink ? 'فتح جروب واتساب' : 'تواصل واتساب',
                        visualDensity: VisualDensity.compact,
                        onPressed: () async {
                          if (group.hasWhatsAppLink) {
                            final uri = Uri.parse(group.whatsappLink!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          } else {
                            _openEditGroup(ctx, group);
                          }
                        },
                      ),
                      _buildGroupPopupMenu(ctx, group, provider, isDark, isPaused),
                    ],
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 0.6),
                const SizedBox(height: 8),

                // Bottom Line: Compact Info Pills (Students count, Price, Schedule)
                Row(
                  children: [
                    // Students Count Pill
                    _buildMiniChip(
                      icon: Icons.people_outline_rounded,
                      label: ArabicNumbers.formatStudentsCount(studentsCount),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),

                    // Price Pill
                    _buildMiniChip(
                      icon: Icons.payments_outlined,
                      label: '${ArabicNumbers.formatCurrency(group.monthlyPrice)} / شهر',
                      isDark: isDark,
                    ),

                    if (daysSummary.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildMiniChip(
                          icon: Icons.access_time_rounded,
                          label: daysSummary,
                          isDark: isDark,
                          isFlexible: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip({
    required IconData icon,
    required String label,
    required bool isDark,
    bool isFlexible = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: isFlexible ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isDark ? AppColors.darkMuted : AppColors.muted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkMuted : const Color(0xFF475569),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupPopupMenu(
    BuildContext ctx,
    GroupModel group,
    GroupsProvider provider,
    bool isDark,
    bool isPaused,
  ) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: isDark ? AppColors.darkMuted : AppColors.muted,
      ),
      tooltip: 'خيارات المجموعة',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (action) async {
        switch (action) {
          case 'profile':
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => GroupProfileScreen(group: group),
              ),
            ).then((_) {
              if (mounted) provider.loadGroups();
            });
            break;
          case 'attendance':
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => AttendanceScreen(
                  groupId: group.id,
                  groupName: group.name,
                ),
              ),
            ).then((_) {
              if (mounted) provider.loadGroups();
            });
            break;
          case 'edit':
            _openEditGroup(ctx, group);
            break;
          case 'exams':
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => ExamsScreen(
                  groupId: group.id,
                  groupName: group.name,
                ),
              ),
            );
            break;
          case 'cancel_session':
            CancelSessionSheet.show(ctx, group: group);
            break;
          case 'pdf':
            _exportGroupToPdf(group);
            break;
          case 'whatsapp':
            if (group.hasWhatsAppLink) {
              final uri = Uri.parse(group.whatsappLink!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            } else {
              _openEditGroup(ctx, group);
            }
            break;
          case 'share_whatsapp':
            if (group.hasWhatsAppLink) {
              SharePlus.instance.share(
                ShareParams(
                  text: '📌 رابط الانضمام لجروب ${group.name} على واتساب:\n${group.whatsappLink}',
                  subject: 'جروب واتساب ${group.name}',
                ),
              );
            }
            break;
          case 'toggle_pause':
            if (isPaused) {
              await provider.restoreGroup(group.id);
            } else {
              await provider.pauseGroup(group.id);
            }
            break;
          case 'delete':
            await _confirmDeleteWithOptions(ctx, group, provider);
            break;
        }
      },
      itemBuilder: (_) => [
        _menuItem('profile', 'بروفايل المجموعة', Icons.account_box_outlined, AppColors.primary),
        _menuItem('attendance', 'رصد التحضير', Icons.how_to_reg_rounded, AppColors.green),
        _menuItem('edit', 'تعديل المجموعة', Icons.edit_outlined, AppColors.primary),
        _menuItem('exams', 'الاختبارات والدرجات', Icons.quiz_outlined, AppColors.info),
        if (!isPaused)
          _menuItem('cancel_session', 'إلغاء حصة وإشعار', Icons.event_busy_rounded, AppColors.orange),
        _menuItem('pdf', 'تصدير تقرير PDF', Icons.picture_as_pdf_outlined, const Color(0xFF1E7E34)),
        _menuItem(
          'whatsapp',
          group.hasWhatsAppLink ? 'فتح جروب الواتساب' : 'إضافة رابط واتساب',
          Icons.chat_bubble_outline_rounded,
          const Color(0xFF25D366),
        ),
        if (group.hasWhatsAppLink)
          _menuItem('share_whatsapp', 'مشاركة رابط الجروب', Icons.share_outlined, AppColors.primary),
        const PopupMenuDivider(),
        _menuItem(
          'toggle_pause',
          isPaused ? 'تنشيط المجموعة ▶️' : 'إيقاف مؤقت ⏸️',
          isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          AppColors.orange,
        ),
        _menuItem('delete', 'حذف المجموعة', Icons.delete_outline_rounded, AppColors.error),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color == AppColors.error ? AppColors.error : null,
            ),
          ),
        ],
      ),
    );
  }

  void _openAddGroup(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => const AddEditGroupScreen()),
    ).then((_) {
      if (mounted) context.read<GroupsProvider>().loadGroups();
    });
  }

  void _openEditGroup(BuildContext ctx, GroupModel group) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => AddEditGroupScreen(group: group)),
    ).then((_) {
      if (mounted) context.read<GroupsProvider>().loadGroups();
    });
  }

  Future<void> _exportGroupToPdf(GroupModel group) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('جاري التصدير إلى PDF...', style: GoogleFonts.tajawal())),
      );

      final db = DatabaseHelper();
      final studentsData = await db.query(AppConstants.tableStudents, where: 'group_id = ?', whereArgs: [group.id]);
      final students = studentsData.map((s) => StudentModel.fromMap(s)).toList();

      final attendanceData = await db.query(AppConstants.tableAttendance, where: 'group_id = ?', whereArgs: [group.id]);
      final attendance = attendanceData.map((a) => AttendanceModel.fromMap(a)).toList();

      final examsData = await db.query(AppConstants.tableExams, where: 'group_id = ?', whereArgs: [group.id]);
      final exams = examsData.map((e) => ExamModel.fromMap(e)).toList();

      final List<ExamResultModel> examResults = [];
      for (final exam in exams) {
        final resultsData = await db.query(AppConstants.tableExamResults, where: 'exam_id = ?', whereArgs: [exam.id]);
        examResults.addAll(resultsData.map((r) => ExamResultModel.fromMap(r)));
      }

      final paymentsData = await db.query(AppConstants.tablePayments, where: 'group_id = ?', whereArgs: [group.id]);
      final payments = paymentsData.map((p) => PaymentModel.fromMap(p)).toList();

      await FinancePdfService().exportGroupToPdf(
        group: group,
        students: students,
        attendanceRecords: attendance,
        exams: exams,
        examResults: examResults,
        payments: payments,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التصدير: $e', style: GoogleFonts.tajawal()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<bool> _confirmDeleteWithOptions(
      BuildContext ctx, GroupModel group, GroupsProvider provider) async {
    final studentsCount = provider.getStudentCount(group.id);

    if (studentsCount > 0) {
      final result = await showDialog<String>(
        context: ctx,
        builder: (dCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'حذف مجموعة "${group.name}"',
            style: GoogleFonts.changa(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'هذه المجموعة بها ${ArabicNumbers.convert(studentsCount)} طالب',
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.darkBg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'يرجى نقل الطلاب أولاً أو إيقاف المجموعة مؤقتاً',
                style: GoogleFonts.tajawal(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, 'cancel'),
              child: Text('إلغاء', style: GoogleFonts.tajawal()),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dCtx, 'pause'),
              icon: const Icon(Icons.pause, size: 16),
              label: Text('إيقاف المجموعة', style: GoogleFonts.tajawal()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );

      if (result == 'pause') {
        await provider.pauseGroup(group.id);
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('تم إيقاف المجموعة ⏸️', style: GoogleFonts.tajawal()),
              backgroundColor: AppColors.orange,
            ),
          );
        }
      }
      return false;
    }

    final confirmed = await ConfirmationDialog.show(
      ctx,
      title: 'حذف المجموعة',
      message:
          'هل أنت متأكد من حذف مجموعة "${group.name}"؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف نهائي',
      danger: true,
    );
    if (confirmed == true) {
      await provider.deleteGroup(group.id);
      return false;
    }
    return false;
  }
}

