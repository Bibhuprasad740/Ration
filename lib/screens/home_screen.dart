import 'package:flutter/material.dart';

import '../models/ration_item.dart';
import '../services/api_service.dart';
import '../widgets/add_item_dialog.dart';
import '../widgets/ration_list_view.dart';
import 'finished_items_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<RationListViewState> _vegKey =
      GlobalKey<RationListViewState>();
  final GlobalKey<RationListViewState> _rationKey =
      GlobalKey<RationListViewState>();

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

  ItemType get _currentType =>
      _tabController.index == 0 ? ItemType.vegetable : ItemType.ration;

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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FinishedItemsScreen()));
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All'),
        content: Text(
          'Remove all items from ${_currentType == ItemType.vegetable ? 'Vegetables' : 'Rations'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      const api = ApiService();
      await api.clearCollection(_currentType);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Kitchen Ration',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimary,
            ),
          ),
          centerTitle: true,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.3),
          actions: [
            IconButton(
              onPressed: _openFinished,
              icon: const Icon(Icons.list_alt),
              tooltip: 'Finished Items',
            ),
            IconButton(
              onPressed: _clearAll,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear All',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: colorScheme.onPrimary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.black,
            ),
            tabs: const [
              Tab(text: 'Vegetables', icon: Icon(Icons.grass)),
              Tab(text: 'Ration', icon: Icon(Icons.kitchen)),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary.withOpacity(0.05),
                colorScheme.surface,
              ],
            ),
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              RationListView(key: _vegKey, type: ItemType.vegetable),
              RationListView(key: _rationKey, type: ItemType.ration),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _onAdd,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 4,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
