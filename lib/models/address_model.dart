class AddressModel {
  final String id;
  final String label; // "Rumah", "Kantor", "Apartemen", "Kos", "Lainnya"
  final String address;
  final String detail; // Detail patokan / catatan
  final String receiverName;
  final String receiverPhone;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.label,
    required this.address,
    this.detail = '',
    this.receiverName = '',
    this.receiverPhone = '',
    this.isDefault = false,
  });

  AddressModel copyWith({
    String? id,
    String? label,
    String? address,
    String? detail,
    String? receiverName,
    String? receiverPhone,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      detail: detail ?? this.detail,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'address': address,
    'detail': detail,
    'receiverName': receiverName,
    'receiverPhone': receiverPhone,
    'isDefault': isDefault,
  };

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
    id: json['id'] as String? ?? '',
    label: json['label'] as String? ?? 'Rumah',
    address: json['address'] as String? ?? '',
    detail: json['detail'] as String? ?? '',
    receiverName: json['receiverName'] as String? ?? '',
    receiverPhone: json['receiverPhone'] as String? ?? '',
    isDefault: json['isDefault'] as bool? ?? false,
  );
}
