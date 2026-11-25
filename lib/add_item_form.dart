import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'globals.dart' as globals;

class AddItemForm extends StatefulWidget {
  final VoidCallback onItemAdded;
  final double remainingBudget;

  const AddItemForm({
    super.key,
    required this.onItemAdded,
    required this.remainingBudget,
  });

  @override
  State<AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'CPU';
  bool _isSaving = false;

  final List<String> _categories = [
    'CPU', 'GPU', 'Motherboard', 'RAM', 'Storage', 'Monitor', 'Peripheral', 'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Sends new part to backend API
  Future<void> _savePart() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final response = await http.post(
        Uri.parse('${globals.baseUrl}add_item.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': globals.currentUserId,
          'name': _nameController.text.trim(),
          'category': _selectedCategory,
          'price': double.parse(_priceController.text.trim()),
          'notes': _notesController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onItemAdded(); // Refresh list in parent screen
        if (mounted) Navigator.pop(context); // Close this screen
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

  double? get _enteredPrice => double.tryParse(_priceController.text.trim());

  @override
  Widget build(BuildContext context) {
    final bool exceedsRemaining = widget.remainingBudget > 0 &&
        _enteredPrice != null &&
        _enteredPrice! > widget.remainingBudget;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Component')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Remaining budget badge
              if (widget.remainingBudget > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Text(
                        'Remaining budget: \$${widget.remainingBudget.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ],
                  ),
                ),

              // Name field
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

              // Price field
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price *', prefixText: '\$ '),
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  final parsed = double.tryParse(val?.trim() ?? '');
                  if (parsed == null || parsed <= 0) return 'Enter a valid price';
                  return null;
                },
              ),

              // Over-budget live warning
              if (exceedsRemaining) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                    const SizedBox(width: 6),
                    Text(
                      'Exceeds remaining budget by \$${(_enteredPrice! - widget.remainingBudget).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // Notes field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePart,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add Component', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
