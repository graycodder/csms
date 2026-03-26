import 'package:equatable/equatable.dart';

class ShopSettings extends Equatable {
  final int notificationDaysBefore;
  final int expiredDaysBefore;
  final bool showProductFilters;
  final bool autoArchiveExpired;
  final bool whatsappReminderEnabled;
  final String defaultCountryCode;

  const ShopSettings({
    required this.notificationDaysBefore,
    required this.expiredDaysBefore,
    required this.showProductFilters,
    required this.autoArchiveExpired,
    required this.whatsappReminderEnabled,
    this.defaultCountryCode = '91',
  });

  factory ShopSettings.fromJson(Map<dynamic, dynamic> json) {
    return ShopSettings(
      notificationDaysBefore: json['notificationDaysBefore'] ?? 2,
      expiredDaysBefore: json['expiredDaysBefore'] ?? 10,
      showProductFilters: json['showProductFilters'] ?? false,
      autoArchiveExpired: json['autoArchiveExpired'] ?? true,
      whatsappReminderEnabled: json['whatsappReminderEnabled'] ?? false,
      defaultCountryCode: json['defaultCountryCode'] ?? '91',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationDaysBefore': notificationDaysBefore,
      'expiredDaysBefore': expiredDaysBefore,
      'showProductFilters': showProductFilters,
      'autoArchiveExpired': autoArchiveExpired,
      'whatsappReminderEnabled': whatsappReminderEnabled,
      'defaultCountryCode': defaultCountryCode,
    };
  }

  @override
  List<Object?> get props => [
    notificationDaysBefore,
    expiredDaysBefore,
    showProductFilters,
    autoArchiveExpired,
    whatsappReminderEnabled,
    defaultCountryCode,
  ];
}

class ShopEntity extends Equatable {
  final String shopId;
  final String ownerId;
  final String shopName;
  final String shopAddress;
  final String category;
  final String? phone;
  final ShopSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String updatedById;

  const ShopEntity({
    required this.shopId,
    required this.ownerId,
    required this.shopName,
    required this.shopAddress,
    required this.category,
    this.phone,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedById,
  });

  @override
  List<Object?> get props => [
    shopId,
    ownerId,
    shopName,
    shopAddress,
    category,
    phone,
    settings,
    createdAt,
    updatedAt,
    updatedById,
    ];
}
