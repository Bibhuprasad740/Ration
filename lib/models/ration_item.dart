import 'dart:convert';

enum ItemType { vegetable, ration }

ItemType itemTypeFromString(String value) {
  switch (value) {
    case 'vegetable':
      return ItemType.vegetable;
    case 'ration':
      return ItemType.ration;
    default:
      return ItemType.ration;
  }
}

String itemTypeToString(ItemType type) {
  switch (type) {
    case ItemType.vegetable:
      return 'vegetable';
    case ItemType.ration:
      return 'ration';
  }
}

class RationItem {
  final String id;
  final String name;
  final String imageUrl;
  final ItemType type;

  const RationItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.type,
  });

  RationItem copyWith({
    String? id,
    String? name,
    String? imageUrl,
    ItemType? type,
  }) {
    return RationItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'type': itemTypeToString(type),
    };
  }

  factory RationItem.fromMap(Map<String, dynamic> map) {
    final dynamic typeField = map.containsKey('type') ? map['type'] : map['productCollection'];
    return RationItem(
      id: map['id'] as String,
      name: map['name'] as String,
      imageUrl: map['imageUrl'] as String,
      type: itemTypeFromString((typeField ?? 'ration') as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory RationItem.fromJson(String source) => RationItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
