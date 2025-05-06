import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BirthdaysScreen extends StatefulWidget {
  const BirthdaysScreen({super.key});

  @override
  State<BirthdaysScreen> createState() => _BirthdaysScreenState();
}

class _BirthdaysScreenState extends State<BirthdaysScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  late DateTime _today;
  
  // Mock data
  final List<Map<String, dynamic>> _employees = [
    {
      'id': 'EMP001',
      'name': 'John Smith',
      'department': 'Engineering',
      'position': 'Senior Developer',
      'birthday': DateTime(1990, 5, 15),
      'image': 'https://i.pravatar.cc/150?img=1',
    },
    {
      'id': 'EMP002',
      'name': 'Sarah Johnson',
      'department': 'Marketing',
      'position': 'Marketing Manager',
      'birthday': DateTime(1985, 5, 20),
      'image': 'https://i.pravatar.cc/150?img=5',
    },
    {
      'id': 'EMP003',
      'name': 'Michael Brown',
      'department': 'Finance',
      'position': 'Financial Analyst',
      'birthday': DateTime(1992, 6, 3),
      'image': 'https://i.pravatar.cc/150?img=3',
    },
    {
      'id': 'EMP004',
      'name': 'Emily Davis',
      'department': 'Human Resources',
      'position': 'HR Specialist',
      'birthday': DateTime(1988, 6, 10),
      'image': 'https://i.pravatar.cc/150?img=9',
    },
    {
      'id': 'EMP005',
      'name': 'David Wilson',
      'department': 'Engineering',
      'position': 'UX Designer',
      'birthday': DateTime(1995, 6, 18),
      'image': 'https://i.pravatar.cc/150?img=4',
    },
    {
      'id': 'EMP006',
      'name': 'Jessica Taylor',
      'department': 'Marketing',
      'position': 'Content Specialist',
      'birthday': DateTime(1993, 7, 5),
      'image': 'https://i.pravatar.cc/150?img=6',
    },
    {
      'id': 'EMP007',
      'name': 'Robert Anderson',
      'department': 'Engineering',
      'position': 'DevOps Engineer',
      'birthday': DateTime(1987, 7, 22),
      'image': 'https://i.pravatar.cc/150?img=7',
    },
    {
      'id': 'EMP008',
      'name': 'Jennifer Thomas',
      'department': 'Finance',
      'position': 'Accountant',
      'birthday': DateTime(1991, 8, 9),
      'image': 'https://i.pravatar.cc/150?img=8',
    },
    {
      'id': 'EMP009',
      'name': 'William Jackson',
      'department': 'Sales',
      'position': 'Sales Manager',
      'birthday': DateTime(1984, 5, 12),
      'image': 'https://i.pravatar.cc/150?img=11',
    },
    {
      'id': 'EMP010',
      'name': 'Amanda White',
      'department': 'Customer Support',
      'position': 'Support Specialist',
      'birthday': DateTime(1989, 5, 27),
      'image': 'https://i.pravatar.cc/150?img=10',
    },
  ];
  
  final DateFormat _dateFormat = DateFormat('MMMM d');
  final DateFormat _monthFormat = DateFormat('MMMM');

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _tabController = TabController(length: 3, vsync: this);
    
    // Simulate loading data
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Get upcoming birthdays (this month)
  List<Map<String, dynamic>> get _thisMonthBirthdays {
    return _employees.where((employee) {
      final birthday = employee['birthday'] as DateTime;
      return birthday.month == _today.month;
    }).toList()
      ..sort((a, b) {
        final DateTime dateA = a['birthday'] as DateTime;
        final DateTime dateB = b['birthday'] as DateTime;
        return dateA.day.compareTo(dateB.day);
      });
  }

  // Get next month birthdays
  List<Map<String, dynamic>> get _nextMonthBirthdays {
    final nextMonth = _today.month == 12 ? 1 : _today.month + 1;
    
    return _employees.where((employee) {
      final birthday = employee['birthday'] as DateTime;
      return birthday.month == nextMonth;
    }).toList()
      ..sort((a, b) {
        final DateTime dateA = a['birthday'] as DateTime;
        final DateTime dateB = b['birthday'] as DateTime;
        return dateA.day.compareTo(dateB.day);
      });
  }

  // Get today's birthdays
  List<Map<String, dynamic>> get _todayBirthdays {
    return _employees.where((employee) {
      final birthday = employee['birthday'] as DateTime;
      return birthday.month == _today.month && birthday.day == _today.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Birthdays'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: [
            const Tab(text: 'Today'),
            Tab(text: _monthFormat.format(_today)),
            Tab(
              text: _monthFormat.format(
                DateTime(_today.year, _today.month == 12 ? 1 : _today.month + 1),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayBirthdaysTab(theme),
                _buildMonthBirthdaysTab(_thisMonthBirthdays, theme),
                _buildMonthBirthdaysTab(_nextMonthBirthdays, theme),
              ],
            ),
    );
  }

  Widget _buildTodayBirthdaysTab(ThemeData theme) {
    final birthdays = _todayBirthdays;
    
    if (birthdays.isEmpty) {
      return _buildEmptyState(
        'No birthdays today',
        'There are no employee birthdays to celebrate today.',
      );
    }
    
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.cake,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'Today\'s Celebrations!',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${birthdays.length} ${birthdays.length == 1 ? 'birthday' : 'birthdays'} today',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: birthdays.length,
            itemBuilder: (context, index) {
              return _buildBirthdayCard(
                birthdays[index], 
                theme,
                isToday: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthBirthdaysTab(List<Map<String, dynamic>> birthdays, ThemeData theme) {
    if (birthdays.isEmpty) {
      return _buildEmptyState(
        'No birthdays this month',
        'There are no employee birthdays to celebrate this month.',
      );
    }
    
    // Group birthdays by date
    final Map<int, List<Map<String, dynamic>>> groupedBirthdays = {};
    
    for (final employee in birthdays) {
      final birthday = employee['birthday'] as DateTime;
      if (!groupedBirthdays.containsKey(birthday.day)) {
        groupedBirthdays[birthday.day] = [];
      }
      groupedBirthdays[birthday.day]!.add(employee);
    }
    
    // Sort dates
    final sortedDays = groupedBirthdays.keys.toList()..sort();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final employeesOnDay = groupedBirthdays[day]!;
        final birthdayDate = DateTime(
          _today.year,
          employeesOnDay.first['birthday'].month,
          day,
        );
        
        final isToday = birthdayDate.month == _today.month && birthdayDate.day == _today.day;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isToday ? 
                        theme.colorScheme.primary : 
                        theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _dateFormat.format(birthdayDate),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isToday ? 
                          Colors.white : 
                          theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (isToday)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        'Today',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ...employeesOnDay.map((employee) => _buildBirthdayCard(
              employee, 
              theme,
              isToday: isToday,
            )).toList(),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildBirthdayCard(Map<String, dynamic> employee, ThemeData theme, {bool isToday = false}) {
    final birthday = employee['birthday'] as DateTime;
    final age = _today.year - birthday.year;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isToday ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isToday ? 
          BorderSide(color: theme.colorScheme.primary, width: 2) : 
          BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(employee['image']),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee['name'],
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${employee['position']} - ${employee['department']}',
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Turning $age ${isToday ? 'today' : 'years old'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.cake),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sending birthday wishes to ${employee['name']}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  color: theme.colorScheme.primary,
                ),
                if (isToday)
                  const Text(
                    '🎂',
                    style: TextStyle(fontSize: 20),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cake_outlined,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
} 