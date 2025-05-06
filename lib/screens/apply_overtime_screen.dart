import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ApplyOvertimeScreen extends StatefulWidget {
  const ApplyOvertimeScreen({super.key});

  @override
  State<ApplyOvertimeScreen> createState() => _ApplyOvertimeScreenState();
}

class _ApplyOvertimeScreenState extends State<ApplyOvertimeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  
  String _overtimeType = 'Regular Overtime';
  final List<String> _overtimeTypes = [
    'Regular Overtime',
    'Holiday Overtime',
    'Weekend Overtime',
    'Emergency Overtime',
  ];
  
  double _calculatedHours = 0.0;
  double _hourlyRate = 15.50; // This would normally come from an API

  @override
  void dispose() {
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)), // Allow backdating up to a week
      lastDate: DateTime.now().add(const Duration(days: 30)),
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
        _selectedDate = picked;
        _dateController.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? TimeOfDay.now() : (_startTime ?? TimeOfDay.now()),
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
        if (isStartTime) {
          _startTime = picked;
          _startTimeController.text = picked.format(context);
          // Reset end time if it's earlier than start time
          if (_endTime != null && _isEndTimeBeforeStartTime()) {
            _endTime = null;
            _endTimeController.text = '';
          }
        } else {
          _endTime = picked;
          _endTimeController.text = picked.format(context);
        }
        
        _calculateOvertime();
      });
    }
  }
  
  bool _isEndTimeBeforeStartTime() {
    if (_startTime == null || _endTime == null) return false;
    
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    
    // If end time is earlier than start time, we assume it's for the next day
    return endMinutes < startMinutes;
  }
  
  void _calculateOvertime() {
    if (_startTime == null || _endTime == null) {
      setState(() {
        _calculatedHours = 0.0;
      });
      return;
    }
    
    int startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    int endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    
    // If end time is earlier than start time, assume it's next day
    if (endMinutes < startMinutes) {
      endMinutes += 24 * 60; // Add 24 hours (in minutes)
    }
    
    double hours = (endMinutes - startMinutes) / 60.0;
    // Round to nearest quarter hour
    hours = (hours * 4).round() / 4;
    
    setState(() {
      _calculatedHours = hours;
    });
  }
  
  void _submitOvertimeRequest() async {
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
                'Your overtime request has been submitted successfully and is pending approval.',
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
      _dateController.text = '';
      _startTimeController.text = '';
      _endTimeController.text = '';
      _reasonController.text = '';
      _selectedDate = null;
      _startTime = null;
      _endTime = null;
      _calculatedHours = 0.0;
      _overtimeType = 'Regular Overtime';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Calculate estimated pay
    double rate = _hourlyRate;
    if (_overtimeType == 'Holiday Overtime') {
      rate = _hourlyRate * 2.0; // Double pay for holidays
    } else if (_overtimeType == 'Weekend Overtime') {
      rate = _hourlyRate * 1.5; // Time and a half for weekends
    } else {
      rate = _hourlyRate * 1.25; // Regular overtime at 1.25x
    }
    
    final estimatedPay = _calculatedHours * rate;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Overtime'),
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
                      // Overtime Summary Card
                      if (_calculatedHours > 0)
                        Card(
                          elevation: 4,
                          color: theme.colorScheme.primaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  'Overtime Summary',
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
                                          '${_calculatedHours.toStringAsFixed(2)}h',
                                          style: theme.textTheme.headlineMedium?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Duration',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          '\$${estimatedPay.toStringAsFixed(2)}',
                                          style: theme.textTheme.headlineMedium?.copyWith(
                                            color: theme.colorScheme.tertiary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Est. Pay',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          '\$${rate.toStringAsFixed(2)}/hr',
                                          style: theme.textTheme.headlineMedium?.copyWith(
                                            color: theme.colorScheme.secondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Rate',
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
                        'Overtime Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Overtime Type Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Overtime Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.work),
                        ),
                        value: _overtimeType,
                        items: _overtimeTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _overtimeType = newValue!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select an overtime type';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Date Field
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.calendar_today),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit_calendar),
                            onPressed: () => _selectDate(context),
                          ),
                        ),
                        onTap: () => _selectDate(context),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a date';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Time Fields
                      if (isWideScreen)
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeField(true),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTimeField(false),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildTimeField(true),
                            const SizedBox(height: 16),
                            _buildTimeField(false),
                          ],
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Reason TextArea
                      TextFormField(
                        controller: _reasonController,
                        decoration: InputDecoration(
                          labelText: 'Reason for Overtime',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please provide a reason for your overtime';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting || _calculatedHours <= 0 ? null : _submitOvertimeRequest,
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
  
  Widget _buildTimeField(bool isStartTime) {
    return TextFormField(
      controller: isStartTime ? _startTimeController : _endTimeController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: isStartTime ? 'Start Time' : 'End Time',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        prefixIcon: const Icon(Icons.access_time),
        suffixIcon: IconButton(
          icon: const Icon(Icons.more_time),
          onPressed: () => _selectTime(context, isStartTime),
        ),
      ),
      onTap: () => _selectTime(context, isStartTime),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return isStartTime ? 'Please select a start time' : 'Please select an end time';
        }
        return null;
      },
    );
  }
} 