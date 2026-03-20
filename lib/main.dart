import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/task.dart';
import 'storage/task_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and register adapter for Task
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());

  // Make sure tasks box is open before running app
  await TaskStorage.openBox();

  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Todo List',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.transparent,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TodoHomePage(),
    );
  }
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({Key? key}) : super(key: key);

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  late final Box<Task> taskBox;

  @override
  void initState() {
    super.initState();
    taskBox = Hive.box<Task>(TaskStorage.boxName);
  }

  Future<void> _showAddEditDialog({Task? task}) async {
    final TextEditingController titleController = TextEditingController(
      text: task != null ? task.title : '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: task != null ? task.description : '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(task == null ? 'Add Task' : 'Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Task title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (result == true) {
      final newTitle = titleController.text.trim();
      final newDescription = descriptionController.text.trim();
      if (task == null) {
        await TaskStorage.addTask(taskBox, Task(title: newTitle, description: newDescription));
      } else {
        await TaskStorage.updateTask(task, newTitle, newDescription);
      }
    }
  }

  Future<bool> _confirmDelete(Task task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    return shouldDelete == true;
  }

  Future<void> _showTaskDetails(Task task) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Task Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Status: ${task.isCompleted ? 'Completed' : 'Pending'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showAddEditDialog(task: task);
              },
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final confirmed = await _confirmDelete(task);
                if (confirmed) {
                  await TaskStorage.deleteTask(task);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskTile(Task task) {
    return Dismissible(
      key: Key(task.key.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final confirmed = await _confirmDelete(task);
        if (confirmed) {
          await TaskStorage.deleteTask(task);
        }
        return confirmed;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          leading: GestureDetector(
            onTap: () async {
              await TaskStorage.toggleTaskStatus(task);
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: task.isCompleted
                  ? Colors.green.shade100
                  : Colors.purple.shade100,
              child: Icon(
                task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: task.isCompleted ? Colors.green.shade700 : Colors.purple,
              ),
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: task.isCompleted ? Colors.grey.shade500 : Colors.black87,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty)
                Text(
                  task.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              Text(
                task.isCompleted ? 'Completed' : 'Pending',
                style: TextStyle(
                    color: task.isCompleted
                        ? Colors.green.shade700
                        : Colors.purple.shade700),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.purple),
                onPressed: () => _showAddEditDialog(task: task),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () async {
                  final confirmed = await _confirmDelete(task);
                  if (confirmed) {
                    await TaskStorage.deleteTask(task);
                  }
                },
              ),
            ],
          ),
          onTap: () => _showTaskDetails(task),
        ),
      ),
    );
  }

  Widget _buildTaskSection({required String title, required List<Task> tasks}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          tasks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    title == 'Pending Tasks'
                        ? 'No pending tasks yet'
                        : 'No completed tasks yet',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, index) => _buildTaskTile(tasks[index]),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String _dateLabel =
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('My Todo List',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7C4DFF), Color(0xFF651FFF), Color(0xFF407BFF)],
          ),
        ),
        child: SafeArea(
          child: ValueListenableBuilder<Box<Task>>(
            valueListenable: taskBox.listenable(),
            builder: (_, box, __) {
              final allTasks = TaskStorage.getAllTasks(box);
              final pendingTasks =
                  allTasks.where((t) => !t.isCompleted).toList();
              final completedTasks =
                  allTasks.where((t) => t.isCompleted).toList();

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 80),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Today • $_dateLabel',
                        style: const TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 0.85),
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTaskSection(
                        title: 'Pending Tasks', tasks: pendingTasks),
                    _buildTaskSection(
                        title: 'Completed Tasks', tasks: completedTasks),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 200,
        height: 52,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddEditDialog(),
          label: const Text('Add New Task',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add),
          backgroundColor: Colors.deepPurpleAccent,
        ),
      ),
    );
  }
}
