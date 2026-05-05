import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  Future<UserModel?> login(String email, String password) async {
    try {
      final params = {'email': email};
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/users',
      ).replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (final item in data) {
          if (item['password'] == password) {
            return UserModel.fromJson(item);
          }
        }
      }
      return null;
    } on SocketException {
      throw Exception('Gagal terhubung ke server');
    } on http.ClientException {
      throw Exception('Gagal terhubung ke server');
    } on FormatException {
      throw Exception('Format data tidak valid dari server');
    }
  }

  Future<UserModel> register(String name, String email, String password) async {
    try {
      final params = {'email': email};
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/users',
      ).replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          throw Exception('Email sudah terdaftar');
        }
      }

      final newUser = {
        'name': name,
        'email': email,
        'password': password,
        'role': 'user',
      };

      final postResponse = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/users'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(newUser),
          )
          .timeout(const Duration(seconds: 10));

      if (postResponse.statusCode == 201) {
        return UserModel.fromJson(json.decode(postResponse.body));
      } else {
        throw Exception('Gagal mendaftar');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server');
    } on http.ClientException {
      throw Exception('Gagal terhubung ke server');
    }
  }
}
