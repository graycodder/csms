import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'package:csms/features/product/presentation/bloc/product_bloc.dart';
import 'package:csms/features/product/presentation/widgets/product_item_card.dart';
import 'package:csms/features/product/presentation/pages/add_product_page.dart';
import 'package:csms/features/product/presentation/pages/edit_product_page.dart';
import 'package:csms/core/utils/loading_overlay.dart';
import 'package:lottie/lottie.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {

  String? _shopId(BuildContext context) {
    final shopState = context.read<ShopContextBloc>().state;
    if (shopState is ShopSelected) return shopState.selectedShop.shopId;
    return null;
  }

  String? _ownerId(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.ownerId;
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shopId = _shopId(context);
      final ownerId = _ownerId(context);
      if (shopId != null && ownerId != null) {
        context.read<ProductBloc>().add(LoadProducts(
              shopId: shopId,
              ownerId: ownerId,
            ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: BlocConsumer<ProductBloc, ProductState>(
              listener: (context, state) {
                if (state is ProductOperationInProgress) {
                  LoadingOverlay.show(context);
                } else if (state is ProductLoaded) {
                  LoadingOverlay.hide();
                } else if (state is ProductError) {
                  LoadingOverlay.hide();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              builder: (context, state) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    // ── Top row: "Your Products" + Add Product button ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Products',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final shopId = _shopId(context);
                            final ownerId = _ownerId(context);
                            final productBloc = context.read<ProductBloc>();
                            if (shopId != null && ownerId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: productBloc,
                                    child: AddProductPage(
                                      shopId: shopId,
                                      ownerId: ownerId,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              Icon(Icons.add,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 4),
                              const Text(
                                'Add Product',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── State-driven list ──
                    if (state is ProductLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Lottie.asset(
                            'assets/animations/loading.json',
                            width: 80,
                            height: 80,
                          ),
                        ),
                      )
                    else if (state is ProductError)
                      _buildError(state.message)
                    else if (state is ProductLoaded && state.products.isEmpty)
                      _buildEmptyState()
                    else if (state is ProductLoaded)
                      ...state.products.map((p) {
                        return ProductItemCard(
                          key: ValueKey(p.productId),
                          product: p,
                          onEdit: () {
                            final ownerId = _ownerId(context);
                            final productBloc = context.read<ProductBloc>();
                            if (ownerId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: productBloc,
                                    child: EditProductPage(
                                      product: p,
                                      ownerId: ownerId,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          onStatusToggle: () {
                            final ownerId = _ownerId(context);
                            if (ownerId != null) {
                              final newStatus =
                                  p.status == 'active' ? 'inactive' : 'active';
                              
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(
                                    newStatus == 'inactive' 
                                        ? 'Deactivate Product?' 
                                        : 'Activate Product?'
                                  ),
                                  content: Text(
                                    'Are you sure you want to ${newStatus == 'inactive' ? 'deactivate' : 'activate'} "${p.name}"?'
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext),
                                      child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
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
                                        productBloc.add(UpdateProduct(
                                            ownerId: ownerId, product: updatedProduct));
                                      },
                                      child: Text(
                                        newStatus == 'inactive' ? 'Deactivate' : 'Activate',
                                        style: TextStyle(
                                          color: newStatus == 'inactive' ? Colors.redAccent : const Color(0xFF10B981),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        );
                      })
                    else if (state is ProductInitial)
                      _buildEmptyState(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Configure and manage',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0).withOpacity(0.6)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 52, color: Color(0xFFBDBDBD)),
          SizedBox(height: 12),
          Text(
            'No products yet',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Add your first product to get started',
            style: TextStyle(fontSize: 13, color: Color(0xFFBDBDBD)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              final shopId = _shopId(context);
              final ownerId = _ownerId(context);
              if (shopId != null && ownerId != null) {
                context
                    .read<ProductBloc>()
                    .add(LoadProducts(shopId: shopId, ownerId: ownerId));
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
