import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/product_model.dart';

class ProductService {
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/products'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => ProductModel.fromJson(e)).toList();
      } else {
        throw Exception('Gagal memuat produk');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server');
    } on http.ClientException {
      throw Exception('Gagal terhubung ke server');
    }
  }

  Future<ProductModel> getProductById(String id) async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/products/$id'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ProductModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Produk tidak ditemukan');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server');
    } on http.ClientException {
      throw Exception('Gagal terhubung ke server');
    }
  }

  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/products'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(product.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return ProductModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Gagal membuat produk');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server');
    } on http.ClientException {
      throw Exception('Gagal terhubung ke server');
    }
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/products/${product.id}'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(product.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ProductModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Gagal update produk');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server');
    } on http.ClientException {
      throw Exception('Gagal terhubung ke server');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final response = await http
          .delete(Uri.parse('${ApiConfig.baseUrl}/products/$id'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Gagal hapus produk');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server');
    } on http.ClientException {
      throw Exception('Gagal terhubung ke server');
    }
  }

  Future<ProductModel> updateStock(String id, int newStock) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/products/$id'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'stock': newStock}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ProductModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Gagal update stok');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server');
    } on http.ClientException {
      throw Exception('Gagal terhubung ke server');
    }
  }
}
