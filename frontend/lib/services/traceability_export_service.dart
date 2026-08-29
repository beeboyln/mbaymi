import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'theme_provider.dart';

class TraceabilitySection {
  final String title;
  final List<Map<String, dynamic>> rows;

  const TraceabilitySection({required this.title, required this.rows});
}

class TraceabilityExportService {
  // Couleurs de la charte graphique
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF2D5A27); // Vert forêt / agricole
  static const PdfColor primaryLight = PdfColor.fromInt(0xFFF4F7F4);
  static const PdfColor textColor = PdfColor.fromInt(0xFF2D3748);
  static const PdfColor textMuted = PdfColor.fromInt(0xFF718096);
  static const PdfColor borderColor = PdfColor.fromInt(0xFFE2E8F0);

  static Future<void> showExportMenu({
    required BuildContext context,
    required String title,
    required Future<List<TraceabilitySection>> Function() loadSections,
  }) async {
    final format = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF2D5A27)),
              title: const Text('Télécharger en PDF (Format Pro)'),
              onTap: () => Navigator.pop(sheetContext, 'pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined, color: Color(0xFF2D5A27)),
              title: const Text('Télécharger en Word (.doc)'),
              onTap: () => Navigator.pop(sheetContext, 'word'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (format == null || !context.mounted) return;

    try {
      final sections = await loadSections();
      if (format == 'pdf') {
        await _sharePdf(title, sections);
      } else {
        await _shareWord(title, sections);
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export impossible : $error')),
      );
    }
  }

  static Future<String> getCurrencyCode() async {
    return AppCurrencyService.getCurrency();
  }

  static String formatCurrencyValue(dynamic value, String? currencyOverride) {
    final amount = _parseNumericValue(value) ?? 0;
    final code = (currencyOverride == null || currencyOverride.trim().isEmpty)
        ? AppCurrencyService.defaultCurrency
        : currencyOverride.trim().toUpperCase();
    return '${_formatAmount(amount)} $code';
  }

  static String buildActivityQuantityLabel({
    required dynamic quantity,
    String? unit,
    String? productName,
  }) {
    final numeric = _parseNumericValue(quantity);
    if (numeric == null) return '';

    final cleanUnit = (unit ?? '').toString().trim();
    final cleanProduct = (productName ?? '').toString().trim();
    final normalizedProduct = cleanProduct.isEmpty ? '' : cleanProduct.toLowerCase();

    if (cleanUnit.isNotEmpty && normalizedProduct.isNotEmpty) {
      return '${_formatAmount(numeric)} $cleanUnit de $normalizedProduct';
    }
    if (cleanUnit.isNotEmpty) {
      return '${_formatAmount(numeric)} $cleanUnit';
    }
    if (normalizedProduct.isNotEmpty) {
      return '${_formatAmount(numeric)} de $normalizedProduct';
    }
    return _formatAmount(numeric);
  }

  static List<Map<String, dynamic>> enrichActivityRows({
    required List<Map<String, dynamic>> activities,
    required List<dynamic> inputs,
  }) {
    final inputById = <int, Map<String, dynamic>>{};
    for (final rawInput in inputs) {
      if (rawInput is! Map) continue;
      final input = Map<String, dynamic>.from(rawInput as Map);
      final id = input['id'];
      if (id is int) inputById[id] = input;
    }

    return activities.map((activity) {
      final row = Map<String, dynamic>.from(activity);
      final inputId = row['input_id'];
      final quantityValue = row['quantity_used'];
      final quantity = _parseNumericValue(quantityValue);

      if (quantity != null && inputId is int && inputById.containsKey(inputId)) {
        final input = inputById[inputId]!;
        final productName = (input['name'] ?? input['input_type'] ?? 'Intrant').toString().trim();
        final unit = (input['unit'] ?? '').toString().trim();
        row['quantity_used'] = buildActivityQuantityLabel(
          quantity: quantity,
          unit: unit,
          productName: productName,
        );
      } else if (quantity != null) {
        row['quantity_used'] = buildActivityQuantityLabel(
          quantity: quantity,
          unit: (row['unit'] ?? '').toString().trim(),
          productName: (row['input_name'] ?? row['product_name'] ?? row['name'] ?? '').toString().trim(),
        );
      }
      return row;
    }).toList();
  }

  static Future<void> _sharePdf(
    String title,
    List<TraceabilitySection> sections,
  ) async {
    final currencyCode = await getCurrencyCode();
    final cleanedSections = sections.map((section) => _sanitizeSection(section, currencyCode: currencyCode)).toList();
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),

        // En-tête de chaque page
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          padding: const pw.EdgeInsets.only(bottom: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 0.8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'MBAYMI · TRAÇABILITÉ AGRICOLE',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 1.0,
                ),
              ),
              pw.Text(
                'DOCUMENT OFFICIEL',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        // Pied de page dynamique
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 16),
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: borderColor, width: 0.8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Généré le ${_date(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 8, color: textMuted),
              ),
              pw.Text(
                'Page ${context.pageNumber} / ${context.pagesCount}',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),

        // Corps du document
        build: (context) => [
          // En-tête du document
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: primaryLight,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: primaryColor, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DOCUMENT DE TRAÇABILITÉ',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Liste des sections
          ...cleanedSections.expand((section) => _buildPdfSection(section)),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await document.save(),
      filename: '${_safeName(title)}.pdf',
    );
  }

  static List<pw.Widget> _buildPdfSection(TraceabilitySection section) {
    final entries = section.rows.expand((row) => row.entries).toList();
    final summaryLine = _summarizeSection(section);

    return [
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 12, bottom: 8),
        padding: const pw.EdgeInsets.only(left: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(left: pw.BorderSide(color: primaryColor, width: 3)),
        ),
        child: pw.Text(
          section.title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ),
      if (summaryLine.isNotEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            summaryLine,
            style: pw.TextStyle(
              fontSize: 8,
              color: textMuted,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
      if (entries.isEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Text(
            'Aucune donnée enregistrée.',
            style: pw.TextStyle(
              fontSize: 9,
              color: textMuted,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        )
      else
        pw.Table(
          border: pw.TableBorder.all(color: borderColor, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(4),
            1: pw.FlexColumnWidth(6),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: primaryColor),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: pw.Text(
                    'DÉTAIL',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: pw.Text(
                    'VALEUR',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  ),
                ),
              ],
            ),
            ...entries.asMap().entries.map((entryIndex) {
              final isEven = entryIndex.key % 2 == 0;
              final entry = entryIndex.value;

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: isEven ? PdfColors.white : PdfColor.fromInt(0xFFF8FAFC),
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: pw.Text(
                      entry.key,
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF4A5568),
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: pw.Text(
                      _value(entry.value),
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      pw.SizedBox(height: 14),
    ];
  }

  static String _summarizeSection(TraceabilitySection section) {
    final entries = section.rows.expand((row) => row.entries).toList();
    if (entries.isEmpty) return '';

    final parcel = section.rows.firstWhere(
      (row) => row.containsKey('Parcelle') || row.containsKey('Culture') || row.containsKey('Ferme'),
      orElse: () => const <String, dynamic>{},
    );

    final labels = <String>[];
    for (final entry in parcel.entries) {
      final key = entry.key;
      if (key == 'Parcelle' || key == 'Culture' || key == 'Ferme') {
        labels.add('${entry.key} : ${_value(entry.value)}');
      }
    }

    final suffix = labels.isNotEmpty ? ' • ${labels.join(' • ')}' : '';
    return ' ${entries.length} élément${entries.length > 1 ? 's' : ''} enregistré${entries.length > 1 ? 's' : ''}$suffix';
  }

  static Future<void> _shareWord(
    String title,
    List<TraceabilitySection> sections,
  ) async {
    final currencyCode = await getCurrencyCode();
    final cleanedSections = sections.map((section) => _sanitizeSection(section, currencyCode: currencyCode)).toList();
    final html = StringBuffer()
      ..writeln('<!doctype html><html><head><meta charset="utf-8">')
      ..writeln('<style>')
      ..writeln('body { font-family: Arial, sans-serif; color: #2D3748; padding: 20px; }')
      ..writeln('h1 { color: #2D5A27; font-size: 20px; border-bottom: 2px solid #2D5A27; padding-bottom: 5px; }')
      ..writeln('h2 { color: #2D5A27; font-size: 14px; margin-top: 20px; margin-bottom: 8px; }')
      ..writeln('.meta { color: #718096; font-size: 11px; font-style: italic; margin: 0 0 10px 0; }')
      ..writeln('table { width: 100%; border-collapse: collapse; margin-bottom: 15px; }')
      ..writeln('th { background-color: #2D5A27; color: white; padding: 8px; font-size: 11px; text-align: left; }')
      ..writeln('td { padding: 8px; font-size: 11px; border: 1px solid #E2E8F0; vertical-align: top; }')
      ..writeln('tr:nth-child(even) { background-color: #F8FAFC; }')
      ..writeln('</style></head><body>')
      ..writeln('<h1>${_escape(title)}</h1>')
      ..writeln('<p style="color: #718096; font-size: 11px;">Document de traçabilité · Généré le ${_date(DateTime.now())}</p>');

    for (final section in cleanedSections) {
      html.writeln('<h2>${_escape(section.title)}</h2>');
      final summary = _summarizeSection(section);
      if (summary.isNotEmpty) {
        html.writeln('<p class="meta">${_escape(summary.trim())}</p>');
      }
      html.writeln('<table>');
      html.writeln('<thead><tr><th style="width: 40%;">Détail</th><th>Valeur</th></tr></thead><tbody>');

      for (final row in section.rows) {
        for (final entry in row.entries) {
          html.writeln('<tr><td><b>${_escape(entry.key)}</b></td><td>${_escape(_value(entry.value))}</td></tr>');
        }
      }
      html.writeln('</tbody></table>');
    }
    html.writeln('</body></html>');

    await Share.shareXFiles([
      XFile.fromData(
        Uint8List.fromList(utf8.encode(html.toString())),
        name: '${_safeName(title)}.doc',
        mimeType: 'application/msword',
      ),
    ], subject: title);
  }

  static TraceabilitySection _sanitizeSection(TraceabilitySection section, {String? currencyCode}) {
    return TraceabilitySection(
      title: _cleanSectionTitle(section.title),
      rows: section.rows
          .map((row) => _sanitizeRow(row, currencyCode: currencyCode))
          .where((row) => row.isNotEmpty)
          .toList(),
    );
  }

  static Map<String, dynamic> normalizeQuantityFields(Map<String, dynamic> row) {
    final normalized = Map<String, dynamic>.from(row);

    final currentQuantity = _parseNumericValue(
      normalized['quantity'] ??
          normalized['current_quantity'] ??
          normalized['current'] ??
          normalized['stock_quantity'] ??
          normalized['remaining_quantity'] ??
          normalized['available_quantity'],
    );

    final usedQuantity = _parseNumericValue(
      normalized['quantity_used'] ??
          normalized['used_quantity'] ??
          normalized['consumed_quantity'] ??
          normalized['used'],
    );

    final initialQuantity = _parseNumericValue(
      normalized['initial_quantity'] ??
          normalized['initial_stock'] ??
          normalized['starting_quantity'] ??
          normalized['initial'],
    );

    final computedInitial = initialQuantity ??
        ((currentQuantity != null && usedQuantity != null) ? currentQuantity + usedQuantity : null);

    if (computedInitial != null && !normalized.containsKey('initial_quantity')) {
      normalized['initial_quantity'] = computedInitial;
    }

    if (currentQuantity != null && !normalized.containsKey('remaining_quantity')) {
      normalized['remaining_quantity'] = currentQuantity;
    }

    if (currentQuantity != null && normalized.containsKey('remaining_quantity') &&
        (normalized['remaining_quantity'] is num) &&
        normalized['remaining_quantity'].toDouble() == currentQuantity) {
      normalized.remove('current_quantity');
    } else if (currentQuantity != null && !normalized.containsKey('current_quantity')) {
      normalized['current_quantity'] = currentQuantity;
    }

    if (normalized.containsKey('quantity') && !normalized.containsKey('initial_quantity') && usedQuantity != null) {
      normalized['initial_quantity'] = (currentQuantity ?? 0) + usedQuantity;
    }

    return normalized;
  }

  static Map<String, dynamic> _sanitizeRow(Map<String, dynamic> row, {String? currencyCode}) {
    final normalized = normalizeQuantityFields(row);
    final cleaned = <String, dynamic>{};
    final effectiveCurrency = (currencyCode == null || currencyCode.trim().isEmpty)
        ? AppCurrencyService.defaultCurrency
        : currencyCode.trim().toUpperCase();
    for (final entry in normalized.entries) {
      final rawKey = entry.key.toString();
      final label = cleanKey(rawKey);
      final value = _cleanValue(entry.value, rawKey, currencyCode: effectiveCurrency);
      if (label.isEmpty || value == null || value.toString().trim().isEmpty) {
        continue;
      }
      cleaned[label] = value;
    }
    return cleaned;
  }

  static Map<String, dynamic> sanitizeRow(Map<String, dynamic> row, {String? currencyCode}) => _sanitizeRow(row, currencyCode: currencyCode);

  static String cleanKey(String key) => _cleanKey(key);

  static String _cleanSectionTitle(String title) {
    final cleaned = title
        .replaceAll(RegExp(r'\s*[-·]\s*.*\$'), '')
        .trim();
    if (cleaned.isEmpty) return 'Parcelle';
    return cleaned;
  }

  static String _cleanKey(String key) {
    final raw = key.toString().trim();
    if (raw.isEmpty) return '';

    final expanded = raw.replaceAllMapped(
      RegExp(r'(?<=[a-z0-9])(?=[A-Z])'),
      (_) => ' ',
    );

    final lowercase = expanded.toLowerCase();
    if (lowercase.contains('id') ||
        lowercase.contains('image') ||
        lowercase.contains('photo') ||
        lowercase.contains('cloudinary') ||
        lowercase.contains('url') ||
        lowercase.contains('file') ||
        lowercase.contains('lat') ||
        lowercase.contains('lng') ||
        lowercase.contains('longitude') ||
        lowercase.contains('latitude') ||
        lowercase.contains('coordinates') ||
        lowercase.contains('geo') ||
        lowercase.contains('map')) {
      return '';
    }

    final friendly = expanded
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final labels = {
      'farm name': 'Ferme',
      'crop name': 'Parcelle',
      'parcelle': 'Parcelle',
      'culture': 'Culture',
      'crop': 'Culture',
      'name': 'Nom',
      'title': 'Titre',
      'type': 'Type',
      'activity type': 'Type d\'activité',
      'activity_type': 'Type d\'activité',
      'input type': 'Type d\'intrant',
      'input type': 'Type d\'intrant',
      'transaction type': 'Type de transaction',
      'transaction type': 'Type de transaction',
      'category': 'Catégorie',
      'amount': 'Montant',
      'total expenses': 'Total des dépenses',
      'total income': 'Total des revenus',
      'net profit': 'Bénéfice net',
      'quantity': 'Quantité',
      'current quantity': 'Quantité actuelle',
      'current_quantity': 'Quantité actuelle',
      'remaining quantity': 'Quantité restante',
      'remaining_quantity': 'Quantité restante',
      'initial quantity': 'Quantité initiale',
      'initial_quantity': 'Quantité initiale',
      'initial stock': 'Quantité initiale',
      'stock quantity': 'Quantité actuelle',
      'available quantity': 'Quantité disponible',
      'quantity used': 'Quantité utilisée',
      'quantity_used': 'Quantité utilisée',
      'used quantity': 'Quantité utilisée',
      'unit': 'Unité',
      'cost': 'Coût',
      'notes': 'Notes',
      'status': 'Statut',
      'date': 'Date',
      'activity date': 'Date d\'activité',
      'transaction date': 'Date de transaction',
      'created at': 'Créé le',
      'updated at': 'Mis à jour le',
      'location': 'Localisation',
      'address': 'Localisation',
      'village': 'Village',
      'district': 'Quartier',
      'city': 'Ville',
      'region': 'Région',
      'province': 'Province',
      'country': 'Pays',
      'description': 'Description',
      'problem type': 'Type de problème',
      'severity': 'Niveau',
      'diagnosis': 'Diagnostic',
      'treatment': 'Traitement',
      'observations': 'Observations',
      'farm': 'Ferme',
      'user name': 'Utilisateur',
      'email': 'Email',
      'phone': 'Téléphone',
      'full name': 'Nom complet',
      'total followers': 'Abonnés',
      'total posts': 'Publications',
      'applied date': 'Date d\'application',
      'reorder threshold': 'Seuil de réapprovisionnement',
      'remind at': 'Rappel prévu',
      'is done': 'Terminé',
      'notification sent': 'Notification envoyée',
      'repeat rule': 'Répétition',
      'finance type': 'Type de financement',
      'finance amount': 'Montant',
      'problem type': 'Type de problème',
      'total expenses': 'Dépenses totales',
      'total income': 'Revenus totaux',
      'net profit': 'Bénéfice net',
      'quantity used': 'Quantité utilisée',
      'type de transaction': 'Type de transaction',
    };

    final keyToUse = friendly.toLowerCase();
    return labels[keyToUse] ?? _capitalizeWords(friendly);
  }

  static String _capitalizeWords(String value) {
    if (value.isEmpty) return '';
    return value
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static double? _parseNumericValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value.toString().replaceAll(',', '.'));
    return parsed;
  }

  static dynamic _cleanValue(dynamic value, String key, {String? currencyCode}) {
    if (value == null) return null;

    if (value is DateTime) return _date(value);
    if (value is bool) return _translateBoolean(value);
    if (value is Iterable && value is! String) {
      final values = value
          .map((item) => _stringifyScalar(item))
          .where((item) => item.isNotEmpty)
          .toList();
      return values.isEmpty ? null : values.join(', ');
    }
    if (value is Map) {
      final values = value.entries
          .map((entry) => '${_cleanKey(entry.key.toString())}: ${_stringifyScalar(entry.value)}')
          .where((entry) => entry.isNotEmpty)
          .toList();
      return values.isEmpty ? null : values.join(', ');
    }

    final text = _stringifyScalar(value);
    if (text.isEmpty) return null;

    final normalizedKey = key.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');

    if (normalizedKey.contains('location') || normalizedKey.contains('address')) {
      return _shortLocation(text);
    }

    if (normalizedKey.contains('net profit')) {
      final numeric = _parseNumericValue(text);
      final code = (currencyCode == null || currencyCode.trim().isEmpty)
          ? AppCurrencyService.defaultCurrency
          : currencyCode.trim().toUpperCase();
      if (numeric != null) {
        if (numeric < 0) return 'Perte nette: ${_formatAmount(numeric.abs())} $code';
        if (numeric > 0) return 'Bénéfice net: ${_formatAmount(numeric)} $code';
        return '0 $code';
      }
    }

    if (normalizedKey.contains('amount') ||
        normalizedKey.contains('cost') ||
        normalizedKey.contains('total expenses') ||
        normalizedKey.contains('total income') ||
        normalizedKey.contains('finance') ||
        normalizedKey.contains('montant')) {
      final code = (currencyCode == null || currencyCode.trim().isEmpty)
          ? AppCurrencyService.defaultCurrency
          : currencyCode.trim().toUpperCase();
      final numeric = _parseNumericValue(text);
      if (numeric != null) return '${_formatAmount(numeric)} $code';
    }

    if (normalizedKey.contains('date') || normalizedKey.contains('created') || normalizedKey.contains('updated') || normalizedKey.contains('remind') || normalizedKey.contains('due')) {
      final parsed = DateTime.tryParse(text);
      if (parsed != null) return _date(parsed);
    }

    if (_looksLikeBoolean(text)) return _translateBooleanText(text);

    final translated = _translateValueText(text);
    return _truncate(translated, 140);
  }

  static String _stringifyScalar(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) return _date(value);
    if (value is num) {
      final number = value.toDouble();
      if (number % 1 == 0) return number.toInt().toString();
      return number.toStringAsFixed(2).replaceAll('.', ',');
    }
    final text = value.toString().trim();
    if (text.isEmpty) return '';
    if (text.startsWith('http://') || text.startsWith('https://')) return '';
    if (text.contains('cloudinary')) return '';
    if (text.contains('lat') && (text.contains('lng') || text.contains('lon'))) return '';
    return text;
  }

  static bool _looksLikeBoolean(String value) {
    final lower = value.toLowerCase();
    return lower == 'true' || lower == 'false' || lower == 'yes' || lower == 'no';
  }

  static String _translateBoolean(bool value) => value ? 'Oui' : 'Non';

  static String _translateBooleanText(String value) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == 'yes') return 'Oui';
    if (lower == 'false' || lower == 'no') return 'Non';
    return value;
  }

  static String _translateValueText(String value) {
    final lowered = value.toLowerCase().trim();
    if (lowered.isEmpty) return '';

    final translations = {
      'expense': 'Dépense',
      'income': 'Revenu',
      'semis': 'Semis',
      'plantation': 'Plantation',
      'harvest': 'Récolte',
      'fertilisation': 'Fertilisation',
      'irrigation': 'Irrigation',
      'treatment': 'Traitement',
      'inspection': 'Inspection',
      'maintenance': 'Entretien',
      'follow up': 'Suivi',
      'followup': 'Suivi',
      'poor_yield': 'Faible rendement',
      'yellowing': 'Jaunissement',
      'rot': 'Pourriture',
      'disease': 'Maladie',
      'resolved': 'Résolu',
      'pending': 'En attente',
      'high': 'Élevé',
      'medium': 'Moyen',
      'low': 'Faible',
      'healthy': 'Sain',
      'sick': 'Malade',
      'treated': 'Traité',
      'vaccinated': 'Vacciné',
      'isolated': 'Isolé',
      'male': 'Mâle',
      'female': 'Femelle',
      'cattle': 'Bovins',
      'goat': 'Chèvres',
      'sheep': 'Moutons',
      'pig': 'Porcs',
      'poultry': 'Volailles',
      'horse': 'Chevaux',
      'donkey': 'Ânes',
      'daily': 'Tous les jours',
      'weekly': 'Chaque semaine',
      'monthly': 'Chaque mois',
      'none': 'Aucune',
      'true': 'Oui',
      'false': 'Non',
    };

    final translated = translations[lowered];
    if (translated != null) return translated;

    return value
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _shortLocation(String value) {
    final normalized = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\bhttps?://\S+'), '')
        .trim();
    if (normalized.isEmpty) return '';
    if (normalized.length <= 80) return normalized;
    return '${normalized.substring(0, 80).trim()}...';
  }

  static String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength - 3).trim()}...';
  }

  static String _formatAmount(num value) {
    final rounded = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
    return rounded.replaceAll('.', ',');
  }

  static String _value(dynamic value) {
    if (value == null) return '-';
    if (value is DateTime) return _date(value);
    return _truncate(value.toString(), 140);
  }

  static String _date(DateTime date) => DateFormat('dd/MM/yyyy HH:mm').format(date);

  static String _safeName(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  static String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}