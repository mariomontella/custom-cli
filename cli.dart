import 'dart:io';
import 'package:args/args.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';
import 'dart:convert';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('name', abbr: 'n', help: 'Nome del progetto')
    ..addOption('template', abbr: 't', defaultsTo: 'default', help: 'Template da usare (default, mvvm, bloc)')
    ..addFlag('no-firebase', negatable: false, help: 'Escludi Firebase dalle dipendenze')
    ..addFlag('with-tests', negatable: false, help: 'Aggiungi configurazione test unitari')
    ..addFlag('with-analytics', negatable: false, help: 'Aggiungi configurazione analytics')
    ..addOption('description', help: 'Descrizione del progetto')
    ..addOption('organization', defaultsTo: 'com.example', help: 'ID organizzazione')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Mostra questo help');

  try {
    final argResults = parser.parse(arguments);
    
    if (argResults['help']) {
      _printUsage(parser);
      exit(0);
    }
    
    final projectName = argResults['name'];
    if (projectName == null || projectName.isEmpty) {
      print('❌ Errore: è necessario specificare un nome per il progetto con --name.');
      _printUsage(parser);
      exit(1);
    }
    
    final template = argResults['template'];
    final excludeFirebase = argResults['no-firebase'];
    final withTests = argResults['with-tests'];
    final withAnalytics = argResults['with-analytics'];
    final description = argResults['description'] ?? 'A new Flutter project';
    final organization = argResults['organization'];

    await _createProject(
      projectName: projectName, 
      template: template, 
      excludeFirebase: excludeFirebase, 
      withTests: withTests,
      withAnalytics: withAnalytics,
      description: description,
      organization: organization
    );
  } catch (e) {
    print('❌ Errore: ${e.toString()}');
    _printUsage(parser);
    exit(1);
  }
}

void _printUsage(ArgParser parser) {
  print('\nUtilizzo: dart create_flutter_project.dart --name=my_app [options]');
  print(parser.usage);
}

Future<void> _createProject({
  required String projectName,
  required String template,
  required bool excludeFirebase,
  required bool withTests,
  required bool withAnalytics,
  required String description,
  required String organization,
}) async {
  print('🚀 Inizializzazione progetto Flutter: $projectName');
  print('📋 Template: $template');

  // Creazione del progetto Flutter con organizzazione personalizzata
  final createResult = await Process.run(
    'flutter', 
    ['create', 
     '--org', organization,
     '--description', description,
     projectName
    ]
  );
  
  if (createResult.exitCode != 0) {
    print('❌ Errore durante la creazione del progetto:');
    print(createResult.stderr);
    exit(1);
  }

  final projectPath = Directory(projectName);
  if (!projectPath.existsSync()) {
    print('❌ Errore: impossibile creare il progetto.');
    exit(1);
  }

  // Naviga nel progetto
  Directory.current = projectPath;
  
  // Crea struttura cartelle in base al template
  await _createProjectStructure(template);
  
  // Aggiorna pubspec.yaml
  await _updatePubspec(excludeFirebase, withTests, withAnalytics);
  
  // Crea file di configurazione
  await _createConfigFiles(projectName);
  
  // Esegui flutter pub get
  print('📦 Installazione dipendenze...');
  final pubGetResult = await Process.run('flutter', ['pub', 'get']);
  if (pubGetResult.exitCode != 0) {
    print('⚠️ Attenzione: problemi durante l\'installazione delle dipendenze.');
    print(pubGetResult.stderr);
  }
  
  // Configura git repository
  await _initGit();
  
  print('\n✅ Progetto $projectName creato con successo!');
  print('\n🔍 Prossimi passi:');
  print('  1. cd $projectName');
  print('  2. flutter run');
  print('  3. Modifica lib/main.dart per personalizzare la tua app');
}

