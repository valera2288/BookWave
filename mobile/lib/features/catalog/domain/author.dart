class Author {
  const Author({required this.id, required this.name});

  final int id;
  final String name;

  factory Author.fromJson(Map<String, dynamic> json) => Author(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}
