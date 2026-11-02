/// A person who receives the SOS message. List order is priority:
/// the first contact is the one SOS calls.
class EmergencyContact {
  const EmergencyContact({required this.id, required this.name, required this.phone});

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
      );

  final String id;
  final String name;

  /// Normalized number: +8801XXXXXXXXX for Bangladeshi mobiles.
  final String phone;

  EmergencyContact copyWith({String? name, String? phone}) =>
      EmergencyContact(id: id, name: name ?? this.name, phone: phone ?? this.phone);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone};
}
