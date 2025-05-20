import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ApplyNightPremiumScreen extends StatefulWidget {
  const ApplyNightPremiumScreen({super.key});

  @override
  State<ApplyNightPremiumScreen> createState() => _ApplyNightPremiumScreenState();
}

class _ApplyNightPremiumScreenState extends State<ApplyNightPremiumScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  
  DateTime? _startDate;
  DateTime? _endDate;
  final TimeOfDay _nightShiftStart = const TimeOfDay(hour: 22, minute: 0); // 10 PM
  final TimeOfDay _nightShiftEnd = const TimeOfDay(hour: 6, minute: 0); // 6 AM
  
  bool _includeWeekends = false;
  final double _premiumRate = 0.15; // 15% premium over base pay
  final double _baseHourlyRate = 15.50; // This would normally come from an API
  
  int _calculatedNights = 0;
  double _estimatedPremium = 0.0;
  
  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? DateTime.now() : (_startDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Allow backdating within reason
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
        
        _calculateNightPremium();
      });
    }
  }
  
  void _calculateNightPremium() {
    if (_startDate == null || _endDate == null) {
      setState(() {
        _calculatedNights = 0;
        _estimatedPremium = 0.0;
      });
      return;
    }
    
    int nights = 0;
    DateTime date = _startDate!;
    
    // Calculate number of night shifts
    while (date.isBefore(_endDate!) || date.isAtSameMomentAs(_endDate!)) {
      final bool isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      
      // Skip weekends if not included
      if (!isWeekend || _includeWeekends) {
        nights++;
      }
      
      date = date.add(const Duration(days: 1));
    }
    
    // Calculate total hours (assuming 8-hour shift)
    final double totalHours = nights * 8.0;
    
    // Calculate estimated premium
    final double hourlyPremium = _baseHourlyRate * _premiumRate;
    final double totalPremium = totalHours * hourlyPremium;
    
    setState(() {
      _calculatedNights = nights;
      _estimatedPremium = totalPremium;
    });
  }
  
  void _submitNightPremiumRequest() async {
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
                'Your night premium request has been submitted successfully and is pending approval.',
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
      _startDate = null;
      _endDate = null;
      _includeWeekends = false;
      _calculatedNights = 0;
      _estimatedPremium = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double nightPremiumPercentage = _premiumRate * 100;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Night Premium'),
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
                      // Night Premium Info Card
                      Card(
                        elevation: 4,
                        color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Night Shift Premium',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildInfoItem(
                                    icon: Icons.nightlight_round,
                                    label: 'Hours',
                                    value: '${_nightShiftStart.format(context)} - ${_nightShiftEnd.format(context)}',
                                    theme: theme,
                                  ),
                                  _buildInfoItem(
                                    icon: Icons.trending_up,
                                    label: 'Premium',
                                    value: '$nightPremiumPercentage%',
                                    theme: theme,
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text(
                                'Employees working between ${_nightShiftStart.format(context)} and ${_nightShiftEnd.format(context)} are entitled to a night shift premium of $nightPremiumPercentage% of their base hourly rate.',
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Premium Summary Card
                      if (_calculatedNights > 0)
                        Card(
                          elevation: 4,
                          color: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  'Premium Summary',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          '$_calculatedNights',
                                          style: theme.textTheme.headlineMedium?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Nights',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          '${_calculatedNights * 8}',
                                          style: theme.textTheme.headlineMedium?.copyWith(
                                            color: theme.colorScheme.tertiary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Hours',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          '\$${_estimatedPremium.toStringAsFixed(2)}',
                                          style: theme.textTheme.headlineMedium?.copyWith(
                                            color: theme.colorScheme.secondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Premium',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      Text(
                        'Request Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Date Fields
                      if (isWideScreen)
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(true),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDateField(false),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildDateField(true),
                            const SizedBox(height: 16),
                            _buildDateField(false),
                          ],
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Include Weekends Switch
                      SwitchListTile(
                        title: const Text('Include Weekends'),
                        subtitle: const Text('Toggle to include weekend nights in your premium calculation'),
                        value: _includeWeekends,
                        activeColor: theme.colorScheme.primary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
                        ),
                        onChanged: (bool value) {
                          setState(() {
                            _includeWeekends = value;
                            _calculateNightPremium();
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Reason TextArea
                      TextFormField(
                        controller: _reasonController,
                        decoration: InputDecoration(
                          labelText: 'Additional Notes (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.note_alt),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting || _calculatedNights <= 0 ? null : _submitNightPremiumRequest,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator()
                              : const Text(
                                  'Submit Request',
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
  
  Widget _buildDateField(bool isStartDate) {
    return TextFormField(
      controller: isStartDate ? _startDateController : _endDateController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: isStartDate ? 'Start Date' : 'End Date',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: IconButton(
          icon: const Icon(Icons.edit_calendar),
          onPressed: () => _selectDate(context, isStartDate),
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
  
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 28,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
} 