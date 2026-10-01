import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostTaskScreen extends StatefulWidget {
  const PostTaskScreen({super.key});

  @override
  State<PostTaskScreen> createState() => _PostTaskScreenState();
}

class _PostTaskScreenState extends State<PostTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers matching TaskModel requirements
  final _titleController = TextEditingController();
  final _budgetController = TextEditingController();
  final _workersController = TextEditingController(text: '1'); // Added for numOfWorkers
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Cleaning', 'icon': Icons.cleaning_services_outlined},
    {'name': 'Repairs', 'icon': Icons.build_outlined},
    {'name': 'Gardening', 'icon': Icons.eco_outlined},
    {'name': 'Delivery', 'icon': Icons.inventory_2_outlined},
    {'name': 'Painting', 'icon': Icons.format_paint_outlined},
    {'name': 'Shopping', 'icon': Icons.shopping_cart_outlined},
    {'name': 'Pet Care', 'icon': Icons.pets},
    {'name': 'Tech Help', 'icon': Icons.computer_outlined},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _budgetController.dispose();
    _workersController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Create a document reference first to generate the taskID
      final docRef = FirebaseFirestore.instance.collection('Tasks').doc();

      // Writing exact fields to match your TaskModel
      await docRef.set({
        'taskID': docRef.id,
        'creatorID': currentUser.uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'status': 'Active', // Matches the dashboard UI requirement
        'paymentAmount': double.tryParse(_budgetController.text.replaceAll('R', '').trim()) ?? 0.0,
        'numOfWorkers': int.tryParse(_workersController.text.trim()) ?? 1,
        'category': _selectedCategory,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task successfully posted!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Return to the dashboard automatically
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting task: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1976D2); // Standardized team color

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: themeColor,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Post a Task', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('TASK TITLE *'),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('e.g. Fix leaking sink'),
                validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 20),
              
              _buildLabel('CATEGORY *'),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat['name'];
                  return InkWell(
                    onTap: () => setState(() => _selectedCategory = cat['name']),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? themeColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? themeColor : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat['icon'], color: isSelected ? Colors.white : Colors.grey.shade600, size: 24),
                          const SizedBox(height: 6),
                          Text(
                            cat['name'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('BUDGET (R) *'),
                        TextFormField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('e.g. 350'),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('WORKERS NEEDED *'),
                        TextFormField(
                          controller: _workersController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('e.g. 1'),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildLabel('LOCATION *'),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('e.g. Bellville, Cape Town'),
                validator: (val) => val == null || val.isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 20),
              
              _buildLabel('DESCRIPTION *'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _inputDecoration('What needs doing? Materials available, access info...'),
                validator: (val) => val == null || val.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Post Task - It\'s Free',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1976D2)),
      ),
    );
  }
}