import 'package:flutter/material.dart';

import 'styled_text.dart';

class GradientContainer extends StatelessWidget {
  // {}->for named params
  // (a,b)->for positional params.
  GradientContainer({super.key});
  // const is kept to unlock the potential
  // optimization.
  //a key needed to be passed by the child to the
  //parent after the creation of the child in the
  //constructor.
  //so for that.
  //initialization work.
  // GradientContainer({super.key})
  // for so that sake we give a named argument to the
  //constructor named super.key
  //this key will be passed to the parent by the child.
  // in the form of a named argument.
  // const can be added to optimize the runtime performance.

  var startAlignment = Alignment.topLeft;
  // in dart variable types are assigned by themselves only
  //and the typed will only have all the type of values
  //they are assigned for the rest of it's life.
  //eg->in this case it's Alignment is the only type of the
  //variable it is assigned to.and that variable can only
  //store Alignment type of variables.
  /*in those cases where i don't know which type of variable
  will be stored inside that variable i can add dynamic
  ,initialize dynamic variables instead.but i might incur
  few bugs while dealing with such things.
  
  one more way is that if i know what is the type i want to
  store in that variable i can initialize that variable like
  that only 
  Eg->Alignment startAlignment;
  but even though like this also we might have errors because
  we are not assigning anything to it,
  while we are initializing
  so in those cases it is storing a null values
  to allow our varible to store a null value while 
  initialzing it is by adding a ? tag after Alignment
  (yes the dataType i mean)
  Eg->Alignment ? startAlignment;
  means it is either the type alignment or null
  so it's optional wheather it's set or not.
  type inference-->read about it
  */
  var endAlignment = Alignment.bottomRight;

  @override
  Widget build(context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [
            Color.fromARGB(255, 255, 255, 255),
            Color.fromARGB(255, 178, 18, 18)
          ],
          begin: startAlignment,
          end: endAlignment,
          // press ctrl+space for suggestions.
        ),
      ),
      // you cannot add const to the constainer's prefix,hence
      // you can't add const to it's parents also
      // so i removed const infront of materialApp widget too
      // which i was returning.
      child: const Center(
        child: StyledText(),
      ),
    );
  }
}
