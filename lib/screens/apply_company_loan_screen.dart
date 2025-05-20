import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ApplyCompanyLoanScreen extends StatefulWidget {
  const ApplyCompanyLoanScreen({super.key});

  @override
  State<ApplyCompanyLoanScreen> createState() => _ApplyCompanyLoanScreenState();
}

class _ApplyCompanyLoanScreenState extends State<ApplyCompanyLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();
  bool _isSubmitting = false;
  
  String _selectedLoanType = 'Personal Loan';
  final List<String> _loanTypes = [
    'Personal Loan',
    'Emergency Loan',
    'Housing Loan',
    'Education Loan',
    'Vehicle Loan',
    'Medical Loan',
  ];
  
  int _selectedTerm = 12; // Default to 12 months
  final List<int> _availableTerms = [3, 6, 12, 24, 36, 48, 60];
  
  double _interestRate = 0.05; // 5% annual interest
  double _loanAmount = 0.0;
  final double _maxLoanAmount = 50000.0; // Maximum allowed loan amount
  
  final currencyFormatter = NumberFormat("#,##0.00", "en_US");
  
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _termsController.dispose();
    super.dispose();
  }
  
  void _calculateLoanDetails() {
    try {
      if (_amountController.text.isEmpty) {
        setState(() {
          _loanAmount = 0.0;
        });
        return;
      }
      
      // Parse amount string to double
      String cleanAmount = _amountController.text.replaceAll(',', '');
      double principal = double.parse(cleanAmount);
      
      setState(() {
        _loanAmount = principal;
      });
    } catch (e) {
      print('Error calculating loan details: $e');
    }
  }
  
  double _calculateMonthlyPayment() {
    if (_loanAmount <= 0 || _selectedTerm <= 0) return 0.0;
    
    // Monthly interest rate
    double monthlyRate = _interestRate / 12.0;
    
    // Calculate payment using amortization formula
    double payment = (_loanAmount * monthlyRate * pow(1 + monthlyRate, _selectedTerm)) / 
                     (pow(1 + monthlyRate, _selectedTerm) - 1);
    
    return payment;
  }
  
  double _calculateTotalPayment() {
    return _calculateMonthlyPayment() * _selectedTerm;
  }
  
  double _calculateTotalInterest() {
    return _calculateTotalPayment() - _loanAmount;
  }
  
  void _submitLoanRequest() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      setState(() {
        _isSubmitting = true;
      });
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Application Submitted'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your loan application has been submitted successfully and is pending approval.',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loan ID: LN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 13)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetForm();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } else if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  void _resetForm() {
    setState(() {
      _amountController.text = '';
      _purposeController.text = '';
      _termsController.text = '';
      _selectedLoanType = 'Personal Loan';
      _selectedTerm = 12;
      _loanAmount = 0.0;
      _agreeToTerms = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthlyPayment = _calculateMonthlyPayment();
    final totalInterest = _calculateTotalInterest();
    final totalPayment = _calculateTotalPayment();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Company Loan'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 600;
              
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWideScreen ? 
                    constraints.maxWidth * 0.1 : 16.0,
                  vertical: 24.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Loan Calculator Card
                      if (_loanAmount > 0)
                        Card(
                          elevation: 4,
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  'Loan Summary',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildLoanSummaryItem(
                                      label: 'Principal',
                                      value: '\$${currencyFormatter.format(_loanAmount)}',
                                      icon: Icons.attach_money,
                                      theme: theme,
                                    ),
                                    _buildLoanSummaryItem(
                                      label: 'Term',
                                      value: '$_selectedTerm months',
                                      icon: Icons.calendar_today,
                                      theme: theme,
                                    ),
                                    _buildLoanSummaryItem(
                                      label: 'Interest',
                                      value: '${(_interestRate * 100).toStringAsFixed(1)}%',
                                      icon: Icons.percent,
                                      theme: theme,
                                    ),
                                  ],
                                ),
                                
                                const Divider(height: 32),
                                
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildLoanSummaryItem(
                                      label: 'Monthly Payment',
                                      value: '\$${currencyFormatter.format(monthlyPayment)}',
                                      icon: Icons.payment,
                                      theme: theme,
                                      isHighlighted: true,
                                    ),
                                    _buildLoanSummaryItem(
                                      label: 'Total Interest',
                                      value: '\$${currencyFormatter.format(totalInterest)}',
                                      icon: Icons.account_balance,
                                      theme: theme,
                                    ),
                                    _buildLoanSummaryItem(
                                      label: 'Total Payment',
                                      value: '\$${currencyFormatter.format(totalPayment)}',
                                      icon: Icons.summarize,
                                      theme: theme,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      Text(
                        'Loan Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Loan Type Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Loan Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.account_balance_wallet),
                        ),
                        value: _selectedLoanType,
                        items: _loanTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedLoanType = newValue!;
                            // Adjust interest rate based on loan type
                            if (newValue == 'Emergency Loan') {
                              _interestRate = 0.03; // 3%
                            } else if (newValue == 'Housing Loan') {
                              _interestRate = 0.06; // 6%
                            } else if (newValue == 'Education Loan') {
                              _interestRate = 0.04; // 4%
                            } else if (newValue == 'Vehicle Loan') {
                              _interestRate = 0.055; // 5.5%
                            } else if (newValue == 'Medical Loan') {
                              _interestRate = 0.02; // 2%
                            } else {
                              _interestRate = 0.05; // 5% default
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a loan type';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Loan Amount Field
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            if (newValue.text.isEmpty) {
                              return newValue;
                            }
                            double value = double.parse(newValue.text);
                            String newText = currencyFormatter.format(value);
                            return TextEditingValue(
                              text: newText,
                              selection: TextSelection.collapsed(offset: newText.length),
                            );
                          }),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Loan Amount',
                          hintText: 'Enter amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.attach_money),
                          suffixText: 'Max: \$${currencyFormatter.format(_maxLoanAmount)}',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a loan amount';
                          }
                          
                          String cleanValue = value.replaceAll(',', '');
                          double amount = double.tryParse(cleanValue) ?? 0;
                          
                          if (amount <= 0) {
                            return 'Amount must be greater than zero';
                          }
                          
                          if (amount > _maxLoanAmount) {
                            return 'Amount exceeds maximum allowed';
                          }
                          
                          return null;
                        },
                        onChanged: (value) {
                          _calculateLoanDetails();
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Loan Term Dropdown
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'Loan Term (months)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.calendar_month),
                        ),
                        value: _selectedTerm,
                        items: _availableTerms.map((int term) {
                          return DropdownMenuItem<int>(
                            value: term,
                            child: Text('$term months'),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _selectedTerm = newValue!;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a loan term';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Purpose TextArea
                      TextFormField(
                        controller: _purposeController,
                        decoration: InputDecoration(
                          labelText: 'Purpose of Loan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please provide the purpose of this loan';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Terms and Conditions Checkbox
                      CheckboxListTile(
                        title: const Text('I agree to the terms and conditions'),
                        subtitle: Text(
                          'By checking this box, I confirm that I have read and agree to the loan terms and repayment conditions.',
                          style: theme.textTheme.bodySmall,
                        ),
                        value: _agreeToTerms,
                        activeColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        onChanged: (bool? value) {
                          setState(() {
                            _agreeToTerms = value!;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting || _loanAmount <= 0 ? null : _submitLoanRequest,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator()
                              : const Text(
                                  'Submit Loan Application',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoanSummaryItem({
    required String label,
    required String value,
    required IconData icon,
    required ThemeData theme,
    bool isHighlighted = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: isHighlighted ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlighted ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  
  // Helper for math power function
  double pow(double x, int y) {
    double result = 1.0;
    for (int i = 0; i < y; i++) {
      result *= x;
    }
    return result;
  }
} 