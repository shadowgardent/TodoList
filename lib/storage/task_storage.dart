import 'package:hive/hive.dart';
import '../models/task.dart';

class TaskStorage {
  static const String boxName = 'tasksBox';

  static Future<Box<Task>> openBox() async {
    return await Hive.openBox<Task>(boxName);
  }

  static List<Task> getAllTasks(Box<Task> box) {
    return box.values.toList();
  }

  static Future<void> addTask(Box<Task> box, Task task) async {
    await box.add(task);
  }

  static Future<void> updateTask(Task task, String newTitle, String newDescription) async {
    task.title = newTitle;
    task.description = newDescription;
    await task.save();
  }

  static Future<void> deleteTask(Task task) async {
    await task.delete();
  }

  static Future<void> toggleTaskStatus(Task task) async {
    task.isCompleted = !task.isCompleted;
    await task.save();
  }
}
