import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/models/project_notebook_model.dart';
import 'package:mbaymi/services/notebook_service.dart';
import 'package:mbaymi/screens/notebook/notebook_editor_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SECTION TITLE — cohérent avec le reste de l'app
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 20, height: 1, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.8,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            height: 1,
            color: AppColors.primary.withOpacity(0.12),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY PILL
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.darkCardBg : const Color(0xFFFAF8F4)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w300,
            color: selected
                ? Colors.white
                : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY META
// ─────────────────────────────────────────────────────────────────────────────
class _CatTag extends StatelessWidget {
  final String category;
  final bool isDark;
  const _CatTag(this.category, {required this.isDark});

  static const _map = {
    'culture':     {'icon': Icons.grass_outlined,          'label': 'CULTURE'},
    'elevage':     {'icon': Icons.pets_outlined,           'label': 'ÉLEVAGE'},
    'finance':     {'icon': Icons.receipt_long_outlined,   'label': 'FINANCE'},
    'maintenance': {'icon': Icons.build_outlined,          'label': 'MAINTENANCE'},
    'general':     {'icon': Icons.folder_outlined,         'label': 'GÉNÉRAL'},
  };

  @override
  Widget build(BuildContext context) {
    final data = _map[category] ?? _map['general']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.09),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            data['icon'] as IconData,
            size: 9,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            data['label'] as String,
            style: const TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.3,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ProjectNotebookListScreen extends StatefulWidget {
  final String farmId;
  final String userId;

  const ProjectNotebookListScreen({
    required this.farmId,
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  State<ProjectNotebookListScreen> createState() =>
      _ProjectNotebookListScreenState();
}

class _ProjectNotebookListScreenState
    extends State<ProjectNotebookListScreen> with SingleTickerProviderStateMixin {
  late NotebookService _notebookService;
  List<ProjectNotebook> _notebooks = [];
  List<ProjectNotebook> _filteredNotebooks = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = true;

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _categories = [
    'all', 'culture', 'elevage', 'general', 'finance', 'maintenance',
  ];

  static const _categoryLabels = {
    'all': 'Tous',
    'culture': 'Culture',
    'elevage': 'Élevage',
    'general': 'Général',
    'finance': 'Finance',
    'maintenance': 'Maintenance',
  };

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _initializeAndLoad();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeAndLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notebookService = NotebookService(prefs);
      await _loadNotebooks();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNotebooks() async {
    try {
      // Fetch notebooks from server and cache locally
      final notebooks = await _notebookService.syncNotebooksFromServer();
      if (mounted) {
        setState(() {
          _notebooks = notebooks;
          _applyFilters();
          _isLoading = false;
        });
        _entryCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredNotebooks = _notebooks.where((nb) {
      final matchesCat =
          _selectedCategory == 'all' || nb.category == _selectedCategory;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          nb.title.toLowerCase().contains(q) ||
          nb.description.toLowerCase().contains(q);
      return matchesCat && matchesSearch;
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> _openCreate() async {
    final result = await Navigator.push<ProjectNotebook?>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectNotebookEditorScreen(
          farmId: widget.farmId,
          userId: widget.userId,
        ),
      ),
    );
    if (result != null) await _loadNotebooks();
  }

  Future<void> _openEdit(ProjectNotebook nb) async {
    final result = await Navigator.push<ProjectNotebook?>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectNotebookEditorScreen(
          farmId: widget.farmId,
          userId: widget.userId,
          notebook: nb,
        ),
      ),
    );
    if (result != null) await _loadNotebooks();
  }

  Future<void> _deleteNotebook(ProjectNotebook nb) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkCardBg : AppColors.lightBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Supprimer ce cahier ?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: isDark ? AppColors.textDark : AppColors.textLight,
            letterSpacing: -0.3,
          ),
        ),
        content: Text(
          '"${nb.title}" sera définitivement supprimé.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(
                color: Color(0xFFE05252),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _notebookService.deleteNotebook(nb.id);
        await _loadNotebooks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppColors.createSnackBar(
                message: 'Cahier supprimé', isError: false, durationMs: 800),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppColors.createSnackBar(
                message: 'Erreur : $e', isError: true),
          );
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardBg = isDark ? AppColors.darkCardBg : const Color(0xFFFAF8F4);
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPri = isDark ? AppColors.textDark : AppColors.textLight;
    final textSec = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────────────
            _buildHeader(isDark, cardBg, border, textPri, textSec),

            // ── CATEGORY FILTERS ────────────────────────────────────────────
            _buildCategoryBar(isDark, border),

            // ── SEARCH ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _buildSearchField(isDark, cardBg, border, textSec),
            ),
            const SizedBox(height: 14),

            // ── SECTION LABEL + COUNT ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionLabel(
                _filteredNotebooks.isEmpty
                    ? 'AUCUN CAHIER'
                    : '${_filteredNotebooks.length} CAHIER${_filteredNotebooks.length > 1 ? 'S' : ''}',
              ),
            ),
            const SizedBox(height: 14),

            // ── LIST ────────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 1.8,
                      ),
                    )
                  : _filteredNotebooks.isEmpty
                      ? _buildEmptyState(textSec)
                      : FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              itemCount: _filteredNotebooks.length,
                              itemBuilder: (_, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _NotebookCard(
                                  notebook: _filteredNotebooks[i],
                                  isDark: isDark,
                                  cardBg: cardBg,
                                  border: border,
                                  textPri: textPri,
                                  textSec: textSec,
                                  onTap: () => _openEdit(_filteredNotebooks[i]),
                                  onDelete: () =>
                                      _deleteNotebook(_filteredNotebooks[i]),
                                ),
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildHeader(bool isDark, Color cardBg, Color border, Color textPri,
      Color textSec) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cahiers de projet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: textPri,
                    letterSpacing: -0.8,
                  ),
                ),
                Text(
                  '${_notebooks.length} cahier${_notebooks.length != 1 ? 's' : ''} · Ferme #${widget.farmId}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w300,
                    color: textSec,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _openCreate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 5),
                  Text(
                    'Nouveau',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(bool isDark, Color border) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          return Padding(
            padding: const EdgeInsets.only(right: 7),
            child: _CategoryPill(
              label: _categoryLabels[cat] ?? cat,
              selected: _selectedCategory == cat,
              isDark: isDark,
              onTap: () => setState(() {
                _selectedCategory = cat;
                _applyFilters();
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField(
      bool isDark, Color cardBg, Color border, Color textSec) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1),
      ),
      child: TextField(
        onChanged: (v) => setState(() {
          _searchQuery = v;
          _applyFilters();
        }),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w300,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher un cahier…',
          hintStyle: TextStyle(
            color: textSec,
            fontWeight: FontWeight.w300,
            fontSize: 13,
          ),
          prefixIcon:
              Icon(Icons.search_rounded, color: AppColors.primary, size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textSec) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun cahier trouvé',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w300,
              color: textSec,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Créez votre premier cahier de projet',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              color: textSec.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: _openCreate,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Nouveau cahier',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTEBOOK CARD — widget séparé pour la lisibilité
// ─────────────────────────────────────────────────────────────────────────────
class _NotebookCard extends StatelessWidget {
  final ProjectNotebook notebook;
  final bool isDark;
  final Color cardBg;
  final Color border;
  final Color textPri;
  final Color textSec;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotebookCard({
    required this.notebook,
    required this.isDark,
    required this.cardBg,
    required this.border,
    required this.textPri,
    required this.textSec,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.18)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Accent bar
              Container(
                width: 2.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.accent.withOpacity(0.85),
                      AppColors.primary.withOpacity(0.25),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notebook.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: textPri,
                                letterSpacing: 0.05,
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Menu
                          GestureDetector(
                            onTap: () => _showMenu(context),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Icon(
                                Icons.more_horiz_rounded,
                                size: 14,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (notebook.description.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          notebook.description,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w300,
                            color: textSec,
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Tags row
                      Row(
                        children: [
                          _CatTag(notebook.category, isDark: isDark),
                          const SizedBox(width: 6),
                          ...notebook.tags.take(2).map((tag) => Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: _TagChip(tag, isDark: isDark),
                              )),
                          if (notebook.tags.length > 2)
                            _TagChip('+${notebook.tags.length - 2}',
                                isDark: isDark),
                          const Spacer(),
                          if (notebook.isPublic)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'PUBLIC',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Footer
                      Row(
                        children: [
                          _Stat(
                            icon: Icons.view_list_rounded,
                            label:
                                '${notebook.sections.length} section${notebook.sections.length != 1 ? 's' : ''}',
                            textSec: textSec,
                          ),
                          const SizedBox(width: 14),
                          _Stat(
                            icon: Icons.chat_bubble_outline_rounded,
                            label:
                                '${notebook.comments.length} commentaire${notebook.comments.length != 1 ? 's' : ''}',
                            textSec: textSec,
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('dd MMM yyyy')
                                .format(notebook.updatedAt),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w300,
                              color: textSec.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkCardBg : AppColors.lightBg;
        final border =
            isDark ? AppColors.borderDark : AppColors.borderLight;
        final textPri =
            isDark ? AppColors.textDark : AppColors.textLight;

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
            border: Border(top: BorderSide(color: border, width: 0.5)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 34,
                  height: 3,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _MenuAction(
                icon: Icons.edit_outlined,
                label: 'Modifier ce cahier',
                textColor: textPri,
                onTap: () {
                  Navigator.pop(ctx);
                  onTap();
                },
              ),
              const SizedBox(height: 8),
              _MenuAction(
                icon: Icons.delete_outline_rounded,
                label: 'Supprimer',
                textColor: const Color(0xFFE05252),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _TagChip(this.label, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.borderDark : const Color(0xFFEEEBE4),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w400,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textSec;
  const _Stat(
      {required this.icon, required this.label, required this.textSec});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 11, color: textSec.withOpacity(0.6)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w300,
            color: textSec.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _MenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final VoidCallback onTap;
  const _MenuAction({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBg : const Color(0xFFF5F2ED),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: textColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}