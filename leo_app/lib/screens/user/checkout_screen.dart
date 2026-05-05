import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../models/order_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _orderService = OrderService();
  final _productService = ProductService();
  String _method = 'takeaway';
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  String _formatRupiah(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Future<void> _handleCheckout() async {
    if (_method == 'delivery' && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alamat pengiriman harus diisi'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cart = context.read<CartProvider>();
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUser!.id;

      // Validasi stok
      final stockErrors = <String>[];
      for (final item in cart.items) {
        try {
          final serverProduct = await _productService.getProductById(
            item.product.id,
          );
          if (serverProduct.stock < item.qty) {
            stockErrors.add(
              '${item.product.name} (stok: ${serverProduct.stock})',
            );
          }
        } catch (_) {
          stockErrors.add(item.product.name);
        }
      }

      if (stockErrors.isNotEmpty) {
        await _showErrorDialog(stockErrors);
        setState(() => _isLoading = false);
        return;
      }

      // Buat order
      final order = OrderModel(
        id: '',
        userId: userId,
        method: _method,
        address: _method == 'delivery' ? _addressController.text.trim() : '-',
        total: cart.totalPrice.toInt(),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final createdOrder = await _orderService.createOrder(order);

      // Buat order items & kurangi stok
      for (final item in cart.items) {
        final orderItem = OrderItemModel(
          id: '',
          orderId: createdOrder.id,
          productId: item.product.id,
          qty: item.qty,
          price: item.product.price.toInt(),
        );
        await _orderService.createOrderItem(orderItem);
        final newStock = item.product.stock - item.qty;
        await _productService.updateStock(item.product.id, newStock);
      }

      cart.clearCart();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil dibuat'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      Navigator.pushReplacementNamed(context, '/order-history');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showErrorDialog(List<String> errors) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stok Tidak Cukup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Produk berikut stoknya tidak mencukupi:'),
            const SizedBox(height: 8),
            ...errors.map((e) => Text('• $e')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan Pesanan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Consumer<CartProvider>(
                        builder: (context, cart, _) {
                          return Column(
                            children: cart.items.map((item) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
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
                                            item.product.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${item.qty}x ${_formatRupiah(item.product.price)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF616161),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatRupiah(
                                        item.product.price * item.qty,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1565C0),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Consumer<CartProvider>(
                        builder: (context, cart, _) {
                          return Container(
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
                                  _formatRupiah(cart.totalPrice),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Metode Pengiriman',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      RadioListTile<String>(
                        value: 'takeaway',
                        groupValue: _method,
                        onChanged: (v) => setState(() => _method = v!),
                        title: const Text('Take Away'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<String>(
                        value: 'delivery',
                        groupValue: _method,
                        onChanged: (v) => setState(() => _method = v!),
                        title: const Text('Delivery'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_method == 'delivery') ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Alamat Pengiriman',
                            hintText: 'Masukkan alamat lengkap',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleCheckout,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Konfirmasi Pesanan',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
