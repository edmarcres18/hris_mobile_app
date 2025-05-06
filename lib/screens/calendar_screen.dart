import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isLoading = true;
  
  // Mock data for events
  final Map<DateTime, List<Map<String, dynamic>>> _events = {};
  
  // Types of events with corresponding colors
  final Map<String, Color> _eventTypes = {
    'Holiday': Colors.red,
    'Meeting': Colors.blue,
    'Training': Colors.orange,
    'Deadline': Colors.purple,
    'Birthday': Colors.pink,
    'Payday': Colors.green,
  };
  
  final DateFormat _dateFormatter = DateFormat('MMMM dd, yyyy');
  final DateFormat _timeFormatter = DateFormat('h:mm a');

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    
    // Initialize with mock data
    _initializeMockEvents();
    
    // Simulate loading
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _initializeMockEvents() {
    // Current date for reference
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // Company holidays
    _addEvent(
      DateTime(currentYear, 1, 1),
      'Holiday',
      'New Year\'s Day',
      'Company closed',
      startTime: null,
      endTime: null,
    );
    
    _addEvent(
      DateTime(currentYear, 5, 1),
      'Holiday',
      'Labor Day',
      'Company closed',
      startTime: null,
      endTime: null,
    );
    
    _addEvent(
      DateTime(currentYear, 12, 25),
      'Holiday',
      'Christmas Day',
      'Company closed',
      startTime: null,
      endTime: null,
    );
    
    // Paydays (assuming 15th and last day of month)
    for (int month = 1; month <= 12; month++) {
      // Get last day of month
      final lastDay = month < 12 
          ? DateTime(currentYear, month + 1, 0).day 
          : DateTime(currentYear + 1, 1, 0).day;
      
      _addEvent(
        DateTime(currentYear, month, 15),
        'Payday',
        'Mid-month Payroll',
        'Salary crediting',
        startTime: null,
        endTime: null,
      );
      
      _addEvent(
        DateTime(currentYear, month, lastDay),
        'Payday',
        'End-month Payroll',
        'Salary crediting',
        startTime: null,
        endTime: null,
      );
    }
    
    // Add meetings for the current month
    _addEvent(
      DateTime(currentYear, currentMonth, 10),
      'Meeting',
      'Team Sync',
      'Weekly team sync meeting',
      startTime: const TimeOfDay(hour: 10, minute: 0),
      endTime: const TimeOfDay(hour: 11, minute: 0),
      location: 'Conference Room A',
    );
    
    _addEvent(
      DateTime(currentYear, currentMonth, 15),
      'Meeting',
      'Project Review',
      'Monthly project status review',
      startTime: const TimeOfDay(hour: 14, minute: 0),
      endTime: const TimeOfDay(hour: 16, minute: 0),
      location: 'Virtual Meeting Room',
    );
    
    _addEvent(
      DateTime(currentYear, currentMonth, 20),
      'Training',
      'Security Awareness',
      'Mandatory security training for all employees',
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 12, minute: 0),
      location: 'Training Room',
    );
    
    _addEvent(
      DateTime(currentYear, currentMonth, 25),
      'Deadline',
      'Report Submission',
      'Monthly report submission deadline',
      startTime: const TimeOfDay(hour: 17, minute: 0),
      endTime: null,
    );
    
    // Add a birthday
    _addEvent(
      DateTime(currentYear, currentMonth, 18),
      'Birthday',
      'John Smith\'s Birthday',
      'Office celebration at 3 PM',
      startTime: const TimeOfDay(hour: 15, minute: 0),
      endTime: const TimeOfDay(hour: 16, minute: 0),
      location: 'Break Room',
    );
    
    // Add more events for next month
    final nextMonth = currentMonth == 12 ? 1 : currentMonth + 1;
    final nextMonthYear = currentMonth == 12 ? currentYear + 1 : currentYear;
    
    _addEvent(
      DateTime(nextMonthYear, nextMonth, 5),
      'Meeting',
      'Department Meeting',
      'Quarterly goals discussion',
      startTime: const TimeOfDay(hour: 13, minute: 0),
      endTime: const TimeOfDay(hour: 15, minute: 0),
      location: 'Main Conference Room',
    );
    
    _addEvent(
      DateTime(nextMonthYear, nextMonth, 12),
      'Training',
      'Professional Development',
      'Leadership skills workshop',
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 17, minute: 0),
      location: 'External Venue',
    );
  }
  
  void _addEvent(
    DateTime date, 
    String type, 
    String title, 
    String description, {
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? location,
  }) {
    // Normalize date to avoid time component issues
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    if (!_events.containsKey(normalizedDate)) {
      _events[normalizedDate] = [];
    }
    
    _events[normalizedDate]!.add({
      'type': type,
      'title': title,
      'description': description,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
    });
  }
  
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _events[normalizedDate] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Calendar'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to today',
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
          PopupMenuButton<CalendarFormat>(
            tooltip: 'Calendar view',
            icon: const Icon(Icons.more_vert),
            onSelected: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarFormat.month,
                child: Text('Month view'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.twoWeeks,
                child: Text('2 weeks view'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.week,
                child: Text('Week view'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildCalendar(theme),
                ),
                const Divider(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Events',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _dateFormatter.format(_selectedDay),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildEventList(theme),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add event feature coming soon'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        tooltip: 'Add Event',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      eventLoader: _getEventsForDay,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarStyle: CalendarStyle(
        markerDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildEventList(ThemeData theme) {
    final events = _getEventsForDay(_selectedDay);
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: theme.colorScheme.onBackground.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No events for this day',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final eventColor = _eventTypes[event['type']] ?? theme.colorScheme.primary;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showEventDetails(event, eventColor),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 80,
                    decoration: BoxDecoration(
                      color: eventColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: eventColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                event['type'],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: eventColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (event['startTime'] != null)
                              Text(
                                _formatTimeRange(event['startTime'], event['endTime']),
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event['title'],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event['description'],
                          style: theme.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (event['location'] != null) 
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  event['location'],
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  String _formatTimeRange(TimeOfDay? start, TimeOfDay? end) {
    if (start == null) return '';
    
    final startStr = _formatTimeOfDay(start);
    if (end == null) return startStr;
    
    final endStr = _formatTimeOfDay(end);
    return '$startStr - $endStr';
  }
  
  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year, 
      now.month, 
      now.day, 
      time.hour, 
      time.minute,
    );
    return _timeFormatter.format(dateTime);
  }
  
  void _showEventDetails(Map<String, dynamic> event, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 5,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event['type'],
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _dateFormatter.format(_selectedDay),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event['title'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (event['startTime'] != null) 
                    _buildDetailItem(
                      Icons.access_time,
                      'Time',
                      _formatTimeRange(event['startTime'], event['endTime']),
                      color,
                    ),
                  if (event['location'] != null) 
                    _buildDetailItem(
                      Icons.location_on,
                      'Location',
                      event['location'],
                      color,
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event['description'],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        Icons.edit,
                        'Edit',
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edit feature coming soon'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        Icons.share,
                        'Share',
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Share feature coming soon'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        Icons.calendar_today,
                        'Remind',
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reminder feature coming soon'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildDetailItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(
    IconData icon,
    String label, {
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
} 