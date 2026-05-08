class LookupItem {
  final int id;
  final String name;
  final String? city;
  final String? state;

  LookupItem({required this.id, required this.name, this.city, this.state});

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    return LookupItem(
      id: json['id'] as int,
      name: json['name'] as String,
      city: json['city'] as String?,
      state: json['state'] as String?,
    );
  }

  // Very helpful for debugging!
  @override
  String toString() => name;
}
