import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ration_item.dart';

class StorageService {
  static const String keyVegetables = 'vegetables';
  static const String keyRations = 'rations';
  static const String keyFinished = 'finished';

  StorageService._internal();
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  Future<List<RationItem>> _getList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString == null || jsonString.isEmpty) return [];
    final List<dynamic> data = json.decode(jsonString) as List<dynamic>;
    return data.map((e) => RationItem.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveList(String key, List<RationItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(items.map((e) => e.toMap()).toList());
    await prefs.setString(key, jsonString);
  }

  Future<void> clearVegetables() => _saveList(keyVegetables, []);
  Future<void> clearRations() => _saveList(keyRations, []);
  Future<void> clearFinished() => _saveList(keyFinished, []);

  Future<List<RationItem>> getVegetables() => _getList(keyVegetables);
  Future<List<RationItem>> getRations() => _getList(keyRations);
  Future<List<RationItem>> getFinished() => _getList(keyFinished);

  Future<void> addVegetable(RationItem item) async {
    final items = await getVegetables();
    items.add(item.copyWith(type: ItemType.vegetable));
    await _saveList(keyVegetables, items);
  }

  Future<void> addRation(RationItem item) async {
    final items = await getRations();
    items.add(item.copyWith(type: ItemType.ration));
    await _saveList(keyRations, items);
  }

  Future<void> addFinished(RationItem item) async {
    final items = await getFinished();
    items.add(item);
    await _saveList(keyFinished, items);
  }

  Future<void> deleteById(String key, String id) async {
    final list = await _getList(key);
    list.removeWhere((e) => e.id == id);
    await _saveList(key, list);
  }

  Future<void> _update(String key, RationItem updated) async {
    final list = await _getList(key);
    final index = list.indexWhere((e) => e.id == updated.id);
    if (index == -1) return;
    list[index] = updated;
    await _saveList(key, list);
  }

  Future<void> updateVegetable(RationItem item) => _update(keyVegetables, item.copyWith(type: ItemType.vegetable));
  Future<void> updateRation(RationItem item) => _update(keyRations, item.copyWith(type: ItemType.ration));
  Future<void> updateFinished(RationItem item) => _update(keyFinished, item);
}