Future<void> _createProjectStructure(String template) async {
  print('📂 Creazione struttura cartelle per template: $template');
  
  // Cartelle base comuni a tutti i template
  final baseDirs = [
    "assets/fonts",
    "assets/images",
    "assets/translations",
    "lib/constants",
    "lib/utility",
    "lib/widgets/common",
  ];
  
  final templateDirs = <String>[];
  
  // Aggiungi cartelle specifiche in base al template
  switch (template.toLowerCase()) {
    case 'mvvm':
      templateDirs.addAll([
        "lib/models",
        "lib/views",
        "lib/viewmodels",
        "lib/services",
        "lib/repositories",
      ]);
      break;
    case 'bloc':
      templateDirs.addAll([
        "lib/bloc",
        "lib/models",
        "lib/repositories",
        "lib/screens",
        "lib/services",
      ]);
      break;
    case 'default':
    default:
      templateDirs.addAll([
        "lib/api",
        "lib/models",
        "lib/screens",
        "lib/services",
        "lib/private",
      ]);
      break;
  }
  
  // Crea tutte le cartelle
  for (var dir in [...baseDirs, ...templateDirs]) {
    Directory(dir).createSync(recursive: true);
    // Crea un file .gitkeep per mantenere la struttura delle cartelle vuote in git
    File('$dir/.gitkeep').writeAsStringSync('');
  }
  
  // Crea file di esempio in base al template
  await _createTemplateFiles(template);
}

Future<void> _createTemplateFiles(String template) async {
  // Crea file constants
  _createFile("lib/constants/app_constants.dart", """
class AppConstants {
  // App info
  static const String appName = 'My Flutter App';
  static const String appVersion = '1.0.0';
  
  // API endpoints
  static const String apiBaseUrl = 'https://api.example.com';
  
  // Timeouts
  static const int connectionTimeout = 30000; // milliseconds
  
  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}
  """);
  
  _createFile("lib/constants/route_constants.dart", """
class RouteConstants {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String settings = '/settings';
}
  """);
  
  _createFile("lib/constants/error_constants.dart", """
class ErrorConstants {
  static const String networkError = 'Errore di connessione. Controlla la tua connessione internet.';
  static const String serverError = 'Errore del server. Riprova più tardi.';
  static const String authError = 'Errore di autenticazione. Accedi nuovamente.';
  static const String unknownError = 'Si è verificato un errore sconosciuto.';
}
  """);
  
  // Crea file utility
  _createFile("lib/utility/connectivity_utils.dart", """
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityUtils {
  static Future<bool> isConnected() async {
    return await InternetConnectionChecker().hasConnection;
  }
}
  """);
  
  // Crea main.dart basato sul template
  switch (template.toLowerCase()) {
    case 'mvvm':
      _createMainDartMVVM();
      break;
    case 'bloc':
      _createMainDartBloc();
      break;
    default:
      _createMainDartDefault();
      break;
  }
  
  // Crea README personalizzato
  _createFile("README.md", """
# Flutter Project Template

Project template generated with Flutter CLI tool.

## Structure

This project follows the ${template.toUpperCase()} architecture pattern.

## Getting Started

1. Run `flutter pub get` to install dependencies
2. Run `flutter run` to start the app

## Features

- Organized folder structure
- Pre-configured dependencies
- Common utilities included
- Ready-to-use widgets

## Dependencies

Check the `pubspec.yaml` file for all dependencies.
  """);
}

void _createMainDartDefault() {
  _createFile("lib/main.dart", """
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const MyApp({Key? key, required this.prefs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
      builder: EasyLoading.init(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const HomeTab(),
    const SettingsTab(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter App'),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Home Tab', style: TextStyle(fontSize: 24)),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings Tab', style: TextStyle(fontSize: 24)),
    );
  }
}
  """);
}

