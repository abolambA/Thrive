class AIAdvice {
  final int? id;
  final String date;
  final String advice;
  final int riskScore;
  final String riskLevel;
  final String createdAt;

  AIAdvice({
    this.id,
    required this.date,
    required this.advice,
    required this.riskScore,
    required this.riskLevel,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'date': date,
    'advice': advice,
    'risk_score': riskScore,
    'risk_level': riskLevel,
    'created_at': createdAt,
  };

  factory AIAdvice.fromMap(Map<String, dynamic> m) => AIAdvice(
    id: m['id'] as int?,
    date: m['date'] as String,
    advice: m['advice'] as String,
    riskScore: m['risk_score'] as int,
    riskLevel: m['risk_level'] as String,
    createdAt: m['created_at'] as String,
  );
}
