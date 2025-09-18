import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ration_item.dart';

class ApiService {
  static const String baseUrl = 'https://29de2ef75916.ngrok-free.app/api';

  const ApiService();

  String _collectionPath(ItemType type) => itemTypeToString(type);

  Uri _buildUri(List<String> segments) {
    final path = ([baseUrl] + segments).join('/');
    return Uri.parse(path);
  }

  Map<String, String> get _jsonHeaders => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<List<RationItem>> fetchProducts(ItemType type) async {
    final uri = _buildUri([_collectionPath(type), 'products']);
    final res = await http.get(uri, headers: _jsonHeaders);
    if (res.statusCode != 200) {
      throw Exception('Failed to load products (${res.statusCode})');
    }
    final List<dynamic> data = json.decode(res.body) as List<dynamic>;
    return data
        .map((e) => RationItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<RationItem> createProduct({
    required ItemType type,
    required String name,
    required String imageUrl,
  }) async {
    final uri = _buildUri([_collectionPath(type), 'products']);
    final res = await http.post(
      uri,
      headers: _jsonHeaders,
      body: json.encode({'name': name, 'imageUrl': imageUrl}),
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to create product (${res.statusCode})');
    }
    final Map<String, dynamic> data =
        json.decode(res.body) as Map<String, dynamic>;
    return RationItem.fromMap(data);
  }

  Future<RationItem> updateProduct({
    required ItemType type,
    required String id,
    String? name,
    String? imageUrl,
  }) async {
    final uri = _buildUri([_collectionPath(type), 'products', id]);
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (imageUrl != null) payload['imageUrl'] = imageUrl;
    final res = await http.put(
      uri,
      headers: _jsonHeaders,
      body: json.encode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update product (${res.statusCode})');
    }
    final Map<String, dynamic> data =
        json.decode(res.body) as Map<String, dynamic>;
    return RationItem.fromMap(data);
  }

  Future<void> deleteProduct({
    required ItemType type,
    required String id,
  }) async {
    final uri = _buildUri([_collectionPath(type), 'products', id]);
    final res = await http.delete(uri, headers: _jsonHeaders);
    if (res.statusCode != 204) {
      throw Exception('Failed to delete product (${res.statusCode})');
    }
  }

  Future<List<RationItem>> fetchFinished() async {
    final uri = _buildUri(['finished']);
    final res = await http.get(uri, headers: _jsonHeaders);
    if (res.statusCode != 200) {
      throw Exception('Failed to load finished items (${res.statusCode})');
    }
    final List<dynamic> data = json.decode(res.body) as List<dynamic>;
    return data
        .map((e) => RationItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<RationItem> addToFinished({
    required ItemType type,
    required String id,
  }) async {
    final uri = _buildUri([_collectionPath(type), 'products', id, 'finish']);
    final res = await http.post(uri, headers: _jsonHeaders);
    if (res.statusCode != 200) {
      throw Exception('Failed to add to finished (${res.statusCode})');
    }
    final Map<String, dynamic> data =
        json.decode(res.body) as Map<String, dynamic>;
    return RationItem.fromMap(data);
  }

  Future<RationItem> removeFromFinished({
    required ItemType type,
    required String id,
  }) async {
    final uri = _buildUri([_collectionPath(type), 'products', id, 'finish']);
    final res = await http.delete(uri, headers: _jsonHeaders);
    if (res.statusCode != 200) {
      throw Exception('Failed to remove from finished (${res.statusCode})');
    }
    final Map<String, dynamic> data =
        json.decode(res.body) as Map<String, dynamic>;
    return RationItem.fromMap(data);
  }

  Future<void> clearCollection(ItemType type) async {
    final items = await fetchProducts(type);
    for (final item in items) {
      await deleteProduct(type: type, id: item.id);
    }
  }
}
