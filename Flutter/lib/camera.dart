import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'gradient_container.dart';

class MyApp2 extends StatelessWidget {
  const MyApp2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //i am returning a widget
    //that's the reason i had written Widget first.
    //i think build i a built-in method which i am overriding according to my
    //convenience.

    // return const MaterialApp(home: Scaffold(body: Text('Hello Dad!')));
    //  this was before and whatever your seeing below is after adding
    //the existing widget into another centre widget to make the hello dad
    //to appear in centre of the screen
    /*for performing the above thing you need to go and right click
    on the Text and select the wrap with centre option */

    return MaterialApp(
      home: Scaffold(
        // backgroundColor: Color.fromARGB(255, 131, 127, 89),
        // for accessing the above features we need to click on
        // ctrl+space bar.for broad variety of arguments
        body: GradientContainer(),
      ),
    );
  }
}
