import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/receipt_model.dart';
import '../../models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';
import '../../viewmodels/receipt_scanner/receipt_verification_viewmodel.dart';


class ReceiptVerificationPage extends StatelessWidget {
  final ReceiptModel receiptData;
  const ReceiptVerificationPage({required this.receiptData, super.key});

  @override
  Widget build(BuildContext context) {
    // Using the MockTransactionRepository to mock Firebase
    return ChangeNotifierProvider(
      create: (context) => ReceiptVerificationViewModel(
        transactionRepository: MockTransactionRepository(), 
        initialReceiptData: receiptData,
      ),
      child: const _ReceiptVerificationForm(),
    );
  }
}

class _ReceiptVerificationForm extends StatefulWidget {
  const _ReceiptVerificationForm();

  @override
  State<_ReceiptVerificationForm> createState() => _ReceiptVerificationFormState();
}

class _ReceiptVerificationFormState extends State<_ReceiptVerificationForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _vendorController;
  late TextEditingController _totalController;
  late TextEditingController _dateController;
  late String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final vm = context.read<ReceiptVerificationViewModel>();
    _vendorController = TextEditingController(text: vm.initialVendor);
    
    // Only supports USD for now
    String initialTotalText = vm.initialTotal.trim();
    if (initialTotalText.isNotEmpty && !initialTotalText.startsWith(r'$')) {
      initialTotalText = r'$' + initialTotalText;
    }
    _totalController = TextEditingController(text: initialTotalText);
    
    _dateController = TextEditingController(text: vm.initialDate);
    
    // Initialize selected category to null, so the user must select one manually
    _selectedCategory = null; 
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _totalController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _capitalize(String s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReceiptVerificationViewModel>();
    final theme = Theme.of(context);

    // List of category names dropdown
    final List<String> categoryNames = ExpenseCategory.values
        .map((e) => e.toString().split('.').last)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verify Receipt Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),

      /// All fields are editable by the user here.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTotalAmountField(theme, _totalController),
                  
                  const SizedBox(height: 24),

                  // Store name
                  _buildTextField(
                    controller: _vendorController,
                    label: 'Store / Vendor Name',
                    icon: Icons.store,
                    validator: (v) => v!.isEmpty ? 'Vendor name is required.' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Field (tapping opens Date Picker)
                  _buildDateField(context, theme),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  _buildCategoryDropdown(theme, categoryNames),
                  const SizedBox(height: 24),
                  
                  if (vm.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        vm.errorMessage!,
                        style: theme.textTheme.titleMedium!.copyWith(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  const SizedBox(height: 32),

                  // Save Button
                  _buildSaveButton(context, vm),

                  const SizedBox(height: 16),
                  
                  // Cancel Button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Navigate back to the root screen to cancel the transaction
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.primary, 
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Total dollar amount to add to expenses
  Widget _buildTotalAmountField(ThemeData theme, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Total Amount Detected',
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8), 
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center, 
          style: theme.textTheme.headlineLarge!.copyWith( 
            color: theme.colorScheme.onSurface, 
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            prefixText: '', 
            border: InputBorder.none, 
            isDense: true, 
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            hintText: r'$0.00',
          ),
          
          validator: (v) {
            if (v == null || v.isEmpty) return 'Total is required.';
            
            // Validate total value
            final cleanedValue = v.startsWith(r'$') ? v.substring(1) : v;

            if (double.tryParse(cleanedValue) == null) return 'Must be a valid number.';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }

  Widget _buildDateField(BuildContext context, ThemeData theme) {
    return InkWell(
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          setState(() {
            _dateController.text = pickedDate.toIso8601String().split('T').first;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Purchase Date',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        baseStyle: theme.textTheme.titleMedium,
        child: Text(_dateController.text),
      ),
    );
  }
  
  Widget _buildCategoryDropdown(ThemeData theme, List<String> categoryNames) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: 'Category',
            style: TextStyle(
              color: theme.colorScheme.onSurface, 
              fontSize: 16,
            ),
            // Showing the user that category is a required field not autofilled in
            children: <TextSpan>[
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      // Add validator to ensure a category is selected
      validator: (v) => v == null ? 'Please select a category.' : null,
      items: categoryNames.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(_capitalize(category)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        // Update the nullable state
        setState(() {
          _selectedCategory = newValue;
        });
      },
    );
  }

  Widget _buildSaveButton(BuildContext context, ReceiptVerificationViewModel vm) {
    return ElevatedButton.icon(
      onPressed: vm.isLoading
          ? null
          : () async {
              if (_formKey.currentState!.validate()) {
                // Ensures we pass the clean number to the view model
                final rawTotal = _totalController.text.startsWith(r'$') 
                    ? _totalController.text.substring(1) 
                    : _totalController.text;

                final success = await vm.saveTransaction(
                  vendor: _vendorController.text,
                  total: rawTotal, // Pass the cleaned total
                  date: _dateController.text,
                  category: _selectedCategory!, // Pass the currently selected category by the user
                );
                if (success) {
                  // Navigate back to the main screen after successful save
                  if (context.mounted) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                } else {
                  // If transaction failed show an error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(vm.errorMessage ?? 'Failed to save transaction.')),
                  );
                }
              }
            },
      icon: vm.isLoading
          ? const SizedBox(
              height: 20, 
              width: 20, 
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
            )
          : const Icon(Icons.check_circle_outline),
      label: Text(vm.isLoading ? 'Saving...' : 'Save Transaction'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}