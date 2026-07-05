class NoteModel {
  final int? id;
  final int? userId;
  final String title;
  final String content;
  final String category; // Ex: 'Personnel', 'Travail', 'Idées'
  final int isArchived;   // 0 = Active, 1 = Dans la corbeille
  final String createdAt;

  NoteModel({
    this.id,
    this.userId,
    required this.title,
    required this.content,
    this.category = 'Général',
    this.isArchived = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      'title': title,
      'content': content,
      'category': category,
      'isArchived': isArchived,
      'createdAt': createdAt,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String? ?? 'Général',
      isArchived: map['isArchived'] as int? ?? 0,
      createdAt: map['createdAt'] as String,
    );
  }
}