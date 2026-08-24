import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';

class SpecialtiesBottomSheet extends StatefulWidget {
  final List<String> initialSelected;

  const SpecialtiesBottomSheet({
    super.key,
    required this.initialSelected,
  });

  static Future<List<String>?> show(
    BuildContext context, {
    required List<String> initialSelected,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SpecialtiesBottomSheet(initialSelected: initialSelected),
      ),
    );
  }

  @override
  State<SpecialtiesBottomSheet> createState() => _SpecialtiesBottomSheetState();
}

class _SpecialtiesBottomSheetState extends State<SpecialtiesBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _otherCustomController = TextEditingController();
  final FocusNode _otherFocusNode = FocusNode();

  late Set<String> _selectedSpecialties;
  final List<String> _customSpecialties = [];
  bool _otherExpanded = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedSpecialties = Set<String>.from(widget.initialSelected);

    // Identify standard specialties
    final standardItems = AppConstants.defaultSpecialties
        .where((e) => e != 'تخصص آخر')
        .toSet();

    // Populate existing custom specialties
    for (final item in widget.initialSelected) {
      if (!standardItems.contains(item) && item != 'تخصص آخر') {
        if (!_customSpecialties.contains(item)) {
          _customSpecialties.add(item);
        }
      }
    }

    if (_customSpecialties.isNotEmpty || widget.initialSelected.contains('تخصص آخر')) {
      _otherExpanded = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _otherCustomController.dispose();
    _otherFocusNode.dispose();
    super.dispose();
  }

  List<String> get _allAvailableList {
    final list = <String>[];
    for (final s in AppConstants.defaultSpecialties) {
      if (s != 'تخصص آخر') {
        list.add(s);
      }
    }
    // Add custom specialties
    for (final cs in _customSpecialties) {
      if (!list.contains(cs)) {
        list.add(cs);
      }
    }
    list.add('تخصص آخر');
    return list;
  }

  List<String> get _filteredList {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _allAvailableList;
    }
    return _allAvailableList
        .where((s) => s.toLowerCase().contains(query))
        .toList();
  }

  void _toggleSpecialty(String specialty) {
    setState(() {
      if (specialty == 'تخصص آخر') {
        _otherExpanded = !_otherExpanded;
        if (_otherExpanded) {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) _otherFocusNode.requestFocus();
          });
        }
      } else {
        if (_selectedSpecialties.contains(specialty)) {
          _selectedSpecialties.remove(specialty);
        } else {
          _selectedSpecialties.add(specialty);
        }
      }
    });
  }

  void _addCustomSpecialty() {
    final text = _otherCustomController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      if (!_customSpecialties.contains(text)) {
        _customSpecialties.add(text);
      }
      _selectedSpecialties.add(text);
      _otherCustomController.clear();
      _otherFocusNode.requestFocus();
    });
  }

  void _removeCustomSpecialty(String specialty) {
    setState(() {
      _customSpecialties.remove(specialty);
      _selectedSpecialties.remove(specialty);
    });
  }

  void _onConfirm() {
    // If user typed something in the other field and didn't press add, auto add it
    final pendingText = _otherCustomController.text.trim();
    if (pendingText.isNotEmpty) {
      if (!_customSpecialties.contains(pendingText)) {
        _customSpecialties.add(pendingText);
      }
      _selectedSpecialties.add(pendingText);
    }

    final List<String> result = [];
    for (final item in _selectedSpecialties) {
      if (item != 'تخصص آخر') {
        result.add(item);
      }
    }

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int selectedCount = _selectedSpecialties.where((s) => s != 'تخصص آخر').length;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16232F) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 25,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F7F4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Color(0xFF0D8A7A),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'التخصصات الأكاديمية',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1A2332),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Counter badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: selectedCount > 0
                            ? const Color(0xFFE0F7F4)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'تم اختيار $selectedCount تخصص',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selectedCount > 0
                              ? const Color(0xFF0D8A7A)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Real-time Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن مادة أو تخصص...',
                    hintStyle: GoogleFonts.cairo(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF8CA0BB) : const Color(0xFF999999),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF0D6B6B),
                      size: 22,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1A2E46)
                        : const Color(0xFFF4F7F9),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1),

              // Specialties List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _filteredList.length,
                  itemBuilder: (context, index) {
                    final specialty = _filteredList[index];
                    final isOtherTrigger = specialty == 'تخصص آخر';
                    final isCustom = _customSpecialties.contains(specialty);
                    final isSelected = !isOtherTrigger && _selectedSpecialties.contains(specialty);

                    return Column(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _toggleSpecialty(specialty),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFE0F7F4).withValues(alpha: isDark ? 0.2 : 0.8)
                                    : (isOtherTrigger && _otherExpanded
                                        ? const Color(0xFFE0F7F4).withValues(alpha: 0.4)
                                        : (isDark ? const Color(0xFF16232F) : Colors.white)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF0D8A7A)
                                      : (isOtherTrigger && _otherExpanded
                                          ? const Color(0xFF0D8A7A).withValues(alpha: 0.5)
                                          : (isDark ? const Color(0xFF2A3F5A) : const Color(0xFFECEFF1))),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (isOtherTrigger)
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D6B6B).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.add_circle_outline_rounded,
                                        size: 18,
                                        color: Color(0xFF0D6B6B),
                                      ),
                                    )
                                  else
                                    // Custom Checkbox
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF0D6B6B)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF0D6B6B)
                                              : Colors.grey.withValues(alpha: 0.6),
                                          width: 1.8,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  const SizedBox(width: 14),

                                  // Title
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          specialty,
                                          style: GoogleFonts.cairo(
                                            fontSize: 15,
                                            fontWeight: isSelected || (isOtherTrigger && _otherExpanded)
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? const Color(0xFF0D8A7A)
                                                : (isDark ? Colors.white : const Color(0xFF333333)),
                                          ),
                                        ),
                                        if (isCustom) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0D8A7A).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'مخصص',
                                              style: GoogleFonts.cairo(
                                                fontSize: 10,
                                                color: const Color(0xFF0D8A7A),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  if (isCustom)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                      onPressed: () => _removeCustomSpecialty(specialty),
                                      tooltip: 'حذف التخصص',
                                    )
                                  else if (isOtherTrigger)
                                    Icon(
                                      _otherExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                      color: const Color(0xFF0D6B6B),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // If "تخصص آخر" is expanded, render multi custom specialty adding section
                        if (isOtherTrigger && _otherExpanded)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(top: 6, bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E324B)
                                  : const Color(0xFFF0FDFB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF0D8A7A).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'أضف تخصصك الخاص (يمكنك إضافة أكثر من تخصص):',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0D6B6B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _otherCustomController,
                                        focusNode: _otherFocusNode,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) => _addCustomSpecialty(),
                                        decoration: InputDecoration(
                                          hintText: 'مثال: علم النفس، جيولوجيا...',
                                          hintStyle: GoogleFonts.cairo(
                                            fontSize: 13,
                                            color: const Color(0xFF999999),
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.edit_note_rounded,
                                            color: Color(0xFF0D8A7A),
                                          ),
                                          filled: true,
                                          fillColor: isDark ? const Color(0xFF122036) : Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(
                                              color: const Color(0xFF0D8A7A).withValues(alpha: 0.3),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(
                                              color: const Color(0xFF0D8A7A).withValues(alpha: 0.3),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF0D8A7A),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: _addCustomSpecialty,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0D8A7A),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.add, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            'إضافة',
                                            style: GoogleFonts.cairo(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Chips for added custom specialties
                                if (_customSpecialties.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: _customSpecialties.map((cs) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F7F4),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: const Color(0xFF0D8A7A).withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              cs,
                                              style: GoogleFonts.cairo(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF0D8A7A),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            InkWell(
                                              onTap: () => _removeCustomSpecialty(cs),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                size: 14,
                                                color: Color(0xFF0D8A7A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              // Bottom Actions Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16232F) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6B6B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'تأكيد الاختيار',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
