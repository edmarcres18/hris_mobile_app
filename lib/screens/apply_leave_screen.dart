import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasSignature = false;
  
  String _selectedLeaveType = 'Vacation Leave';
  final List<String> _leaveTypes = [
    'Vacation Leave',
    'Sick Leave',
    'Emergency Leave'
  ];
  
  DateTime? _startDate;
  DateTime? _endDate;
  
  final int _availableLeaves = 21; // This would normally come from an API
  
  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _reasonController.dispose();
    _contactController.dispose();
    _signatureController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (DateTime.now()) : (_startDate ?? DateTime.now()),
      firstDate: isStartDate ? DateTime.now() : (_startDate ?? DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('MMM dd, yyyy').format(picked);
          // Reset end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
            _endDateController.text = '';
          }
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('MMM dd, yyyy').format(picked);
        }
      });
    }
  }
  
  int _calculateLeaveDays() {
    if (_startDate == null || _endDate == null) return 0;
    
    // Calculate weekdays only
    int days = 0;
    DateTime date = _startDate!;
    
    while (date.isBefore(_endDate!) || date.isAtSameMomentAs(_endDate!)) {
      // Skip weekends (Saturday and Sunday)
      if (date.weekday != DateTime.saturday && date.weekday != DateTime.sunday) {
        days++;
      }
      date = date.add(const Duration(days: 1));
    }
    
    return days;
  }
  
  void _submitLeaveRequest() async {
    if (_formKey.currentState!.validate()) {
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
                  const Text('Success'),
                ],
              ),
              content: const Text(
                'Your leave request has been submitted successfully and is pending approval.',
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
    }
  }
  
  void _resetForm() {
    setState(() {
      _startDateController.text = '';
      _endDateController.text = '';
      _reasonController.text = '';
      _contactController.text = '';
      _signatureController.text = '';
      _selectedLeaveType = 'Vacation Leave';
      _startDate = null;
      _endDate = null;
      _hasSignature = false;
    });
  }

  void _updateProfile() {
    setState(() {
      _hasSignature = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully with signature'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaveDays = _calculateLeaveDays();
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Leave'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
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
                      // Notice Alert
                      if (!_hasSignature)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade700),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, 
                                color: Colors.amber.shade800),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Notice:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Please add your signature to your profile before applying for leave.',
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: _updateProfile,
                                      child: Text(
                                        'Update your profile here',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Leave Balance Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.8),
                                theme.colorScheme.primary.withOpacity(0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Text(
                                'Leave Balance',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildBalanceItem('$_availableLeaves', 'Available', 
                                    Colors.white, theme),
                                  Container(
                                    height: 40,
                                    width: 1,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  _buildBalanceItem('$leaveDays', 'Requested', 
                                    leaveDays > 0 ? Colors.white : Colors.white.withOpacity(0.7),
                                    theme),
                                  Container(
                                    height: 40,
                                    width: 1,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  _buildBalanceItem('${_availableLeaves - leaveDays}', 'Remaining',
                                    (_availableLeaves - leaveDays) < 5 ? 
                                      Colors.orange.shade100 : Colors.white,
                                    theme),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 28),
                      Text(
                        'Leave Application Form',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Divider(height: 30),
                      
                      // Leave Type Dropdown
                      Text(
                        'Leave Type',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(Icons.type_specimen),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, 
                            vertical: 16,
                          ),
                        ),
                        value: _selectedLeaveType,
                        items: _leaveTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedLeaveType = newValue!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a leave type';
                          }
                          return null;
                        },
                        icon: Icon(
                          Icons.arrow_drop_down_circle,
                          color: theme.colorScheme.primary,
                        ),
                        dropdownColor: Colors.white,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Date Range
                      Text(
                        'Date Range',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Dates
                      if (isWideScreen)
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(true, theme),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDateField(false, theme),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildDateField(true, theme),
                            const SizedBox(height: 16),
                            _buildDateField(false, theme),
                          ],
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Reason
                      Text(
                        'Reason',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reasonController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          hintText: 'Please provide detailed information',
                          prefixIcon: const Icon(Icons.description),
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, 
                            vertical: 16,
                          ),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please provide a reason for your leave';
                          } else if (value.length < 10) {
                            return 'Please provide a more detailed reason';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Emergency Contact
                      Text(
                        'Emergency Contact',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contactController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          hintText: 'Contact number in case of emergency',
                          prefixIcon: const Icon(Icons.contact_phone),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, 
                            vertical: 16,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (_selectedLeaveType == 'Emergency Leave' && 
                              (value == null || value.isEmpty)) {
                            return 'Emergency contact is required for Emergency Leave';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Submit and Close Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting || leaveDays == 0 || !_hasSignature ? 
                                null : _submitLeaveRequest,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 2,
                          ),
                              icon: const Icon(Icons.send),
                              label: _isSubmitting
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Submitting...'),
                                    ],
                                  )
                              : const Text(
                                    'Submit Leave Request',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                          ),
                        ],
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
  
  Widget _buildBalanceItem(String value, String label, Color textColor, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDateField(bool isStartDate, ThemeData theme) {
    return TextFormField(
      controller: isStartDate ? _startDateController : _endDateController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: isStartDate ? 'Start Date' : 'End Date',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        prefixIcon: Icon(
          isStartDate ? Icons.date_range : Icons.event_available,
          color: theme.colorScheme.primary,
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.edit_calendar),
          color: theme.colorScheme.secondary,
          onPressed: () => _selectDate(context, isStartDate),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, 
          vertical: 16,
        ),
      ),
      onTap: () => _selectDate(context, isStartDate),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return isStartDate ? 'Please select a start date' : 'Please select an end date';
        }
        return null;
      },
    );
  }
} 