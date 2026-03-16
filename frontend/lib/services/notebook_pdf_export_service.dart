import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/project_notebook_model.dart';

class NotebookPdfExportService {
  /// Générer un PDF et l'ouvrir
  static Future<void> exportToPdf(ProjectNotebook notebook) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          // En-tête avec titre
          pw.Container(
            padding: pw.EdgeInsets.only(bottom: 24),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 2)),
              color: PdfColor.fromHex('#f5f5f5'),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  notebook.title,
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1B5E20'),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  notebook.description,
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Catégorie: ${notebook.category.toUpperCase()}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Créé: ${_formatDate(notebook.createdAt)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                if (notebook.tags.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Wrap(
                    spacing: 8,
                    children: notebook.tags
                        .map((tag) => pw.Container(
                          padding: pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#C8E6C9'),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            tag,
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColor.fromHex('#1B5E20'),
                            ),
                          ),
                        ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Contenu des sections
          ...notebook.sections.map((section) => pw.Column(
            children: [
              pw.Text(
                section.title,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#2E7D32'),
                ),
              ),
              pw.SizedBox(height: 12),
              ...section.contents.map((content) => _buildContentWidget(content)),
              pw.SizedBox(height: 16),
            ],
          )),

          // Commentaires
          if (notebook.comments.isNotEmpty) ...[
            pw.Divider(),
            pw.SizedBox(height: 16),
            pw.Text(
              'Commentaires',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#2E7D32'),
              ),
            ),
            pw.SizedBox(height: 12),
            ...notebook.comments.map((comment) => pw.Container(
              padding: pw.EdgeInsets.all(12),
              margin: pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#f9f9f9'),
                border: pw.Border(
                  left: pw.BorderSide(
                    color: PdfColor.fromHex('#4CAF50'),
                    width: 3,
                  ),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        comment.userName,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      pw.Text(
                        _formatDate(comment.createdAt),
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    comment.text,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            )),
          ],

          // Pied de page
          pw.SizedBox(height: 32),
          pw.Container(
            padding: pw.EdgeInsets.only(top: 16),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Mbaymi - Cahier de projet agricole',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'Généré le ${_formatDate(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Ouvrir le PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// Générer et sauvegarder le PDF localement
  static Future<void> savePdfLocally(
    ProjectNotebook notebook,
    String filePath,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Container(
            padding: pw.EdgeInsets.only(bottom: 24),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 2)),
              color: PdfColor.fromHex('#f5f5f5'),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  notebook.title,
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1B5E20'),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  notebook.description,
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          ...notebook.sections.map((section) => pw.Column(
            children: [
              pw.Text(section.title),
              ...section.contents.map((content) => _buildContentWidget(content)),
            ],
          )),
        ],
      ),
    );

    // Sauvegarder le fichier PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${notebook.title}.pdf',
    );
  }

  /// Widget pour afficher le contenu dans le PDF
  static pw.Widget _buildContentWidget(NoteContent content) {
    switch (content.type) {
      case 'text':
        return pw.Container(
          margin: pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            content.content,
            style: const pw.TextStyle(fontSize: 11),
            textAlign: pw.TextAlign.left,
          ),
        );

      case 'title':
        return pw.Container(
          margin: pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            content.content,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#2E7D32'),
            ),
          ),
        );

      case 'heading':
        return pw.Container(
          margin: pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            content.content,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#558B2F'),
            ),
          ),
        );

      case 'list':
        final items = content.content.split('\n').where((l) => l.isNotEmpty);
        return pw.Container(
          margin: pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: items
                .map((item) => pw.Row(
              children: [
                pw.Container(
                  margin: pw.EdgeInsets.only(right: 8),
                  child: pw.Text('•'),
                ),
                pw.Expanded(child: pw.Text(item)),
              ],
            ))
                .toList(),
          ),
        );

      case 'quote':
        return pw.Container(
          padding: pw.EdgeInsets.all(12),
          margin: pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(
                color: PdfColor.fromHex('#558B2F'),
                width: 3,
              ),
            ),
            color: PdfColor.fromHex('#f1f8e9'),
          ),
          child: pw.Text(
            content.content,
            style: pw.TextStyle(
              fontSize: 11,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        );

      case 'code':
        return pw.Container(
          padding: pw.EdgeInsets.all(12),
          margin: pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#f5f5f5'),
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.Text(
            content.content,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
        );

      default:
        return pw.Container();
    }
  }

  static String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
