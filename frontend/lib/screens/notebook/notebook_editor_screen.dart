import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/models/project_notebook_model.dart';
import 'package:mbaymi/services/notebook_service.dart';
import 'package:mbaymi/services/notebook_pdf_export_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BLOCK MODEL
// ─────────────────────────────────────────────────────────────────────────────
enum BlockType { h1, h2, h3, text, bullet, numbered, todo, quote, code, divider }

class NoteBlock {
  final String id;
  BlockType type;
  String content;
  bool checked;

  NoteBlock({String? id, this.type = BlockType.text, this.content = '', this.checked = false})
      : id = id ?? UniqueKey().toString();

  NoteBlock copyWith({BlockType? type, String? content, bool? checked}) =>
      NoteBlock(id: id, type: type ?? this.type, content: content ?? this.content,
          checked: checked ?? this.checked);

  Map<String, dynamic> toJson() =>
      {'id': id, 'type': type.name, 'content': content, 'checked': checked};

  factory NoteBlock.fromJson(Map<String, dynamic> j) => NoteBlock(
      id: j['id'] as String? ?? UniqueKey().toString(),
      type: BlockType.values.firstWhere((e) => e.name == j['type'],
          orElse: () => BlockType.text),
      content: j['content'] as String? ?? '',
      checked: j['checked'] as bool? ?? false);
}

// ─────────────────────────────────────────────────────────────────────────────
// SLASH COMMAND
// ─────────────────────────────────────────────────────────────────────────────
class _Cmd {
  final IconData icon;
  final String label;
  final String shortcut;
  final BlockType type;
  const _Cmd(this.icon, this.label, this.shortcut, this.type);
}

const _cmds = [
  _Cmd(Icons.title_rounded,           'Titre 1',        'h1',   BlockType.h1),
  _Cmd(Icons.text_fields_rounded,     'Titre 2',        'h2',   BlockType.h2),
  _Cmd(Icons.short_text_rounded,      'Titre 3',        'h3',   BlockType.h3),
  _Cmd(Icons.notes_rounded,           'Texte',          'text', BlockType.text),
  _Cmd(Icons.format_list_bulleted,    'Liste à puces',  'ul',   BlockType.bullet),
  _Cmd(Icons.format_list_numbered,    'Liste numérotée','ol',   BlockType.numbered),
  _Cmd(Icons.check_box_outlined,      'Tâche',          'todo', BlockType.todo),
  _Cmd(Icons.format_quote_rounded,    'Citation',       'quote',BlockType.quote),
  _Cmd(Icons.code_rounded,            'Code',           'code', BlockType.code),
  _Cmd(Icons.horizontal_rule_rounded, 'Séparateur',     'hr',   BlockType.divider),
];

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 20, height: 1, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(text.toUpperCase(),
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w500,
                letterSpacing: 2.8, color: AppColors.primary)),
        const SizedBox(width: 8),
        Flexible(child: Container(height: 1, color: AppColors.primary.withOpacity(0.12))),
      ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _TabChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  const _TabChip({required this.icon, required this.label, required this.selected,
      required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary
                : (isDark ? AppColors.darkCardBg : const Color(0xFFFAF8F4)),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14,
                color: selected ? Colors.white
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11.5,
                fontWeight: selected ? FontWeight.w400 : FontWeight.w300,
                color: selected ? Colors.white
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SLASH COMMAND MENU WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _SlashMenu extends StatelessWidget {
  final List<_Cmd> commands;
  final bool isDark;
  final void Function(_Cmd) onSelect;
  const _SlashMenu({required this.commands, required this.isDark, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkCardBg : Colors.white;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPri = isDark ? AppColors.textDark : AppColors.textLight;
    final textSec = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 0.5),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
            blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Align(alignment: Alignment.centerLeft,
              child: Text('BLOCS', style: TextStyle(fontSize: 7.5,
                  fontWeight: FontWeight.w600, letterSpacing: 1.8,
                  color: textSec.withOpacity(0.6)))),
          ),
          ...commands.map((cmd) => InkWell(
            onTap: () => onSelect(cmd),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(7)),
                  child: Icon(cmd.icon, size: 15, color: AppColors.primary)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cmd.label, style: TextStyle(fontSize: 12.5,
                      fontWeight: FontWeight.w400, color: textPri)),
                  Text('/${cmd.shortcut}', style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w300, color: textSec)),
                ])),
              ]),
            ),
          )),
          const SizedBox(height: 6),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SINGLE BLOCK ROW
