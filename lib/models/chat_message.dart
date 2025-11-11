class ChatMessage {
  final String text;
  final bool isUser;
  final bool pending;

  ChatMessage({
    required this.text,
    this.isUser = true,
    this.pending = false,
  });

  Map<String, dynamic> toMap() => {
        'text': text,
        'isUser': isUser,
        'pending': pending,
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        text: map['text'] ?? '',
        isUser: map['isUser'] ?? true,
        pending: map['pending'] ?? false,
      );
}