void _createMainDartMVVM() {
  // Crea prima un file di servizio esempio
  _createFile("lib/services/auth_service.dart", """
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final SharedPreferences _prefs;
  
  AuthService(this._prefs);
  
  Future<bool> isLoggedIn() async {
    return _prefs.getString('token') != null;
  }
  
  Future<void> login(String token) async {
    await _prefs.setString('token', token);
  }
  
  Future<void> logout() async {
    await _prefs.remove('token');
  }
}
  """);
  
  // Crea un viewmodel di esempio
  _createFile("lib/viewmodels/home_viewmodel.dart", """
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class HomeViewModel with ChangeNotifier {
  final AuthService _authService;
  bool _isLoading = false;
  String _message = 'Welcome to MVVM pattern!';
  
  HomeViewModel(this._authService);
  
  bool get isLoading => _isLoading;
  String get message => _message;
  
  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      _message = isLoggedIn 
          ? 'User is authenticated' 
          : 'User is not authenticated';
    } catch (e) {
      _message = 'Error checking authentication: \${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
  """);
  
  // Crea il main.dart per MVVM
  _createFile("lib/main.dart", """
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'services/auth_service.dart';
import 'viewmodels/home_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final authService = AuthService(prefs);
  
  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  
  const MyApp({Key? key, required this.authService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MVVM Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => HomeViewModel(authService),
          ),
        ],
        child: const HomePage(),
      ),
      builder: EasyLoading.init(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Get the ViewModel and call checkAuth when the page loads
    Future.microtask(() => 
      Provider.of<HomeViewModel>(context, listen: false).checkAuth()
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MVVM Pattern'),
      ),
      body: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  viewModel.message,
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => viewModel.checkAuth(),
                  child: const Text('Refresh Status'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
  """);
}

void _createMainDartBloc() {
  // Creare esempi file bloc
  _createFile("lib/bloc/counter_event.dart", """
abstract class CounterEvent {}

class IncrementEvent extends CounterEvent {}

class DecrementEvent extends CounterEvent {}

class ResetEvent extends CounterEvent {}
  """);
  
  _createFile("lib/bloc/counter_state.dart", """
class CounterState {
  final int count;
  
  const CounterState(this.count);
  
  factory CounterState.initial() => const CounterState(0);
}
  """);
  
  _createFile("lib/bloc/counter_bloc.dart", """
import 'package:flutter_bloc/flutter_bloc.dart';
import 'counter_event.dart';
import 'counter_state.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterState.initial()) {
    on<IncrementEvent>(_onIncrement);
    on<DecrementEvent>(_onDecrement);
    on<ResetEvent>(_onReset);
  }

  void _onIncrement(IncrementEvent event, Emitter<CounterState> emit) {
    emit(CounterState(state.count + 1));
  }

  void _onDecrement(DecrementEvent event, Emitter<CounterState> emit) {
    emit(CounterState(state.count - 1));
  }

  void _onReset(ResetEvent event, Emitter<CounterState> emit) {
    emit(CounterState.initial());
  }
}
  """);
  
  // Crea il main.dart per BLoC
  _createFile("lib/main.dart", """
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'bloc/counter_bloc.dart';
import 'bloc/counter_event.dart';
import 'bloc/counter_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLoC Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => CounterBloc(),
        child: const HomePage(),
      ),
      builder: EasyLoading.init(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLoC Pattern Example'),
      ),
      body: Center(
        child: BlocBuilder<CounterBloc, CounterState>(
          builder: (context, state) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Counter Value:',
                  style: TextStyle(fontSize: 20),
                ),
                Text(
                  '\${state.count}',
                  style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        context.read<CounterBloc>().add(DecrementEvent());
                      },
                      tooltip: 'Decrement',
                      child: const Icon(Icons.remove),
                    ),
                    const SizedBox(width: 20),
                    FloatingActionButton(
                      onPressed: () {
                        context.read<CounterBloc>().add(ResetEvent());
                      },
                      tooltip: 'Reset',
                      child: const Icon(Icons.refresh),
                    ),
                    const SizedBox(width: 20),
                    FloatingActionButton(
                      onPressed: () {
                        context.read<CounterBloc>().add(IncrementEvent());
                      },
                      tooltip: 'Increment',
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
  """);
}

