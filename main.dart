import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';

// ==========================================
// 1. MODELS
// ==========================================
class Project {
  final String id;
  final String name;
  Project({required this.id, required this.name});
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Project.fromJson(Map<String, dynamic> json) =>
      Project(id: json['id'], name: json['name']);
}

class Task {
  final String id;
  final String name;
  Task({required this.id, required this.name});
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Task.fromJson(Map<String, dynamic> json) =>
      Task(id: json['id'], name: json['name']);
}

class TimeEntry {
  final String id;
  final String projectId;
  final String taskId;
  final double totalTime;
  final DateTime date;
  final String note;

  TimeEntry(
      {required this.id,
      required this.projectId,
      required this.taskId,
      required this.totalTime,
      required this.date,
      required this.note});

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'taskId': taskId,
        'totalTime': totalTime,
        'date': date.toIso8601String(),
        'note': note
      };

  factory TimeEntry.fromJson(Map<String, dynamic> json) => TimeEntry(
      id: json['id'],
      projectId: json['projectId'],
      taskId: json['taskId'],
      totalTime: (json['totalTime'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      note: json['note'] ?? "");
}

// ==========================================
// 2. PROVIDER (State Management)
// ==========================================
class TimeEntryProvider with ChangeNotifier {
  final LocalStorage storage = LocalStorage('time_tracker_final_v3');
  List<TimeEntry> _entries = [];
  List<Project> _projects = [
    Project(id: '1', name: 'Project Alpha'),
    Project(id: '2', name: 'Project Beta'),
    Project(id: '3', name: 'Project Gamma'),
  ];
  List<Task> _tasks = [
    Task(id: '1', name: 'Task A'),
    Task(id: '2', name: 'Task B'),
    Task(id: '3', name: 'Task C'),
  ];

  List<TimeEntry> get entries => _entries;
  List<Project> get projects => _projects;
  List<Task> get tasks => _tasks;

  TimeEntryProvider() {
    _init();
  }

  Future<void> _init() async {
    await storage.ready;
    var e = storage.getItem('timeEntries');
    var p = storage.getItem('projects');
    var t = storage.getItem('tasks');
    if (e != null)
      _entries =
          List<TimeEntry>.from((e as List).map((i) => TimeEntry.fromJson(i)));
    if (p != null)
      _projects =
          List<Project>.from((p as List).map((i) => Project.fromJson(i)));
    if (t != null)
      _tasks = List<Task>.from((t as List).map((i) => Task.fromJson(i)));
    notifyListeners();
  }

  void addEntry(TimeEntry entry) {
    _entries.add(entry);
    _save();
    notifyListeners();
  }

  void deleteEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
    _save();
    notifyListeners();
  }

  void addProject(String name) {
    _projects.add(Project(id: DateTime.now().toString(), name: name));
    _save();
    notifyListeners();
  }

  void deleteProject(String id) {
    _projects.removeWhere((p) => p.id == id);
    _save();
    notifyListeners();
  }

  void addTask(String name) {
    _tasks.add(Task(id: DateTime.now().toString(), name: name));
    _save();
    notifyListeners();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    _save();
    notifyListeners();
  }

  void _save() {
    storage.setItem('timeEntries', _entries.map((e) => e.toJson()).toList());
    storage.setItem('projects', _projects.map((p) => p.toJson()).toList());
    storage.setItem('tasks', _tasks.map((t) => t.toJson()).toList());
  }
}

// ==========================================
// 3. MAIN NAVIGATION (Tabs & Drawer)
// ==========================================
void main() => runApp(ChangeNotifierProvider(
      create: (_) => TimeEntryProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primaryColor: Color(0xFF4DB6AC)),
        home: MainTabsScreen(),
      ),
    ));

class MainTabsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF438A7E), // Teal from PDF Page 1
          iconTheme: IconThemeData(color: Colors.white),
          title: Text("Time Tracking", style: TextStyle(color: Colors.white)),
          bottom: TabBar(
            indicatorColor: Colors.yellow, // Yellow indicator from PDF Page 1
            labelColor: Colors.white,
            tabs: [Tab(text: "All Entries"), Tab(text: "Grouped by Projects")],
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF438A7E)),
                child: Text("Menu",
                    style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
              ListTile(
                  leading: Icon(Icons.assignment),
                  title: Text("Manage Projects"),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ManageItemsScreen(isProject: true)))),
              ListTile(
                  leading: Icon(Icons.check_circle),
                  title: Text("Manage Tasks"),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ManageItemsScreen(isProject: false)))),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AllEntriesList(),
            Center(child: Text("Grouping Logic: View time by Projects")),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Color(0xFFFDD835), // Yellow FAB from PDF Page 1
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => AddEntryScreen())),
          child: Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }
}

