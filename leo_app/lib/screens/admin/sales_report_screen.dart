import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../models/order_item_model.dart';
import '../../providers/product_provider.dart';
import '../../services/order_service.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final _orderService = OrderService();

  List<OrderModel> _orders = [];
  List<OrderItemModel> _orderItems = [];
  bool _isLoading = true;
  String? _error;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _orders = await _orderService.getAllOrders();
      _orderItems = [];
      for (final order in _orders) {
        final items = await _orderService.getOrderItems(order.id);
        _orderItems.addAll(items);
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<OrderModel> get _filteredOrders {
    if (_startDate == null && _endDate == null) return _orders;
    return _orders.where((o) {
      if (_startDate != null && o.createdAt.isBefore(_startDate!)) return false;
      if (_endDate != null) {
        final endOfDay = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          23,
          59,
          59,
        );
        if (o.createdAt.isAfter(endOfDay)) return false;
      }
      return true;
    }).toList();
  }

  int get _totalRevenue {
    return _filteredOrders
        .where((o) => o.status == 'completed')
        .fold(0, (sum, o) => sum + o.total);
  }

  int _countByStatus(String status) {
    return _filteredOrders.where((o) => o.status == status).length;
  }

  List<MapEntry<String, int>> _topProducts() {
    final Map<String, int> qtyMap = {};
    final filteredOrderIds = _filteredOrders.map((o) => o.id).toSet();

    for (final item in _orderItems) {
      if (filteredOrderIds.contains(item.orderId)) {
        qtyMap[item.productId] = (qtyMap[item.productId] ?? 0) + item.qty;
      }
    }

    final entries = qtyMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(5).toList();
  }

  String _getProductName(String productId) {
    final products = context.read<ProductProvider>().products;
    try {
      return products.firstWhere((p) => p.id == productId).name;
    } catch (_) {
      return 'Produk #$productId';
    }
  }

  String _fmtRupiah(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Penjualan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFD32F2F)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchData,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Filter tanggal
                      _DateFilterCard(
                        startDate: _startDate,
                        endDate: _endDate,
                        onTap: _selectDateRange,
                        onClear: () => setState(() {
                          _startDate = null;
                          _endDate = null;
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Total pendapatan
                      _SectionTitle('Total Pendapatan'),
                      const SizedBox(height: 8),
                      _RevenueCard(
                        amount: _totalRevenue,
                        formatRupiah: _fmtRupiah,
                      ),
                      const SizedBox(height: 16),

                      // Order per status
                      _SectionTitle('Jumlah Order per Status'),
                      const SizedBox(height: 8),
                      _StatusTable(
                        pending: _countByStatus('pending'),
                        processing: _countByStatus('processing'),
                        completed: _countByStatus('completed'),
                        cancelled: _countByStatus('cancelled'),
                      ),
                      const SizedBox(height: 16),

                      // Top 5 produk
                      _SectionTitle('Top 5 Produk Terlaris'),
                      const SizedBox(height: 8),
                      _TopProductsTable(
                        topProducts: _topProducts(),
                        getProductName: _getProductName,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
      ),
    );
  }
}

class _DateFilterCard extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateFilterCard({
    required this.startDate,
    required this.endDate,
    required this.onTap,
    required this.onClear,
  });

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final hasFilter = startDate != null || endDate != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, color: Color(0xFF1565C0)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Tanggal',
                  style: TextStyle(fontSize: 12, color: Color(0xFF616161)),
                ),
                const SizedBox(height: 4),
                Text(
                  hasFilter
                      ? '${_fmt(startDate!)} - ${_fmt(endDate!)}'
                      : 'Semua tanggal',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (hasFilter)
            IconButton(
              icon: const Icon(Icons.clear, color: Color(0xFF616161)),
              onPressed: onClear,
              iconSize: 20,
            ),
          IconButton(
            icon: const Icon(Icons.edit_calendar, color: Color(0xFF1565C0)),
            onPressed: onTap,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final int amount;
  final String Function(int) formatRupiah;

  const _RevenueCard({required this.amount, required this.formatRupiah});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Pendapatan',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                formatRupiah(amount),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusTable extends StatelessWidget {
  final int pending;
  final int processing;
  final int completed;
  final int cancelled;

  const _StatusTable({
    required this.pending,
    required this.processing,
    required this.completed,
    required this.cancelled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          _StatusRow('Pending', pending, const Color(0xFFF57C00)),
          const Divider(height: 16),
          _StatusRow('Processing', processing, const Color(0xFF1565C0)),
          const Divider(height: 16),
          _StatusRow('Completed', completed, const Color(0xFF2E7D32)),
          const Divider(height: 16),
          _StatusRow('Cancelled', cancelled, const Color(0xFFD32F2F)),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopProductsTable extends StatelessWidget {
  final List<MapEntry<String, int>> topProducts;
  final String Function(String) getProductName;

  const _TopProductsTable({
    required this.topProducts,
    required this.getProductName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 8,
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF616161),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Produk',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF616161),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'Terjual',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF616161),
                  ),
                ),
              ],
            ),
          ),
          if (topProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Belum ada data',
                style: TextStyle(color: Color(0xFF616161)),
              ),
            )
          else
            ...topProducts.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: idx < topProducts.length - 1
                      ? const Border(
                          bottom: BorderSide(color: Color(0xFFF5F7FA)),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 8,
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: idx == 0
                              ? const Color(0xFFFFC107)
                              : const Color(0xFF616161),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        getProductName(item.key),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item.value}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
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
}
