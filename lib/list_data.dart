import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'globals.dart' as globals;
import 'add_item_form.dart';
import 'edit_data.dart';
import 'auth_screen.dart';

class ListData extends StatefulWidget {
  const ListData({super.key});

  @override
  State<ListData> createState() => _ListDataState();
}

class _ListDataState extends State<ListData> {
  List<dynamic> _items = []; // Components from MySQL
  bool _isLoading = true;
  double _budget = 0; // User's total budget

  @override
  void initState() {
    super.initState();
    _loadBudget();
    _fetchItems();
  }

  // Calculate total spent across all components
  double get _totalSpent {
    double total = 0;
    for (var item in _items) {
      total += (item['price'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  // Calculate remaining budget
  double get _remainingBudget => _budget - _totalSpent;

  // 1. GET: Fetch the user's budget from MySQL
  Future<void> _loadBudget() async {
    try {
      final url = '${globals.baseUrl}budget.php?user_id=${globals.currentUserId}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _budget = (data['budget'] as num?)?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      debugPrint('Error loading budget: $e');
    }
  }

  // 2. POST: Update the user's budget in MySQL
  Future<void> _saveBudget(double newBudget) async {
    setState(() => _budget = newBudget); // Update UI immediately
    try {
      await http.post(
        Uri.parse('${globals.baseUrl}budget.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': globals.currentUserId,
          'budget': newBudget,
        }),
      );
    } catch (e) {
      debugPrint('Error saving budget: $e');
    }
  }

  // 3. GET: Fetch all parts for the logged-in user
  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final url = '${globals.baseUrl}get_items.php?user_id=${globals.currentUserId}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          _items = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load parts: $e')),
        );
      }
    }
  }

  // 4. POST: Delete an item from MySQL
  Future<void> _deleteItem(dynamic id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Component'),
        content: Text('Are you sure you want to remove "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await http.post(
        Uri.parse('${globals.baseUrl}delete_item.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );
      _fetchItems(); // Refresh list after deleting
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e')),
        );
      }
    }
  }

  // Show dialog to set total budget
  void _showSetBudgetDialog() {
    final controller = TextEditingController(
      text: _budget > 0 ? _budget.toStringAsFixed(0) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Total Budget'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(prefixText: '\$ ', hintText: 'e.g. 1500'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val >= 0) _saveBudget(val);
              Navigator.pop(ctx);
            },
            child: const Text('Save Budget'),
          ),
        ],
      ),
    );
  }

  // Logout and return to Auth screen
  void _logout() {
    globals.currentUserId = null;
    globals.currentUsername = null;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  // Helper icon for each hardware category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cpu':
        return Icons.memory;
      case 'gpu':
        return Icons.videogame_asset;
      case 'motherboard':
        return Icons.developer_board;
      case 'ram':
        return Icons.straighten;
      case 'storage':
        return Icons.sd_storage;
      case 'monitor':
        return Icons.monitor;
      case 'peripheral':
        return Icons.keyboard;
      default:
        return Icons.devices_other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasBudget = _budget > 0;
    final bool isOverBudget = hasBudget && _remainingBudget < 0;

    // Progress percentage (0.0 to 1.0)
    final double progress = hasBudget ? (_totalSpent / _budget).clamp(0.0, 1.0) : 0.0;

    // Progress bar color based on spending level
    Color statusColor = const Color(0xFF16A34A); // Green
    if (isOverBudget) {
      statusColor = const Color(0xFFDC2626); // Red
    } else if (hasBudget && (_totalSpent / _budget) > 0.85) {
      statusColor = const Color(0xFFF59E0B); // Orange / warning
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PC Rig Builder',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'User: ${globals.currentUsername ?? "Builder"}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Set Budget',
            onPressed: _showSetBudgetDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchItems,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Clean Budget Card ──
                  Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showSetBudgetDialog,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.account_balance_wallet, color: statusColor, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hasBudget ? 'Total Budget (tap to edit)' : 'No budget set',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                      ),
                                      Text(
                                        hasBudget ? '\$${_budget.toStringAsFixed(2)}' : 'Tap to set budget',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF94A3B8)),
                              ],
                            ),

                            if (hasBudget) ...[
                              const SizedBox(height: 16),
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation(statusColor),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Spent & Remaining stats
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        const Text('Spent', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                        const SizedBox(height: 2),
                                        Text(
                                          '\$${_totalSpent.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        const Text('Remaining', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                        const SizedBox(height: 2),
                                        Text(
                                          '\$${_remainingBudget.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Over-budget alert
                            if (isOverBudget) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Over budget by \$${(_remainingBudget.abs()).toStringAsFixed(2)}!',
                                      style: const TextStyle(
                                        color: Color(0xFFDC2626),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Components',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '${_items.length} parts',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Parts list ──
                  if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.layers_clear_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No components added yet',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap the "+ Add Part" button below to start your build',
                            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._items.map((item) {
                      final name = item['name'] ?? '';
                      final category = item['category'] ?? 'Other';
                      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                      final notes = item['notes'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_getCategoryIcon(category), color: const Color(0xFF2563EB), size: 22),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          subtitle: Text(
                            notes.isNotEmpty ? '$category • $notes' : category,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\$${price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFF94A3B8)),
                                onPressed: () => _deleteItem(item['id'], name),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => EditData(
                                  item: Map<String, dynamic>.from(item),
                                  onItemUpdated: _fetchItems,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => AddItemForm(
                onItemAdded: _fetchItems,
                remainingBudget: _remainingBudget,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Part', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
