import 'package:equatable/equatable.dart';

class ServiceCategory extends Equatable {
  final String id;
  final String name;
  final String icon; // asset path like "assets/icons/dryclean.png"
  final String? duration; // e.g., "3 days"

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.duration,
  });

  factory ServiceCategory.fromMap(Map<String, dynamic> map) {
    return ServiceCategory(
      id: (map['id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      icon: (map['icon'] ?? 'assets/icons/default.png') as String,
      duration: map['duration'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'duration': duration,
    };
  }

  @override
  List<Object?> get props => [id, name, icon, duration];
}

