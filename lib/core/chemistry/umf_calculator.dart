import '../materials/material_model.dart';
import '../../features/recipes/recipe_models.dart';

// Oxide molecular weights (g/mol)
const _mw = {
  'SiO2':  60.08,
  'Al2O3': 101.96,
  'Fe2O3': 159.69,
  'TiO2':  79.87,
  'CaO':   56.08,
  'MgO':   40.30,
  'K2O':   94.20,
  'Na2O':  61.98,
  'Li2O':  29.88,
  'ZnO':   81.39,
  'BaO':   153.33,
  'SrO':   103.62,
  'MnO':   70.94,
  'MnO2':  86.94,
  'P2O5':  141.94,
  'B2O3':  69.62,
  'PbO':   223.20,
  'CoO':   74.93,
  'CuO':   79.55,
  'Cr2O3': 152.00,
  'NiO':   74.71,
  'V2O5':  181.88,
  'ZrO2':  123.22,
};

// R2O + RO fluxes used for UMF normalization
const _fluxOxides = {
  'Na2O', 'K2O', 'Li2O',
  'CaO', 'MgO', 'ZnO', 'BaO', 'SrO', 'PbO',
};

class UmfResult {
  final Map<String, double> oxides;
  final double fluxTotal;
  final bool complete;

  const UmfResult({
    required this.oxides,
    required this.fluxTotal,
    required this.complete,
  });

  double get si  => oxides['SiO2']  ?? 0;
  double get al  => oxides['Al2O3'] ?? 0;
  double get b   => oxides['B2O3']  ?? 0;
  double get siAl => al > 0 ? si / al : 0;
}

UmfResult? calculateUmf(
  List<RecipeIngredient> ingredients,
  List<MaterialModel> database,
) {
  if (ingredients.isEmpty) return null;

  final byName = {for (final m in database) m.name: m};
  final weightTotals = <String, double>{};
  var allFound = true;

  for (final ing in ingredients) {
    final mat = byName[ing.name];
    if (mat == null) {
      allFound = false;
      continue;
    }
    for (final ox in mat.oxides) {
      final name = ox.oxideName;
      if (name == 'LOI' || name == 'C') continue;
      // weight of this oxide per 100g of batch
      final w = ing.percentage * ox.analysis / 100.0;
      weightTotals[name] = (weightTotals[name] ?? 0) + w;
    }
  }

  if (weightTotals.isEmpty) return null;

  // Convert weight totals to moles
  final moles = <String, double>{};
  for (final entry in weightTotals.entries) {
    final mw = _mw[entry.key];
    if (mw == null || mw == 0) continue;
    moles[entry.key] = entry.value / mw;
  }

  final fluxTotal = moles.entries
      .where((e) => _fluxOxides.contains(e.key))
      .fold(0.0, (sum, e) => sum + e.value);

  if (fluxTotal == 0) return null;

  final umf = {
    for (final e in moles.entries) e.key: e.value / fluxTotal,
  };

  return UmfResult(oxides: umf, fluxTotal: fluxTotal, complete: allFound);
}

// Display order for UMF table
const umfDisplayGroups = [
  ['K2O', 'Na2O', 'Li2O'],
  ['CaO', 'MgO', 'ZnO', 'BaO', 'SrO', 'PbO'],
  ['Al2O3', 'Fe2O3', 'B2O3'],
  ['SiO2', 'TiO2', 'ZrO2'],
];
