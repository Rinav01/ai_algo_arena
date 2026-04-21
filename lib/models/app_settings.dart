class AppSettings {
  final double neonGlowIntensity;
  final double gridTransparency;
  final bool allowDiagonalMoves;
  final double heuristicWeight;
  final bool collisionVibration;
  final bool executionPulse;

  const AppSettings({
    this.neonGlowIntensity = 0.5,
    this.gridTransparency = 0.4,
    this.allowDiagonalMoves = false,
    this.heuristicWeight = 1.0,
    this.collisionVibration = true,
    this.executionPulse = false,
  });

  AppSettings copyWith({
    double? neonGlowIntensity,
    double? gridTransparency,
    bool? allowDiagonalMoves,
    double? heuristicWeight,
    bool? collisionVibration,
    bool? executionPulse,
  }) {
    return AppSettings(
      neonGlowIntensity: neonGlowIntensity ?? this.neonGlowIntensity,
      gridTransparency: gridTransparency ?? this.gridTransparency,
      allowDiagonalMoves: allowDiagonalMoves ?? this.allowDiagonalMoves,
      heuristicWeight: heuristicWeight ?? this.heuristicWeight,
      collisionVibration: collisionVibration ?? this.collisionVibration,
      executionPulse: executionPulse ?? this.executionPulse,
    );
  }

  Map<String, dynamic> toJson() => {
        'neonGlowIntensity': neonGlowIntensity,
        'gridTransparency': gridTransparency,
        'allowDiagonalMoves': allowDiagonalMoves,
        'heuristicWeight': heuristicWeight,
        'collisionVibration': collisionVibration,
        'executionPulse': executionPulse,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      neonGlowIntensity: (json['neonGlowIntensity'] ?? 0.5).toDouble(),
      gridTransparency: (json['gridTransparency'] ?? 0.4).toDouble(),
      allowDiagonalMoves: json['allowDiagonalMoves'] ?? false,
      heuristicWeight: (json['heuristicWeight'] ?? 1.0).toDouble(),
      collisionVibration: json['collisionVibration'] ?? true,
      executionPulse: json['executionPulse'] ?? false,
    );
  }
}
