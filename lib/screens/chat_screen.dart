import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Message {
  final String content;
  final bool isSentByMe;
  final DateTime timestamp;
  final String senderName;
  final String? avatarUrl;
  final bool isRead;

  Message({
    required this.content,
    required this.isSentByMe,
    required this.timestamp,
    required this.senderName,
    this.avatarUrl,
    this.isRead = false,
  });
}

class ChatScreen extends StatefulWidget {
  final String contactId;
  final String contactName;
  final String contactAvatar;
  final bool isGroup;

  const ChatScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    required this.contactAvatar,
    this.isGroup = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Simulate loading existing messages
    _loadSampleMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadSampleMessages() {
    // Sample data - in a real app, these would come from an API based on contactId
    final senderName = widget.isGroup ? "Team Member" : widget.contactName;
    final avatarUrl = widget.contactAvatar;
    
    final DateTime now = DateTime.now();
    
    List<Message> sampleMessages = [];
    
    if (widget.contactId == "1") { // HR Department
      sampleMessages = [
        Message(
          content: "Good morning team! Just a reminder about our meeting at 2pm today.",
          isSentByMe: false,
          timestamp: now.subtract(const Duration(hours: 2)),
          senderName: senderName,
          avatarUrl: avatarUrl,
        ),
        Message(
          content: "Thanks for the reminder. Will the presentation slides be shared before the meeting?",
          isSentByMe: true,
          timestamp: now.subtract(const Duration(hours: 1, minutes: 45)),
          senderName: "Me",
          isRead: true,
        ),
        Message(
          content: "Yes, I'll share them in 30 minutes. Would you please prepare the quarterly report section?",
          isSentByMe: false,
          timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
          senderName: senderName,
          avatarUrl: avatarUrl,
        ),
        Message(
          content: "I've already prepared it. Will include it in today's discussion.",
          isSentByMe: true,
          timestamp: now.subtract(const Duration(hours: 1, minutes: 25)),
          senderName: "Me",
          isRead: true,
        ),
        Message(
          content: "Great job! Looking forward to seeing everyone at the meeting.",
          isSentByMe: false,
          timestamp: now.subtract(const Duration(minutes: 45)),
          senderName: senderName,
          avatarUrl: avatarUrl,
        ),
      ];
    } else if (widget.contactId == "2") { // Team Announcements
      sampleMessages = [
        Message(
          content: "Important: The new project timeline has been updated.",
          isSentByMe: false,
          timestamp: now.subtract(const Duration(hours: 4)),
          senderName: "Project Manager",
          avatarUrl: "https://i.pravatar.cc/150?img=12",
        ),
        Message(
          content: "All team members should review the updated timeline document and adjust their schedules accordingly.",
          isSentByMe: false,
          timestamp: now.subtract(const Duration(hours: 3, minutes: 55)),
          senderName: "Project Manager",
          avatarUrl: "https://i.pravatar.cc/150?img=12",
        ),
        Message(
          content: "Where can we find the updated document?",
          isSentByMe: false,
          timestamp: now.subtract(const Duration(hours: 3, minutes: 40)),
          senderName: "Sarah Williams",
          avatarUrl: "https://i.pravatar.cc/150?img=3",
        ),
        Message(
          content: "It's in the shared drive folder: Team Projects > 2023 > Q4",
          isSentByMe: false,
          timestamp: now.subtract(const Duration(hours: 3, minutes: 30)),
          senderName: "Project Manager",
          avatarUrl: "https://i.pravatar.cc/150?img=12",
        ),
        Message(
          content: "Got it. I've reviewed the timeline. I'll need to reschedule a couple of meetings.",
          isSentByMe: true,
          timestamp: now.subtract(const Duration(hours: 2)),
          senderName: "Me",
          isRead: true,
        ),
        Message(
          content: "The deadline for the first milestone has been moved from next Friday to the following Monday.",
          isSentByMe: false,
          timestamp: now.subtract(const Duration(hours: 2)),
          senderName: "Project Manager",
          avatarUrl: "https://i.pravatar.cc/150?img=12",
        ),
      ];
    } else if (widget.contactId == "3") { // Sarah Williams (HR)
      sampleMessages = [
        Message(
          content: "Hi, I'm reviewing your leave request for next month.",
          isSentByMe: false,
          timestamp: now.subtract(const Duration(hours: 8)),
          senderName: senderName,
          avatarUrl: avatarUrl,
        ),
        Message(
          content: "Thanks Sarah. Is there any issue with the dates?",
          isSentByMe: true,
          timestamp: now.subtract(const Duration(hours: 7)),
          senderName: "Me",
          isRead: true,
        ),
        Message(
          content: "No issues. I've approved your leave request.",
          isSentByMe: false,
          timestamp: now.subtract(const Duration(hours: 5)),
          senderName: senderName,
          avatarUrl: avatarUrl,
        ),
        Message(
          content: "Great! Thanks for the quick approval.",
          isSentByMe: true,
          timestamp: now.subtract(const Duration(hours: 4, minutes: 45)),
          senderName: "Me",
          isRead: true,
        ),
        Message(
          content: "You're welcome. Remember to hand over any pending tasks before you leave.",
          isSentByMe: false,
          timestamp: now.subtract(const Duration(hours: 4, minutes: 30)),
          senderName: senderName,
          avatarUrl: avatarUrl,
        ),
      ];
    } else {
      // Default conversation for other contacts
      sampleMessages = [
        Message(
          content: "Hello, how can I help you today?",
          isSentByMe: false,
          timestamp: now.subtract(const Duration(hours: 6)),
          senderName: senderName,
          avatarUrl: avatarUrl,
        ),
        Message(
          content: "I had a question about the company policy.",
          isSentByMe: true,
          timestamp: now.subtract(const Duration(hours: 5, minutes: 45)),
          senderName: "Me",
          isRead: true,
        ),
        Message(
          content: "Sure, what would you like to know?",
          isSentByMe: false,
          timestamp: now.subtract(const Duration(hours: 5, minutes: 30)),
          senderName: senderName,
          avatarUrl: avatarUrl,
        ),
        Message(
          content: "I'm looking for information about the work from home policy.",
          isSentByMe: true,
          timestamp: now.subtract(const Duration(hours: 5)),
          senderName: "Me",
          isRead: true,
        ),
        Message(
          content: "I'll check and get back to you with details shortly.",
          isSentByMe: false,
          timestamp: now.subtract(const Duration(hours: 4)),
          senderName: senderName,
          avatarUrl: avatarUrl,
        ),
      ];
    }

    setState(() {
      _messages.addAll(sampleMessages);
    });
    
    // Scroll to bottom after loading messages
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = Message(
      content: _messageController.text.trim(),
      isSentByMe: true,
      timestamp: DateTime.now(),
      senderName: "Me",
    );

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    // Scroll to bottom after sending message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Simulate response for demo
    _simulateResponse();
  }

