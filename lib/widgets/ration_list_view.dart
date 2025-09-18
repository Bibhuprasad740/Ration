import 'package:flutter/material.dart';

import '../models/ration_item.dart';
import '../services/api_service.dart';
import 'edit_item_dialog.dart';

class RationListView extends StatefulWidget {
  final ItemType type;
  const RationListView({super.key, required this.type});

  @override
  RationListViewState createState() => RationListViewState();
}

enum SortMode { defaultOrder, asc, desc }

class RationListViewState extends State<RationListView> {
  final ApiService _api = const ApiService();
  late Future<List<RationItem>> _future;
  SortMode _sortMode = SortMode.defaultOrder;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<RationItem>> _load() {
    return _api.fetchProducts(widget.type);
  }

  List<RationItem> _applySort(List<RationItem> list) {
    final items = List<RationItem>.from(list);
    switch (_sortMode) {
      case SortMode.asc:
        items.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case SortMode.desc:
        items.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
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
    await _api.deleteProduct(type: widget.type, id: id);
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
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _delete(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<List<RationItem>>(
      future: _future,
      builder: (context, snapshot) {
        final baseItems = snapshot.data ?? [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading ${widget.type == ItemType.vegetable ? 'vegetables' : 'rations'}...',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }
        if (baseItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.type == ItemType.vegetable
                      ? Icons.grass
                      : Icons.kitchen,
                  size: 64,
                  color: colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${widget.type == ItemType.vegetable ? 'vegetables' : 'rations'} yet',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first item',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        final items = _applySort(baseItems);
        return RefreshIndicator(
          color: colorScheme.primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.type == ItemType.vegetable ? 'Vegetables' : 'Rations'} (${items.length})',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SortMode>(
                          value: _sortMode,
                          onChanged: (v) => setState(
                            () => _sortMode = v ?? SortMode.defaultOrder,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: SortMode.defaultOrder,
                              child: Text(
                                'Default',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            DropdownMenuItem(
                              value: SortMode.asc,
                              child: Text(
                                'A-Z',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            DropdownMenuItem(
                              value: SortMode.desc,
                              child: Text(
                                'Z-A',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(12),
                          icon: const Icon(Icons.sort, size: 20),
                          isDense: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = items[index];
                    return _GridCard(
                      item: item,
                      type: widget.type,
                      onDelete: () => _confirmDelete(item.id),
                      onEdit: () => _edit(item),
                    );
                  }, childCount: items.length),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 260,
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
  final ItemType type;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _GridCard({
    required this.item,
    required this.type,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onEdit,
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
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Material(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Material(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 18,
                          ),
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: type == ItemType.vegetable
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      type == ItemType.vegetable ? 'Vegetable' : 'Ration',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: type == ItemType.vegetable
                            ? Colors.green[800]
                            : Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
