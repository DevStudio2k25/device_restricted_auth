// 🔐 Device Metadata Model
// Contains additional device information

class DeviceMetadata {
  final String brand;
  final String model;
  final String osVersion;
  final Map<String, dynamic> additional;

  const DeviceMetadata({
    required this.brand,
    required this.model,
    required this.osVersion,
    this.additional = const {},
  });

  factory DeviceMetadata.fromMap(Map<String, dynamic> map) {
    return DeviceMetadata(
      brand: map['brand'] as String? ?? '',
      model: map['model'] as String? ?? '',
      osVersion: map['osVersion'] as String? ?? '',
      additional: Map<String, dynamic>.from(map['additional'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'model': model,
      'osVersion': osVersion,
      'additional': additional,
    };
  }

  @override
  String toString() {
    return 'DeviceMetadata(brand: $brand, model: $model, osVersion: $osVersion)';
  }
}