// ==========================================
// 4. SCREENS
// ==========================================

class AllEntriesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeEntryProvider>(context);
    if (provider.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 100, color: Colors.grey[300]),
            Text("No time entries yet!",
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text("Tap the + button to add your first entry.",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: provider.entries.length,
      itemBuilder: (context, i) {
        final entry = provider.entries[i];
        return ListTile(
          title: Text("${entry.taskId} (${entry.projectId})"),
          subtitle: Text(
              "${entry.totalTime} hrs - ${DateFormat('yyyy-MM-dd').format(entry.date)}"),
          trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => provider.deleteEntry(entry.id)),
        );
      },
    );
  }
}

class AddEntryScreen extends StatefulWidget {
  @override
  _AddEntryScreenState createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  String? selProject;
  String? selTask;
  DateTime selDate = DateTime.now();
  final timeCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeEntryProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Time Entry", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF438A7E),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Project", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              isExpanded: true,
              value: selProject,
              hint: Text("Select Project"),
              items: provider.projects
                  .map((p) =>
                      DropdownMenuItem(value: p.name, child: Text(p.name)))
                  .toList(),
              onChanged: (v) => setState(() => selProject = v),
            ),
            SizedBox(height: 15),
            Text("Task", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              isExpanded: true,
              value: selTask,
              hint: Text("Select Task"),
              items: provider.tasks
                  .map((t) =>
                      DropdownMenuItem(value: t.name, child: Text(t.name)))
                  .toList(),
              onChanged: (v) => setState(() => selTask = v),
            ),
            SizedBox(height: 15),
            Text("Date: ${DateFormat('yyyy-MM-dd').format(selDate)}",
                style: TextStyle(fontSize: 16)),
            TextButton(
                onPressed: () async {
                  DateTime? p = await showDatePicker(
                      context: context,
                      initialDate: selDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100));
                  if (p != null) setState(() => selDate = p);
                },
                child: Text("Select Date")),
            TextField(
                controller: timeCtrl,
                decoration: InputDecoration(labelText: "Total Time (in hours)"),
                keyboardType: TextInputType.number),
            TextField(
                controller: noteCtrl,
                decoration: InputDecoration(labelText: "Note")),
            SizedBox(height: 30),
            Center(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF438A7E)),
                    onPressed: () {
                      if (selProject != null && selTask != null) {
                        provider.addEntry(TimeEntry(
                            id: DateTime.now().toString(),
                            projectId: selProject!,
                            taskId: selTask!,
                            totalTime: double.tryParse(timeCtrl.text) ?? 0.0,
                            date: selDate,
                            note: noteCtrl.text));
                        Navigator.pop(context);
                      }
                    },
                    child: Text("Save Entry",
                        style: TextStyle(color: Colors.white)))),
          ],
        ),
      ),
    );
  }
}

class ManageItemsScreen extends StatelessWidget {
  final bool isProject;
  ManageItemsScreen({required this.isProject});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeEntryProvider>(context);

    // Explicitly casting to avoid 'Object' getter error
    return Scaffold(
      appBar: AppBar(
        title: Text(isProject ? "Manage Projects" : "Manage Tasks",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple, // Matches PDF Page 3 & 4
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: isProject ? provider.projects.length : provider.tasks.length,
        itemBuilder: (context, i) {
          final String name =
              isProject ? provider.projects[i].name : provider.tasks[i].name;
          final String id =
              isProject ? provider.projects[i].id : provider.tasks[i].id;

          return ListTile(
            title: Text(name),
            trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => isProject
                    ? provider.deleteProject(id)
                    : provider.deleteTask(id)),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFFDD835),
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                final ctrl = TextEditingController();
                return AlertDialog(
                  title: Text(isProject ? "Add Project" : "Add Task"),
                  content: TextField(
                      controller: ctrl,
                      decoration: InputDecoration(hintText: "Name")),
                  actions: [
                    TextButton(
                        child: Text("Cancel"),
                        onPressed: () => Navigator.pop(context)),
                    TextButton(
                        child: Text("Add"),
                        onPressed: () {
                          if (isProject)
                            provider.addProject(ctrl.text);
                          else
                            provider.addTask(ctrl.text);
                          Navigator.pop(context);
                        }),
                  ],
                );
              });
        },
        child: Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
