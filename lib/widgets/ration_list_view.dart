import 'package:flutter/material.dart';

import '../models/ration_item.dart';
import '../services/storage_service.dart';
import 'edit_item_dialog.dart';

class RationListView extends StatefulWidget {
  final ItemType type;
  const RationListView({super.key, required this.type});

  @override
  RationListViewState createState() => RationListViewState();
}

enum SortMode { defaultOrder, asc, desc }

class RationListViewState extends State<RationListView> {
  final StorageService _storage = StorageService();
  late Future<List<RationItem>> _future;
  SortMode _sortMode = SortMode.defaultOrder;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<RationItem>> _load() {
    if (widget.type == ItemType.vegetable) {
      return _storage.getVegetables();
    } else {
      return _storage.getRations();
    }
  }

  List<RationItem> _applySort(List<RationItem> list) {
    final items = List<RationItem>.from(list);
    switch (_sortMode) {
      case SortMode.asc:
        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortMode.desc:
        items.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortMode.defaultOrder:
        break;
    }
    return items;
  }

  Future<void> _refresh() async {
    final items = await _load();
    if (mounted) {
      setState(() {
        _future = Future.value(items);
      });
    }
  }

  Future<void> refresh() => _refresh();

  Future<void> _delete(String id) async {
    final key = widget.type == ItemType.vegetable ? StorageService.keyVegetables : StorageService.keyRations;
    await _storage.deleteById(key, id);
    await _refresh();
  }

  Future<void> _edit(RationItem item) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => EditItemDialog(item: item, type: widget.type),
    );
    if (saved == true) {
      await _refresh();
    }
  }

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _delete(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RationItem>>(
      future: _future,
      builder: (context, snapshot) {
        final baseItems = snapshot.data ?? [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (baseItems.isEmpty) {
          return const Center(child: Text('No items yet'));
        }
        final items = _applySort(baseItems);
        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.type == ItemType.vegetable ? 'Vegetables' : 'Rations',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      DropdownButton<SortMode>(
                        value: _sortMode,
                        onChanged: (v) => setState(() => _sortMode = v ?? SortMode.defaultOrder),
                        items: const [
                          DropdownMenuItem(value: SortMode.defaultOrder, child: Text('Default')),
                          DropdownMenuItem(value: SortMode.asc, child: Text('A-Z')),
                          DropdownMenuItem(value: SortMode.desc, child: Text('Z-A')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return _GridCard(
                        item: item,
                        label: widget.type == ItemType.vegetable ? 'Vegetable' : 'Ration',
                        onDelete: () => _confirmDelete(item.id),
                        onEdit: () => _edit(item),
                      );
                    },
                    childCount: items.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 240,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        );
      },
    );
  }
}

class _GridCard extends StatelessWidget {
  final RationItem item;
  final String label;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _GridCard({required this.item, required this.label, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onLongPress: onDelete,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported)),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Material(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.edit, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Material(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.delete, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
