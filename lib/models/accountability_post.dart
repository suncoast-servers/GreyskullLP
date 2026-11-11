enum AccountabilityPostMode {
  off,
  manual,
  onWorkoutComplete,
  endOfDaySummary,
}

class AccountabilityDraft {
  final String id;
  final DateTime timestamp;
  final String title;
  final String content;
  final String category;
  final bool isPosted;

  AccountabilityDraft({
    required this.id,
    required this.timestamp,
    required this.title,
    required this.content,
    required this.category,
    this.isPosted = false,
  });

  AccountabilityDraft copyWith({
    String? id,
    DateTime? timestamp,
    String? title,
    String? content,
    String? category,
    bool? isPosted,
  }) {
    return AccountabilityDraft(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      isPosted: isPosted ?? this.isPosted,
    );
  }

  Map<String, dynamic> toJsonMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'title': title,
        'content': content,
        'category': category,
        'isPosted': isPosted,
      };

  factory AccountabilityDraft.fromJsonMap(Map<String, dynamic> map) {
    return AccountabilityDraft(
      id: map['id'] as String? ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      title: map['title'] as String? ?? 'Accountability Post',
      content: map['content'] as String? ?? '',
      category: map['category'] as String? ?? 'general',
      isPosted: map['isPosted'] as bool? ?? false,
    );
  }
}
