import 'package:flutter/material.dart';

import '../models/ration_item.dart';
import '../services/storage_service.dart';

class FinishedItemsScreen extends StatefulWidget {
  const FinishedItemsScreen({super.key});

  @override
  State<FinishedItemsScreen> createState() => _FinishedItemsScreenState();
}

class _FinishedItemsScreenState extends State<FinishedItemsScreen> {
  final StorageService _storage = StorageService();
  List<RationItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _storage.getFinished();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _refresh() => _load();

  Future<void> _delete(String id) async {
    await _storage.deleteById(StorageService.keyFinished, id);
    if (!mounted) return;
    setState(() {
      _items.removeWhere((e) => e.id == id);
    });
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<RationItem>(
      context: context,
      builder: (context) => const _AddFinishedDialog(),
    );
    if (result != null) {
      if (!mounted) return;
      setState(() {
        _items.insert(0, result);
      });
    }
  }

  Future<void> _showEditDialog(RationItem item) async {
    final result = await showDialog<RationItem>(
      context: context,
      builder: (context) => _EditFinishedDialog(item: item),
    );
    if (result != null) {
      if (!mounted) return;
      setState(() {
        final idx = _items.indexWhere((e) => e.id == result.id);
        if (idx != -1) _items[idx] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Finished Items')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? const Center(child: Text('No finished items'))
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.only(
                    bottom: 96,
                    left: 12,
                    right: 12,
                    top: 12,
                  ),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        color: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _delete(item.id),
                      child: Card(
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported),
                            ),
                          ),
                          title: Text(item.name),
                          subtitle: Text(
                            item.type == ItemType.vegetable
                                ? 'Vegetable'
                                : 'Ration',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showEditDialog(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(item.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Finished'),
        ),
      ),
    );
  }
}

class _EditFinishedDialog extends StatefulWidget {
  final RationItem item;
  const _EditFinishedDialog({required this.item});

  @override
  State<_EditFinishedDialog> createState() => _EditFinishedDialogState();
}

class _EditFinishedDialogState extends State<_EditFinishedDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl = TextEditingController(
    text: widget.item.name,
  );
  late final TextEditingController _imageCtrl = TextEditingController(
    text: widget.item.imageUrl,
  );
  late ItemType _type = widget.item.type;
  bool _saving = false;
  final StorageService _storage = StorageService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final updated = widget.item.copyWith(
      name: _nameCtrl.text.trim(),
      imageUrl: _imageCtrl.text.trim(),
      type: _type,
    );
    await _storage.updateFinished(updated);
    if (mounted) Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Finished Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ItemType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(
                    value: ItemType.vegetable,
                    child: Text('Vegetable'),
                  ),
                  DropdownMenuItem(
                    value: ItemType.ration,
                    child: Text('Ration'),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => _type = v ?? ItemType.vegetable),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageCtrl,
                decoration: const InputDecoration(labelText: 'Image URL'),
                keyboardType: TextInputType.url,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter image URL' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _AddFinishedDialog extends StatefulWidget {
  const _AddFinishedDialog();

  @override
  State<_AddFinishedDialog> createState() => _AddFinishedDialogState();
}

class _AddFinishedDialogState extends State<_AddFinishedDialog> {
  final StorageService _storage = StorageService();
  ItemType _type = ItemType.vegetable;
  List<RationItem> _options = [];
  String? _selectedId;
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loading = true;
      _selectedId = null;
    });
    final list = _type == ItemType.vegetable
        ? await _storage.getVegetables()
        : await _storage.getRations();
    if (!mounted) return;
    setState(() {
      _options = list;
      _loading = false;
    });
  }

  List<RationItem> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _options;
    return _options.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _save() async {
    if (_selectedId == null) return;
    final selected = _options.firstWhere((e) => e.id == _selectedId);
    final item = RationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: selected.name,
      imageUrl: selected.imageUrl,
      type: _type,
    );
    await _storage.addFinished(item);
    if (mounted) Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Finished Item'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ItemType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(
                  value: ItemType.vegetable,
                  child: Text('Vegetable'),
                ),
                DropdownMenuItem(value: ItemType.ration, child: Text('Ration')),
              ],
              onChanged: (v) {
                setState(() => _type = v ?? ItemType.vegetable);
                _loadOptions();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search',
              ),
            ),
            const SizedBox(height: 12),
            _loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                : SizedBox(
                    height: 300,
                    child: _filtered.isEmpty
                        ? const Center(child: Text('No items in this category'))
                        : ListView.separated(
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final e = _filtered[index];
                              return RadioListTile<String>(
                                value: e.id,
                                groupValue: _selectedId,
                                onChanged: (v) =>
                                    setState(() => _selectedId = v),
                                title: Text(e.name),
                                secondary: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    e.imageUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedId == null ? null : _save,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
