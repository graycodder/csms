import '../../domain/entities/shop_entity.dart';

class ShopModel extends ShopEntity {
  const ShopModel({
    required super.shopId,
    required super.ownerId,
    required super.shopName,
    required super.shopAddress,
    required super.category,
    super.phone,
    required super.settings,
    required super.createdAt,
    required super.updatedAt,
    required super.updatedById,
  });

  factory ShopModel.fromJson(Map<dynamic, dynamic> json, String id) {
    return ShopModel(
      shopId: id,
      ownerId: json['ownerId'] ?? '',
      shopName: json['shopName'] ?? '',
      shopAddress: json['shopAddress'] ?? '',
      category: json['category'] ?? '',
      phone: json['phone'],
      settings: json['settings'] != null
          ? ShopSettings.fromJson(json['settings'])
          : const ShopSettings(
              notificationDaysBefore: 2,
              expiredDaysBefore: 10,
              showProductFilters: false,
              autoArchiveExpired: true,
              whatsappReminderEnabled: false,
              defaultCountryCode: '91',
              registrationFeeEnabled: false,
            ),
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : DateTime.now(),
      updatedById: json['updatedById'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'shopName': shopName,
      'shopAddress': shopAddress,
      'category': category,
      'phone': phone ?? '',
      'settings': settings.toJson(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'updatedById': updatedById,
    };
  }
}
