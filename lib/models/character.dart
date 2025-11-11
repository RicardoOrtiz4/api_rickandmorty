class Character {
  final int id;
  final String name;
  final String status; // Alive, Dead, unknown
  final String species;
  final String imageUrl;

  Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.imageUrl,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      species: (json['species'] ?? '').toString(),
      imageUrl: (json['image'] ?? '').toString(),
    );
  }
}

