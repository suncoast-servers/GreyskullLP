/// Optional body measurement entry (issue #57).
///
/// Every field is optional: a user may log only bodyweight, only tape
/// measurements, or any combination. Entries are local-first and included in
/// backup export/import.
class BodyMeasurement {
  BodyMeasurement({
    String? id,
    DateTime? date,
    this.weightKg,
    this.bodyFatPct,
    this.waistCm,
    this.chestCm,
    this.armsCm,
    this.notes = '',
    this.photoBase64,
  })  : id = id ?? '${(date ?? DateTime.now()).microsecondsSinceEpoch}_bm',
        date = date ?? DateTime.now();

  final String id;
  final DateTime date;

  /// Bodyweight in kilograms.
  final double? weightKg;

  /// Body-fat percentage (0-75).
  final double? bodyFatPct;

  /// Waist circumference in centimetres.
  final double? waistCm;

  /// Chest circumference in centimetres.
  final double? chestCm;

  /// Arm circumference in centimetres.
  final double? armsCm;

  final String notes;

  /// Optional progress selfie, base64 JPEG. Stored locally and only leaves the
  /// device through an explicit backup export (#85).
  final String? photoBase64;

  bool get hasAnyValue =>
      weightKg != null ||
      bodyFatPct != null ||
      waistCm != null ||
      chestCm != null ||
      armsCm != null;

  BodyMeasurement copyWith({
    DateTime? date,
    double? weightKg,
    double? bodyFatPct,
    double? waistCm,
    double? chestCm,
    double? armsCm,
    String? notes,
    String? photoBase64,
    bool clearPhoto = false,
    bool clearWeight = false,
    bool clearBodyFat = false,
    bool clearWaist = false,
    bool clearChest = false,
    bool clearArms = false,
  }) {
    return BodyMeasurement(
      id: id,
      date: date ?? this.date,
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      bodyFatPct: clearBodyFat ? null : (bodyFatPct ?? this.bodyFatPct),
      waistCm: clearWaist ? null : (waistCm ?? this.waistCm),
      chestCm: clearChest ? null : (chestCm ?? this.chestCm),
      armsCm: clearArms ? null : (armsCm ?? this.armsCm),
      notes: notes ?? this.notes,
      photoBase64: clearPhoto ? null : (photoBase64 ?? this.photoBase64),
    );
  }

  Map<String, dynamic> toJsonMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'bodyFatPct': bodyFatPct,
        'waistCm': waistCm,
        'chestCm': chestCm,
        'armsCm': armsCm,
        'notes': notes,
        'photoBase64': photoBase64,
      };

  factory BodyMeasurement.fromJsonMap(Map<String, dynamic> map) {
    double? asDouble(Object? value) =>
        value is num ? value.toDouble() : double.tryParse('$value');

    final rawDate =
        DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now();

    return BodyMeasurement(
      id: map['id'] as String?,
      date: rawDate,
      weightKg: asDouble(map['weightKg']),
      bodyFatPct: asDouble(map['bodyFatPct']),
      waistCm: asDouble(map['waistCm']),
      chestCm: asDouble(map['chestCm']),
      armsCm: asDouble(map['armsCm']),
      notes: map['notes'] as String? ?? '',
      photoBase64: map['photoBase64'] as String?,
    );
  }
}
