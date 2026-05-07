import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/reports/domain/entities/report_entity.dart';
import 'package:csms/features/reports/presentation/bloc/report_bloc.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csms/core/utils/terminology_helper.dart';
import 'package:csms/core/widgets/web_sidebar.dart';
import 'package:intl/intl.dart';

class ReportPageWeb extends StatefulWidget {
  const ReportPageWeb({super.key});

  @override
  State<ReportPageWeb> createState() => _ReportPageWebState();
}

class _ReportPageWebState extends State<ReportPageWeb>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReportFilter _currentFilter = ReportFilter.daily;
  DateTime _referenceDate = DateTime.now();
  final ScrollController _chartScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentFilter = ReportFilter.values[_tabController.index];
        });
        _triggerFilter();
      }
    });

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerFilter();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chartScrollController.dispose();
    super.dispose();
  }

  void _triggerFilter() {
    final shopState = context.read<ShopContextBloc>().state;
    if (shopState is ShopSelected) {
      context.read<ReportBloc>().add(
        LoadReport(
          shopId: shopState.selectedShop.shopId,
          ownerId: shopState.selectedShop.ownerId,
          filter: _currentFilter,
          referenceDate: _referenceDate,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportBloc, ReportState>(
      listener: (context, state) {
        if (state is ReportLoading) {
          // LoadingOverlayHelper.show(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: Row(
          children: [
            const WebSidebar(selectedIndex: 1),
            Expanded(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: BlocBuilder<ReportBloc, ReportState>(
                      builder: (context, state) {
                        if (state is ReportLoading && state.report == null) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (state is ReportError) {
                          return Center(
                            child: SelectableText(
                              'Error: ${state.message}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        } else if (state is ReportLoaded ||
                            (state is ReportLoading && state.report != null)) {
                          final report =
                              state is ReportLoaded
                                  ? state.report
                                  : (state as ReportLoading).report!;
                          return BlocBuilder<ShopContextBloc, ShopContextState>(
                            builder: (context, shopState) {
                              final term =
                                  shopState is ShopSelected
                                      ? TerminologyHelper.getTerminology(
                                        shopState.selectedShop.category,
                                      )
                                      : TerminologyHelper.getTerminology(
                                        'default',
                                      );
                              final isRegEnabled =
                                  shopState is ShopSelected &&
                                  shopState
                                      .selectedShop
                                      .settings
                                      .registrationFeeEnabled;

                              return SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 32,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_currentFilter == ReportFilter.daily)
                                      _buildDailyView(
                                        report,
                                        term,
                                        isRegEnabled,
                                      )
                                    else
                                      _buildMonthlyView(
                                        report,
                                        term,
                                        isRegEnabled,
                                      ),
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                        return const Center(child: Text('No data available'));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyView(
    ReportEntity report,
    BusinessTerminology term,
    bool isRegEnabled,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRevenueHeroCard(report, term, isRegEnabled),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: _buildPaymentModeCard(report)),
            const SizedBox(width: 32),
            Expanded(flex: 4, child: _buildActivityGrid(report, term)),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          title: 'Revenue by Hour',
          icon: Icons.bar_chart,
          child: SizedBox(height: 300, child: _buildRevenueChart(report)),
        ),
        const SizedBox(height: 32),
        _buildSection(
          title: '${term.planLabel} Breakdown',
          icon: Icons.inventory_2_outlined,
          child: _buildPlansBreakdownList(report, term),
        ),
      ],
    );
  }

  Widget _buildMonthlyView(
    ReportEntity report,
    BusinessTerminology term,
    bool isRegEnabled,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRevenueHeroCard(report, term, isRegEnabled),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: _buildPaymentModeCard(report)),
            const SizedBox(width: 32),
            Expanded(flex: 4, child: _buildActivityGrid(report, term)),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          title: 'Revenue by Day',
          icon: Icons.bar_chart,
          child: SizedBox(height: 300, child: _buildRevenueChart(report)),
        ),
        const SizedBox(height: 32),
        _buildSection(
          title: '${term.planLabel} Breakdown',
          icon: Icons.inventory_2_outlined,
          child: _buildPlansBreakdownList(report, term),
        ),
      ],
    );
  }

  Widget _buildRevenueHeroCard(
    ReportEntity report,
    BusinessTerminology term,
    bool isRegEnabled,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Revenue Collected',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${report.totalRevenueCollected.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildHeroStatItem(
                '${term.subscriptionLabel}s',
                '₹${report.subscriptionRevenueCollected.toStringAsFixed(0)}',
                Icons.autorenew,
                const Color(0xFF006064),
                const Color(0xFFE0F7FA),
              ),
              const SizedBox(width: 24),
              if (isRegEnabled) ...[
                _buildHeroStatItem(
                  'Reg. Fees',
                  '₹${report.registrationFeeCollected.toStringAsFixed(0)}',
                  Icons.badge_outlined,
                  const Color(0xFF004D40),
                  const Color(0xFFE0F2F1),
                ),
                const SizedBox(width: 24),
              ],
              _buildHeroStatItem(
                'Pending Balance',
                '₹${report.totalPendingBalance.toStringAsFixed(0)}',
                Icons.access_time,
                const Color(0xFFE65100),
                const Color(0xFFFFF3E0),
              ),
              if (isRegEnabled) ...[
                const SizedBox(width: 24),
                _buildHeroStatItem(
                  'Pending Reg. Fees',
                  '₹${report.registrationFeePending.toStringAsFixed(0)}',
                  Icons.access_time,
                  const Color(0xFFE65100),
                  const Color(0xFFFFF3E0),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityGrid(ReportEntity report, BusinessTerminology term) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.2,
      children: [
        _buildActivityCard(
          'New ${term.customerLabel}s',
          report.newJoiners.toString(),
          Icons.person,
          const Color(0xFF00838F),
          const Color(0xFFE0F7FA),
        ),
        _buildActivityCard(
          'New ${term.subscriptionLabel}s',
          report.newSubscriptions.toString(),
          Icons.edit_document,
          const Color(0xFF00838F),
          const Color(0xFFE0F7FA),
        ),
        _buildActivityCard(
          'Active ${term.subscriptionLabel}s',
          report.activeCustomers.toString(),
          Icons.group,
          const Color(0xFF00838F),
          const Color(0xFFE0F7FA),
        ),
        _buildActivityCard(
          'Inactive ${term.subscriptionLabel}s',
          report.inactiveCustomers.toString(),
          Icons.group_off,
          const Color(0xFF00838F),
          const Color(0xFFE0F7FA),
        ),
        _buildActivityCard(
          'Expiring Soon',
          report.expiringSoonSubscriptions.toString(),
          Icons.notifications_active,
          const Color(0xFFE65100),
          const Color(0xFFFFF3E0),
        ),
        _buildActivityCard(
          'Expired',
          report.expiredSubscriptions.toString(),
          Icons.notifications_off,
          const Color(0xFFE65100),
          const Color(0xFFFFF3E0),
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentModeCard(ReportEntity report) {
    final modes = [
      ('Cash', const Color(0xFF43A047)),
      ('UPI', const Color(0xFF1E88E5)),
      ('Card', const Color(0xFF8E24AA)),
      ('Bank Transfer', const Color(0xFF00897B)),
      ('Other', const Color(0xFF757575)),
    ];
    final total = report.paymentModeBreakdown.values.fold(0.0, (s, v) => s + v);
    final hasData = total > 0;

    return _buildSection(
      title: 'Collection by Payment Mode',
      icon: Icons.payments_outlined,
      child: Column(
        children: [
          if (hasData)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: modes.map((m) {
                  final val = report.paymentModeBreakdown[m.$1] ?? 0.0;
                  final frac = val / total;
                  if (frac <= 0) return const SizedBox.shrink();
                  return Flexible(
                    flex: (frac * 1000).round(),
                    child: Container(height: 12, color: m.$2),
                  );
                }).toList(),
              ),
            )
          else
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          const SizedBox(height: 32),
          ...modes.map((m) {
            final val = report.paymentModeBreakdown[m.$1] ?? 0.0;
            final pct = hasData ? (val / total * 100) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: m.$2,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      m.$1,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '₹${val.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${pct.toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(24.0), child: child),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(ReportEntity report) {
    final nonZeroData = report.revenueChartData.where((p) => p.value > 0);
    final double maxVal = nonZeroData.isEmpty
        ? 2000
        : nonZeroData.fold(0.0, (m, p) => p.value > m ? p.value : m);

    double yLimit = (maxVal / 1000).ceil() * 1000.0;
    if (yLimit < 5000) {
      yLimit = 5000;
    } else if (yLimit == maxVal) {
      yLimit += 1000;
    }

    return Row(
      children: [
        // Y-Axis Titles
        SizedBox(
          width: 60,
          height: 250,
          child: BarChart(
            BarChartData(
              maxY: yLimit,
              minY: 0,
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      if (val == 0) return const SizedBox.shrink();
                      return Text(
                        '₹${val.toInt()}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      );
                    },
                    reservedSize: 60,
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [],
            ),
          ),
        ),
        // Chart Body
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: yLimit,
              minY: 0,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final label =
                        report.revenueChartData[group.x.toInt()].label;
                    return BarTooltipItem(
                      '₹${rod.toY.toInt()}\n$label',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= report.revenueChartData.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          report.revenueChartData[idx].label.split('/')[0],
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: Colors.grey[100]!, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: report.revenueChartData
                  .asMap()
                  .entries
                  .map(
                    (e) => BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.value,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.7),
                              AppColors.primary,
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlansBreakdownList(
    ReportEntity report,
    BusinessTerminology term,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: report.productBreakdown.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final plan = report.productBreakdown[index];
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  plan.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 7,
                child: Row(
                  children: [
                    _buildPlanStat(
                      'Active',
                      plan.activeCount,
                      const Color(0xFF00838F),
                      const Color(0xFFE0F7FA),
                    ),
                    const SizedBox(width: 12),
                    _buildPlanStat(
                      'Expiring',
                      plan.expiringCount,
                      const Color(0xFFE65100),
                      const Color(0xFFFFF3E0),
                    ),
                    const SizedBox(width: 12),
                    _buildPlanStat(
                      'Expired',
                      plan.expiredCount,
                      const Color(0xFFC62828),
                      const Color(0xFFFFEBEE),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanStat(
    String label,
    int value,
    Color textColor,
    Color bgColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Sidebar & Header ---

  Widget _buildHeader(BuildContext context) {
    final dateStr = _currentFilter == ReportFilter.daily
        ? DateFormat('MMMM d, yyyy').format(_referenceDate)
        : DateFormat('MMMM yyyy').format(_referenceDate);

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
                'Business Reports',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Comprehensive analytics & insights',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Filter Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: ReportFilter.values.map((filter) {
                final isSelected = _currentFilter == filter;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentFilter = filter;
                      _tabController.animateTo(filter.index);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      filter.label,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 24),
          // Date Selector
          InkWell(
            onTap: () => _showDateSelectionDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDateSelectionDialog(BuildContext context) async {
    if (_currentFilter == ReportFilter.daily) {
      final picked = await showDatePicker(
        context: context,
        initialDate: _referenceDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        setState(() => _referenceDate = picked);
        _triggerFilter();
      }
    } else {
      // Month selection dialog for web
      DateTime tempDate = _referenceDate;
      final picked = await showDialog<DateTime>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setDialogState(
                      () => tempDate = DateTime(
                        tempDate.year - 1,
                        tempDate.month,
                      ),
                    ),
                  ),
                  Text(
                    '${tempDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: tempDate.year >= DateTime.now().year
                        ? null
                        : () => setDialogState(
                            () => tempDate = DateTime(
                              tempDate.year + 1,
                              tempDate.month,
                            ),
                          ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 300,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final monthDate = DateTime(tempDate.year, index + 1);
                    final isSelected =
                        _referenceDate.month == index + 1 &&
                        _referenceDate.year == tempDate.year;
                    final isFuture = monthDate.isAfter(DateTime.now());

                    return GestureDetector(
                      onTap: isFuture
                          ? null
                          : () => Navigator.pop(context, monthDate),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey[200]!,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          DateFormat('MMM').format(monthDate),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isFuture ? Colors.grey[300] : Colors.black),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      );
      if (picked != null) {
        setState(() => _referenceDate = picked);
        _triggerFilter();
      }
    }
  }
}
