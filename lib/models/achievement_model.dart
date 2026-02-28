class AchievementModel {
  final int id;
  final String name;
  final String description;
  final String iconName;
  final String conditionType;
  final int conditionValue;
  final DateTime createdAt;

  AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.conditionType,
    required this.conditionValue,
    required this.createdAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      iconName: json['icon_name'] as String? ?? 'star',
      conditionType: json['condition_type'] as String,
      conditionValue: json['condition_value'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'icon_name': iconName,
      'condition_type': conditionType,
      'condition_value': conditionValue,
    };
  }
}
