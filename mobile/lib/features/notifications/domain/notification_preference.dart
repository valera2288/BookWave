class NotificationPreference {
  const NotificationPreference({
    required this.category,
    required this.label,
    required this.enabled,
  });

  final String category;
  final String label;
  final bool enabled;

  factory NotificationPreference.fromJson(Map<String, dynamic> json) => NotificationPreference(
        category: json['category'] as String,
        label: json['label'] as String,
        enabled: json['enabled'] as bool,
      );
}
