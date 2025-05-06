import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LoanContributionsScreen extends StatefulWidget {
  const LoanContributionsScreen({super.key});

  @override
  State<LoanContributionsScreen> createState() => _LoanContributionsScreenState();
}

class _LoanContributionsScreenState extends State<LoanContributionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Mock data
  final List<Map<String, dynamic>> _activeLoans = [
    {
      'id': 'LN-58392175',
      'type': 'Personal Loan',
      'amount': 25000.00,
      'balance': 18750.00,
      'startDate': DateTime(2023, 9, 15),
      'endDate': DateTime(2024, 9, 15),
      'installment': 2083.33,
      'status': 'Active',
      'interestRate': 0.05,
    },
    {
      'id': 'LN-67234891',
      'type': 'Emergency Loan',
      'amount': 10000.00,
      'balance': 3333.33,
      'startDate': DateTime(2023, 5, 10),
      'endDate': DateTime(2023, 12, 10),
      'installment': 1428.57,
      'status': 'Active',
      'interestRate': 0.03,
    },
  ];

  final List<Map<String, dynamic>> _contributionsHistory = [
    {
      'type': 'Pension Fund',
      'employee': 2450.00,
      'employer': 2450.00,
      'total': 4900.00,
      'date': DateTime(2023, 11, 30),
      'status': 'Processed',
    },
    {
      'type': 'Health Insurance',
      'employee': 1375.00,
      'employer': 2750.00,
      'total': 4125.00,
      'date': DateTime(2023, 11, 30),
      'status': 'Processed',
    },
    {
      'type': 'Income Tax',
      'employee': 4125.00,
      'employer': 0.00,
      'total': 4125.00,
      'date': DateTime(2023, 11, 30),
      'status': 'Processed',
    },
    {
      'type': 'Pension Fund',
      'employee': 2450.00,
      'employer': 2450.00,
      'total': 4900.00,
      'date': DateTime(2023, 10, 31),
      'status': 'Processed',
    },
    {
      'type': 'Health Insurance',
      'employee': 1375.00,
      'employer': 2750.00,
      'total': 4125.00,
      'date': DateTime(2023, 10, 31),
      'status': 'Processed',
    },
  ];

  final List<Map<String, dynamic>> _loanHistory = [
    {
      'id': 'LN-32567891',
      'type': 'Vehicle Loan',
      'amount': 35000.00,
      'startDate': DateTime(2022, 3, 15),
      'endDate': DateTime(2023, 9, 15),
      'status': 'Completed',
    },
    {
      'id': 'LN-43215678',
      'type': 'Medical Loan',
      'amount': 8000.00,
      'startDate': DateTime(2022, 8, 10),
      'endDate': DateTime(2023, 2, 10),
      'status': 'Completed',
    },
  ];

  final currencyFormatter = NumberFormat("#,##0.00", "en_US");
  final dateFormatter = DateFormat("MMM dd, yyyy");

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Simulate loading data
    Future.delayed(const Duration(milliseconds: 1500), () {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans & Contributions'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(text: 'Active Loans'),
            Tab(text: 'Loan History'),
            Tab(text: 'Contributions'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveLoansTab(theme),
                _buildLoanHistoryTab(theme),
                _buildContributionsTab(theme),
              ],
            ),
    );
  }

  Widget _buildActiveLoansTab(ThemeData theme) {
    return _activeLoans.isEmpty
        ? _buildEmptyState('No active loans', 'You do not have any active loans at the moment.')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _activeLoans.length,
            itemBuilder: (context, index) {
              final loan = _activeLoans[index];
              final progress = 1 - (loan['balance'] / loan['amount']);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              loan['type'],
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              loan['status'],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Loan ID: ${loan['id']}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLoanInfoItem(
                            label: 'Principal',
                            value: '\$${currencyFormatter.format(loan['amount'])}',
                            theme: theme,
                          ),
                          _buildLoanInfoItem(
                            label: 'Outstanding',
                            value: '\$${currencyFormatter.format(loan['balance'])}',
                            theme: theme,
                          ),
                          _buildLoanInfoItem(
                            label: 'Interest',
                            value: '${(loan['interestRate'] * 100).toStringAsFixed(1)}%',
                            theme: theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress.toDouble(),
                        backgroundColor: theme.colorScheme.primaryContainer,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}% repaid',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            'Complete by ${dateFormatter.format(loan['endDate'])}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monthly Payment',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                '\$${currencyFormatter.format(loan['installment'])}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Show loan details
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('View details feature coming soon'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.visibility),
                            label: const Text('View Details'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildLoanHistoryTab(ThemeData theme) {
    return _loanHistory.isEmpty
        ? _buildEmptyState('No loan history', 'You do not have any previous loans.')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _loanHistory.length,
            itemBuilder: (context, index) {
              final loan = _loanHistory[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              loan['type'],
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              loan['status'],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Loan ID: ${loan['id']}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLoanInfoItem(
                            label: 'Amount',
                            value: '\$${currencyFormatter.format(loan['amount'])}',
                            theme: theme,
                          ),
                          _buildLoanInfoItem(
                            label: 'Start Date',
                            value: dateFormatter.format(loan['startDate']),
                            theme: theme,
                          ),
                          _buildLoanInfoItem(
                            label: 'End Date',
                            value: dateFormatter.format(loan['endDate']),
                            theme: theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Download statement
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Download feature coming soon'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Download Statement'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildContributionsTab(ThemeData theme) {
    return _contributionsHistory.isEmpty
        ? _buildEmptyState('No contributions', 'You do not have any contributions recorded.')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _contributionsHistory.length,
            itemBuilder: (context, index) {
              final contribution = _contributionsHistory[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              contribution['type'],
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            dateFormatter.format(contribution['date']),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildContributionColumn(
                              'Your Contribution',
                              '\$${currencyFormatter.format(contribution['employee'])}',
                              theme,
                            ),
                          ),
                          Expanded(
                            child: _buildContributionColumn(
                              'Employer Contribution',
                              '\$${currencyFormatter.format(contribution['employer'])}',
                              theme,
                            ),
                          ),
                          Expanded(
                            child: _buildContributionColumn(
                              'Total',
                              '\$${currencyFormatter.format(contribution['total'])}',
                              theme,
                              isHighlighted: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, 
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            contribution['status'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.tertiary,
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
              Icons.info_outline,
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

  Widget _buildLoanInfoItem({
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildContributionColumn(
    String label,
    String value,
    ThemeData theme, {
    bool isHighlighted = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlighted ? theme.colorScheme.primary : null,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 