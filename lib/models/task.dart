import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  bool isCompleted;

  @HiveField(2)
  String description;

  Task({required this.title, this.description = '', this.isCompleted = false});
}
