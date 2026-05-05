import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/order_service.dart';
import 'product_list_screen.dart';
import 'order_management_screen.dart';
import 'sales_report_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(onLogout: () => _logout()),
          _ProductsTab(),
          _OrdersTab(),
          _ReportsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: const Color(0xFF616161),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Produk'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Pesanan'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Laporan'),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }
}

// ─── Tab: Dashboard ─────────────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  final VoidCallback onLogout;

  const _DashboardTab({required this.onLogout});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  Future<void> _fetchOrders() async {
    try {
      _orders = await _orderService.getAllOrders();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<OrderModel> _todayOrders() {
    final now = DateTime.now();
    return _orders.where((o) {
      return o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day;
    }).toList();
  }

  int _todayRevenue() {
    return _todayOrders()
        .where((o) => o.status == 'completed')
        .fold(0, (sum, o) => sum + o.total);
  }

  String _fmtRupiah(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Consumer<ProductProvider>(
            builder: (context, productProvider, _) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Statistik Hari Ini',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 16),
                  _StatCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'Total Produk',
                    value: '${productProvider.products.length}',
                    color: const Color(0xFF1565C0),
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Pesanan Hari Ini',
                    value: _isLoading ? '...' : '${_todayOrders().length}',
                    color: const Color(0xFFF57C00),
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.payments_outlined,
                    label: 'Pendapatan Hari Ini',
                    value: _isLoading ? '...' : _fmtRupiah(_todayRevenue()),
                    color: const Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 24),
                  const Text('Ringkasan Keseluruhan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 16),
                  _StatCard(
                    icon: Icons.list_alt_outlined,
                    label: 'Total Semua Pesanan',
                    value: '${_orders.length}',
                    color: const Color(0xFF616161),
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.check_circle_outline,
                    label: 'Selesai',
                    value: '${_orders.where((o) => o.status == 'completed').length}',
                    color: const Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.pending_outlined,
                    label: 'Pending',
                    value: '${_orders.where((o) => o.status == 'pending').length}',
                    color: const Color(0xFFF57C00),
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.cancel_outlined,
                    label: 'Dibatalkan',
                    value: '${_orders.where((o) => o.status == 'cancelled').length}',
                    color: const Color(0xFFD32F2F),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Tab: Produk ────────────────────────────────────────────────────────────

class _ProductsTab extends StatelessWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context) {
    return const ProductListScreen();
  }
}

// ─── Tab: Pesanan ────────────────────────────────────────────────────────────

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return const OrderManagementScreen();
  }
}

// ─── Tab: Laporan ────────────────────────────────────────────────────────────

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return const SalesReportScreen();
  }
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF616161))),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}