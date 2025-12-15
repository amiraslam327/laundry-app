import 'package:equatable/equatable.dart';

class FragranceModel extends Equatable {
  final String id;
  final String name;
  final String? iconUrl;

  const FragranceModel({
    required this.id,
    required this.name,
    this.iconUrl,
  });

  factory FragranceModel.fromMap(Map<String, dynamic> map) {
    return FragranceModel(
      id: map['id'] as String,
      name: map['name'] as String,
      iconUrl: map['iconUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconUrl': iconUrl,
    };
  }

  @override
  List<Object?> get props => [id, name, iconUrl];
}

