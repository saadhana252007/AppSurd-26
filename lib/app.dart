
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
import 'screens/command_center_screen.dart';
import 'screens/task_registry_screen.dart';
import 'screens/ledger_screen.dart';
import 'screens/task_detail_screen.dart';
import 'screens/evidence_court_screen.dart';
import 'screens/auth_screen.dart';

class ProofLockApp extends StatelessWidget {
const ProofLockApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'PROOFLOCK',
debugShowCheckedModeBanner: false,
theme: AppTheme.dark,
home: const AuthGate(),
onGenerateRoute: (settings) {
if (settings.name == '/task-detail') {
final taskId = settings.arguments;

if (taskId is! String || taskId.isEmpty) {
return MaterialPageRoute(
builder: (_) => const MainNavigation(initialIndex: 1),
);
}

return MaterialPageRoute(
builder: (_) => TaskDetailScreen(taskId: taskId),
);
}

if (settings.name == '/evidence-court') {
final reportId = settings.arguments;

if (reportId is! String || reportId.isEmpty) {
return MaterialPageRoute(
builder: (_) => const MainNavigation(initialIndex: 2),
);
}

return MaterialPageRoute(
builder: (_) => EvidenceCourtScreen(reportId: reportId),
);
}

if (settings.name == '/tasks') {
return MaterialPageRoute(
builder: (_) => const MainNavigation(initialIndex: 1),
);
}

return null;
},
);
}
}

class AuthGate extends StatelessWidget {
const AuthGate({super.key});

@override
Widget build(BuildContext context) {
final client = Supabase.instance.client;

return StreamBuilder<AuthState>(
stream: client.auth.onAuthStateChange,
initialData: AuthState(
AuthChangeEvent.initialSession,
client.auth.currentSession,
),
builder: (context, snapshot) {
if (client.auth.currentSession != null) {
return const MainNavigation();
}

return const AuthScreen();
},
);
}
}

class MainNavigation extends StatefulWidget {
final int initialIndex;

const MainNavigation({
super.key,
this.initialIndex = 0,
});

@override
State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
late int index;

final screens = const [
CommandCenterScreen(),
TaskRegistryScreen(),
LedgerScreen(),
];

@override
void initState() {
super.initState();
index = widget.initialIndex.clamp(0, 2);
}

@override
Widget build(BuildContext context) {
return Scaffold(
body: IndexedStack(
index: index,
children: screens,
),
bottomNavigationBar: NavigationBar(
selectedIndex: index,
onDestinationSelected: (value) {
setState(() => index = value);
},
destinations: const [
NavigationDestination(
icon: Icon(Icons.dashboard_outlined),
selectedIcon: Icon(Icons.dashboard),
label: 'Command',
),
NavigationDestination(
icon: Icon(Icons.fact_check_outlined),
selectedIcon: Icon(Icons.fact_check),
label: 'Tasks',
),
NavigationDestination(
icon: Icon(Icons.receipt_long_outlined),
selectedIcon: Icon(Icons.receipt_long),
label: 'Ledger',
),
],
),
);
}
}
