import 'package:flutter_test/flutter_test.dart';
import 'package:mbaymi/services/traceability_export_service.dart';

void main() {
  group('TraceabilityExportService', () {
    test('normalizes initial and remaining quantities for stock exports', () {
      final row = {
        'name': 'Engrais NPK',
        'quantity': 120.0,
        'quantity_used': 35.0,
      };

      final normalized = TraceabilityExportService.normalizeQuantityFields(row);

      expect(normalized['initial_quantity'], 155.0);
      expect(normalized['remaining_quantity'], 120.0);
      expect(normalized.containsKey('current_quantity'), isFalse);
      expect(normalized['quantity_used'], 35.0);
    });

    test('keeps translated labels in French for stock fields', () {
      expect(TraceabilityExportService.cleanKey('initial_quantity'), 'Quantité initiale');
      expect(TraceabilityExportService.cleanKey('current_quantity'), 'Quantité actuelle');
      expect(TraceabilityExportService.cleanKey('remaining_quantity'), 'Quantité restante');
      expect(TraceabilityExportService.cleanKey('quantity_used'), 'Quantité utilisée');
    });

    test('removes duplicate current and remaining stock entries when both are identical', () {
      final row = {
        'quantity': 30.0,
        'remaining_quantity': 30.0,
      };

      final normalized = TraceabilityExportService.normalizeQuantityFields(row);

      expect(normalized.containsKey('current_quantity'), isFalse);
      expect(normalized['remaining_quantity'], 30.0);
    });

    test('formats negative net profit as a loss, not a gain', () {
      final row = {'total_expenses': 7000.0, 'total_income': 3000.0, 'net_profit': -4000.0};
      final cleaned = TraceabilityExportService.sanitizeRow(row);

      expect(cleaned['Dépenses totales'], '7000 FCFA');
      expect(cleaned['Revenus totaux'], '3000 FCFA');
      expect(cleaned['Bénéfice net'], 'Perte nette: 4000 FCFA');
    });

    test('formats money values using the selected currency code', () {
      expect(TraceabilityExportService.formatCurrencyValue(700, 'FCFA'), '700 FCFA');
      expect(TraceabilityExportService.formatCurrencyValue(700, 'USD'), '700 USD');
      expect(TraceabilityExportService.formatCurrencyValue(700, null), '700 FCFA');
    });

    test('formats activity quantity with product and unit', () {
      final value = TraceabilityExportService.buildActivityQuantityLabel(
        quantity: 100,
        unit: 'kg',
        productName: 'Tomate',
      );

      expect(value, '100 kg de tomate');
    });
  });
}
