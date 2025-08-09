class Event {
  final String? id;
  final String? title;
  final String? description;
  final String? location;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? authorId;
  final DateTime? createdAt;

  Event({
    this.id,
    this.title,
    this.description,
    this.location,
    this.startDateTime,
    this.endDateTime,
    this.authorId,
    this.createdAt,
  });
}
