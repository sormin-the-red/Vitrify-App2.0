class OxideAnalysis {
  final String oxideName;
  final double analysis;

  const OxideAnalysis({required this.oxideName, required this.analysis});

  factory OxideAnalysis.fromJson(Map<String, dynamic> j) => OxideAnalysis(
        oxideName: j['OxideName'] as String,
        analysis: (j['Analysis'] as num).toDouble(),
      );
}

class MaterialModel {
  final String name;
  final List<OxideAnalysis> oxides;
  final double oxidesWeight;
  final String description;
  final bool hazardous;
  final String? imageUrl;

  const MaterialModel({
    required this.name,
    required this.oxides,
    required this.oxidesWeight,
    required this.description,
    required this.hazardous,
    this.imageUrl,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> j) => MaterialModel(
        name: j['Name'] as String,
        oxides: (j['Oxides'] as List)
            .map((e) => OxideAnalysis.fromJson(e as Map<String, dynamic>))
            .toList(),
        oxidesWeight: (j['OxidesWeight'] as num).toDouble(),
        description: j['Description'] as String? ?? '',
        hazardous: j['Hazardous'] as bool? ?? false,
        imageUrl: j['imageUrl'] as String?,
      );
}