  void _simulateResponse() {
    // Show typing indicator
    setState(() {
      _isTyping = true;
    });

    // Get the last message sent by the user to generate a contextual response
    final lastUserMessage = _messageController.text.trim().toLowerCase();
    String responseText = "I've received your message. I'll get back to you shortly.";
    
    // Simple context-based response logic
    if (lastUserMessage.contains("hello") || lastUserMessage.contains("hi")) {
      responseText = "Hello! How can I help you today?";
    } else if (lastUserMessage.contains("thanks") || lastUserMessage.contains("thank you")) {
      responseText = "You're welcome! Is there anything else you need help with?";
    } else if (lastUserMessage.contains("leave") || lastUserMessage.contains("vacation")) {
      responseText = "Regarding your leave request, I'll check the calendar and get back to you.";
    } else if (lastUserMessage.contains("meeting") || lastUserMessage.contains("schedule")) {
      responseText = "About the meeting, let me check the available time slots and confirm.";
    } else if (lastUserMessage.contains("deadline") || lastUserMessage.contains("project")) {
      responseText = "I'll review the project timeline and confirm the deadlines for you.";
    } else if (lastUserMessage.contains("policy") || lastUserMessage.contains("procedure")) {
      responseText = "I'll check the company policy on that and provide you with the details.";
    } else if (lastUserMessage.contains("help") || lastUserMessage.contains("support")) {
      responseText = "I'm here to help. Could you provide more details about what you need?";
    } else if (lastUserMessage.contains("document") || lastUserMessage.contains("file")) {
      responseText = "I'll locate that document and share it with you shortly.";
    } else if (lastUserMessage.length < 10) {
      responseText = "Could you provide more details so I can better assist you?";
    }
    
    // Context specific response based on the contact
    if (widget.isGroup) {
      responseText = "This is important information for the team: " + responseText;
    }
    
    // Simulate delay and response
    Future.delayed(const Duration(seconds: 2), () {
      final responseMessage = Message(
        content: responseText,
        isSentByMe: false,
        timestamp: DateTime.now(),
        senderName: widget.isGroup ? "Team Member" : widget.contactName,
        avatarUrl: widget.contactAvatar,
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(responseMessage);
        });

        // Scroll to bottom after receiving response
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Hero(
              tag: 'contact_avatar_${widget.contactId}',
              child: CircleAvatar(
                backgroundImage: NetworkImage(widget.contactAvatar),
                radius: 16,
                child: widget.isGroup 
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.group,
                          color: Colors.white,
                          size: 16,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.contactName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isTyping ? "typing..." : "Online",
                    style: TextStyle(
                      fontSize: 12,
                      color: _isTyping 
                          ? theme.colorScheme.primary 
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!widget.isGroup)
            IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Video call feature coming soon")),
                );
              },
            ),
          if (!widget.isGroup)
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Call feature coming soon")),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show chat options
              showModalBottomSheet(
                context: context,
                builder: (context) => ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.search),
                      title: const Text("Search in conversation"),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Search feature coming soon")),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text("Mute notifications"),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Notifications muted")),
                        );
                      },
                    ),
                    if (widget.isGroup)
                      ListTile(
                        leading: const Icon(Icons.group),
                        title: const Text("View group members"),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Group members feature coming soon")),
                          );
                        },
                      ),
                    ListTile(
                      leading: Icon(Icons.delete, color: theme.colorScheme.error),
                      title: Text("Clear chat history", 
                          style: TextStyle(color: theme.colorScheme.error)),
                      onTap: () {
                        Navigator.pop(context);
                        // Show confirmation dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Clear chat history?"),
                            content: const Text("This action cannot be undone."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _messages.clear();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Chat history cleared")),
                                  );
                                },
                                child: Text("Clear", 
                                    style: TextStyle(color: theme.colorScheme.error)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        elevation: 2,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final previousMessage = index > 0 ? _messages[index - 1] : null;
                
                // Show date header if needed
                final showDateHeader = previousMessage == null || 
                    !DateUtils.isSameDay(message.timestamp, previousMessage.timestamp);
                
                // Show sender info if needed
                final showSenderInfo = previousMessage == null || 
                    previousMessage.isSentByMe != message.isSentByMe || 
                    message.timestamp.difference(previousMessage.timestamp).inMinutes > 5;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showDateHeader)
                      _buildDateHeader(message.timestamp),
                    
                    _buildMessageBubble(
                      message: message,
                      showSenderInfo: showSenderInfo,
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Typing indicator
          if (_isTyping)
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          child: _buildTypingDot(0),
                        ),
                        Positioned(
                          left: 10,
                          child: _buildTypingDot(150),
                        ),
                        Positioned(
                          left: 20,
                          child: _buildTypingDot(300),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    color: theme.colorScheme.primary,
                    onPressed: () {
                      // Show attachment options
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          padding: EdgeInsets.only(
                            top: 20,
                            bottom: 20 + mediaQuery.viewInsets.bottom,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildAttachmentButton(
                                icon: Icons.image,
                                label: "Photo",
                                color: Colors.green,
                              ),
                              _buildAttachmentButton(
                                icon: Icons.insert_drive_file,
                                label: "Document",
                                color: Colors.blue,
                              ),
                              _buildAttachmentButton(
                                icon: Icons.location_on,
                                label: "Location",
                                color: Colors.orange,
                              ),
                              _buildAttachmentButton(
                                icon: Icons.poll,
                                label: "Poll",
                                color: Colors.purple,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface.withOpacity(0.8),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      maxLines: 5,
                      minLines: 1,
                      onChanged: (value) {
                        if (value.isNotEmpty && !_isTyping) {
                          setState(() {
                            _isTyping = true;
                          });
                          
                          // Simulate stopping typing after 2 seconds of inactivity
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) {
                              setState(() {
                                _isTyping = false;
                              });
                            }
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: _messageController.text.trim().isNotEmpty 
                        ? theme.colorScheme.primary
                        : Colors.grey,
                    onPressed: _messageController.text.trim().isNotEmpty 
                        ? _sendMessage
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime timestamp) {
    final today = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    String dateText;
    if (DateUtils.isSameDay(timestamp, today)) {
      dateText = "Today";
    } else if (DateUtils.isSameDay(timestamp, yesterday)) {
      dateText = "Yesterday";
    } else {
      dateText = DateFormat("MMMM d, yyyy").format(timestamp);
    }
    
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          dateText,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required Message message,
    required bool showSenderInfo,
  }) {
    final theme = Theme.of(context);
    final timeText = DateFormat("h:mm a").format(message.timestamp);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isSentByMe 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isSentByMe && showSenderInfo) ...[
            CircleAvatar(
              backgroundImage: message.avatarUrl != null 
                  ? NetworkImage(message.avatarUrl!) 
                  : null,
              backgroundColor: theme.colorScheme.primary,
              radius: 16,
              child: message.avatarUrl == null 
                  ? Text(
                      message.senderName[0],
                      style: const TextStyle(color: Colors.white),
                    ) 
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          
          if (!message.isSentByMe && !showSenderInfo)
            const SizedBox(width: 40),
          
          Flexible(
            child: Column(
              crossAxisAlignment: message.isSentByMe 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                if (!message.isSentByMe && showSenderInfo)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: message.isSentByMe 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: message.isSentByMe ? const Radius.circular(4) : null,
                      bottomLeft: !message.isSentByMe ? const Radius.circular(4) : null,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: message.isSentByMe ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeText,
                            style: TextStyle(
                              fontSize: 10,
                              color: message.isSentByMe 
                                  ? Colors.white.withOpacity(0.7) 
                                  : Colors.grey,
                            ),
                          ),
                          if (message.isSentByMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.isRead 
                                  ? Icons.done_all 
                                  : Icons.done,
                              size: 12,
                              color: message.isRead 
                                  ? Colors.white 
                                  : Colors.white.withOpacity(0.7),
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
          
          if (message.isSentByMe)
            const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$label attachment coming soon")),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
} 