// ─────────────────────────────────────────────────────────────────────────────
class _BlockRow extends StatefulWidget {
  final NoteBlock block;
  final int index;
  final bool isDark;
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;
  final VoidCallback onEnter;
  final VoidCallback onBackspace;
  final void Function(BlockType) onTypeChange;
  final VoidCallback onToggleCheck;
  final VoidCallback onShowSlash;

  const _BlockRow({
    Key? key,
    required this.block,
    required this.index,
    required this.isDark,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onEnter,
    required this.onBackspace,
    required this.onTypeChange,
    required this.onToggleCheck,
    required this.onShowSlash,
  }) : super(key: key);

  @override
  State<_BlockRow> createState() => _BlockRowState();
}

class _BlockRowState extends State<_BlockRow> {
  bool _hovered = false;

  Color get _tc => widget.isDark ? AppColors.textDark : AppColors.textLight;
  Color get _sc =>
      widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

  @override
  Widget build(BuildContext context) {
    if (widget.block.type == BlockType.divider) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            _handle(),
            Expanded(child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  AppColors.primary.withOpacity(0.20),
                  Colors.transparent,
                ]),
              ),
            )),
            _menu(),
          ]),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: _pad(),
        child: Row(
          crossAxisAlignment: _multiline()
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            _handle(),
            if (widget.block.type == BlockType.todo) _check(),
            if (widget.block.type == BlockType.bullet) _dot(),
            if (widget.block.type == BlockType.numbered) _num(),
            if (widget.block.type == BlockType.quote) _quotebar(),
            Expanded(child: _field()),
            _menu(),
          ],
        ),
      ),
    );
  }

  EdgeInsets _pad() {
    switch (widget.block.type) {
      case BlockType.h1: return const EdgeInsets.symmetric(vertical: 12);
      case BlockType.h2: return const EdgeInsets.symmetric(vertical: 8);
      case BlockType.h3: return const EdgeInsets.symmetric(vertical: 6);
      default: return const EdgeInsets.symmetric(vertical: 4);
    }
  }

  bool _multiline() =>
      widget.block.type == BlockType.code ||
      widget.block.type == BlockType.quote;

  Widget _handle() => AnimatedOpacity(
        opacity: _hovered ? 0.35 : 0,
        duration: const Duration(milliseconds: 150),
        child: ReorderableDragStartListener(
          index: widget.index,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.drag_indicator_rounded, size: 16, color: _sc),
          ),
        ),
      );

  Widget _menu() => AnimatedOpacity(
        opacity: _hovered ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: GestureDetector(
          onTap: () => _showTypeSheet(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(Icons.add_rounded, size: 13, color: _sc),
            ),
          ),
        ),
      );

  void _showTypeSheet(BuildContext ctx) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final bg = widget.isDark ? AppColors.darkCardBg : AppColors.lightBg;
        final border = widget.isDark ? AppColors.borderDark : AppColors.borderLight;
        final textPri = widget.isDark ? AppColors.textDark : AppColors.textLight;
        final textSec = widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            border: Border(top: BorderSide(color: border, width: 0.5)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(
              width: 34, height: 3,
              decoration: BoxDecoration(color: border,
                  borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Text('Changer le type', style: TextStyle(
              fontSize: 8, fontWeight: FontWeight.w500,
              letterSpacing: 2.2, color: textSec.withOpacity(0.6))),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8,
              children: _cmds.map((cmd) {
                final active = widget.block.type == cmd.type;
                return GestureDetector(
                  onTap: () { Navigator.pop(ctx); widget.onTypeChange(cmd.type); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.primary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: active ? AppColors.primary : border, width: 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(cmd.icon, size: 13,
                          color: active ? Colors.white : AppColors.primary),
                      const SizedBox(width: 6),
                      Text(cmd.label, style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: active ? Colors.white : textPri)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ]),
        );
      },
    );
  }

  Widget _check() => GestureDetector(
        onTap: widget.onToggleCheck,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 18, height: 18,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: widget.block.checked ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: widget.block.checked
                  ? AppColors.primary
                  : _sc.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: widget.block.checked
              ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
              : null,
        ),
      );

  Widget _dot() => Container(
        width: 5, height: 5,
        margin: const EdgeInsets.only(right: 10, top: 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
      );

  Widget _num() => Container(
        margin: const EdgeInsets.only(right: 8),
        child: Text('${widget.index + 1}.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400,
                color: AppColors.primary.withOpacity(0.7))),
      );

  Widget _quotebar() => Container(
        width: 3,
        margin: const EdgeInsets.only(right: 12, top: 2, bottom: 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  TextStyle _style() {
    final base = TextStyle(color: _tc, height: 1.6);
    switch (widget.block.type) {
      case BlockType.h1:
        return base.copyWith(fontSize: 26, fontWeight: FontWeight.w300,
            letterSpacing: -1.0, height: 1.2);
      case BlockType.h2:
        return base.copyWith(fontSize: 20, fontWeight: FontWeight.w300,
            letterSpacing: -0.5, height: 1.3);
      case BlockType.h3:
        return base.copyWith(fontSize: 16, fontWeight: FontWeight.w400,
            letterSpacing: -0.2);
      case BlockType.quote:
        return base.copyWith(fontSize: 15.5, fontWeight: FontWeight.w300, height: 1.75,
            fontStyle: FontStyle.italic, color: _tc.withOpacity(0.75));
      case BlockType.code:
        return base.copyWith(fontSize: 12.5, fontFamily: 'monospace',
            color: AppColors.primary, height: 1.6);
      case BlockType.todo:
        return base.copyWith(fontSize: 15.5, fontWeight: FontWeight.w300, height: 1.75,
            decoration: widget.block.checked ? TextDecoration.lineThrough : null,
            color: widget.block.checked ? _sc : _tc);
      default:
        return base.copyWith(fontSize: 15.5, fontWeight: FontWeight.w300, height: 1.75);
    }
  }

  String _hint() {
    switch (widget.block.type) {
      case BlockType.h1: return 'Titre principal…';
      case BlockType.h2: return 'Titre secondaire…';
      case BlockType.h3: return 'Sous-titre…';
      case BlockType.bullet: return 'Élément de liste…';
      case BlockType.numbered: return 'Élément numéroté…';
      case BlockType.todo: return 'Tâche à accomplir…';
      case BlockType.quote: return 'Citation ou remarque…';
      case BlockType.code: return '// Code ici…';
      default: return 'Écrivez ici… (/ pour les commandes)';
    }
  }

  Widget _field() {
    final isCode = widget.block.type == BlockType.code;
    final style = _style();

    Widget tf = KeyboardListener(
      focusNode: FocusNode(skipTraversal: true),
      onKeyEvent: (e) {
        if (e is KeyDownEvent &&
            e.logicalKey == LogicalKeyboardKey.backspace &&
            widget.controller.text.isEmpty) {
          widget.onBackspace();
        }
      },
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        style: style,
        maxLines: (widget.block.type == BlockType.h1 ||
                    widget.block.type == BlockType.h2 ||
                    widget.block.type == BlockType.h3)
            ? 1
            : null,
        minLines: 1,
        keyboardType: isCode ? TextInputType.multiline : TextInputType.text,
        textInputAction: isCode ? TextInputAction.newline : TextInputAction.none,
        decoration: InputDecoration(
          hintText: _hint(),
          hintStyle: style.copyWith(color: _sc.withOpacity(0.35)),
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
        ),
        onChanged: widget.onChanged,
        onSubmitted: (_) => widget.onEnter(),
      ),
    );

    if (isCode) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isDark
              ? const Color(0xFF0D1A0A)
              : const Color(0xFFF0F7EC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1),
        ),
        child: tf,
      );
    }
    return tf;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BLOCK EDITOR
