import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/order_model.dart';
import '../../models/order_item_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../config/api_config.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final _orderService = OrderService();
  final _productService = ProductService();

  List<OrderModel> _orders = [];
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ordersFuture = _orderService.getAllOrders();
      final usersFuture = _getUsers();

      await Future.wait([ordersFuture, usersFuture]);

      _orders = await ordersFuture;
      _users = await usersFuture;

      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<UserModel>> _getUsers() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/users'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => UserModel.fromJson(e)).toList();
    }
    return [];
  }

  String _getUserName(String userId) {
    try {
      return _users.firstWhere((u) => u.id == userId).name;
    } catch (_) {
      return 'User #$userId';
    }
  }

  String _formatRupiah(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF57C00);
      case 'processing':
        return const Color(0xFF1565C0);
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF616161);
    }
  }

  Future<void> _updateStatus(OrderModel order, String newStatus) async {
    try {
      await _orderService.updateOrderStatus(order.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status pesanan #${order.id} diubah menjadi $newStatus',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      _fetchData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal update: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  Future<void> _showOrderDetail(OrderModel order) async {
    List<OrderItemModel> items;
    try {
      items = await _orderService.getOrderItems(order.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _OrderDetailSheet(
        order: order,
        items: items,
        productService: _productService,
        formatRupiah: _formatRupiah,
        formatDate: _formatDate,
        statusColor: _statusColor,
        getUserName: _getUserName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Pesanan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
      );
    }

    if (_orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Color(0xFFE0E0E0),
            ),
            SizedBox(height: 16),
            Text(
              'Belum ada pesanan',
              style: TextStyle(color: Color(0xFF616161)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _OrderTile(
            order: order,
            userName: _getUserName(order.userId),
            formatRupiah: _formatRupiah,
            formatDate: _formatDate,
            statusColor: _statusColor,
            onTap: () => _showOrderDetail(order),
            onUpdateStatus: _updateStatus,
          );
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final OrderModel order;
  final String userName;
  final String Function(int) formatRupiah;
  final String Function(DateTime) formatDate;
  final Color Function(String) statusColor;
  final VoidCallback onTap;
  final void Function(OrderModel, String) onUpdateStatus;

  const _OrderTile({
    required this.order,
    required this.userName,
    required this.formatRupiah,
    required this.formatDate,
    required this.statusColor,
    required this.onTap,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor(order.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              userName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              formatDate(order.createdAt),
              style: const TextStyle(fontSize: 12, color: Color(0xFF616161)),
            ),
            const SizedBox(height: 4),
            Text(
              '${order.method == 'delivery' ? 'Delivery' : 'Take Away'} • ${formatRupiah(order.total)}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF616161)),
            ),
            if (order.status == 'pending' || order.status == 'processing') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (order.status == 'pending') ...[
                    _ActionBtn(
                      label: 'Proses',
                      color: const Color(0xFF1565C0),
                      onPressed: () => onUpdateStatus(order, 'processing'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (order.status == 'processing') ...[
                    _ActionBtn(
                      label: 'Selesaikan',
                      color: const Color(0xFF2E7D32),
                      onPressed: () => onUpdateStatus(order, 'completed'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _ActionBtn(
                    label: 'Batalkan',
                    color: const Color(0xFFD32F2F),
                    outlined: true,
                    onPressed: () => onUpdateStatus(order, 'cancelled'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onPressed;

  const _ActionBtn({
    required this.label,
    required this.color,
    this.outlined = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _OrderDetailSheet extends StatefulWidget {
  final OrderModel order;
  final List<OrderItemModel> items;
  final ProductService productService;
  final String Function(int) formatRupiah;
  final String Function(DateTime) formatDate;
  final Color Function(String) statusColor;
  final String Function(String) getUserName;

  const _OrderDetailSheet({
    required this.order,
    required this.items,
    required this.productService,
    required this.formatRupiah,
    required this.formatDate,
    required this.statusColor,
    required this.getUserName,
  });

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  final Map<String, ProductModel> _productCache = {};
  bool _loadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    for (final item in widget.items) {
      if (!_productCache.containsKey(item.productId)) {
        try {
          final product = await widget.productService.getProductById(
            item.productId,
          );
          if (mounted) _productCache[item.productId] = product;
        } catch (_) {}
      }
    }
    if (mounted) setState(() => _loadingProducts = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${widget.order.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.statusColor(widget.order.status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.order.status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pelanggan: ${widget.getUserName(widget.order.userId)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF616161),
                    ),
                  ),
                  Text(
                    'Tanggal: ${widget.formatDate(widget.order.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF616161),
                    ),
                  ),
                  Text(
                    'Metode: ${widget.order.method == 'delivery' ? 'Delivery' : 'Take Away'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF616161),
                    ),
                  ),
                  if (widget.order.method == 'delivery' &&
                      widget.order.address != '-')
                    Text(
                      'Alamat: ${widget.order.address}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF616161),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loadingProducts
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        ...widget.items.map((item) {
                          final product = _productCache[item.productId];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product?.name ??
                                            'Produk #${item.productId}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${item.qty}x ${widget.formatRupiah(item.price)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF616161),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  widget.formatRupiah(item.price * item.qty),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                widget.formatRupiah(widget.order.total),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
