import 'package:flutter/material.dart';

import '../models/ration_item.dart';
import '../services/storage_service.dart';
import '../widgets/add_item_dialog.dart';
import '../widgets/ration_list_view.dart';
import 'finished_items_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<RationListViewState> _vegKey = GlobalKey<RationListViewState>();
  final GlobalKey<RationListViewState> _rationKey = GlobalKey<RationListViewState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ItemType get _currentType => _tabController.index == 0 ? ItemType.vegetable : ItemType.ration;

  Future<void> _onAdd() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AddItemDialog(type: _currentType),
    );
    if (saved == true) {
      if (_currentType == ItemType.vegetable) {
        _vegKey.currentState?.refresh();
      } else {
        _rationKey.currentState?.refresh();
      }
    }
  }

  void _openFinished() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinishedItemsScreen()));
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All'),
        content: Text('Remove all items from ${_currentType == ItemType.vegetable ? 'Vegetables' : 'Rations'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed == true) {
      final storage = StorageService();
      if (_currentType == ItemType.vegetable) {
        await storage.clearVegetables();
      } else {
        await storage.clearRations();
      }
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kitchen Ration'),
          actions: [
            IconButton(onPressed: _openFinished, icon: const Icon(Icons.list_alt)),
            IconButton(onPressed: _clearAll, icon: const Icon(Icons.clear_all)),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Vegetables', icon: Icon(Icons.grass)),
              Tab(text: 'Ration', icon: Icon(Icons.kitchen)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            RationListView(key: _vegKey, type: ItemType.vegetable),
            RationListView(key: _rationKey, type: ItemType.ration),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _onAdd,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
