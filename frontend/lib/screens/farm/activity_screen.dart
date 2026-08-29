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
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s48 = 48.0;

  static const primary = Color(0xFF8B6B4D);
  static const primaryMuted = Color(0xFFA58A6D);

  static TextStyle mono(Color c, {double size = 10, double spacing = 2}) =>
      TextStyle(
          fontSize: size,
          letterSpacing: spacing,
          fontWeight: FontWeight.w400,
          color: c);

  static TextStyle serif(Color c, {double size = 22, double spacing = 1}) =>
      TextStyle(
          fontFamily: 'Georgia',
          fontSize: size,
          letterSpacing: spacing,
          fontWeight: FontWeight.w300,
          color: c);

  static TextStyle body(Color c) => TextStyle(
      fontSize: 13,
      letterSpacing: 0.2,
      fontWeight: FontWeight.w300,
      color: c,
      height: 1.6);
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
    with SingleTickerProviderStateMixin {
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
        vsync: this, duration: const Duration(milliseconds: 250));
    _formFade = CurvedAnimation(parent: _formAnim, curve: Curves.easeOut);
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
              fontSize: 12, letterSpacing: 0.5, color: Colors.white)),
      backgroundColor: error ? AppColors.error : _Z.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
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
      _snack('Saisissez une quantité d\'intrant utilisée', error: true);
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
        _snack('Activité enregistrée');
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

  // ── Colors ────────────────────────────────────────────────────────────────
  Color get _bg => AppColors.getBgColor(_dark);
  Color get _text => AppColors.getTextColor(_dark);
  Color get _sub => AppColors.getSecondaryTextColor(_dark);
  Color get _border => AppColors.getBorderColor(_dark);
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
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + _Z.s24),
                child: Column(
                  children: [
                    if (_canEdit) _buildFormSection(),
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
      padding: const EdgeInsets.symmetric(
          horizontal: _Z.s20, vertical: _Z.s16),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _border, width: 0.5))),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new,
                size: 16, color: _sub),
          ),
          const SizedBox(width: _Z.s20),
          Text('ACTIVITÉS', style: _Z.mono(_text, size: 11, spacing: 3)),
          const Spacer(),
          GestureDetector(
            onTap: _exportTraceability,
            child: Icon(Icons.download_outlined, size: 20, color: _text),
          ),
        ],
      ),
    );
  }

  // ── Form section ──────────────────────────────────────────────────────────
  Widget _buildFormSection() {
    return Container(
      margin: const EdgeInsets.all(_Z.s20),
      decoration: BoxDecoration(
          border: Border.all(color: _border, width: 0.5)),
      child: Column(
        children: [
          // Toggle button
          GestureDetector(
            onTap: _toggleForm,
            child: Padding(
              padding: const EdgeInsets.all(_Z.s16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedRotation(
                    turns: _showForm ? 0.125 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.add, size: 16, color: _text),
                  ),
                  const SizedBox(width: _Z.s12),
                  Text(
                    _showForm
                        ? 'ANNULER'
                        : 'NOUVELLE ACTIVITÉ',
                    style: _Z.mono(_text, size: 10, spacing: 2.5),
                  ),
                ],
              ),
            ),
          ),

          // Form (animated)
          FadeTransition(
            opacity: _formFade,
            child: SizeTransition(
              sizeFactor: _formFade,
              child: _showForm
                  ? Container(
                      decoration: BoxDecoration(
                          border: Border(
                              top: BorderSide(
                                  color: _border, width: 0.5))),
                      padding: const EdgeInsets.all(_Z.s20),
                      child: _buildForm(),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Activity type grid ──────────────────────────────────────────
        ..._categories.entries.map((e) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: _Z.s12),
                  child: Text(e.key,
                      style: _Z.mono(_sub, size: 9, spacing: 2.5)),
                ),
                Wrap(
                  spacing: _Z.s8,
                  runSpacing: _Z.s8,
                  children: e.value.map((t) {
                    final sel = _selectedType == t.value;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedType = t.value);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: _Z.s12, vertical: _Z.s8),
                        decoration: BoxDecoration(
                          color: sel
                              ? t.color.withOpacity(0.15)
                              : t.color.withOpacity(0.05),
                          border: Border.all(
                            color: sel ? t.color : t.color.withOpacity(0.25),
                            width: sel ? 1.5 : 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon,
                                size: 14,
                                color: sel ? t.color : t.color.withOpacity(0.7)),
                            const SizedBox(width: _Z.s8),
                            Text(t.label,
                                style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                    fontWeight: sel ? FontWeight.w500 : FontWeight.w300,
                                    color: sel ? t.color : _text)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: _Z.s20),
              ],
            )),

        // ── Custom type ─────────────────────────────────────────────────
        if (_selectedType == 'Autre') ...[
          _ZaraField(
              controller: _customTypeCtrl,
              label: 'PRÉCISER',
              text: _text,
              sub: _sub,
              border: _border),
          const SizedBox(height: _Z.s20),
        ],

        // ── Date picker ─────────────────────────────────────────────────
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
            padding: const EdgeInsets.symmetric(
                horizontal: 0, vertical: _Z.s12),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: _date != null ? _Z.primary : _border,
                        width: 0.5))),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14,
                    color: _date != null ? _Z.primary : _sub),
                const SizedBox(width: _Z.s12),
                Text(
                  _date != null
                      ? _fmt(_date, p: 'EEEE d MMMM yyyy')
                      : 'DATE',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1,
                      color: _date != null ? _text : _sub),
                ),
                const Spacer(),
                Icon(Icons.chevron_right,
                    size: 16, color: _sub),
              ],
            ),
          ),
        ),
        const SizedBox(height: _Z.s20),

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
                Text('INTRANT UTILISÉ (OPTIONNEL)', style: _Z.mono(_sub, size: 9, spacing: 2.5)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  value: _selectedInputId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Aucun intrant',
                    hintStyle: _Z.body(_sub),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _border, width: 0.5)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _text, width: 0.5)),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Aucun intrant')),
                    ...inputs.map((item) => DropdownMenuItem<int?>(
                          value: item['id'] as int,
                          child: Text('${item['name'] ?? item['input_type'] ?? 'Intrant'} (${item['quantity'] ?? 0} ${item['unit'] ?? ''})'),
                        )),
                  ],
                  onChanged: (value) => setState(() => _selectedInputId = value),
                ),
                if (selected != null) ...[
                  const SizedBox(height: _Z.s12),
                  TextField(
                    controller: _quantityUsedCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: _Z.body(_text),
                    decoration: InputDecoration(
                      labelText: 'QUANTITÉ UTILISÉE (${selected['unit'] ?? ''})',
                      labelStyle: _Z.mono(_sub, size: 9, spacing: 1.5),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _border, width: 0.5)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _text, width: 0.5)),
                    ),
                  ),
                ],
                const SizedBox(height: _Z.s20),
              ],
            );
          },
        ),

        Text('IMPACT FINANCIER (OPTIONNEL)', style: _Z.mono(_sub, size: 9, spacing: 2.5)),
        const SizedBox(height: _Z.s8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _financeType = 'expense'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: _Z.s12),
                  decoration: BoxDecoration(
                    color: _financeType == 'expense' ? Colors.red.withOpacity(0.12) : Colors.transparent,
                    border: Border.all(color: _financeType == 'expense' ? Colors.red.shade300 : _border),
                  ),
                  child: Text('DÉPENSE', textAlign: TextAlign.center, style: _Z.mono(_financeType == 'expense' ? Colors.red.shade700 : _sub, size: 10, spacing: 1.5)),
                ),
              ),
            ),
            const SizedBox(width: _Z.s8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _financeType = 'income'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: _Z.s12),
                  decoration: BoxDecoration(
                    color: _financeType == 'income' ? Colors.green.withOpacity(0.12) : Colors.transparent,
                    border: Border.all(color: _financeType == 'income' ? Colors.green.shade300 : _border),
                  ),
                  child: Text('REVENU', textAlign: TextAlign.center, style: _Z.mono(_financeType == 'income' ? Colors.green.shade700 : _sub, size: 10, spacing: 1.5)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: _Z.s12),
        TextField(
          controller: _financeAmountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: _Z.body(_text),
          decoration: InputDecoration(
            labelText: 'MONTANT (FCFA)',
            labelStyle: _Z.mono(_sub, size: 9, spacing: 1.5),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _border, width: 0.5)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _text, width: 0.5)),
          ),
        ),
        const SizedBox(height: _Z.s20),

        // ── Notes ───────────────────────────────────────────────────────
        TextField(
          controller: _notesCtrl,
          maxLines: 4,
          style: _Z.body(_text),
          decoration: InputDecoration(
            hintText: 'Notes et observations...',
            hintStyle: _Z.body(_sub),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _border, width: 0.5)),
            focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: _text, width: 0.5)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: _Z.s24),

        // ── Image picker ────────────────────────────────────────────────
        if (_imageBytes.isNotEmpty) ...[
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imageBytes.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: _Z.s8),
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration:
                          BoxDecoration(border: Border.all(color: _border, width: 0.5)),
                      child: Image.memory(_imageBytes[i],
                          fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _imageFiles.removeAt(i);
                          _imageBytes.removeAt(i);
                        }),
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(3),
                          child: const Icon(Icons.close,
                              size: 10, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: _Z.s16),
        ],

        GestureDetector(
          onTap: _pickImages,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: _Z.s12),
            decoration: BoxDecoration(
                border: Border.all(color: _border, width: 0.5)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 14, color: _sub),
                const SizedBox(width: _Z.s8),
                Text('AJOUTER PHOTOS',
                    style:
                        _Z.mono(_sub, size: 10, spacing: 2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: _Z.s24),

        // ── Submit ──────────────────────────────────────────────────────
        GestureDetector(
          onTap: _loading ? null : _submit,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: _Z.s16),
            color: _loading ? _Z.primaryMuted : _Z.primary,
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white))
                  : Text('ENREGISTRER',
                      style: _Z.mono(Colors.white,
                          size: 10, spacing: 3)),
            ),
          ),
        ),
      ],
    );
  }

  // ── History section ───────────────────────────────────────────────────────
  Widget _buildHistorySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: _Z.s20, vertical: _Z.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: _Z.s16),
            child: Text('HISTORIQUE',
                style: _Z.mono(_sub, size: 9, spacing: 2.5)),
          ),
          FutureBuilder<List<dynamic>>(
            future: _future,
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(_Z.s48),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 1,
                          color: _Z.primary),
                    ),
                  ),
                );
              }

              final activities = snap.data ?? [];
              if (activities.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: _Z.s48),
                  child: Center(
                    child: Text('AUCUNE ACTIVITÉ',
                        style: _Z.mono(_sub,
                            size: 10, spacing: 2.5)),
                  ),
                );
              }

              return Column(
                children: activities
                    .map((a) => _buildCard(
                        a as Map<String, dynamic>))
                    .toList(),
              );
            },
          ),
        ],
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
    final isCreator =
        !widget.readOnly && a['user_id'] == widget.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: _Z.s12),
      decoration:
          BoxDecoration(border: Border.all(color: _border, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(_Z.s16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color bar
                Container(
                  width: 3,
                  height: 40,
                  decoration: BoxDecoration(
                    color: type.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: const EdgeInsets.only(right: _Z.s12),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(type.icon, size: 13, color: type.color),
                          const SizedBox(width: _Z.s8),
                          Text(a['activity_type'] ?? '',
                              style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w500,
                                  color: type.color)),
                        ],
                      ),
                      if (date != null) ...[
                        const SizedBox(height: _Z.s4),
                        Text(_fmt(date),
                            style: _Z.mono(_sub,
                                size: 10, spacing: 1)),
                      ],
                      if (financeAmount != null && financeAmount > 0 && financeType != null) ...[
                        const SizedBox(height: _Z.s8),
                        Text(
                          '${financeType == 'expense' ? 'DÉPENSE' : 'REVENU'} · ${_formatActivityAmount(financeAmount)} FCFA',
                          style: _Z.mono(financeType == 'expense' ? Colors.red.shade700 : Colors.green.shade700, size: 9, spacing: 1.2),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isCreator)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showEditDialog(a),
                        child: Padding(
                          padding: const EdgeInsets.all(_Z.s4),
                          child: Icon(Icons.edit_outlined,
                              size: 14, color: _sub),
                        ),
                      ),
                      const SizedBox(width: _Z.s8),
                      GestureDetector(
                        onTap: () => _showDeleteDialog(a['id']),
                        child: Padding(
                          padding: const EdgeInsets.all(_Z.s4),
                          child: Icon(Icons.delete_outline,
                              size: 14,
                              color: Colors.red.shade300),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Notes ────────────────────────────────────────────────────
          if ((a['notes'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  _Z.s16 + 14, 0, _Z.s16, _Z.s16),
              child: Text(a['notes'].toString(),
                  style: _Z.body(_text)),
            ),

          // ── Images ───────────────────────────────────────────────────
          if (imgs.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                    _Z.s16, 0, _Z.s16, _Z.s16),
                itemCount: imgs.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: _Z.s8),
                  child: Image.network(imgs[i] as String,
                      width: 90,
                      height: 75,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            width: 90,
                            height: 75,
                            color: _border,
                            child: Icon(
                                Icons.broken_image_outlined,
                                size: 18,
                                color: _sub),
                          )),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatActivityAmount(double amount) =>
      NumberFormat('#,##0', 'fr_FR').format(amount);

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showEditDialog(Map<String, dynamic> a) {
    HapticFeedback.lightImpact();
    final notesC =
        TextEditingController(text: a['notes'] ?? '');
    String selType = a['activity_type'] ?? '';
    DateTime? selDate = a['activity_date'] != null
        ? DateTime.tryParse(a['activity_date'].toString())
        : null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => _ZaraDialog(
          dark: _dark,
          title: 'MODIFIER',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type dropdown
              Text('TYPE', style: _Z.mono(_sub, size: 9)),
              const SizedBox(height: _Z.s8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: _Z.s12, vertical: _Z.s4),
                decoration: BoxDecoration(
                    border: Border.all(color: _border, width: 0.5)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selType.isNotEmpty ? selType : null,
                    isExpanded: true,
                    hint: Text('Sélectionner',
                        style: _Z.body(_sub)),
                    dropdownColor: _bg,
                    style: _Z.body(_text),
                    items: _categories.values
                        .expand((l) => l)
                        .map((t) => DropdownMenuItem(
                              value: t.value,
                              child: Row(children: [
                                Icon(t.icon,
                                    size: 14, color: t.color),
                                const SizedBox(width: _Z.s8),
                                Text(t.label,
                                    style: _Z.body(_text)),
                              ]),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setS(() => selType = v ?? selType),
                  ),
                ),
              ),
              const SizedBox(height: _Z.s16),

              // Date
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
                  padding: const EdgeInsets.symmetric(
                      vertical: _Z.s12),
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: _border, width: 0.5))),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: _sub),
                      const SizedBox(width: _Z.s8),
                      Text(
                        selDate != null
                            ? DateFormat('dd MMM yyyy', 'fr_FR')
                                .format(selDate!)
                            : 'DATE',
                        style: _Z.mono(_text,
                            size: 11, spacing: 1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: _Z.s16),

              // Notes
              TextField(
                controller: notesC,
                maxLines: 3,
                style: _Z.body(_text),
                decoration: InputDecoration(
                  hintText: 'Notes...',
                  hintStyle: _Z.body(_sub),
                  enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: _border, width: 0.5)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: _text, width: 0.5)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          onConfirm: () {
            _updateActivity(
                a['id'] as int, selType, selDate, notesC.text);
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
        content: Text(
            'Cette action est irréversible.',
            style: _Z.body(_sub)),
        confirmLabel: 'SUPPRIMER',
        confirmColor: Colors.red.shade700,
        onConfirm: () => _deleteActivity(id as int),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _ZaraField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color text, sub, border;
  final TextInputType type;
  final bool obscure;

  const _ZaraField({
    required this.controller,
    required this.label,
    required this.text,
    required this.sub,
    required this.border,
    this.type = TextInputType.text,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      style: TextStyle(
          fontSize: 13,
          letterSpacing: 0.3,
          color: text,
          fontWeight: FontWeight.w300),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(fontSize: 10, letterSpacing: 2, color: sub),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: border, width: 0.5)),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: text, width: 1)),
      ),
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
        decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 0.5)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 3,
                    color: text)),
            const SizedBox(height: 6),
            Container(height: 0.5, color: border),
            const SizedBox(height: 20),
            content,
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      onCancel?.call();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: border, width: 0.5)),
                      child: Center(
                        child: Text('ANNULER',
                            style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 2,
                                color: sub)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      color: action,
                      child: Center(
                        child: Text(confirmLabel,
                            style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 2,
                                color: Colors.white)),
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