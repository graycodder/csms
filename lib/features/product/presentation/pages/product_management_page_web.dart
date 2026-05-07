import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'package:csms/features/product/presentation/bloc/product_bloc.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/product/presentation/pages/add_product_page.dart';
import 'package:csms/features/product/presentation/pages/edit_product_page.dart';
import 'package:csms/core/utils/loading_overlay.dart';
import 'package:intl/intl.dart';
import 'package:csms/core/widgets/web_sidebar.dart';

class ProductManagementPageWeb extends StatefulWidget {
  const ProductManagementPageWeb({super.key});

  @override
  State<ProductManagementPageWeb> createState() =>
      _ProductManagementPageWebState();
}

class _ProductManagementPageWebState extends State<ProductManagementPageWeb> {
  String? _shopId(BuildContext context) {
    final shopState = context.read<ShopContextBloc>().state;
    if (shopState is ShopSelected) {
      return shopState.selectedShop.shopId;
    }
    return null;
  }

  String? _ownerId(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.ownerId;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shopId = _shopId(context);
      final ownerId = _ownerId(context);
      if (shopId != null && ownerId != null) {
        context.read<ProductBloc>().add(
          LoadProducts(shopId: shopId, ownerId: ownerId),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        children: [
          const WebSidebar(selectedIndex: 3),
          Expanded(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: BlocConsumer<ProductBloc, ProductState>(
                    listenWhen: (previous, current) => true,
                    buildWhen: (previous, current) {
                      return current is ProductLoading ||
                          current is ProductError ||
                          current is ProductLoaded ||
                          current is ProductInitial;
                    },
                    listener: (context, state) {
                      if (state is ProductOperationInProgress) {
                        LoadingOverlayHelper.show(context);
                      } else if (state is ProductLoaded) {
                        LoadingOverlayHelper.hide();
                      } else if (state is ProductActionSuccess) {
                        LoadingOverlayHelper.hide();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else if (state is ProductError) {
                        LoadingOverlayHelper.hide();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is ProductLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is ProductError) {
                        return _buildError(state.message);
                      } else if (state is ProductLoaded) {
                        List<ProductEntity> products = state.products;

                        if (products.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 32,
                          ),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Your Products',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    final shopId = _shopId(context);
                                    final ownerId = _ownerId(context);
                                    if (shopId != null && ownerId != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddProductPage(
                                            shopId: shopId,
                                            ownerId: ownerId,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Product'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...products.map(
                              (p) => _buildProductCard(context, p),
                            ),
                          ],
                        );
                      } else {
                        return _buildEmptyState();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Product Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure and manage',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductEntity p) {
    final bool isInactive = p.status == 'inactive';
    return ColorFiltered(
      colorFilter: isInactive
          ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
          : const ColorFilter.matrix([
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]), // Grayscale filter for inactive products
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInactive
                ? AppColors.border.withOpacity(0.5)
                : AppColors.border.withOpacity(0.3),
          ),
          boxShadow: isInactive
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        p.name[0].toUpperCase() +
                            p.name.substring(1).toLowerCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isInactive
                              ? AppColors.textDark
                              : AppColors.textLight,
                          decoration: !isInactive
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isInactive
                              ? const Color(0xFF10B981).withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          !isInactive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: !isInactive
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Price: ${p.priceType == 'flexible' ? 'Flexible' : p.price.toStringAsFixed(0)} • ${p.validityType == 'flexible' ? 'Flexible' : '${p.validityValue} ${p.validityUnit}'}',
                    style: TextStyle(
                      color: isInactive
                          ? AppColors.textLight
                          : AppColors.textLight.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Created: ${DateFormat('dd MMM yyyy').format(p.createdAt)}',
                    style: TextStyle(
                      color: AppColors.textLight.withOpacity(0.5),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    final ownerId = _ownerId(context);
                    if (ownerId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditProductPage(product: p, ownerId: ownerId),
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  tooltip: 'Edit',
                ),
                SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    final ownerId = _ownerId(context);
                    if (ownerId != null) {
                      final newStatus = isInactive ? 'active' : 'inactive';
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            isInactive
                                ? 'Activate Product?'
                                : 'Deactivate Product?',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to ${isInactive ? 'activate' : 'deactivate'} "${p.name}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                final productBloc = context.read<ProductBloc>();
                                Navigator.pop(dialogContext);

                                final updatedProduct = ProductEntity(
                                  productId: p.productId,
                                  shopId: p.shopId,
                                  name: p.name,
                                  price: p.price,
                                  validityValue: p.validityValue,
                                  validityUnit: p.validityUnit,
                                  validityDays: p.validityDays,
                                  createdAt: p.createdAt,
                                  updatedAt: DateTime.now(),
                                  updatedById: ownerId,
                                  ownerId: p.ownerId,
                                  status: newStatus,
                                );
                                productBloc.add(
                                  UpdateProduct(
                                    ownerId: ownerId,
                                    product: updatedProduct,
                                  ),
                                );
                              },
                              child: Text(
                                isInactive ? 'Activate' : 'Deactivate',
                                style: TextStyle(
                                  color: isInactive
                                      ? const Color(0xFF10B981)
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    isInactive ? Icons.block : Icons.check_circle_outline,
                    color: isInactive
                        ? const Color(0xFF10B981)
                        : Colors.redAccent,
                    size: 20,
                  ),
                  tooltip: isInactive ? 'Activate' : 'Deactivate',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          Padding(
            padding: EdgeInsetsGeometry.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    final shopId = _shopId(context);
                    final ownerId = _ownerId(context);
                    if (shopId != null && ownerId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddProductPage(shopId: shopId, ownerId: ownerId),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Product'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              children: [
                const SizedBox(height: 200),
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No products yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Click "+ Add Product" to get started',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              final shopId = _shopId(context);
              final ownerId = _ownerId(context);
              if (shopId != null && ownerId != null) {
                context.read<ProductBloc>().add(
                  LoadProducts(shopId: shopId, ownerId: ownerId),
                );
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
