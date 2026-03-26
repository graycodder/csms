import 'package:shared_preferences/shared_preferences.dart';

abstract class ShopLocalDataSource {
  Future<void> saveSelectedShopId(String shopId);
  String? getSelectedShopId();
  Future<void> clearSelectedShopId();
}

class ShopLocalDataSourceImpl implements ShopLocalDataSource {
  final SharedPreferences sharedPreferences;

  ShopLocalDataSourceImpl({required this.sharedPreferences});

  static const String _selectedShopIdKey = 'selected_shop_id';

  @override
  Future<void> saveSelectedShopId(String shopId) async {
    await sharedPreferences.setString(_selectedShopIdKey, shopId);
  }

  @override
  String? getSelectedShopId() {
    return sharedPreferences.getString(_selectedShopIdKey);
  }

  @override
  Future<void> clearSelectedShopId() async {
    await sharedPreferences.remove(_selectedShopIdKey);
  }
}
