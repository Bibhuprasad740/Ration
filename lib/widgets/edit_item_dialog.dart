import 'package:flutter/material.dart';

import '../models/ration_item.dart';
import '../services/storage_service.dart';

class EditItemDialog extends StatefulWidget {
  final RationItem item;
  final ItemType type;
  const EditItemDialog({super.key, required this.item, required this.type});

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _imageCtrl;
  bool _saving = false;
  final StorageService _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _imageCtrl = TextEditingController(text: widget.item.imageUrl);
  }

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
      type: widget.type,
    );
    if (widget.type == ItemType.vegetable) {
      await _storage.updateVegetable(updated);
    } else {
      await _storage.updateRation(updated);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.type == ItemType.vegetable ? 'Vegetable' : 'Ration'}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageCtrl,
                decoration: const InputDecoration(labelText: 'Image URL'),
                keyboardType: TextInputType.url,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter image URL' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).maybePop(), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save')),
      ],
    );
  }
}
