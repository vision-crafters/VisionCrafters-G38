import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutterbasics/firebase_options.dart';
import 'package:flutterbasics/providers/app_state.dart';
import 'package:flutterbasics/pages/home_page.dart';
import 'package:flutterbasics/services/database.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure Flutter Firebase is initialized
  await dotenv.load(fileName: ".env");

  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  final database = await dbHelper.database;

  //Ensures that Firebase has been fully initialized before running the app.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //Configures Firebase Functions to use a local emulator if
  //the app is running in debug mode.
  if (kDebugMode) {
    final host = dotenv.get('HOST');
    FirebaseFunctions.instanceFor(region: "us-central1")
        .useFunctionsEmulator(host, 5001); //Uses the local emulator
  }

  runApp(
      MyApp(database: database));  //Launches the root widget of the application
}

class MyApp extends StatelessWidget {
  final Database database;

  const MyApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      //Provides the AppState to the widget tree,
      //allowing state management.
      create: (_) => AppState(),
      child: MaterialApp(
        //Sets up the material design for the app,
        //including themes and the home page.
        debugShowCheckedModeBanner: false,
        title: "Vision Crafters",
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.system,
        home: HomePage(
            database:
                database), //The initial screen displayed when the app starts.
      ),
    );
  }
}
