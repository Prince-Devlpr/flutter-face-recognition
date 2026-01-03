class Student {
  final String name;
  final String rollNo;
  final String className;
  final String photoPath;
  final List<double>? embedding; // null until we compute with FaceNet

  Student({
    required this.name,
    required this.rollNo,
    required this.className,
    required this.photoPath,
    this.embedding,
  });

  Student copyWith({List<double>? embedding}) {
    return Student(
      name: name,
      rollNo: rollNo,
      className: className,
      photoPath: photoPath,
      embedding: embedding ?? this.embedding,
    );
  }
}
