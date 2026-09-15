import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/services/traceability_export_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _Z {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s10 = 10.0;
  static const s12 = 12.0;
  static const s14 = 14.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s48 = 48.0;

  static const primary = Color(0xFF8B6B4D);
  static const primaryMuted = Color(0xFFA58A6D);

  static TextStyle mono(Color c, {double size = 10, double spacing = 1.5, FontWeight weight = FontWeight.w400}) =>
      TextStyle(
          fontSize: size,
          letterSpacing: spacing,
          fontWeight: weight,
          color: c);

  static TextStyle body(Color c, {double size = 14, FontWeight weight = FontWeight.w400}) => TextStyle(
      fontSize: size,
      letterSpacing: 0.2,
      fontWeight: weight,
      color: c,
      height: 1.4);
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA
// ─────────────────────────────────────────────────────────────────────────────
class _ActivityType {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _ActivityType(this.value, this.label, this.icon, this.color);
}

const _categories = {
  'CULTURE': [
    _ActivityType('Semis', 'Semis', Icons.grass, Color(0xFF4CAF50)),
    _ActivityType('Plantation', 'Plantation', Icons.eco, Color(0xFF66BB6A)),
    _ActivityType('Récolte', 'Récolte', Icons.agriculture, Color(0xFFFFA726)),
    _ActivityType('Labour', 'Labour', Icons.agriculture_outlined, Color(0xFF8D6E63)),
  ],
  'SOINS': [
    _ActivityType('Arrosage', 'Arrosage', Icons.water_drop, Color(0xFF42A5F5)),
    _ActivityType('Fertilisation', 'Fertilisation', Icons.clean_hands, Color(0xFF26C6DA)),
    _ActivityType('Taille', 'Taille', Icons.content_cut, Color(0xFFFF7043)),
    _ActivityType('Traitement', 'Traitement', Icons.bug_report, Color(0xFFEF5350)),
  ],
  'AUTRES': [
    _ActivityType('Inspection', 'Inspection', Icons.assignment, Color(0xFFAB47BC)),
    _ActivityType('Maintenance', 'Maintenance', Icons.build, Color(0xFF78909C)),
    _ActivityType('Suivi', 'Suivi', Icons.assessment, Color(0xFF26A69A)),
    _ActivityType('Autre', 'Autre', Icons.edit, Color(0xFF8B6B4D)),
  ],
};

_ActivityType _typeFor(String value) {
  for (final list in _categories.values) {
    for (final t in list) {
      if (t.value == value) return t;
    }
  }
  return _categories['AUTRES']!.last;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ActivityScreen extends StatefulWidget {
  final int farmId;
  final int cropId;
  final int userId;
  final int? farmOwnerId;
  final bool readOnly;

  const ActivityScreen({
    super.key,
    required this.farmId,
    required this.cropId,
    required this.userId,
    this.farmOwnerId,
    this.readOnly = false,
  });

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with TickerProviderStateMixin {
  // Form state
  final _notesCtrl = TextEditingController();
  final _customTypeCtrl = TextEditingController();
  final _quantityUsedCtrl = TextEditingController();
  final _financeAmountCtrl = TextEditingController();
  String _selectedType = '';
  DateTime? _date;
  int? _selectedInputId;
  String _financeType = 'expense';
  late Future<List<dynamic>> _inputsFuture;
  final List<XFile> _imageFiles = [];
  final List<Uint8List> _imageBytes = [];

  // UI state
  bool _loading = false;
  bool _showForm = false;
  String _selectedTabCategory = 'TOUT';
  late Future<List<dynamic>> _future;
  late AnimationController _formAnim;
  late Animation<double> _formFade;

  bool get _canEdit =>
      !widget.readOnly &&
      (widget.farmOwnerId == null || widget.userId == widget.farmOwnerId);

  @override
  void initState() {
    super.initState();
    _future = ApiService.getActivitiesForCrop(widget.cropId);
    _inputsFuture = ApiService.listInputsForCrop(widget.cropId);
    _formAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _formFade = CurvedAnimation(parent: _formAnim, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _customTypeCtrl.dispose();
    _quantityUsedCtrl.dispose();
    _financeAmountCtrl.dispose();
    _formAnim.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _future = ApiService.getActivitiesForCrop(widget.cropId);
      _inputsFuture = ApiService.listInputsForCrop(widget.cropId);
    });
  }

  void _toggleForm() {
    HapticFeedback.lightImpact();
    setState(() => _showForm = !_showForm);
    _showForm ? _formAnim.forward() : _formAnim.reverse();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              fontSize: 13, letterSpacing: 0.5, color: Colors.white, fontWeight: FontWeight.w500)),
      backgroundColor: error ? AppColors.error : _Z.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      duration: Duration(milliseconds: error ? 2500 : 1200),
    ));
  }

  Future<void> _exportTraceability() {
    return TraceabilityExportService.showExportMenu(
      context: context,
      title: 'Traçabilité des activités',
      loadSections: () async {
        final activities = await _future;
        final inputs = await ApiService.listInputsForCrop(widget.cropId);
        final enriched = TraceabilityExportService.enrichActivityRows(
          activities: activities.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
          inputs: inputs,
        );
        return [TraceabilitySection(
          title: 'Activités de la parcelle',
          rows: enriched,
        )];
      },
    );
  }

  Future<void> _pickImages() async {
    HapticFeedback.lightImpact();
    final picked = await ImagePicker().pickMultiImage(maxWidth: 1600);
    if (picked.isEmpty) return;
    final bytes = await Future.wait(picked.map((f) => f.readAsBytes()));
    setState(() {
      _imageFiles.addAll(picked);
      _imageBytes.addAll(bytes);
    });
  }

  Future<void> _submit() async {
    final type = _selectedType == 'Autre'
        ? _customTypeCtrl.text.trim()
        : _selectedType;
    if (type.isEmpty) {
      _snack('Sélectionnez un type d\'activité', error: true);
      return;
    }
    final quantityUsed = _selectedInputId == null
        ? null
        : double.tryParse(_quantityUsedCtrl.text.replaceAll(',', '.'));
    if (_selectedInputId != null && (quantityUsed == null || quantityUsed <= 0)) {
      _snack('Saisissez une quantité d\'intrant valide', error: true);
      return;
    }
    final financeAmount = double.tryParse(_financeAmountCtrl.text.replaceAll(',', '.'));
    if (_financeAmountCtrl.text.trim().isNotEmpty &&
        (financeAmount == null || financeAmount <= 0)) {
      _snack('Saisissez un montant financier valide', error: true);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      final urls = <String>[];
      for (final f in _imageFiles) {
        final u = await ApiService.uploadImageToCloudinary(f);
        if (u != null) urls.add(u);
      }
      await ApiService.createActivity(
        farmId: widget.farmId,
        cropId: widget.cropId,
        userId: widget.userId,
        activityType: type,
        activityDate: _date,
        notes: _notesCtrl.text.trim(),
        imageUrls: urls,
        inputId: _selectedInputId,
        quantityUsed: quantityUsed,
        financeType: financeAmount == null ? null : _financeType,
        financeAmount: financeAmount,
      );
      if (mounted) {
        _notesCtrl.clear();
        _customTypeCtrl.clear();
        _quantityUsedCtrl.clear();
        _financeAmountCtrl.clear();
        _imageFiles.clear();
        _imageBytes.clear();
        setState(() {
          _date = null;
          _selectedType = '';
          _selectedInputId = null;
          _financeType = 'expense';
          _showForm = false;
          _loading = false;
        });
        _formAnim.reverse();
        _snack('Activité enregistrée avec succès');
        _refresh();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _snack('Erreur: $e', error: true);
    }
  }

  Future<void> _deleteActivity(int id) async {
    try {
      setState(() => _loading = true);
      await ApiService.deleteActivity(id);
      _snack('Activité supprimée');
      _refresh();
    } catch (e) {
      _snack('Erreur: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateActivity(
      int id, String type, DateTime? date, String notes) async {
    if (type.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService.updateActivity(
        activityId: id,
        farmId: widget.farmId,
        cropId: widget.cropId,
        activityType: type,
        activityDate: date,
        notes: notes.isEmpty ? null : notes,
      );
      _snack('Activité mise à jour');
      _refresh();
    } catch (e) {
      _snack('Erreur: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(DateTime? dt, {String p = 'd MMM yyyy'}) {
    if (dt == null) return '';
    try {
      return DateFormat(p, 'fr_FR').format(dt);
    } catch (_) {
      return dt.toString().split('.')[0];
    }
  }

  String _formatActivityAmount(double amount) =>
      NumberFormat('#,##0', 'fr_FR').format(amount);

  Color get _bg => AppColors.getBgColor(_dark);
  Color get _text => AppColors.getTextColor(_dark);
  Color get _sub => AppColors.getSecondaryTextColor(_dark);
  Color get _border => AppColors.getBorderColor(_dark);
  Color get _fieldBg => _dark ? const Color(0xFF1E232A) : const Color(0xFFF4F5F7);
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    _dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + _Z.s32),
                child: Column(
                  children: [
                    if (_canEdit) _buildActionTriggerBar(),
                    if (_canEdit) _buildFormSection(),
                    _buildTabsBar(),
                    _buildHistorySection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _Z.s16, vertical: _Z.s12),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _border, width: 0.5))),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            tooltip: 'Retour',
            icon: Icon(Icons.arrow_back_ios_new, size: 18, color: _text),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(width: _Z.s8),
          Text('ACTIVITÉS', style: _Z.mono(_text, size: 13, spacing: 2.5, weight: FontWeight.w600)),
          const Spacer(),
          IconButton(
            onPressed: _exportTraceability,
            tooltip: 'Exporter la traçabilité',
            icon: Icon(Icons.download_outlined, size: 22, color: _text),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }

  // ── Action Bar (Trigger Form) ─────────────────────────────────────────────
Widget _buildActionTriggerBar() {
  final accentColor = _showForm 
      ? Color(0xFFE8877C)    // Terracotta doux
      : Color(0xFFD4AF37);   // Or doux

  return Padding(
    padding: const EdgeInsets.fromLTRB(_Z.s20, _Z.s24, _Z.s20, _Z.s16),
    child: Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _toggleForm,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          width: 64,
          height: 48,
          decoration: BoxDecoration(
            // ── Fond gris très clair ──
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(24),
            // ── Border gris subtile ──
            border: Border.all(
              color: Color(0xFFE0E0E0),
              width: 1,
            ),
            // ── Ombre douce et diffuse ──
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ── Slider : cercle qui glisse ──
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                left: _showForm ? 16 : 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    // ── Shadow du cercle (très subtile) ──
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        spreadRadius: 0,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  // ── Icône au centre du cercle ──
                  child: Center(
                    child: AnimatedRotation(
                      turns: _showForm ? 0.5 : 0,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        _showForm ? Icons.close_rounded : Icons.add_rounded,
                        size: 20,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  // ── Form Section ──────────────────────────────────────────────────────────
  Widget _buildFormSection() {
    return FadeTransition(
      opacity: _formFade,
      child: SizeTransition(
        sizeFactor: _formFade,
        child: _showForm
            ? Container(
                margin: const EdgeInsets.symmetric(horizontal: _Z.s20, vertical: _Z.s8),
                padding: const EdgeInsets.all(_Z.s16),
                decoration: BoxDecoration(
                  border: Border.all(color: _border, width: 0.8),
                ),
                child: _buildForm(),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Activity Type Selection ─────────────────────────────────────
        ..._categories.entries.map((e) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: _Z.s8, top: _Z.s4),
                  child: Text(e.key, style: _Z.mono(_sub, size: 11, spacing: 2, weight: FontWeight.w600)),
                ),
                Wrap(
                  spacing: _Z.s8,
                  runSpacing: _Z.s8,
                  children: e.value.map((t) {
                    final sel = _selectedType == t.value;
                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedType = t.value);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: _Z.s12, vertical: _Z.s10),
                        decoration: BoxDecoration(
                          color: sel ? t.color.withOpacity(0.18) : _fieldBg,
                          border: Border.all(
                            color: sel ? t.color : _border,
                            width: sel ? 1.5 : 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon, size: 15, color: sel ? t.color : _sub),
                            const SizedBox(width: _Z.s8),
                            Text(t.label,
                                style: _Z.body(sel ? t.color : _text,
                                    size: 13, weight: sel ? FontWeight.w600 : FontWeight.w400)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: _Z.s14),
              ],
            )),

        if (_selectedType == 'Autre') ...[
          _ZaraVisibleField(
            controller: _customTypeCtrl,
            label: 'PRÉCISER LE TYPE',
            hint: 'Ex: Traitement spécial',
            icon: Icons.edit_note,
            dark: _dark,
          ),
          const SizedBox(height: _Z.s16),
        ],

        // ── Date Picker ─────────────────────────────────────────────────
        Text('DATE DE L\'ACTIVITÉ', style: _Z.mono(_sub, size: 10, spacing: 1.5, weight: FontWeight.w600)),
        const SizedBox(height: _Z.s8),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: ColorScheme.light(
                      primary: _Z.primary,
                      onPrimary: Colors.white,
                      surface: _bg),
                ),
                child: child!,
              ),
            );
            if (d != null) setState(() => _date = d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: _Z.s14, vertical: _Z.s14),
            decoration: BoxDecoration(
                color: _fieldBg,
                border: Border.all(color: _date != null ? _Z.primary : _border, width: _date != null ? 1.5 : 0.8),
                borderRadius: BorderRadius.circular(2)),
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined, size: 18, color: _date != null ? _Z.primary : _sub),
                const SizedBox(width: _Z.s12),
                Text(
                  _date != null ? _fmt(_date, p: 'EEEE d MMMM yyyy') : 'Sélectionner une date',
                  style: _Z.body(_date != null ? _text : _sub, size: 13, weight: _date != null ? FontWeight.w500 : FontWeight.w400),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 18, color: _sub),
              ],
            ),
          ),
        ),
        const SizedBox(height: _Z.s20),

        // ── Intrant selection (Input très visible) ──────────────────────
        FutureBuilder<List<dynamic>>(
          future: _inputsFuture,
          builder: (context, snapshot) {
            final inputs = snapshot.data ?? [];
            if (inputs.isEmpty) return const SizedBox.shrink();
            final matchingInputs = inputs.where((item) => item['id'] == _selectedInputId);
            final selected = matchingInputs.isEmpty ? null : matchingInputs.first;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('INTRANT UTILISÉ (OPTIONNEL)', style: _Z.mono(_sub, size: 10, spacing: 1.5, weight: FontWeight.w600)),
                const SizedBox(height: _Z.s8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: _Z.s12),
                  decoration: BoxDecoration(
                    color: _fieldBg,
                    border: Border.all(color: _selectedInputId != null ? _Z.primary : _border, width: _selectedInputId != null ? 1.5 : 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedInputId,
                      isExpanded: true,
                      dropdownColor: _bg,
                      icon: Icon(Icons.arrow_drop_down, color: _text),
                      style: _Z.body(_text, size: 14, weight: FontWeight.w500),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 18, color: _sub),
                              const SizedBox(width: _Z.s10),
                              Text('Aucun intrant', style: _Z.body(_sub, size: 13)),
                            ],
                          ),
                        ),
                        ...inputs.map((item) => DropdownMenuItem<int?>(
                              value: item['id'] as int,
                              child: Row(
                                children: [
                                  const Icon(Icons.inventory_2, size: 18, color: _Z.primary),
                                  const SizedBox(width: _Z.s10),
                                  Expanded(
                                    child: Text(
                                      '${item['name'] ?? item['input_type'] ?? 'Intrant'} (${item['quantity'] ?? 0} ${item['unit'] ?? ''})',
                                      overflow: TextOverflow.ellipsis,
                                      style: _Z.body(_text, size: 13, weight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                      onChanged: (value) => setState(() => _selectedInputId = value),
                    ),
                  ),
                ),
                if (selected != null) ...[
                  const SizedBox(height: _Z.s16),
                  _ZaraVisibleField(
                    controller: _quantityUsedCtrl,
                    label: 'QUANTITÉ UTILISÉE (${selected['unit'] ?? ''})',
                    hint: 'Ex: 2.5',
                    icon: Icons.scale_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    dark: _dark,
                  ),
                ],
                const SizedBox(height: _Z.s20),
              ],
            );
          },
        ),

        // ── Impact financier (Contrôle & Saisie très visibles) ─────────
        Text('IMPACT FINANCIER (OPTIONNEL)', style: _Z.mono(_sub, size: 10, spacing: 1.5, weight: FontWeight.w600)),
        const SizedBox(height: _Z.s8),
        Container(
          height: 44,
          decoration: BoxDecoration(border: Border.all(color: _border, width: 0.8)),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _financeType = 'expense'),
                  child: Container(
                    color: _financeType == 'expense' ? Colors.red.shade700 : _fieldBg,
                    alignment: Alignment.center,
                    child: Text('DÉPENSE',
                        style: _Z.mono(_financeType == 'expense' ? Colors.white : _sub,
                            size: 11, spacing: 1.5, weight: FontWeight.w600)),
                  ),
                ),
              ),
              Container(width: 0.8, color: _border),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _financeType = 'income'),
                  child: Container(
                    color: _financeType == 'income' ? Colors.green.shade700 : _fieldBg,
                    alignment: Alignment.center,
                    child: Text('REVENU',
                        style: _Z.mono(_financeType == 'income' ? Colors.white : _sub,
                            size: 11, spacing: 1.5, weight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _Z.s14),
        _ZaraVisibleField(
          controller: _financeAmountCtrl,
          label: 'MONTANT DE LA TRANSACTION (FCFA)',
          hint: 'Ex: 15000',
          icon: Icons.payments_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          dark: _dark,
        ),
        const SizedBox(height: _Z.s20),

        // ── Notes (Visible & Confortable) ──────────────────────────────
        _ZaraVisibleField(
          controller: _notesCtrl,
          label: 'NOTES ET OBSERVATIONS',
          hint: 'Écrivez vos remarques, conditions météo, etc...',
          icon: Icons.notes_outlined,
          maxLines: 3,
          dark: _dark,
        ),
        const SizedBox(height: _Z.s20),

        // ── Gallery Preview & Add Photos ────────────────────────────────
        if (_imageBytes.isNotEmpty) ...[
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imageBytes.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: _Z.s8),
                child: Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(border: Border.all(color: _border, width: 0.8)),
                      child: Image.memory(_imageBytes[i], fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _imageFiles.removeAt(i);
                          _imageBytes.removeAt(i);
                        }),
                        child: Container(
                          color: Colors.black.withOpacity(0.7),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: _Z.s12),
        ],

        InkWell(
          onTap: _pickImages,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: _Z.s14),
            decoration: BoxDecoration(color: _fieldBg, border: Border.all(color: _border, width: 0.8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 18, color: _sub),
                const SizedBox(width: _Z.s8),
                Text('AJOUTER DES PHOTOS', style: _Z.mono(_sub, size: 11, spacing: 1.5, weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: _Z.s24),

        // ── Submit Button ───────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _Z.primary,
              elevation: 0,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('ENREGISTRER L\'ACTIVITÉ', style: _Z.mono(Colors.white, size: 11, spacing: 2, weight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ── Tabs Navigation ───────────────────────────────────────────────────────
  Widget _buildTabsBar() {
    final tabs = ['TOUT', 'CULTURE', 'SOINS', 'AUTRES'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _Z.s20, vertical: _Z.s12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _border, width: 0.8))),
      child: Row(
        children: tabs.map((t) {
          final isSelected = _selectedTabCategory == t;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTabCategory = t);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: _Z.s12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? _Z.primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    t,
                    style: _Z.mono(
                      isSelected ? _Z.primary : _sub,
                      size: 10,
                      spacing: 1.2,
                      weight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── History Section ───────────────────────────────────────────────────────
  Widget _buildHistorySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _Z.s20),
      child: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(_Z.s48),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: _Z.primary),
                ),
              ),
            );
          }

          final allActivities = snap.data ?? [];
          
          final activities = allActivities.where((a) {
            if (_selectedTabCategory == 'TOUT') return true;
            final categoryItems = _categories[_selectedTabCategory] ?? [];
            final typeStr = a['activity_type'] ?? '';
            return categoryItems.any((c) => c.value == typeStr);
          }).toList();

          if (activities.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: _Z.s48),
              child: Center(
                child: Text('AUCUNE ACTIVITÉ DANS CETTE CATÉGORIE',
                    style: _Z.mono(_sub, size: 10, spacing: 1.5)),
              ),
            );
          }

          return Column(
            children: activities.map((a) => _buildCard(a as Map<String, dynamic>)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> a) {
    final type = _typeFor(a['activity_type'] ?? '');
    final date = a['activity_date'] != null
        ? DateTime.tryParse(a['activity_date'].toString())
        : null;
    final imgs = (a['image_urls'] as List?) ?? [];
    final financeAmount = (a['finance_amount'] as num?)?.toDouble();
    final financeType = a['finance_type']?.toString();
    final isCreator = !widget.readOnly && a['user_id'] == widget.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: _Z.s12),
      decoration: BoxDecoration(border: Border.all(color: _border, width: 0.8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(_Z.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(_Z.s8),
                  decoration: BoxDecoration(color: type.color.withOpacity(0.12)),
                  child: Icon(type.icon, size: 18, color: type.color),
                ),
                const SizedBox(width: _Z.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(a['activity_type'] ?? '',
                              style: _Z.mono(_text, size: 12, spacing: 1, weight: FontWeight.w600)),
                          if (date != null)
                            Text(_fmt(date), style: _Z.mono(_sub, size: 10, spacing: 0.5)),
                        ],
                      ),
                      if (financeAmount != null && financeAmount > 0 && financeType != null) ...[
                        const SizedBox(height: _Z.s4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: financeType == 'expense' ? Colors.red.shade50 : Colors.green.shade50,
                            border: Border.all(
                                color: financeType == 'expense' ? Colors.red.shade300 : Colors.green.shade300,
                                width: 0.8),
                          ),
                          child: Text(
                            '${financeType == 'expense' ? '-' : '+'} ${_formatActivityAmount(financeAmount)} FCFA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: financeType == 'expense' ? Colors.red.shade800 : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isCreator)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18, color: _sub),
                    color: _bg,
                    elevation: 2,
                    onSelected: (value) {
                      if (value == 'edit') _showEditDialog(a);
                      if (value == 'delete') _showDeleteDialog(a['id']);
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16, color: _text),
                            const SizedBox(width: 8),
                            Text('Modifier', style: _Z.body(_text, size: 13)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
                            const SizedBox(width: 8),
                            Text('Supprimer', style: _Z.body(Colors.red.shade400, size: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          if ((a['notes'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(_Z.s12, 0, _Z.s12, _Z.s12),
              child: Text(a['notes'].toString(), style: _Z.body(_text, size: 13)),
            ),

          if (imgs.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(_Z.s12, 0, _Z.s12, _Z.s12),
                itemCount: imgs.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: _Z.s8),
                  child: ClipRRect(
                    child: Image.network(
                      imgs[i] as String,
                      width: 80,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 68,
                        color: _border,
                        child: Icon(Icons.broken_image_outlined, size: 18, color: _sub),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showEditDialog(Map<String, dynamic> a) {
    HapticFeedback.lightImpact();
    final notesC = TextEditingController(text: a['notes'] ?? '');
    String selType = a['activity_type'] ?? '';
    DateTime? selDate = a['activity_date'] != null
        ? DateTime.tryParse(a['activity_date'].toString())
        : null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => _ZaraDialog(
          dark: _dark,
          title: 'MODIFIER L\'ACTIVITÉ',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TYPE D\'ACTIVITÉ', style: _Z.mono(_sub, size: 9, weight: FontWeight.w600)),
              const SizedBox(height: _Z.s8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: _Z.s12),
                decoration: BoxDecoration(
                  color: _fieldBg,
                  border: Border.all(color: _border, width: 0.8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selType.isNotEmpty ? selType : null,
                    isExpanded: true,
                    dropdownColor: _bg,
                    style: _Z.body(_text, size: 13, weight: FontWeight.w500),
                    items: _categories.values
                        .expand((l) => l)
                        .map((t) => DropdownMenuItem(
                              value: t.value,
                              child: Row(children: [
                                Icon(t.icon, size: 16, color: t.color),
                                const SizedBox(width: _Z.s8),
                                Text(t.label, style: _Z.body(_text, size: 13)),
                              ]),
                            ))
                        .toList(),
                    onChanged: (v) => setS(() => selType = v ?? selType),
                  ),
                ),
              ),
              const SizedBox(height: _Z.s16),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: selDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setS(() => selDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: _Z.s12, vertical: _Z.s12),
                  decoration: BoxDecoration(
                    color: _fieldBg,
                    border: Border.all(color: _border, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 15, color: _sub),
                      const SizedBox(width: _Z.s8),
                      Text(
                        selDate != null ? DateFormat('dd MMM yyyy', 'fr_FR').format(selDate!) : 'SÉLECTIONNER DATE',
                        style: _Z.mono(_text, size: 11, spacing: 1, weight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: _Z.s16),
              _ZaraVisibleField(
                controller: notesC,
                label: 'NOTES',
                hint: 'Modifier les notes...',
                icon: Icons.notes_outlined,
                maxLines: 3,
                dark: _dark,
              ),
            ],
          ),
          onConfirm: () {
            _updateActivity(a['id'] as int, selType, selDate, notesC.text);
            notesC.dispose();
          },
          onCancel: () => notesC.dispose(),
        ),
      ),
    );
  }

  void _showDeleteDialog(dynamic id) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (_) => _ZaraDialog(
        dark: _dark,
        title: 'SUPPRIMER',
        content: Text('Voulez-vous vraiment supprimer cette activité ?', style: _Z.body(_sub, size: 13)),
        confirmLabel: 'SUPPRIMER',
        confirmColor: Colors.red.shade700,
        onConfirm: () => _deleteActivity(id as int),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSANT CHAMP VISIBLE ET CONTRASTÉ
// ─────────────────────────────────────────────────────────────────────────────
class _ZaraVisibleField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;
  final bool dark;

  const _ZaraVisibleField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.dark,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final text = AppColors.getTextColor(dark);
    final sub = AppColors.getSecondaryTextColor(dark);
    final border = AppColors.getBorderColor(dark);
    final fieldBg = dark ? const Color(0xFF1E232A) : const Color(0xFFF4F5F7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _Z.mono(sub, size: 10, spacing: 1.5, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: _Z.body(text, size: 14, weight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: _Z.body(sub.withOpacity(0.6), size: 13),
            prefixIcon: Icon(icon, size: 18, color: sub),
            filled: true,
            fillColor: fieldBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: border, width: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _Z.primary, width: 1.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

class _ZaraDialog extends StatelessWidget {
  final bool dark;
  final String title;
  final Widget content;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final String confirmLabel;
  final Color? confirmColor;

  const _ZaraDialog({
    required this.dark,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.onCancel,
    this.confirmLabel = 'CONFIRMER',
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBgColor(dark);
    final text = AppColors.getTextColor(dark);
    final sub = AppColors.getSecondaryTextColor(dark);
    final border = AppColors.getBorderColor(dark);
    final action = confirmColor ?? text;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 0.8)),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: _Z.mono(text, size: 11, spacing: 2, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(height: 0.8, color: border),
            const SizedBox(height: 16),
            content,
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      onCancel?.call();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: border, width: 0.8)),
                      child: Center(
                        child: Text('ANNULER', style: _Z.mono(sub, size: 10, spacing: 1.5, weight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: action,
                      child: Center(
                        child: Text(confirmLabel, style: _Z.mono(Colors.white, size: 10, spacing: 1.5, weight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}