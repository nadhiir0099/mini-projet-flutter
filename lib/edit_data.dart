import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'globals.dart' as globals;

class EditData extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onItemUpdated;

  const EditData({
    super.key,
    required this.item,
    required this.onItemUpdated,
  });

  @override
  State<EditData> createState() => _EditDataState();
}

class _EditDataState extends State<EditData> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;

  String _selectedCategory = 'CPU';
  bool _isSaving = false;

  final List<String> _categories = [
    'CPU', 'GPU', 'Motherboard', 'RAM', 'Storage', 'Monitor', 'Peripheral', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populate fields with existing item data
    _nameController = TextEditingController(text: widget.item['name']?.toString() ?? '');
    _priceController = TextEditingController(text: widget.item['price']?.toString() ?? '');
    _notesController = TextEditingController(text: widget.item['notes']?.toString() ?? '');

    final existingCat = widget.item['category']?.toString() ?? 'CPU';
    if (_categories.contains(existingCat)) {
      _selectedCategory = existingCat;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Updates component in MySQL via POST
  Future<void> _updatePart() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final response = await http.post(
        Uri.parse('${globals.baseUrl}edit_item.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': widget.item['id'],
          'name': _nameController.text.trim(),
          'category': _selectedCategory,
          'price': double.parse(_priceController.text.trim()),
          'notes': _notesController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        widget.onItemUpdated(); // Refresh parent list
        if (mounted) Navigator.pop(context); // Close edit screen
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Component')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Component Name *'),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 14),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 14),

              // Price
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price *', prefixText: '\$ '),
                validator: (val) {
                  final parsed = double.tryParse(val?.trim() ?? '');
                  if (parsed == null || parsed <= 0) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updatePart,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
