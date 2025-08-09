class Post {
  var id;
  var title;
  var description;
  var poster;
  var authorId;
  var date_posted;
  String? imageBase64;

  Post({
    this.id,
    this.title,
    this.description,
    this.poster,
    this.authorId,
    this.date_posted,
    this.imageBase64,
  });
}
