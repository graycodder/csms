import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:csms/core/theme/app_colors.dart';
import '../bloc/shop_subscription_bloc.dart';
import '../../domain/entities/shop_subscription_log_entity.dart';
import 'package:csms/core/utils/loading_overlay.dart';

class ShopSubscriptionHistoryPageWeb extends StatelessWidget {
  final String shopId;
  final String ownerId;

  const ShopSubscriptionHistoryPageWeb({
    super.key,
    required this.shopId,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                Expanded(
                  child:
                      BlocBuilder<ShopSubscriptionBloc, ShopSubscriptionState>(
                        builder: (context, state) {
                          if (state is ShopSubscriptionLoading) {
                            return const LoadingOverlay();
                          } else if (state is ShopSubscriptionError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 48,
                                      color: AppColors.errorText,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      state.message,
                                      style: const TextStyle(
                                        color: AppColors.textLight,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else if (state is ShopSubscriptionHistoryLoaded) {
                            if (state.logs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history_rounded,
                                      size: 64,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No history found',
                                      style: TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 32,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 800.w),
                                  child: Container(
                                    padding: const EdgeInsets.all(40),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 20,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: state.logs.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 16),
                                      itemBuilder: (context, index) {
                                        final log = state.logs[index];
                                        return _buildLogCard(log);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
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
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
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
                'Subscription History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'View all past and current subscription details',
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

  Widget _buildLogCard(ShopSubscriptionLogEntity log) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.planName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (log.price != null)
                      Text(
                        '₹${log.price!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                if (log.startDate != null && log.endDate != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.date_range_outlined,
                        size: 16,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('dd MMM yyyy').format(log.startDate!)} - ${DateFormat('dd MMM yyyy').format(log.endDate!)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
                if (log.status != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: log.status == 'active'
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.border.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      log.status!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: log.status == 'active'
                            ? AppColors.success
                            : AppColors.textLight,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