// ─────────────────────────────────────────────────────────────────────────────
class _BlockEditor extends StatefulWidget {
  final List<NoteBlock> blocks;
  final bool isDark;
  final void Function(List<NoteBlock>) onChanged;

  const _BlockEditor({
    required this.blocks,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<_BlockEditor> {
  late List<NoteBlock> _blocks;
  final Map<String, TextEditingController> _ctrls = {};
  final Map<String, FocusNode> _foci = {};

  // Slash overlay
  OverlayEntry? _overlay;
  String? _slashId;
  final LayerLink _slashLink = LayerLink();
  String _slashQuery = '';

  @override
  void initState() {
    super.initState();
    _blocks = List.from(widget.blocks);
    if (_blocks.isEmpty) _blocks.add(NoteBlock(type: BlockType.text));
    for (final b in _blocks) _init(b);
  }

  @override
  void dispose() {
    _hideSlash();
    for (final c in _ctrls.values) c.dispose();
    for (final f in _foci.values) f.dispose();
    super.dispose();
  }

  void _init(NoteBlock b) {
    _ctrls[b.id] ??= TextEditingController(text: b.content);
    _foci[b.id] ??= FocusNode();
  }

  void _emit() => widget.onChanged(List.from(_blocks));

  void _addAfter(int i, {BlockType type = BlockType.text}) {
    final nb = NoteBlock(type: type);
    _init(nb);
    setState(() => _blocks.insert(i + 1, nb));
    _emit();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _foci[nb.id]?.requestFocus());
  }

  void _remove(int i) {
    if (_blocks.length <= 1) {
      _ctrls[_blocks[0].id]?.clear();
      setState(() {
        _blocks[0] = _blocks[0].copyWith(content: '', type: BlockType.text);
      });
      _emit();
      return;
    }
    final id = _blocks[i].id;
    setState(() => _blocks.removeAt(i));
    _ctrls.remove(id)?.dispose();
    _foci.remove(id)?.dispose();
    _emit();
    if (i > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pid = _blocks[i - 1].id;
        _foci[pid]?.requestFocus();
        final c = _ctrls[pid];
        if (c != null) c.selection = TextSelection.collapsed(offset: c.text.length);
      });
    }
  }

