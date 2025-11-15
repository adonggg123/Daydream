class Room {
  final String id;
  final String name;
  final String description;
  final double price;
  final int capacity;
  final List<String> amenities;
  final String imageUrl;
  final bool isAvailable;

  Room({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.capacity,
    this.amenities = const [],
    this.imageUrl = '',
    this.isAvailable = true,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'capacity': capacity,
      'amenities': amenities,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }

  // Create from Firestore document
  factory Room.fromMap(String id, Map<String, dynamic> map) {
    return Room(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      capacity: map['capacity'] ?? 1,
      amenities: List<String>.from(map['amenities'] ?? []),
      imageUrl: map['imageUrl'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
    );
  }
}
