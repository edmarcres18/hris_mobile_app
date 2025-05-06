import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeCard(context),
              const SizedBox(height: 24),
              _buildAttendanceHistoryTitle(context),
              const SizedBox(height: 16),
              Expanded(
                child: _buildAttendanceHistory(context),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add attendance functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add new attendance record'),
            ),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTimeCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.access_time,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, snapshot) {
                return Text(
                  _getCurrentTime(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Current Time',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 300) {
                  // For very small screens, stack the buttons vertically
                  return Column(
                    children: [
                      _buildClockInButton(context, isFullWidth: true),
                      const SizedBox(height: 12),
                      _buildClockOutButton(context, isFullWidth: true),
                    ],
                  );
                } else {
                  // For larger screens, place buttons side by side
                  return Row(
                    children: [
                      Expanded(child: _buildClockInButton(context)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildClockOutButton(context)),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockInButton(BuildContext context, {bool isFullWidth = false}) {
    return ElevatedButton.icon(
      onPressed: () {
        // Clock in functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clocked in successfully'),
          ),
        );
      },
      icon: const Icon(Icons.login),
      label: const Text('CLOCK IN'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildClockOutButton(BuildContext context, {bool isFullWidth = false}) {
    final theme = Theme.of(context);
    
    return OutlinedButton.icon(
      onPressed: () {
        // Clock out functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clocked out successfully'),
          ),
        );
      },
      icon: const Icon(Icons.logout),
      label: const Text('CLOCK OUT'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildAttendanceHistoryTitle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Attendance History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton.icon(
          onPressed: () {
            // View all attendance history
          },
          icon: const Icon(Icons.calendar_month, size: 16),
          label: const Text('Monthly View'),
        ),
      ],
    );
  }

  Widget _buildAttendanceHistory(BuildContext context) {
    final theme = Theme.of(context);
    
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh attendance data
        await Future.delayed(const Duration(seconds: 1));
      },
      color: theme.colorScheme.primary,
      child: ListView.builder(
        itemCount: 10,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          // Demo data - would come from a real data source
          final date = DateTime.now().subtract(Duration(days: index));
          final isToday = index == 0;
          final clockIn = '08:${30 + index}';
          final clockOut = index == 0 ? 'Active' : '17:${30 + index}';
          final hours = index == 0 ? 'In progress' : '9h ${index % 3}0m';
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () {
                // View detailed attendance for this day
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isToday 
                        ? theme.colorScheme.primary.withAlpha(51)
                        : Colors.grey.withAlpha(51),
                    child: Text(
                      date.day.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isToday ? theme.colorScheme.primary : Colors.grey,
                      ),
                    ),
                  ),
                  title: Text(
                    _formatDate(date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('In: $clockIn - Out: $clockOut'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isToday 
                          ? theme.colorScheme.primary.withAlpha(26)
                          : Colors.grey.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hours,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isToday ? theme.colorScheme.primary : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to get current time
  String _getCurrentTime() {
    final now = DateTime.now();
    final hours = now.hour.toString().padLeft(2, '0');
    final minutes = now.minute.toString().padLeft(2, '0');
    final seconds = now.second.toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    
    if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday';
    }
    
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June', 
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }
} 