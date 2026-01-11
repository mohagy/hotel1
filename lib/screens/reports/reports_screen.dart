/// Reports & Analytics Screen
/// 
/// Displays various reports and analytics for the hotel management system

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/reservation_model.dart';
import '../../models/billing_model.dart';
import '../../services/reservation_service.dart';
import '../../services/billing_service.dart';
import '../../core/theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReservationService _reservationService = ReservationService();
  final BillingService _billingService = BillingService();

  bool _isLoading = true;
  List<ReservationModel> _reservations = [];
  List<BillingModel> _billings = [];

  // Revenue statistics
  double _todayRevenue = 0.0;
  double _weekRevenue = 0.0;
  double _monthRevenue = 0.0;
  double _yearRevenue = 0.0;

  // Reservation statistics
  int _totalReservations = 0;
  int _checkedInCount = 0;
  int _checkedOutCount = 0;
  int _pendingCount = 0;

  // Monthly revenue data for chart
  List<double> _monthlyRevenue = List.filled(12, 0.0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final reservations = await _reservationService.getReservations();
      final billings = await _billingService.getInvoices();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);
      final yearStart = DateTime(now.year, 1, 1);

      // Calculate revenue statistics
      double todayRevenue = 0.0;
      double weekRevenue = 0.0;
      double monthRevenue = 0.0;
      double yearRevenue = 0.0;

      for (var billing in billings) {
        if (billing.isPaid && billing.paidDate != null) {
          final paidDate = billing.paidDate!;
          final amount = billing.amount;

          if (paidDate.isAfter(today.subtract(const Duration(days: 1)))) {
            todayRevenue += amount;
          }
          if (paidDate.isAfter(weekStart.subtract(const Duration(days: 1)))) {
            weekRevenue += amount;
          }
          if (paidDate.isAfter(monthStart.subtract(const Duration(days: 1)))) {
            monthRevenue += amount;
          }
          if (paidDate.isAfter(yearStart.subtract(const Duration(days: 1)))) {
            yearRevenue += amount;
          }

          // Monthly revenue for chart
          if (paidDate.year == now.year) {
            _monthlyRevenue[paidDate.month - 1] += amount;
          }
        }
      }

      // Calculate reservation statistics
      int checkedIn = 0;
      int checkedOut = 0;
      int pending = 0;

      for (var reservation in reservations) {
        switch (reservation.status) {
          case 'checked_in':
            checkedIn++;
            break;
          case 'checked_out':
            checkedOut++;
            break;
          case 'reserved':
            pending++;
            break;
        }
      }

      setState(() {
        _reservations = reservations;
        _billings = billings;
        _todayRevenue = todayRevenue;
        _weekRevenue = weekRevenue;
        _monthRevenue = monthRevenue;
        _yearRevenue = yearRevenue;
        _totalReservations = reservations.length;
        _checkedInCount = checkedIn;
        _checkedOutCount = checkedOut;
        _pendingCount = pending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e')),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Revenue', icon: Icon(Icons.trending_up)),
            Tab(text: 'Reservations', icon: Icon(Icons.event)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(
                  todayRevenue: _todayRevenue,
                  weekRevenue: _weekRevenue,
                  monthRevenue: _monthRevenue,
                  yearRevenue: _yearRevenue,
                  totalReservations: _totalReservations,
                  checkedInCount: _checkedInCount,
                  checkedOutCount: _checkedOutCount,
                  pendingCount: _pendingCount,
                  formatCurrency: _formatCurrency,
                ),
                _RevenueTab(
                  monthlyRevenue: _monthlyRevenue,
                  todayRevenue: _todayRevenue,
                  weekRevenue: _weekRevenue,
                  monthRevenue: _monthRevenue,
                  yearRevenue: _yearRevenue,
                  formatCurrency: _formatCurrency,
                ),
                _ReservationsTab(
                  reservations: _reservations,
                  checkedInCount: _checkedInCount,
                  checkedOutCount: _checkedOutCount,
                  pendingCount: _pendingCount,
                ),
              ],
            ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final double todayRevenue;
  final double weekRevenue;
  final double monthRevenue;
  final double yearRevenue;
  final int totalReservations;
  final int checkedInCount;
  final int checkedOutCount;
  final int pendingCount;
  final String Function(double) formatCurrency;

  const _OverviewTab({
    required this.todayRevenue,
    required this.weekRevenue,
    required this.monthRevenue,
    required this.yearRevenue,
    required this.totalReservations,
    required this.checkedInCount,
    required this.checkedOutCount,
    required this.pendingCount,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Statistics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Today',
                  value: formatCurrency(todayRevenue),
                  icon: Icons.today,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'This Week',
                  value: formatCurrency(weekRevenue),
                  icon: Icons.date_range,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'This Month',
                  value: formatCurrency(monthRevenue),
                  icon: Icons.calendar_month,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'This Year',
                  value: formatCurrency(yearRevenue),
                  icon: Icons.trending_up,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Reservation Statistics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total',
                  value: '$totalReservations',
                  icon: Icons.event,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Checked In',
                  value: '$checkedInCount',
                  icon: Icons.how_to_reg,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Checked Out',
                  value: '$checkedOutCount',
                  icon: Icons.exit_to_app,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Pending',
                  value: '$pendingCount',
                  icon: Icons.pending,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueTab extends StatelessWidget {
  final List<double> monthlyRevenue;
  final double todayRevenue;
  final double weekRevenue;
  final double monthRevenue;
  final double yearRevenue;
  final String Function(double) formatCurrency;

  const _RevenueTab({
    required this.monthlyRevenue,
    required this.todayRevenue,
    required this.weekRevenue,
    required this.monthRevenue,
    required this.yearRevenue,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final maxRevenue = monthlyRevenue.isEmpty ? 1.0 : monthlyRevenue.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Revenue Chart',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxRevenue * 1.2,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipRoundedRadius: 8,
                            tooltipBgColor: Colors.grey[800]!,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < months.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      months[index],
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  formatCurrency(value),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(show: true),
                        barGroups: monthlyRevenue.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value,
                                color: Colors.blue,
                                width: 16,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revenue Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _RevenueRow('Today', todayRevenue, formatCurrency),
                  _RevenueRow('This Week', weekRevenue, formatCurrency),
                  _RevenueRow('This Month', monthRevenue, formatCurrency),
                  _RevenueRow('This Year', yearRevenue, formatCurrency),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationsTab extends StatelessWidget {
  final List<ReservationModel> reservations;
  final int checkedInCount;
  final int checkedOutCount;
  final int pendingCount;

  const _ReservationsTab({
    required this.reservations,
    required this.checkedInCount,
    required this.checkedOutCount,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reservation Status Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _StatusRow('Checked In', checkedInCount, Colors.green),
                  _StatusRow('Checked Out', checkedOutCount, Colors.blue),
                  _StatusRow('Pending', pendingCount, Colors.orange),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  final String label;
  final double value;
  final String Function(double) formatCurrency;

  const _RevenueRow(this.label, this.value, this.formatCurrency);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            formatCurrency(value),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusRow(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

