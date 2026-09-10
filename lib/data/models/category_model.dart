class CategoryModel {
  final int? id;
  final String name;
  final int iconCode;
  final int colorValue;
  final String type; // 'expense' or 'income'

  CategoryModel({
    this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'iconCode': iconCode,
      'colorValue': colorValue,
      'type': type,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconCode: map['iconCode'] as int,
      colorValue: map['colorValue'] as int,
      type: map['type'] as String,
    );
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    int? iconCode,
    int? colorValue,
    String? type,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
    );
  }
}
