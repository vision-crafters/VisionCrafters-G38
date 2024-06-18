import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutterbasics/DashBoardScreen.dart';
import 'package:flutterbasics/Settings.dart';
import 'package:flutterbasics/Speech_To_Text.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'app_state.dart'; // Import the AppState class
import 'firebase_options.dart';
import 'upload.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure Flutter Firebase is initialized
  await dotenv.load(fileName: ".env");
  //Ensures that Firebase has been fully initialized before running the app.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    //Configures Firebase Functions to use a local emulator if
    //the app is running in debug mode.
    final host = dotenv.get('HOST');
    FirebaseFunctions.instanceFor(region: "us-central1")
        .useFunctionsEmulator(host, 5001);//Uses the local emulator
  }
  runApp(const MyApp()); //Launches the root widget of the application
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        home: const HomePage(),
        //The initial screen displayed when the app starts.
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  //A stateful widget that maintains the state of the home page.

  const HomePage({Key? key}) : super(key: key); //constructor for the HomePage widget

  @override
  State<HomePage> createState() => _HomePageState();//Creates the state of the widget
}

class _HomePageState extends State<HomePage> {
  List<String> descriptions = [];
  //used for List of text descriptions generated from images or videos
  File? imageGal;
  File? imageCam;
  //Files for selected images from the gallery and camera

  bool showSpinner = false;
  //Boolean to control the display of a loading spinner.

  void addDescription(String description) {
    //Adds a new description to the list and updates the state of the widget.
    setState(() {
      descriptions.add(description);
    });
  }

  @override
  Widget build(BuildContext context) {
    //Builds the UI of the home page
    final appState = Provider.of<AppState>(context);
    return GestureDetector(
      onDoubleTap: () {
        getImageCM(context, addDescription, appState);
      },//Double tap gesture to open the camera
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => const Speech(),
        );
      },    
      child: Scaffold(
        appBar: AppBar(
          //Displays the title and a settings button.
        title: const Text("Vision Crafters"),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {//Function to be executed when the settings button is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),//Navigates to the settings page
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          //Provides a navigation drawer
        width: MediaQuery.of(context).size.width * 0.8,
          child: DashBoardScreen(),//Displays the dashboard screen
        ),
        body: ModalProgressHUD(
          //Displays a loading spinner when appState.showSpinner is true
        inAsyncCall: appState.showSpinner,
          child: Column(
            children: [
              //Displays the UI of the home page
            const Center(
                child: Text(
                  "Welcome to Vision Crafters",
                  //Displays a welcome message.
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  //Displays the list of descriptions using ListView.builder
                itemCount: descriptions.length, // Number of items in the list
                  itemBuilder: (context, index) {
                    // Builds each item in the list
                  return ListTile(
                      // Displays each item in the list as a ListTile
                    title: Text(descriptions[index]),
                    );
                  },
                ),
              ),
              Container(
                // Displays a floating action button
              padding: const EdgeInsets.all(8.0), // Padding around the button
                child: Row(
                  //Contains a speed dial for image/video picking,a text
                //input field, and a microphone button for speech-to-text
                children: [
                    FloatingActionButton(
                      //Displays a speed dial for image/video picking
                    shape: const CircleBorder(),
                      heroTag: "UniqueTag2", //Unique identifier for the button
                      onPressed: () {},
                      child: SpeedDial(
                        //Speed dial for image/video picking
                      animatedIcon: AnimatedIcons
                          .menu_close, //Animated icon for the button
                        direction:
                          SpeedDialDirection.up, //Direction of the speed dial
                        children: [
                          //List of children for the speed dial
                        SpeedDialChild(
                            //Child for the camera button
                          shape: const CircleBorder(), //Shape of the button
                            child: const Icon(Icons.camera), //Icon for the button
                            onTap: () =>
                                getImageCM(context, addDescription, appState),
                            //Function to be executed when the button is pressed
                          //Calls the getImageCM function with the context,
                          //addDescription, and appState as parameters
                        ),
                          SpeedDialChild(
                            //Child for the video button
                          shape: const CircleBorder(),
                            child: const Icon(Icons.video_call),
                            onTap: () =>
                                getVideoFile(context, addDescription, appState),
                            // Function to be executed when the button is pressed
                          //Calls the getVideoFile function with the context,
                          //addDescription, and appState as parameters
                        ),
                          SpeedDialChild(
                            //Child for the gallery button
                          shape: const CircleBorder(),
                            child: const Icon(Icons.browse_gallery_sharp),
                            onTap: () =>
                                pickMedia(context, addDescription, appState),
                            //Function to be executed when the button is pressed
                          //Calls the pickMedia function with the context,
                          //addDescription, and appState as parameters
                        ),
                        ],
                      ),
                    ),
                    Expanded(
                      //Expanded widget to expand the text input field
                    child: Padding(
                        //Padding widget to add padding to the text input field
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Enter your message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      //Displays a microphone button for speech-to-text
                    onPressed: () {
                        //Function to be executed when the button is pressed
                      showDialog(
                          //Displays a dialog box for speech-to-text
                        context: context, //Context for the dialog box
                          builder: (context) =>
                            const Speech(), //Speech dialog box
                        // will be opened up when the microphone button is pressed
                        );
                      },
                      child:
                        const Icon(Icons.mic), // Icon for the microphone button
                    ),
                  ], //end of children
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
      //This places the FAB at the center of the bottom of the screen, docked 
      //within the BottomAppBar.
    ));
  }
}
