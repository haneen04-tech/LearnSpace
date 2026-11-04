LearnSpace 📚
LearnSpace is an offline, student-focused Learning Management System (LMS) built using Flutter and Dart. Students can create an account, explore courses, enroll, read lessons, track learning progress, submit assignments, and manage their enrollments. App data is stored locally using SQLite.
Project type: Flutter CRUD application / academic mini-project
Platform: Android
Storage: On-device SQLite (no internet connection required for core learning features)

Features
- Student registration and login: Create a student account and sign in with an email and password.
- Persistent login: Remember the signed-in student using SharedPreferences.
- Course catalog: Browse and search available courses.
- Enroll in courses: Add courses to the student's learning list.
- Unenroll from courses: Remove an enrollment after confirming the action.
- Lessons: Read course lessons and mark them complete or incomplete.
- Progress tracking: See percentage progress for each enrolled course.
- Completed courses: Courses with all lessons completed appear in the Completed filter and contribute to the completed-course count.
- Assignments: View assignments, submit written answers, and edit existing submissions.
- Student profile and dashboard: Review progress and learning activity.
Screens
Screen	Purpose
Login / Register	Sign up or access an existing student account
Dashboard	See learning summary and ongoing courses
Courses	Browse, search, and filter All Courses, My Learning, and Completed
Course Details	Enroll, read lessons, view progress, or unenroll
Lesson	Read content and toggle lesson completion
Assignments	View tasks and submit or update answers
Profile	View student details and completion statistics


Tech Stack
Technology	Use
Flutter	Cross-platform application UI framework
Dart	Application programming language
SQLite	Local relational database
sqflite	SQLite operations from Flutter
shared_preferences	Locally remembers the signed-in student ID
crypto	Salted, repeated SHA-256 password hashing for this demonstration app
intl	Formats assignment due dates
path	Constructs the database file path


How Course Progress Works
Course progress is calculated using the number of completed lessons:
Progress (%) = (Completed Lessons / Total Lessons) × 100
For a course containing four lessons:
Completed lessons	Progress
1 / 4	25%
2 / 4	50%
3 / 4	75%
4 / 4	100%


Marking a lesson complete saves a record in the lesson_progress table. Marking it incomplete removes that record. When every lesson of an enrolled course is completed, the course is shown under Completed and increases the completed-course count. Courses with no lessons are not treated as completed.
CRUD Operations
Operation	Example in LearnSpace
Create	Register, enroll in a course, submit an assignment
Read	Browse courses, read lessons, view submissions and progress
Update	Change lesson-completion status, replace an assignment answer
Delete	Unenroll from a course, remove a lesson-completion record


Unenroll behavior: Unenrolling deletes the student's enrollment, saved lesson-completion records, and assignment submissions for that course. It does not delete the course itself or the student's account. The student can enroll again later, but removed progress and submissions are not restored.

Database Design
The application stores data in a local learnspace.db SQLite database with seven tables:
Table	Stores
students	Student names, emails, password salts and password hashes
courses	Available courses and descriptions
lessons	Lessons belonging to courses
enrollments	Student–course enrollments
lesson_progress	Student–lesson completion records
assignments	Assignments and due dates
submissions	Student answers and submission timestamps


Student, course, lesson, and assignment IDs link related records. Enrollment, progress, and submission tables use composite keys to avoid duplicate entries for the same student and item.
Getting Started
Prerequisites
- Flutter SDK and Dart
- Android Studio or VS Code
- Android SDK and an emulator, or a physical Android phone with USB debugging enabled
Installation
1. Clone the repository and open the Flutter project folder:
   git clone https://github.com/HaneenBaghdadi/leranSpace.git
   cd leranSpace
2. Install dependencies:
   flutter pub get
3. Check available devices:
   flutter devices
4. Run the application:
   flutter run
   To target a specific emulator, use flutter run -d <device-id>.

6. Optional: check the code:
   flutter analyze
Build an Android APK
flutter build apk --release
The generated APK can be found at:
build/app/outputs/flutter-apk/app-release.apk
Change the Android Launcher Icon
If flutter_launcher_icons is configured and the icon exists at assets/icon/app_icon.png, run:
dart run flutter_launcher_icons
flutter build apk --release
Android displays the app name according to android:label in android/app/src/main/AndroidManifest.xml (set it to LearnSpace for that label).
Project Structure
The current student demo keeps the primary UI, database helper, and application logic together in lib/main.dart.
learnspace/
├── android/                # Android configuration
├── assets/                 # App artwork (if included)
│   └── icon/
│       └── app_icon.png
├── lib/
│   └── main.dart           # UI, navigation, database and app logic
├── test/                   # Flutter tests
├── pubspec.yaml            # Package dependencies
└── README.md
Example User Flow
1. Register or log in as a student.
2. Explore the available courses.
3. Enroll in a course.
4. Open lessons and mark them as completed.
5. Monitor the course progress bar.
6. Complete every lesson to make the course appear in Completed.
7. View or submit assignments.
8. If needed, unenroll using the confirmation option in Course Details.
Limitations and Future Scope
LearnSpace is an offline academic demonstration, not a production learning platform. It currently uses local demo content and local student accounts; it does not include a teacher/admin portal, cloud synchronization, video hosting, or multi-device account access. The password-hashing method is for a classroom demonstration and should be replaced with a dedicated password-hashing algorithm and a proper authentication system before production deployment.

Possible future improvements include teacher-managed courses, quizzes, notifications, cloud sync, and richer multimedia lessons.
Author
Haneen Baghdadi
Academic Flutter Learning Management System project.
