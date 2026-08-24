import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/widgets/app_scale_button.dart';

/// نموذج خفيف وسريع لمعالجة جهات الاتصال بدون استهلاك الذاكرة أو تجميد الواجهة
class SimpleContact {
  final String id;
  final String displayName;
  final String primaryPhone;
  final List<String> allPhones;
  final String normalizedName;
  final String normalizedPhoneDigits;

  const SimpleContact({
    required this.id,
    required this.displayName,
    required this.primaryPhone,
    required this.allPhones,
    required this.normalizedName,
    required this.normalizedPhoneDigits,
  });
}

class ImportContactsSheet extends StatefulWidget {
  const ImportContactsSheet({super.key});

  static Future<Map<String, String>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, String>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ImportContactsSheet(),
    );
  }

  @override
  State<ImportContactsSheet> createState() => _ImportContactsSheetState();
}

class _ImportContactsSheetState extends State<ImportContactsSheet> {
  static const int _pageSize = 40; // حجم الدفعة الواحدة (Batch / Chunk Size)

  List<SimpleContact> _allContacts = [];
  List<SimpleContact> _filteredContacts = [];
  int _displayedCount = _pageSize;

  bool _isLoading = true;
  bool _permissionDenied = false;
  bool _hasError = false;

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetchContacts();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 250) {
      if (_displayedCount < _filteredContacts.length) {
        setState(() {
          _displayedCount = math.min(_displayedCount + _pageSize, _filteredContacts.length);
        });
      }
    }
  }

  Future<void> _fetchContacts() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
      _hasError = false;
    });

    try {
      final hasPermission = await FlutterContacts.requestPermission(readonly: true);
      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _permissionDenied = true;
            _isLoading = false;
          });
        }
        return;
      }

      // جلب خفيف وسريع للأسماء والأرقام فقط دون الصور المصغرة والحسابات لتفادي بطء التحميل
      final rawContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: false,
        withPhoto: false,
        withAccounts: false,
        sorted: true,
      );

      final List<SimpleContact> parsedList = [];
      for (final c in rawContacts) {
        if (c.phones.isEmpty) continue;
        final phones = c.phones
            .map((p) => p.number.trim())
            .where((p) => p.isNotEmpty)
            .toList();

        if (phones.isEmpty) continue;

        final name = c.displayName.trim().isNotEmpty ? c.displayName.trim() : phones.first;
        final allDigits = phones.map((p) => p.replaceAll(RegExp(r'[^0-9]'), '')).join(' ');

        parsedList.add(
          SimpleContact(
            id: c.id,
            displayName: name,
            primaryPhone: phones.first,
            allPhones: phones,
            normalizedName: name.toLowerCase(),
            normalizedPhoneDigits: allDigits,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _allContacts = parsedList;
          _filteredContacts = parsedList;
          _displayedCount = math.min(_pageSize, parsedList.length);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 160), () {
      _filterContacts(query);
    });
  }

  void _filterContacts(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      setState(() {
        _filteredContacts = _allContacts;
        _displayedCount = math.min(_pageSize, _allContacts.length);
      });
      return;
    }

    final digitsQuery = cleanQuery.replaceAll(RegExp(r'[^0-9]'), '');
    final filtered = _allContacts.where((c) {
      final nameMatches = c.normalizedName.contains(cleanQuery);
      final phoneMatches = digitsQuery.isNotEmpty && c.normalizedPhoneDigits.contains(digitsQuery);
      return nameMatches || phoneMatches;
    }).toList();

    setState(() {
      _filteredContacts = filtered;
      _displayedCount = math.min(_pageSize, filtered.length);
    });

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.jumpTo(0);
    }
  }

  void _selectContact(SimpleContact contact) {
    HapticFeedback.selectionClick();
    if (contact.allPhones.length > 1) {
      _showMultipleNumbersPicker(contact);
    } else {
      Navigator.of(context).pop({
        'name': contact.displayName,
        'phone': contact.primaryPhone,
      });
    }
  }

  void _showMultipleNumbersPicker(SimpleContact contact) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'اختر رقم الهاتف المطلوب لـ (${contact.displayName})',
              style: GoogleFonts.changa(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ...contact.allPhones.map(
              (phone) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  leading: const Icon(Icons.phone_android_rounded, color: AppColors.primary),
                  title: Text(phone, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 15)),
                  trailing: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).pop({
                      'name': contact.displayName,
                      'phone': phone,
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 10),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.contacts_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'استيراد من جهات الاتصال',
                          style: GoogleFonts.changa(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'تحميل فوري وسريع على دفعات',
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            color: isDark ? AppColors.darkMuted : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (!_isLoading && _filteredContacts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${ArabicNumbers.convert(_filteredContacts.length)} جهة اتصال',
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو برقم الهاتف...',
                hintStyle: GoogleFonts.tajawal(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchCtrl.clear();
                          _filterContacts('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Body
          Expanded(
            child: _buildBody(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.no_accounts_rounded, size: 64, color: AppColors.orange),
              const SizedBox(height: 16),
              Text(
                'الرجاء منح إذن الوصول لجهات الاتصال لتتمكن من استيراد الطلاب',
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              AppScaleButton(
                onTap: _fetchContacts,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'إعادة المحاولة والموافقة 🔄',
                    style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.red),
              const SizedBox(height: 14),
              Text(
                'عذراً، حدث خطأ أثناء قراءة جهات الاتصال',
                style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              AppScaleButton(
                onTap: _fetchContacts,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'إعادة المحاولة',
                    style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: 8,
        itemBuilder: (_, index) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 90,
                      height: 11,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 54, color: isDark ? AppColors.darkMuted : AppColors.muted),
            const SizedBox(height: 12),
            Text(
              'لا توجد نتائج مطابقة لـ "${_searchCtrl.text}"',
              style: GoogleFonts.tajawal(
                fontSize: 14,
                color: isDark ? AppColors.darkMuted : AppColors.muted,
              ),
            ),
          ],
        ),
      );
    }

    final visibleCount = math.min(_displayedCount, _filteredContacts.length);
    final hasMore = visibleCount < _filteredContacts.length;

    return ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      itemCount: visibleCount + (hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == visibleCount) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'جاري تحميل المزيد من جهات الاتصال (${ArabicNumbers.convert(visibleCount)} من ${ArabicNumbers.convert(_filteredContacts.length)})...',
                    style: GoogleFonts.tajawal(fontSize: 11.5, color: isDark ? AppColors.darkMuted : AppColors.muted),
                  ),
                ],
              ),
            ),
          );
        }

        final contact = _filteredContacts[index];
        final name = contact.displayName;
        final phone = contact.primaryPhone;
        final firstLetter = name.isNotEmpty ? name[0] : '؟';
        final hasMultiple = contact.allPhones.length > 1;

        return AppScaleButton(
          onTap: () => _selectContact(contact),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    firstLetter,
                    style: GoogleFonts.changa(
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.changa(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, size: 12, color: isDark ? AppColors.darkMuted : AppColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            textDirection: TextDirection.ltr,
                            style: GoogleFonts.tajawal(
                              fontSize: 12.5,
                              color: isDark ? AppColors.darkMuted : AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (hasMultiple) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${ArabicNumbers.convert(contact.allPhones.length)} أرقام',
                                style: GoogleFonts.tajawal(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
