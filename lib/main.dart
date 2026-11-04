import 'dart:math';

import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

import 'dart:convert';

// ==========================================
// 1. COLORS AND THEME
// ==========================================

class C {
  static const navy = Color(0xFF233746);
  static const ivory = Color(0xFFF5F0E6);
  static const orange = Color(0xFFC8795C);
  static const green = Color(0xFF8B9B83);
  static const sand = Color(0xFFE5CFA8);
  static const dark = Color(0xFF263238);
  static const light = Color(0xFFFAF8F3);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DB.instance.database;
  runApp(const LearnSpaceApp());
}

class LearnSpaceApp extends StatefulWidget {
  const LearnSpaceApp({super.key});

  @override
  State<LearnSpaceApp> createState() => _LearnSpaceAppState();
}

class _LearnSpaceAppState extends State<LearnSpaceApp> {
  int? userId;
  bool ready = false;

  @override
  void initState() {
    super.initState();
    restoreSession();
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('student_id');
    final student = id == null ? null : await DB.instance.student(id);
    if (!mounted) return;
    setState(() {
      userId = student == null ? null : id;
      ready = true;
    });
  }

  Future<void> loggedIn(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('student_id', id);
    if (!mounted) return;
    setState(() => userId = id);
  }

  Future<void> loggedOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('student_id');
    if (!mounted) return;
    setState(() => userId = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LearnSpace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: C.ivory,
        colorScheme: ColorScheme.fromSeed(
          seedColor: C.navy,
          primary: C.navy,
          secondary: C.orange,
          surface: C.ivory,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: C.ivory,
          foregroundColor: C.navy,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(17),
        ),
      ),
      home: !ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : userId == null
          ? LoginScreen(onLogin: loggedIn)
          : MainShell(userId: userId!, onLogout: loggedOut),
    );
  }
}

// ==========================================
// 2. SQLITE DATABASE
// ==========================================

