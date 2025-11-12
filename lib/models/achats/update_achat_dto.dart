class UpdateAchatDto {
  final DateTime? createdAt;
  final double? montantTotal;
  final double? tauxUtilise;
  final bool? isDebt;
  final String? status;

  UpdateAchatDto({
    this.createdAt,
    this.montantTotal,
    this.tauxUtilise,
    this.isDebt,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt?.toIso8601String(),
      'montantTotal': montantTotal,
      'tauxUtilise': tauxUtilise,
      'isDebt': isDebt,
      'status': status,
    };
  }
}