Future<void> _updatePubspec(bool excludeFirebase, bool withTests, bool withAnalytics) async {
  print('📝 Aggiornamento pubspec.yaml...');
  
  // Leggi il file pubspec.yaml esistente
  final pubspecFile = File('pubspec.yaml');
  final pubspecContent = pubspecFile.readAsStringSync();
  
  final yamlEditor = YamlEditor(pubspecContent);
  
  // Aggiungi dipendenze di base
  final dependencies = {
    "cupertino_icons": "^1.0.8",
    "hexcolor": "^3.0.1",
    "animated_splash_screen": "^1.3.0",
    "flutter_easyloading": "^3.0.5",
    "http": "^1.2.1",
    "shared_preferences": "^2.2.3",
    "flutter_speed_dial": "^7.0.0",
    "internet_connection_checker": "^1.0.0+1",
    "url_launcher": "^6.2.6",
    "openid_client": "^0.4.8",
    "intl": "^0.19.0",
    "device_info_plus": "^10.1.2",
    "flutter_launcher_icons": "^0.14.1",
    "path_provider": "^2.1.4",
    "flutter_localization": "^0.2.2",
    "open_filex": "^4.6.0",
    "flutter_local_notifications": "^18.0.1",
    "permission_handler": "^11.3.1",
  };
  
  // Aggiungi le dipendenze Firebase se non escluse
  if (!excludeFirebase) {
    dependencies.addAll({
      "firebase_messaging": "^15.1.0",
      "firebase_core": "^3.1.0",
      "cloud_firestore": "^4.15.5",
    });
  }
  
  // Aggiungi dipendenze basate sul template
  final pubspecYaml = loadYaml(pubspecContent) as Map;
  final template = pubspecYaml['flutter_cli']?['template'] ?? 'default';
  
  if (template == 'mvvm') {
    dependencies["provider"] = "^6.1.1";
  } else if (template == 'bloc') {
    dependencies["flutter_bloc"] = "^8.1.4";
    dependencies["equatable"] = "^2.0.5";
  }
  
  // Aggiungi dipendenze per analytics se richiesto
  if (withAnalytics) {
    dependencies["firebase_analytics"] = "^10.8.5";
  }

  // Aggiungi dipendenze di sviluppo per test se richiesto: si può eliminare
  final devDependencies = <String, dynamic>{};
  if (withTests) {
    devDependencies.addAll({
      "flutter_test": {"sdk": "flutter"},
      "mockito": "^5.4.4",
      "build_runner": "^2.4.8",
    });
  }
  
  // Salva le dipendenze
  for (final entry in dependencies.entries) {
    try {
      yamlEditor.update(['dependencies', entry.key], entry.value);
    } catch (e) {
      yamlEditor.update(['dependencies'], {entry.key: entry.value});
    }
  }
  
  // Salva le dev_dependencies
  for (final entry in devDependencies.entries) {
    try {
      yamlEditor.update(['dev_dependencies', entry.key], entry.value);
    } catch (e) {
      yamlEditor.update(['dev_dependencies'], {entry.key: entry.value});
    }
  }
  
  // Aggiungi metadati del template
  try {
    yamlEditor.update(['flutter_cli'], {'template': template});
  } catch (e) {
    yamlEditor.update([], {'flutter_cli': {'template': template}});
  }
  
  // Scrivi il file aggiornato
  pubspecFile.writeAsStringSync(yamlEditor.toString());
}

