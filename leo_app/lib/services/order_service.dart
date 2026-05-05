import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';

class OrderService {
  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/orders'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(order.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return OrderModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Gagal membuat pesanan');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server');
    } on http.ClientException {
      throw Exception('Gagal terhubung ke server');
    }
  }

  Future<OrderItemModel> createOrderItem(OrderItemModel item) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/order_items'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(item.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return OrderItemModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Gagal membuat item pesanan');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server');
    } on http.ClientException {
      throw Exception('Gagal terhubung ke server');
    }
  }

  Future<List<OrderModel>> getOrdersByUser(String userId) async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/orders'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final orders = data
            .map((e) => OrderModel.fromJson(e))
            .where((o) => o.userId == userId)
            .toList();
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return orders;
      } else {
        throw Exception('Gagal memuat pesanan');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server');
    } on http.ClientException {
      throw Exception('Gagal terhubung ke server');
    }
  }

  Future<List<OrderItemModel>> getOrderItems(String orderId) async {
    try {
      final params = {'order_id': orderId};
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/order_items',
      ).replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => OrderItemModel.fromJson(e)).toList();
      } else {
        throw Exception('Gagal memuat detail pesanan');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server');
    } on http.ClientException {
      throw Exception('Gagal terhubung ke server');
    }
  }

  Future<List<OrderModel>> getAllOrders() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/orders'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => OrderModel.fromJson(e)).toList();
      } else {
        throw Exception('Gagal memuat pesanan');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server');
    } on http.ClientException {
      throw Exception('Gagal terhubung ke server');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/orders/$orderId'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'status': status}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Gagal update status pesanan');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server');
    } on http.ClientException {
      throw Exception('Gagal terhubung ke server');
    }
  }
}
