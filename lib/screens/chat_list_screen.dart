import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'dart:math' as math;
import '../routes/app_router.dart';

class ChatContact {
  final String id;
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isGroup;

  ChatContact({
    required this.id,
    required this.name, 
    required this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isGroup = false,
  });
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  late List<ChatContact> _contacts;
  bool _isSearching = false;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  List<ChatContact> _filteredContacts = [];
  late AnimationController _refreshIconController;

  @override
  void initState() {
    super.initState();
    _initContacts();
    _filteredContacts = _contacts;
    _searchController.addListener(_filterContacts);
    _refreshIconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshIconController.dispose();
    super.dispose();
  }

  void _initContacts() {
    _contacts = [
      ChatContact(
        id: '1',
        name: "HR Department",
        avatarUrl: "https://i.pravatar.cc/150?img=1",
        lastMessage: "Great job! Looking forward to seeing everyone at the meeting.",
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 45)),
        unreadCount: 0,
        isOnline: true,
      ),
      ChatContact(
        id: '2',
        name: "Team Announcements",
        avatarUrl: "https://i.pravatar.cc/150?img=2",
        lastMessage: "The new project timeline has been updated.",
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 3,
        isGroup: true,
      ),
      ChatContact(
        id: '3',
        name: "Sarah Williams (HR)",
        avatarUrl: "https://i.pravatar.cc/150?img=3",
        lastMessage: "Your leave request has been approved.",
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
        unreadCount: 1,
        isOnline: true,
      ),
      ChatContact(
        id: '4',
        name: "IT Support",
        avatarUrl: "https://i.pravatar.cc/150?img=4",
        lastMessage: "Please update your password by end of this week.",
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 0,
      ),
      ChatContact(
        id: '5',
        name: "Office Events",
        avatarUrl: "https://i.pravatar.cc/150?img=5",
        lastMessage: "Don't forget the company picnic this Saturday!",
        lastMessageTime: DateTime.now().subtract(const Duration(days: 2)),
        unreadCount: 0,
        isGroup: true,
      ),
      ChatContact(
        id: '6',
        name: "Michael Chen (Manager)",
        avatarUrl: "https://i.pravatar.cc/150?img=6",
        lastMessage: "Let's discuss your performance review next week.",
        lastMessageTime: DateTime.now().subtract(const Duration(days: 3)),
        unreadCount: 0,
        isOnline: false,
      ),
      ChatContact(
        id: '7',
        name: "Finance Department",
        avatarUrl: "https://i.pravatar.cc/150?img=7",
        lastMessage: "Your expense report has been processed.",
        lastMessageTime: DateTime.now().subtract(const Duration(days: 4)),
        unreadCount: 0,
      ),
      ChatContact(
        id: '8',
        name: "Training & Development",
        avatarUrl: "https://i.pravatar.cc/150?img=8",
        lastMessage: "New online course available: Leadership Skills 101",
        lastMessageTime: DateTime.now().subtract(const Duration(days: 5)),
        unreadCount: 0,
        isGroup: true,
      ),
    ];
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts
            .where((contact) => contact.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredContacts = _contacts;
      }
    });
  }

  Future<void> _refreshContacts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    _refreshIconController.repeat();
    
    // Simulate API call with delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Could update contacts from API here
    // For now, just shuffle them to simulate refresh
    setState(() {
      _contacts.shuffle();
      _filteredContacts = List.from(_contacts);
      _isLoading = false;
    });
    
    _refreshIconController.stop();
    _refreshIconController.reset();
  }

  String _formatLastMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    } else if (messageDate == yesterday) {
      return "Yesterday";
    } else if (now.difference(time).inDays < 7) {
      const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
      return days[time.weekday - 1];
    } else {
      return "${time.day}/${time.month}/${time.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: "Search conversations...",
                  border: InputBorder.none,
                ),
                autofocus: true,
              )
            : const Text("Messages"),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          if (!_isSearching)
            RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0).animate(_refreshIconController),
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isLoading ? null : _refreshContacts,
              ),
            ),
          if (!_isSearching)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'new_group',
                  child: Row(
                    children: [
                      Icon(Icons.group_add),
                      SizedBox(width: 8),
                      Text("New Group"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text("Settings"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.mark_chat_read),
                      SizedBox(width: 8),
                      Text("Mark All Read"),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  setState(() {
                    for (var contact in _contacts) {
                      // This is just updating the UI state - in a real app
                      // you would call an API to mark messages as read
                      if (contact.unreadCount > 0) {
                        final index = _contacts.indexOf(contact);
                        _contacts[index] = ChatContact(
                          id: contact.id,
                          name: contact.name,
                          avatarUrl: contact.avatarUrl,
                          lastMessage: contact.lastMessage,
                          lastMessageTime: contact.lastMessageTime,
                          unreadCount: 0,
                          isOnline: contact.isOnline,
                          isGroup: contact.isGroup,
                        );
                      }
                    }
                    _filteredContacts = List.from(_contacts);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("All messages marked as read")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("$value coming soon")),
                  );
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading && !_isSearching)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            ),
          Expanded(
            child: _filteredContacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSearching ? Icons.search_off : Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching 
                              ? "No conversations found" 
                              : "No conversations yet",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        if (!_isSearching) ...[
                          const SizedBox(height: 8),
                          Text(
                            "Start a new conversation",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ]
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshContacts,
                    color: theme.colorScheme.primary,
                    child: ListView.separated(
                      padding: EdgeInsets.only(
                        bottom: mediaQuery.padding.bottom + 16,
                      ),
                      itemCount: _filteredContacts.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        indent: 76,
                      ),
                      itemBuilder: (context, index) {
                        final contact = _filteredContacts[index];
                        return _buildChatTile(contact);
                      },
                    ),
                  ),
          ),
          if (_filteredContacts.isNotEmpty && !_isSearching)
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 8 + mediaQuery.padding.bottom,
                top: 8,
              ),
              child: Text(
                "${_filteredContacts.length} conversation${_filteredContacts.length > 1 ? 's' : ''}",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      floatingActionButton: !_isSearching ? FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("New conversation coming soon")),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.chat, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildChatTile(ChatContact contact) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () {
        // Navigate to chat screen
        AppRouter.navigateToChat(
          context,
          contactId: contact.id,
          contactName: contact.name,
          contactAvatar: contact.avatarUrl,
          isGroup: contact.isGroup,
        );
        
        // Mark as read when returning to the list
        // This relies on focus returning to this screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // When we return to this screen, mark message as read
          // This would typically be handled via an API call
          if (!mounted) return;
          
          setState(() {
            final index = _contacts.indexWhere((c) => c.id == contact.id);
            if (index != -1 && _contacts[index].unreadCount > 0) {
              _contacts[index] = ChatContact(
                id: contact.id,
                name: contact.name,
                avatarUrl: contact.avatarUrl,
                lastMessage: contact.lastMessage,
                lastMessageTime: contact.lastMessageTime,
                unreadCount: 0,
                isOnline: contact.isOnline,
                isGroup: contact.isGroup,
              );
              _updateFilteredContacts();
            }
          });
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'contact_avatar_${contact.id}',
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(contact.avatarUrl),
                    child: contact.isGroup 
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.group,
                              color: Colors.white,
                              size: 24,
                            ),
                          )
                        : null,
                  ),
                ),
                if (contact.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          contact.name,
                          style: TextStyle(
                            fontWeight: contact.unreadCount > 0 
                                ? FontWeight.bold 
                                : FontWeight.w500,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatLastMessageTime(contact.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: contact.unreadCount > 0
                              ? theme.colorScheme.primary
                              : Colors.grey,
                          fontWeight: contact.unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: contact.unreadCount > 0
                                ? Colors.black87
                                : Colors.grey[600],
                            fontWeight: contact.unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (contact.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          child: Center(
                            child: Text(
                              contact.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateFilteredContacts() {
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      _filteredContacts = List.from(_contacts);
    } else {
      _filteredContacts = _contacts
          .where((contact) => contact.name.toLowerCase().contains(query))
          .toList();
    }
  }
} 