Future<void> _createConfigFiles(String projectName) async {
  print('🛠️ Creazione file di configurazione...');
  
  // Crea .gitignore migliorato
  _createFile(".gitignore", """
# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.atom/
.buildlog/
.history
.svn/
migrate_working_dir/

# IntelliJ related
*.iml
*.ipr
*.iws
.idea/

# The .vscode folder contains launch configuration and tasks you configure in
# VS Code which you may wish to be included in version control, so this line
# is commented out by default.
#.vscode/

# Flutter/Dart/Pub related
**/doc/api/
**/ios/Flutter/.last_build_id
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
/build/

# Symbolication related
app.*.symbols

# Obfuscation related
app.*.map.json

# Android Studio will place build artifacts here
/android/app/debug
/android/app/profile
/android/app/release

# iOS specific
**/ios/Pods/
**/ios/Runner.xcworkspace/

# Firebase config files that may contain sensitive info
google-services.json
GoogleService-Info.plist

# Environment variables
.env
.env.local
.env.development
.env.test
.env.production

# Coverage reports
coverage/
  """);
  
  // Crea VSCode settings
  Directory(".vscode").createSync(recursive: true);
  _createFile(".vscode/settings.json", """
{
  "dart.sdkPath": "./flutter",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  },
  "editor.rulers": [80],
  "dart.lineLength": 80,
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true,
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.formatOnSave": true,
    "editor.formatOnType": true,
    "editor.rulers": [80],
    "editor.selectionHighlight": false,
    "editor.suggest.snippetsPreventQuickSuggestions": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": false
  }
}
  """);
  
  // Crea VSCode launch.json
  _createFile(".vscode/launch.json", """
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Development",
      "request": "launch",
      "type": "dart",
      "flutterMode": "debug",
      "args": [
        "--flavor",
        "development"
      ]
    },
    {
      "name": "Production",
      "request": "launch",
      "type": "dart",
      "flutterMode": "release",
      "args": [
        "--flavor",
        "production"
      ]
    }
  ]
}
  """);
  
  // Crea analysis_options.yaml migliorato
  _createFile("analysis_options.yaml", """
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - avoid_print: true
    - avoid_empty_else
    - avoid_relative_lib_imports
    - avoid_unused_constructor_parameters
    - await_only_futures
    - camel_case_types
    - cancel_subscriptions
    - close_sinks
    - constant_identifier_names
    - control_flow_in_finally
    - directives_ordering
    - empty_catches
    - empty_constructor_bodies
    - empty_statements
    - hash_and_equals
    - implementation_imports
    - library_names
    - library_prefixes
    - non_constant_identifier_names
    - package_names
    - package_prefixed_library_names
    - prefer_const_constructors
    - prefer_final_fields
    - prefer_is_not_empty
    - prefer_typing_uninitialized_variables
    - sort_constructors_first
    - test_types_in_equals
    - throw_in_finally
    - unnecessary_brace_in_string_interps
    - unnecessary_const
    - unnecessary_new
    - unrelated_type_equality_checks
    - valid_regexps

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore
  """);
  
  // Crea un file di configurazione locale
  _createFile("lib/constants/config.dart", """
enum Environment {
  development,
  staging,
  production,
}

class Config {
  static Environment environment = Environment.development;
  
  static bool get isDevelopment => environment == Environment.development;
  static bool get isStaging => environment == Environment.staging;
  static bool get isProduction => environment == Environment.production;
  
  static String get apiBaseUrl {
    switch (environment) {
      case Environment.development:
        return 'https://dev-api.example.com';
      case Environment.staging:
        return 'https://staging-api.example.com';
      case Environment.production:
        return 'https://api.example.com';
    }
  }
}
  """);
}

Future<void> _initGit() async {
  print('🔄 Inizializzazione repository Git...');
  
  try {
    await Process.run('git', ['init']);
    await Process.run('git', ['add', '.']);
    await Process.run('git', ['commit', '-m', 'Initial commit']);
    print('✅ Repository Git inizializzato con successo.');
  } catch (e) {
    print('⚠️ Impossibile inizializzare il repository Git: ${e.toString()}');
  }
}

void _createFile(String path, String content) {
  final file = File(path);
  // Crea directory genitore se non esiste
  if (!file.parent.existsSync()) {
    file.parent.createSync(recursive: true);
  }
  file.writeAsStringSync(content);
}