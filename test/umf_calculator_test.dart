import 'package:flutter_test/flutter_test.dart';
import 'package:glazevault/core/chemistry/umf_calculator.dart';
import 'package:glazevault/core/materials/material_model.dart';
import 'package:glazevault/features/recipes/recipe_models.dart';

// Synthetic materials with simple, exact analyses so the expected UMF can be
// computed by hand. Molecular weights: SiO2 60.08, Al2O3 101.96, CaO 56.08.
const _silica = MaterialModel(
  name: 'Test Silica',
  oxides: [OxideAnalysis(oxideName: 'SiO2', analysis: 100)],
  oxidesWeight: 100,
  description: '',
  hazardous: false,
);

// Whiting (CaCO3): 56.08% CaO, rest LOI — LOI must be ignored.
const _whiting = MaterialModel(
  name: 'Test Whiting',
  oxides: [
    OxideAnalysis(oxideName: 'CaO', analysis: 56.08),
    OxideAnalysis(oxideName: 'LOI', analysis: 43.92),
  ],
  oxidesWeight: 100,
  description: '',
  hazardous: false,
);

// Theoretical kaolin: Al2O3·2SiO2·2H2O.
const _kaolin = MaterialModel(
  name: 'Test Kaolin',
  oxides: [
    OxideAnalysis(oxideName: 'Al2O3', analysis: 39.5),
    OxideAnalysis(oxideName: 'SiO2', analysis: 46.55),
    OxideAnalysis(oxideName: 'LOI', analysis: 13.95),
  ],
  oxidesWeight: 100,
  description: '',
  hazardous: false,
);

const _database = [_silica, _whiting, _kaolin];

RecipeIngredient _ing(String name, double pct) =>
    RecipeIngredient(name: name, percentage: pct);

void main() {
  group('calculateUmf', () {
    test('returns null for an empty recipe', () {
      expect(calculateUmf([], _database), isNull);
    });

    test('returns null when the recipe has no flux oxides', () {
      final result = calculateUmf([_ing('Test Silica', 100)], _database);
      expect(result, isNull);
    });

    test('normalizes flux oxides to unity', () {
      final result = calculateUmf(
        [_ing('Test Whiting', 30), _ing('Test Silica', 70)],
        _database,
      )!;
      final fluxSum = (result.oxides['CaO'] ?? 0) +
          (result.oxides['Na2O'] ?? 0) +
          (result.oxides['K2O'] ?? 0);
      expect(fluxSum, closeTo(1.0, 1e-9));
    });

    test('computes the documented 50/50 whiting-silica formula', () {
      // 50g whiting → 50 * 0.5608 = 28.04g CaO → 0.5 mol CaO
      // 50g silica  → 50g SiO2 → 50 / 60.08 = 0.83222 mol SiO2
      // UMF: CaO 1.0, SiO2 0.83222 / 0.5 = 1.66445
      final result = calculateUmf(
        [_ing('Test Whiting', 50), _ing('Test Silica', 50)],
        _database,
      )!;
      expect(result.oxides['CaO'], closeTo(1.0, 1e-6));
      expect(result.si, closeTo(1.66445, 1e-4));
      expect(result.complete, isTrue);
    });

    test('LOI does not contribute to the formula', () {
      final result = calculateUmf(
        [_ing('Test Whiting', 50), _ing('Test Silica', 50)],
        _database,
      )!;
      expect(result.oxides.containsKey('LOI'), isFalse);
    });

    test('flags the result incomplete when a material is unknown', () {
      final result = calculateUmf(
        [_ing('Test Whiting', 50), _ing('No Such Material', 50)],
        _database,
      )!;
      expect(result.complete, isFalse);
    });

    test('alumina from kaolin shows up in the formula', () {
      final result = calculateUmf(
        [
          _ing('Test Whiting', 20),
          _ing('Test Kaolin', 30),
          _ing('Test Silica', 50),
        ],
        _database,
      )!;
      expect(result.al, greaterThan(0));
      expect(result.siAl, greaterThan(0));
    });
  });

  group('umfZone', () {
    UmfResult umf(double si, double al) => UmfResult(
          oxides: {'SiO2': si, 'Al2O3': al},
          fluxTotal: 1,
          complete: true,
        );

    test('low silica is underfired', () {
      expect(umfZone(umf(1.5, 0.3)), GlazeZone.underfired);
    });

    test('low alumina is running', () {
      expect(umfZone(umf(3.0, 0.1)), GlazeZone.running);
    });

    test('high alumina is matte', () {
      expect(umfZone(umf(2.5, 0.6)), GlazeZone.matte);
    });

    test('balanced glaze is glossy', () {
      expect(umfZone(umf(3.5, 0.35)), GlazeZone.glossy);
    });
  });

  group('glazeSuggestions', () {
    test('flags a runny low-alumina glaze with a warning', () {
      final result = UmfResult(
        oxides: const {'SiO2': 3.0, 'Al2O3': 0.1, 'CaO': 0.5, 'Na2O': 0.5},
        fluxTotal: 1,
        complete: true,
      );
      final suggestions = glazeSuggestions(result);
      expect(suggestions.any((s) => s.isWarning), isTrue);
    });

    test('a balanced glaze produces no warnings', () {
      final result = UmfResult(
        oxides: const {
          'SiO2': 3.0,
          'Al2O3': 0.35,
          'CaO': 0.5,
          'MgO': 0.2,
          'Na2O': 0.2,
          'K2O': 0.1,
        },
        fluxTotal: 1,
        complete: true,
      );
      final suggestions = glazeSuggestions(result);
      expect(suggestions.where((s) => s.isWarning), isEmpty);
    });
  });
}