  void _showSlash(String blockId, String query, Offset anchor) {
    _slashId = blockId;
    _slashQuery = query;
    _hideSlash();

    final filtered = _cmds.where((c) =>
        query.isEmpty ||
        c.label.toLowerCase().contains(query.toLowerCase()) ||
        c.shortcut.toLowerCase().startsWith(query.toLowerCase())).toList();
    if (filtered.isEmpty) return;

    _overlay = OverlayEntry(
      builder: (_) => Positioned(
        left: anchor.dx,
        top: anchor.dy + 32,
        width: 240,
        child: _SlashMenu(
          commands: filtered,
          isDark: widget.isDark,
          onSelect: (cmd) {
            _hideSlash();
            final idx = _blocks.indexWhere((b) => b.id == _slashId);
            if (idx < 0) return;
            _ctrls[_blocks[idx].id]?.clear();
            if (cmd.type == BlockType.divider) {
              setState(() => _blocks[idx] =
                  _blocks[idx].copyWith(type: BlockType.divider, content: ''));
              _addAfter(idx);
            } else {
              setState(() => _blocks[idx] =
                  _blocks[idx].copyWith(type: cmd.type, content: ''));
              WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _foci[_blocks[idx].id]?.requestFocus());
            }
            _emit();
          },
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _hideSlash() {
    _overlay?.remove();
    _overlay = null;
    _slashId = null;
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: (o, n) {
        setState(() {
          if (n > o) n--;
          final b = _blocks.removeAt(o);
          _blocks.insert(n, b);
        });
        _emit();
      },
      itemCount: _blocks.length,
      itemBuilder: (ctx, i) {
        final b = _blocks[i];
        return _BlockRow(
          key: ValueKey(b.id),
          block: b,
          index: i,
          isDark: widget.isDark,
          controller: _ctrls[b.id]!,
          focusNode: _foci[b.id]!,
          onChanged: (text) {
            _blocks[i] = b.copyWith(content: text);
            _emit();
            // Slash detection
            if (text.startsWith('/')) {
              final q = text.substring(1);
              final rb = ctx.findRenderObject() as RenderBox?;
              if (rb != null) {
                final pos = rb.localToGlobal(Offset.zero);
                _showSlash(b.id, q, pos);
              }
            } else if (_slashId == b.id) {
              _hideSlash();
            }
          },
          onEnter: () => _addAfter(i),
          onBackspace: () {
            if (_ctrls[b.id]?.text.isEmpty ?? true) _remove(i);
          },
          onTypeChange: (type) {
            setState(() => _blocks[i] = b.copyWith(type: type));
            _emit();
          },
          onToggleCheck: () {
            setState(() => _blocks[i] = b.copyWith(checked: !b.checked));
            _emit();
          },
          onShowSlash: () {
            final rb = ctx.findRenderObject() as RenderBox?;
            if (rb != null) _showSlash(b.id, '', rb.localToGlobal(Offset.zero));
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN EDITOR SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ProjectNotebookEditorScreen extends StatefulWidget {
  final String farmId;
  final String userId;
  final ProjectNotebook? notebook;

  const ProjectNotebookEditorScreen(
      {required this.farmId, required this.userId, this.notebook, Key? key})
      : super(key: key);

  @override
  State<ProjectNotebookEditorScreen> createState() =>
      _ProjectNotebookEditorScreenState();
}

class _ProjectNotebookEditorScreenState
    extends State<ProjectNotebookEditorScreen> with TickerProviderStateMixin {
  late NotebookService _notebookService;
  late ProjectNotebook _notebook;

  final _titleCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  String _selectedCategory = 'general';
  List<String> _tags = [];
  int _activeTab = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  List<NoteBlock> _blocks = [];

  late AnimationController _entryCtrl;
  late List<Animation<double>> _fade;
  late List<Animation<Offset>> _slide;

  static const _categories = ['general','culture','elevage','finance','maintenance'];
  static const _catLabels = {
    'general': 'Général', 'culture': 'Culture', 'elevage': 'Élevage',
    'finance': 'Finance', 'maintenance': 'Maintenance',
  };

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900));
    _fade = List.generate(5, (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryCtrl,
            curve: Interval(i * 0.08, (i * 0.08 + 0.5).clamp(0, 1.0),
                curve: Curves.easeOut))));
    _slide = List.generate(5, (i) =>
        Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(
            CurvedAnimation(parent: _entryCtrl,
                curve: Interval(i * 0.08, (i * 0.08 + 0.5).clamp(0, 1.0),
                    curve: Curves.easeOutCubic))));
    _init();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _titleCtrl.dispose();
    _commentCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Widget _s(int i, Widget child) => FadeTransition(
      opacity: _fade[i],
      child: SlideTransition(position: _slide[i], child: child));

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _notebookService = NotebookService(prefs);
    if (widget.notebook != null) {
      _notebook = widget.notebook!;
    } else {
      _notebook = ProjectNotebook(
          title: '', description: '',
          farmId: widget.farmId, createdBy: widget.userId, sections: []);
    }
    _titleCtrl.text = _notebook.title;
    _selectedCategory = _notebook.category;
    _tags = List.from(_notebook.tags);
    _blocks = _parseBlocks();
    if (_blocks.isEmpty) {
      _blocks = [NoteBlock(type: BlockType.text)];
    }
    setState(() => _isLoading = false);
    _entryCtrl.forward();
  }

  List<NoteBlock> _parseBlocks() {
    if (_notebook.sections.isEmpty) return [];
    final s = _notebook.sections.first;
    return s.contents
        .where((c) => c.type == 'text' && (c.content as String).isNotEmpty)
        .map((c) => NoteBlock(type: BlockType.text, content: c.content as String))
        .toList();
  }

  // colors
  Color _bg(bool d) => d ? AppColors.darkBg : AppColors.lightBg;
  Color _card(bool d) => d ? AppColors.darkCardBg : const Color(0xFFFAF8F4);
  Color _border(bool d) => d ? AppColors.borderDark : AppColors.borderLight;
  Color _text(bool d) => d ? AppColors.textDark : AppColors.textLight;
  Color _sec(bool d) => d ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;


  /// Auto-derives a title from the first non-empty block content
  /// if the user hasn't typed a title. Takes first sentence or first 6 words.
  String _deriveTitle() {
    final typed = _titleCtrl.text.trim();
    if (typed.isNotEmpty) return typed;

    // Walk blocks to find first meaningful text
    for (final b in _blocks) {
      final raw = b.content.trim();
      if (raw.isEmpty) continue;
      // Take first sentence (up to period/newline) or first 6 words
      final firstLine = raw.split('\n').first.trim();
      final firstSentence = firstLine.split(RegExp(r'[.!?]')).first.trim();
      if (firstSentence.isEmpty) continue;
      final words = firstSentence.split(RegExp(r'\s+'));
      return words.take(6).join(' ');
    }
    return 'Sans titre';
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final finalTitle = _deriveTitle();
    // Update the title field if it was empty so user sees what was auto-derived
    if (_titleCtrl.text.trim().isEmpty) {
      _titleCtrl.text = finalTitle;
    }
    setState(() => _isSaving = true);
    try {
      final contents = _blocks
          .where((b) => b.content.isNotEmpty || b.type == BlockType.divider)
          .map((b) => NoteContent(
              type: 'text',
              content: b.type == BlockType.divider ? '---' : b.content))
          .toList();
      _notebook = _notebook.copyWith(
          title: finalTitle,
          category: _selectedCategory,
          tags: _tags,
          sections: [NotebookSection(title: 'Contenu', contents: contents)]);
      await _notebookService.saveNotebook(_notebook);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(AppColors.createSnackBar(
            message: 'Cahier sauvegardé !', isError: false, durationMs: 800));
        Navigator.pop(context, _notebook);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            AppColors.createSnackBar(message: 'Erreur : $e', isError: true));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addTag() {
    final t = _tagCtrl.text.trim();
    if (t.isNotEmpty && !_tags.contains(t)) {
      setState(() { _tags.add(t); _tagCtrl.clear(); });
    }
  }

  void _addComment() {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() {
      _notebook = _notebook.copyWith(comments: [
        ..._notebook.comments,
        NoteComment(userId: widget.userId, userName: 'Utilisateur',
            text: _commentCtrl.text.trim()),
      ]);
      _commentCtrl.clear();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bg(isDark),
        body: Center(child: CircularProgressIndicator(
            color: AppColors.primary, strokeWidth: 1.8)),
      );
    }
    return Scaffold(
      backgroundColor: _bg(isDark),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _header(isDark),
          _tabs(isDark),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                      .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_activeTab),
                child: _activeTab == 0
                    ? _editorTab(isDark)
                    : _activeTab == 1
                        ? _settingsTab(isDark)
                        : _commentsTab(isDark),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _header(bool isDark) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: _card(isDark),
          border: Border(bottom: BorderSide(color: _border(isDark), width: 0.5)),
        ),
        child: Row(children: [
          GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); FocusScope.of(context).unfocus(); Navigator.pop(context); },
            child: Container(width: 34, height: 34,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.close_rounded, size: 17, color: _sec(isDark)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _titleCtrl,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300,
                  color: _text(isDark), letterSpacing: -0.4),
              decoration: InputDecoration(
                hintText: 'Titre…',
                hintStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w300,
                    color: _sec(isDark).withOpacity(0.5), letterSpacing: -0.4),
                border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => NotebookPdfExportService.exportToPdf(_notebook),
            child: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSaving ? null : _save,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9)),
              child: _isSaving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.8, color: Colors.white))
                  : const Text('Sauvegarder', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white)),
            ),
          ),
        ]),
      );

  Widget _tabs(bool isDark) {
    const tabs = [
      {'icon': Icons.edit_note_rounded, 'label': 'Éditeur'},
      {'icon': Icons.tune_rounded, 'label': 'Paramètres'},
      {'icon': Icons.chat_bubble_outline_rounded, 'label': 'Commentaires'},
    ];
    return Container(
      height: 52,
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _border(isDark), width: 0.5))),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        itemCount: tabs.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _TabChip(
            icon: tabs[i]['icon'] as IconData,
            label: tabs[i]['label'] as String,
            selected: _activeTab == i,
            isDark: isDark,
            onTap: () => setState(() => _activeTab = i),
          ),
        ),
      ),
    );
  }

  // ─── EDITOR TAB ───────────────────────────────────────────────────────────
  Widget _editorTab(bool isDark) {
    final allEmpty = _blocks.every((b) => b.content.isEmpty);
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 120,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        if (allEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('/', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500,
                    color: AppColors.primary, fontFamily: 'monospace')),
                  const SizedBox(width: 6),
                  Text('pour les commandes  ·  ↵ nouveau bloc', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w300,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  )),
                ]),
              ),
            ]),
          ),
        _BlockEditor(
          blocks: _blocks,
          isDark: isDark,
          onChanged: (b) => setState(() => _blocks = b),
        ),
        // Tap anywhere below to add new text block — Apple Notes style
        GestureDetector(
          onTap: () {
            final newBlock = NoteBlock(type: BlockType.text);
            setState(() => _blocks.add(newBlock));
          },
          behavior: HitTestBehavior.translucent,
          child: Container(
            height: 120,
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.only(top: 16),
          ),
        ),
      ]),
    );
  }

  // ─── SETTINGS TAB ─────────────────────────────────────────────────────────
  Widget _settingsTab(bool isDark) => SingleChildScrollView(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _s(0, _SectionLabel('Catégorie')),
          const SizedBox(height: 12),
          _s(0, _catSelector(isDark)),
          const SizedBox(height: 24),
          _s(1, _SectionLabel('Tags')),
          const SizedBox(height: 12),
          _s(1, _tagsSection(isDark)),
          const SizedBox(height: 32),
          _s(2, _saveBtn()),
          const SizedBox(height: 24),
        ]),
      );

  // ─── COMMENTS TAB ─────────────────────────────────────────────────────────
  Widget _commentsTab(bool isDark) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: _field(
              ctrl: _commentCtrl,
              label: 'NOUVEAU COMMENTAIRE',
              hint: 'Ajouter une observation…',
              icon: Icons.chat_bubble_outline_rounded,
              isDark: isDark,
              maxLines: 3,
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _addComment,
              child: Container(width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SectionLabel(
                '${_notebook.comments.length} commentaire${_notebook.comments.length != 1 ? 's' : ''}')),
        const SizedBox(height: 12),
        Expanded(
          child: _notebook.comments.isEmpty
              ? _empty(icon: Icons.chat_bubble_outline_rounded,
                  label: 'Aucun commentaire',
                  sub: 'Ajoutez la première observation', isDark: isDark)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: _notebook.comments.length,
                  itemBuilder: (_, i) =>
                      _CommentCard(comment: _notebook.comments[i], isDark: isDark)),
        ),
      ]);

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
  }) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500,
            letterSpacing: 1.8, color: _sec(isDark))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(color: _card(isDark),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border(isDark), width: 1)),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines, minLines: maxLines == 1 ? 1 : 2,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300,
                color: _text(isDark), height: 1.5),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _sec(isDark),
                  fontWeight: FontWeight.w300, fontSize: 13),
              prefixIcon: Icon(icon, color: AppColors.primary, size: 17),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
        ),
      ]);

  Widget _catSelector(bool isDark) => Wrap(
        spacing: 8, runSpacing: 8,
        children: _categories.map((cat) {
          final sel = _selectedCategory == cat;
          return GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); setState(() => _selectedCategory = cat); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary
                    : (isDark ? AppColors.darkCardBg : const Color(0xFFFAF8F4)),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: sel ? AppColors.primary
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
              ),
              child: Text(_catLabels[cat] ?? cat,
                  style: TextStyle(fontSize: 12,
                      fontWeight: sel ? FontWeight.w400 : FontWeight.w300,
                      color: sel ? Colors.white
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
            ),
          );
        }).toList(),
      );

  Widget _tagsSection(bool isDark) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: _card(isDark),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border(isDark), width: 1)),
                child: TextField(
                  controller: _tagCtrl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addTag(),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300, color: _text(isDark)),
                  decoration: InputDecoration(
                    hintText: 'Nouveau tag…',
                    hintStyle: TextStyle(color: _sec(isDark), fontWeight: FontWeight.w300, fontSize: 13),
                    prefixIcon: Icon(Icons.label_outline_rounded, color: AppColors.primary, size: 17),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addTag,
              child: Container(height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.22), width: 1),
                ),
                child: const Center(child: Text('Ajouter',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400,
                        color: AppColors.primary))),
              ),
            ),
          ]),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 7, runSpacing: 7,
              children: _tags.map((t) => _RemovableTag(label: t, isDark: isDark,
                  onRemove: () => setState(() => _tags.remove(t)))).toList()),
          ],
        ],
      );

  Widget _saveBtn() => SizedBox(
        width: double.infinity, height: 52,
        child: Material(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primary,
          child: InkWell(
            onTap: _isSaving ? null : _save,
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.accent.withOpacity(0.12),
            child: Center(
              child: _isSaving
                  ? SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.accent))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                      Icon(Icons.save_outlined, color: Colors.white, size: 17),
                      SizedBox(width: 8),
                      Text('Sauvegarder le cahier', style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w300,
                          color: Colors.white, letterSpacing: 0.2)),
                    ]),
            ),
          ),
        ),
      );

  Widget _empty({required IconData icon, required String label,
      required String sub, required bool isDark}) =>
      Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 56, height: 56,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.07),
                shape: BoxShape.circle),
            child: Icon(icon, size: 24, color: AppColors.primary.withOpacity(0.5))),
          const SizedBox(height: 14),
          Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300,
              color: _sec(isDark))),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w300,
              color: _sec(isDark).withOpacity(0.6))),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMENT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _CommentCard extends StatelessWidget {
  final NoteComment comment;
  final bool isDark;
  const _CommentCard({required this.comment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkCardBg : const Color(0xFFFAF8F4);
    final br = isDark ? AppColors.borderDark : AppColors.borderLight;
    final tp = isDark ? AppColors.textDark : AppColors.textLight;
    final ts = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: br, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 28, height: 28,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle),
              child: Center(child: Text(
                comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                    color: AppColors.primary)))),
            const SizedBox(width: 8),
            Text(comment.userName, style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w400, color: tp)),
            const Spacer(),
            Text(_fmt(comment.createdAt), style: TextStyle(fontSize: 9.5,
                fontWeight: FontWeight.w300, color: ts.withOpacity(0.6))),
          ]),
          const SizedBox(height: 10),
          Text(comment.text, style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w300, color: tp, height: 1.55)),
        ]),
      ),
    );
  }

  String _fmt(DateTime dt) {
    const m = ['jan','fév','mars','avr','mai','juin','juil','août','sep','oct','nov','déc'];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REMOVABLE TAG
// ─────────────────────────────────────────────────────────────────────────────
class _RemovableTag extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onRemove;
  const _RemovableTag({required this.label, required this.isDark, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(left: 10, right: 6, top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.primary.withOpacity(0.20), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: const TextStyle(fontSize: 11.5,
              fontWeight: FontWeight.w300, color: AppColors.primary)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(width: 16, height: 16,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 10, color: AppColors.primary)),
          ),
        ]),
      );
}