class DB {
  DB._();
  static final DB instance = DB._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final folder = await getDatabasesPath();
    _database = await openDatabase(
      p.join(folder, 'learnspace.db'),
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
         CREATE TABLE students(
           id INTEGER PRIMARY KEY AUTOINCREMENT,
           name TEXT NOT NULL,
           email TEXT NOT NULL UNIQUE,
           salt TEXT NOT NULL,
           password_hash TEXT NOT NULL
         )
       ''');

        await db.execute('''
         CREATE TABLE courses(
           id INTEGER PRIMARY KEY,
           title TEXT NOT NULL,
           category TEXT NOT NULL,
           description TEXT NOT NULL
         )
       ''');

        await db.execute('''
         CREATE TABLE lessons(
           id INTEGER PRIMARY KEY,
           course_id INTEGER NOT NULL,
           title TEXT NOT NULL,
           content TEXT NOT NULL,
           FOREIGN KEY(course_id) REFERENCES courses(id)
         )
       ''');

        await db.execute('''
         CREATE TABLE enrollments(
           student_id INTEGER NOT NULL,
           course_id INTEGER NOT NULL,
           PRIMARY KEY(student_id, course_id),
           FOREIGN KEY(student_id) REFERENCES students(id),
           FOREIGN KEY(course_id) REFERENCES courses(id)
         )
       ''');

        await db.execute('''
         CREATE TABLE lesson_progress(
           student_id INTEGER NOT NULL,
           lesson_id INTEGER NOT NULL,
           PRIMARY KEY(student_id, lesson_id),
           FOREIGN KEY(student_id) REFERENCES students(id),
           FOREIGN KEY(lesson_id) REFERENCES lessons(id)
         )
       ''');

        await db.execute('''
         CREATE TABLE assignments(
           id INTEGER PRIMARY KEY,
           course_id INTEGER NOT NULL,
           title TEXT NOT NULL,
           due_date TEXT NOT NULL,
           FOREIGN KEY(course_id) REFERENCES courses(id)
         )
       ''');

        await db.execute('''
         CREATE TABLE submissions(
           student_id INTEGER NOT NULL,
           assignment_id INTEGER NOT NULL,
           answer TEXT NOT NULL,
           submitted_at TEXT NOT NULL,
           PRIMARY KEY(student_id, assignment_id),
           FOREIGN KEY(student_id) REFERENCES students(id),
           FOREIGN KEY(assignment_id) REFERENCES assignments(id)
         )
       ''');

        await seed(db);
      },
    );
    return _database!;
  }

  Future<void> seed(Database db) async {
    final courses = [
      [
        'Python Programming',
        'Programming',
        'Learn Python fundamentals, variables, loops and functions.',
      ],
      [
        'Database Management',
        'Databases',
        'Understand relational databases, SQL and data management.',
      ],
      [
        'Introduction to AI',
        'Artificial Intelligence',
        'Explore AI concepts and practical applications.',
      ],
      [
        'Web Development',
        'Development',
        'Learn HTML, CSS and the foundations of modern websites.',
      ],
      [
        'Data Analytics',
        'Analytics',
        'Understand data analysis, statistics and visualization.',
      ],
    ];

    final lessons = [
      [
        'Introduction',
        'This course introduces the subject and explains its importance in real-world applications.',
      ],
      [
        'Core Concepts',
        'Learn the fundamental terminology, important concepts and common techniques used in this subject.',
      ],
      [
        'Practical Applications',
        'Understand how these concepts are applied to real problems through practical examples.',
      ],
      [
        'Revision and Practice',
        'Review the important concepts and practice applying them to sample problems.',
      ],
    ];

    for (var i = 0; i < courses.length; i++) {
      final id = i + 1;
      await db.insert('courses', {
        'id': id,
        'title': courses[i][0],
        'category': courses[i][1],
        'description': courses[i][2],
      });

      for (var j = 0; j < lessons.length; j++) {
        await db.insert('lessons', {
          'id': id * 100 + j,
          'course_id': id,
          'title': lessons[j][0],
          'content': lessons[j][1],
        });
      }

      await db.insert('assignments', {
        'id': id,
        'course_id': id,
        'title': '${courses[i][0]} – Practice Assignment',
        'due_date': DateTime.now()
            .add(Duration(days: 7 + i * 3))
            .toIso8601String(),
      });
    }
  }

  // Demonstration password hashing.
  // For production, use a dedicated password KDF and server authentication.
  String makeSalt() {
    final random = Random.secure();
    return List.generate(
      24,
      (_) => random.nextInt(256),
    ).map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  }

  String hashPassword(String salt, String password) {
    List<int> bytes = utf8.encode('$salt:$password');

    for (var i = 0; i < 10000; i++) {
      bytes = sha256.convert(bytes).bytes;
    }

    return sha256.convert(bytes).toString();
  }

  Future<int> register(String name, String email, String password) async {
    final db = await database;
    final salt = makeSalt();
    return db.insert('students', {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'salt': salt,
      'password_hash': hashPassword(salt, password),
    });
  }

  Future<int?> login(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'students',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    if (result.isEmpty) return null;

    final s = result.first;
    final hash = hashPassword(s['salt'] as String, password);
    return hash == s['password_hash'] ? s['id'] as int : null;
  }

  Future<Map<String, Object?>?> student(int id) async {
    final db = await database;
    final r = await db.query('students', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : r.first;
  }

  Future<List<Map<String, Object?>>> courses(
    int userId, {
    bool onlyEnrolled = false,
  }) async {
    final db = await database;
    return db.rawQuery(
      '''
     SELECT c.*,
       CASE WHEN e.student_id IS NULL THEN 0 ELSE 1 END AS enrolled,
       (SELECT COUNT(*) FROM lessons l
        WHERE l.course_id = c.id) AS total,
       (SELECT COUNT(*) FROM lesson_progress lp
        JOIN lessons l ON l.id = lp.lesson_id
        WHERE lp.student_id = ? AND l.course_id = c.id) AS completed
     FROM courses c
     LEFT JOIN enrollments e
       ON e.course_id = c.id AND e.student_id = ?
     ${onlyEnrolled ? 'WHERE e.student_id IS NOT NULL' : ''}
     ORDER BY c.id
   ''',
      [userId, userId],
    );
  }

  Future<void> enroll(int userId, int courseId) async {
    final db = await database;
    await db.insert('enrollments', {
      'student_id': userId,
      'course_id': courseId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, Object?>>> lessons(int userId, int courseId) async {
    final db = await database;
    return db.rawQuery(
      '''
     SELECT l.*,
       CASE WHEN lp.lesson_id IS NULL THEN 0 ELSE 1 END AS completed
     FROM lessons l
     LEFT JOIN lesson_progress lp
       ON lp.lesson_id = l.id AND lp.student_id = ?
     WHERE l.course_id = ?
     ORDER BY l.id
   ''',
      [userId, courseId],
    );
  }

  Future<void> toggleLesson(int userId, int lessonId, bool completed) async {
    final db = await database;
    if (completed) {
      await db.delete(
        'lesson_progress',
        where: 'student_id = ? AND lesson_id = ?',
        whereArgs: [userId, lessonId],
      );
    } else {
      await db.insert('lesson_progress', {
        'student_id': userId,
        'lesson_id': lessonId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<List<Map<String, Object?>>> assignments(int userId) async {
    final db = await database;
    return db.rawQuery(
      '''
     SELECT a.*, c.title AS course_title,
       s.answer, s.submitted_at
     FROM assignments a
     JOIN courses c ON c.id = a.course_id
     JOIN enrollments e
       ON e.course_id = a.course_id AND e.student_id = ?
     LEFT JOIN submissions s
       ON s.assignment_id = a.id AND s.student_id = ?
     ORDER BY a.due_date
   ''',
      [userId, userId],
    );
  }

  Future<void> submitAssignment(
    int userId,
    int assignmentId,
    String answer,
  ) async {
    final db = await database;
    await db.insert('submissions', {
      'student_id': userId,
      'assignment_id': assignmentId,
      'answer': answer,
      'submitted_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

// ==========================================
// 3. REUSABLE UI COMPONENTS
// ==========================================

Widget panel(Widget child, {Color color = Colors.white}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
}

Widget heading(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.bold,
        color: C.navy,
      ),
    ),
  );
}

Widget primaryButton(String text, VoidCallback onTap) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: C.navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(text),
    ),
  );
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Widget progressBar(double value) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: LinearProgressIndicator(
      value: value.clamp(0.0, 1.0),
      minHeight: 8,
      backgroundColor: C.ivory,
      color: C.green,
    ),
  );
}

double courseProgress(Map<String, Object?> course) {
  final total = course['total'] as int;
  final done = course['completed'] as int;
  return total == 0 ? 0 : done / total;
}

// ==========================================
// 4. LOGIN AND REGISTRATION
// ==========================================

class LoginScreen extends StatefulWidget {
  final ValueChanged<int> onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool registerMode = false;
  bool busy = false;
  bool hidePassword = true;
  final name = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> authenticate() async {
    if (busy) return;

    final mail = email.text.trim();
    final pass = password.text;

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(mail)) {
      showMessage(context, 'Enter a valid email address');
      return;
    }
    if (pass.length < 6) {
      showMessage(context, 'Password must contain at least 6 characters');
      return;
    }
    if (registerMode && name.text.trim().isEmpty) {
      showMessage(context, 'Please enter your name');
      return;
    }

    setState(() => busy = true);
    try {
      int? id;
      if (registerMode) {
        id = await DB.instance.register(name.text, mail, pass);
      } else {
        id = await DB.instance.login(mail, pass);
      }

      if (!mounted) return;
      if (id == null) {
        showMessage(context, 'Incorrect email or password');
      } else {
        widget.onLogin(id);
      }
    } on DatabaseException catch (_) {
      if (mounted) {
        showMessage(context, 'Account already exists or database error');
      }
    } catch (_) {
      if (mounted) showMessage(context, 'Something went wrong');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_stories_rounded,
                    size: 50,
                    color: C.orange,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'LearnSpace',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: C.navy,
                    ),
                  ),
                  const Text(
                    'A little more organised.\nA lot more learning.',
                    style: TextStyle(fontSize: 16, color: C.dark),
                  ),
                  const SizedBox(height: 36),
                  heading(
                    registerMode ? 'Create your account' : 'Welcome back',
                  ),
                  if (registerMode) ...[
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => hidePassword = !hidePassword),
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  primaryButton(
                    busy
                        ? 'Please wait...'
                        : registerMode
                        ? 'Create account'
                        : 'Sign in',
                    authenticate,
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          setState(() => registerMode = !registerMode),
                      child: Text(
                        registerMode
                            ? 'Already have an account? Sign in'
                            : 'New here? Create an account',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. MAIN NAVIGATION
// ==========================================

class MainShell extends StatefulWidget {
  final int userId;
  final Future<void> Function() onLogout;

  const MainShell({super.key, required this.userId, required this.onLogout});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selected = 0;
  int refresh = 0;

  void reload() => setState(() => refresh++);

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        key: ValueKey('dashboard$refresh'),
        userId: widget.userId,
        onCourses: () => setState(() => selected = 1),
      ),
      CoursesScreen(
        key: ValueKey('courses$refresh'),
        userId: widget.userId,
        onChanged: reload,
      ),
      AssignmentsScreen(key: ValueKey('tasks$refresh'), userId: widget.userId),
      ProfileScreen(
        key: ValueKey('profile$refresh'),
        userId: widget.userId,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      body: SafeArea(child: screens[selected]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        backgroundColor: Colors.white,
        indicatorColor: C.sand,
        onDestinationSelected: (i) {
          setState(() => selected = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 6. DASHBOARD
// ==========================================

class DashboardScreen extends StatefulWidget {
  final int userId;
  final VoidCallback onCourses;

  const DashboardScreen({
    super.key,
    required this.userId,
    required this.onCourses,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<Map<String, dynamic>> load() async {
    final user = await DB.instance.student(widget.userId);
    final enrolled = await DB.instance.courses(
      widget.userId,
      onlyEnrolled: true,
    );
    final tasks = await DB.instance.assignments(widget.userId);
    return {'user': user, 'courses': enrolled, 'tasks': tasks};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: load(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load dashboard: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final user = data['user'] as Map<String, Object?>?;
        final courses = data['courses'] as List<Map<String, Object?>>;
        final tasks = data['tasks'] as List<Map<String, Object?>>;
        final total = courses.fold<int>(
          0,
          (sum, c) => sum + (c['total'] as int),
        );
        final completed = courses.fold<int>(
          0,
          (sum, c) => sum + (c['completed'] as int),
        );
        final percentage = total == 0 ? 0 : completed * 100 ~/ total;
        final pending = tasks.where((a) => a['answer'] == null).length;
        final firstName = (user?['name'] ?? 'Student')
            .toString()
            .split(' ')
            .first;

        return ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const Text(
              'LEARNSPACE',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2.5,
                fontWeight: FontWeight.bold,
                color: C.orange,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hello, $firstName!',
              style: const TextStyle(
                color: C.navy,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Ready to learn something new today?',
              style: TextStyle(color: C.dark),
            ),
            const SizedBox(height: 25),
            panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR LEARNING JOURNEY',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: C.navy,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: C.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  progressBar(percentage / 100),
                  const SizedBox(height: 10),
                  Text('$completed of $total lessons completed'),
                ],
              ),
              color: C.sand,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: panel(
                    Column(
                      children: [
                        const Icon(Icons.auto_stories, color: C.orange),
                        const SizedBox(height: 6),
                        Text(
                          '${courses.length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('My courses'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: panel(
                    Column(
                      children: [
                        const Icon(Icons.pending_actions, color: C.orange),
                        const SizedBox(height: 6),
                        Text(
                          '$pending',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Pending tasks'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            heading('Continue learning'),
            if (courses.isEmpty)
              panel(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your learning journey starts here.'),
                    const SizedBox(height: 14),
                    primaryButton('Explore courses', widget.onCourses),
                  ],
                ),
              )
            else
              ...courses
                  .take(3)
                  .map(
                    (course) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CourseTile(
                        course: course,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseDetailScreen(
                                userId: widget.userId,
                                course: course,
                              ),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            primaryButton('Browse all courses', widget.onCourses),
          ],
        );
      },
    );
  }
}

// ==========================================
// 7. COURSES AND ENROLLMENT
// ==========================================

class CourseTile extends StatelessWidget {
  final Map<String, Object?> course;
  final VoidCallback onTap;

  const CourseTile({super.key, required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final percent = (courseProgress(course) * 100).round();
    final enrolled = course['enrolled'] == 1;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: C.ivory,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.book_outlined, color: C.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title'].toString(),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: C.navy,
                        ),
                      ),
                      Text(
                        course['category'].toString(),
                        style: const TextStyle(color: C.green),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: C.navy),
              ],
            ),
            const SizedBox(height: 12),
            Text(course['description'].toString()),
            if (enrolled) ...[
              const SizedBox(height: 14),
              progressBar(percent / 100),
              const SizedBox(height: 6),
              Text(
                '$percent% completed',
                style: const TextStyle(color: C.navy),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CoursesScreen extends StatefulWidget {
  final int userId;
  final VoidCallback onChanged;

  const CoursesScreen({
    super.key,
    required this.userId,
    required this.onChanged,
  });

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String search = '';
  bool onlyMine = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: DB.instance.courses(widget.userId, onlyEnrolled: onlyMine),
      builder: (context, snapshot) {
        final courses = snapshot.data ?? [];
        final filtered = courses
            .where(
              (c) => c['title'].toString().toLowerCase().contains(
                search.toLowerCase(),
              ),
            )
            .toList();

        return ListView(
          padding: const EdgeInsets.all(22),
          children: [
            heading('Explore courses'),
            const Text('Discover something worth learning.'),
            const SizedBox(height: 20),
            TextField(
              onChanged: (s) => setState(() => search = s),
              decoration: const InputDecoration(
                hintText: 'Search courses',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('My enrolled courses'),
              value: onlyMine,
              onChanged: (v) => setState(() => onlyMine = v),
            ),
            const SizedBox(height: 12),
            if (!snapshot.hasData)
              const Center(child: CircularProgressIndicator())
            else if (filtered.isEmpty)
              panel(const Text('No courses found.'))
            else
              ...filtered.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: CourseTile(
                    course: c,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseDetailScreen(
                            userId: widget.userId,
                            course: c,
                          ),
                        ),
                      );
                      if (mounted) {
                        setState(() {});
                        widget.onChanged();
                      }
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ==========================================
// 8. COURSE DETAILS AND LESSONS
// ==========================================

class CourseDetailScreen extends StatefulWidget {
  final int userId;
  final Map<String, Object?> course;

  const CourseDetailScreen({
    super.key,
    required this.userId,
    required this.course,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late bool enrolled;

  @override
  void initState() {
    super.initState();
    enrolled = widget.course['enrolled'] == 1;
  }

  Future<void> enroll() async {
    await DB.instance.enroll(widget.userId, widget.course['id'] as int);

    if (!mounted) return;

    setState(() {
      enrolled = true;
    });

    showMessage(context, 'Successfully enrolled!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course details')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_stories, size: 50, color: C.orange),
                const SizedBox(height: 18),
                Text(
                  widget.course['title'].toString(),
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: C.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(widget.course['description'].toString()),
              ],
            ),
            color: C.sand,
          ),
          const SizedBox(height: 24),

          if (!enrolled)
            primaryButton('Enroll in this course', enroll)
          else ...[
            heading('Your lessons'),
            FutureBuilder<List<Map<String, Object?>>>(
              future: DB.instance.lessons(
                widget.userId,
                widget.course['id'] as int,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final lessons = snapshot.data!;

                return Column(
                  children: lessons.asMap().entries.map((entry) {
                    final lesson = entry.value;
                    final done = lesson['completed'] == 1;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: panel(
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: done ? C.green : C.ivory,
                            child: Icon(
                              done ? Icons.check : Icons.play_arrow,
                              color: done ? Colors.white : C.navy,
                            ),
                          ),
                          title: Text(lesson['title'].toString()),
                          subtitle: Text('Lesson ${entry.key + 1}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LessonScreen(
                                  userId: widget.userId,
                                  lesson: lesson,
                                ),
                              ),
                            );

                            if (mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class LessonScreen extends StatefulWidget {
  final int userId;
  final Map<String, Object?> lesson;

  const LessonScreen({super.key, required this.userId, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late bool completed;

  @override
  void initState() {
    super.initState();
    completed = widget.lesson['completed'] == 1;
  }

  Future<void> toggle() async {
    await DB.instance.toggleLesson(
      widget.userId,
      widget.lesson['id'] as int,
      completed,
    );
    if (!mounted) return;
    setState(() => completed = !completed);
    showMessage(
      context,
      completed ? 'Lesson marked as completed' : 'Lesson marked as incomplete',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning material')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          heading(widget.lesson['title'].toString()),
          panel(
            Text(
              widget.lesson['content'].toString(),
              style: const TextStyle(fontSize: 17, height: 1.7),
            ),
          ),
          const SizedBox(height: 24),
          primaryButton(
            completed ? 'Mark as incomplete' : 'Mark as completed',
            toggle,
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 9. ASSIGNMENTS
// ==========================================

class AssignmentsScreen extends StatefulWidget {
  final int userId;
  const AssignmentsScreen({super.key, required this.userId});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  Future<void> openAssignment(Map<String, Object?> task) async {
    final controller = TextEditingController(
      text: task['answer']?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(task['title'].toString()),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Write your assignment answer...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await DB.instance.submitAssignment(
                widget.userId,
                task['id'] as int,
                controller.text.trim(),
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (mounted) {
                setState(() {});
                showMessage(context, 'Assignment submitted!');
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: DB.instance.assignments(widget.userId),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(22),
          children: [
            heading('My assignments'),
            const Text('Stay on top of your deadlines.'),
            const SizedBox(height: 22),
            if (!snapshot.hasData)
              const Center(child: CircularProgressIndicator())
            else if (tasks.isEmpty)
              panel(const Text('Enroll in a course to see its assignments.'))
            else
              ...tasks.map((task) {
                final submitted = task['answer'] != null;
                final due = DateTime.parse(task['due_date'].toString());
                final overdue = !submitted && due.isBefore(DateTime.now());
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: panel(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['course_title'].toString(),
                          style: const TextStyle(color: C.orange),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          task['title'].toString(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: C.navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Due: ${DateFormat('dd MMM yyyy').format(due)}'),
                        const SizedBox(height: 8),
                        Text(
                          submitted
                              ? 'Submitted'
                              : overdue
                              ? 'Overdue'
                              : 'Pending',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: submitted ? C.green : C.orange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        primaryButton(
                          submitted ? 'View / edit answer' : 'Submit answer',
                          () => openAssignment(task),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

// ==========================================
// 10. STUDENT PROFILE
// ==========================================

class ProfileScreen extends StatelessWidget {
  final int userId;
  final Future<void> Function() onLogout;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.onLogout,
  });

  Future<Map<String, dynamic>> load() async {
    return {
      'student': await DB.instance.student(userId),
      'courses': await DB.instance.courses(userId, onlyEnrolled: true),
      'assignments': await DB.instance.assignments(userId),
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final student = snapshot.data!['student'] as Map<String, Object?>?;
        final courses = snapshot.data!['courses'] as List<Map<String, Object?>>;
        final tasks =
            snapshot.data!['assignments'] as List<Map<String, Object?>>;
        final completed = courses.fold<int>(
          0,
          (s, c) => s + (c['completed'] as int),
        );
        final submitted = tasks.where((a) => a['answer'] != null).length;

        return ListView(
          padding: const EdgeInsets.all(22),
          children: [
            heading('My profile'),
            panel(
              Column(
                children: [
                  const CircleAvatar(
                    radius: 42,
                    backgroundColor: C.sand,
                    child: Icon(Icons.person, size: 45, color: C.navy),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    student?['name']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: C.navy,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(student?['email']?.toString() ?? ''),
                ],
              ),
            ),
            const SizedBox(height: 24),
            heading('Learning statistics'),
            panel(
              Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.book, color: C.orange),
                    title: const Text('Enrolled courses'),
                    trailing: Text('${courses.length}'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.task_alt, color: C.green),
                    title: const Text('Completed lessons'),
                    trailing: Text('$completed'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.assignment_turned_in,
                      color: C.orange,
                    ),
                    title: const Text('Submitted assignments'),
                    trailing: Text('$submitted'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            primaryButton('Logout', () async {
              await onLogout();
            }),
          ],
        );
      },
    );
  }
}
